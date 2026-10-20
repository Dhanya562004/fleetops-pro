require "test_helper"

class Maintenance::TransitionTest < ActiveSupport::TestCase
  VALID_TRANSITIONS = {
    "inspection" => %w[repair cancelled],
    "repair" => %w[quality_check awaiting_parts cancelled],
    "awaiting_parts" => %w[repair cancelled],
    "quality_check" => %w[repair ready cancelled],
    "ready" => [],
    "cancelled" => []
  }.freeze

  ALL_STATUSES = MaintenanceTicket::STATUSES

  test "moves inspection to repair and writes an audit event" do
    vehicle = create_vehicle(status: "inspection_pending")
    ticket = create_ticket(vehicle:)
    actor = create_user

    Maintenance::Transition.call(ticket:, to: "repair", actor:, note: "Inspection passed")

    assert_equal "repair", ticket.reload.status
    assert_equal "in_repair", vehicle.reload.status
    event = ticket.ticket_status_events.sole
    assert_equal "inspection", event.from_status
    assert_equal "repair", event.to_status
    assert_equal actor, event.user
  end

  test "sets completed_at timestamp when transitioning quality_check to ready" do
    vehicle = create_vehicle(status: "quality_check")
    ticket = create_ticket(vehicle:, status: "quality_check")
    ticket.update_columns(started_at: 2.hours.ago, completed_at: nil)
    actor = create_user

    Maintenance::Transition.call(ticket:, to: "ready", actor:, note: "All checks passed")

    assert_equal "ready", ticket.reload.status
    assert_equal "ready", vehicle.reload.status
    assert_not_nil ticket.completed_at
    event = ticket.ticket_status_events.sole
    assert_equal "quality_check", event.from_status
    assert_equal "ready", event.to_status
  end

  test "preserves vehicle status when cancelling a ticket" do
    vehicle = create_vehicle(status: "in_repair")
    ticket = create_ticket(vehicle:, status: "repair")

    Maintenance::Transition.call(ticket:, to: "cancelled", note: "Ticket superseded")

    assert_equal "cancelled", ticket.reload.status
    assert_equal "in_repair", vehicle.reload.status
    assert_nil ticket.completed_at
  end

  test "prevents quality check while a requested part is unfulfilled (out of stock)" do
    ticket = create_ticket(status: "repair")
    supplier = Supplier.create!(name: "Test supplier #{SecureRandom.hex(3)}")
    part = Part.create!(sku: "TEST-#{SecureRandom.hex(3)}", name: "Brake pads", supplier:, stock_quantity: 0, reorder_threshold: 1)
    ticket.ticket_parts.create!(part:, quantity_requested: 1)

    assert_raises(Maintenance::Transition::InvalidTransition) do
      Maintenance::Transition.call(ticket:, to: "quality_check")
    end
  end

  test "does not allow quality check before stocked parts are fulfilled" do
    ticket = create_ticket(status: "repair")
    supplier = Supplier.create!(name: "Test supplier #{SecureRandom.hex(3)}")
    part = Part.create!(sku: "TEST-#{SecureRandom.hex(3)}", name: "Brake pads", supplier:, stock_quantity: 4, reorder_threshold: 1)
    ticket.ticket_parts.create!(part:, quantity_requested: 1)

    assert_raises(Maintenance::Transition::InvalidTransition) do
      Maintenance::Transition.call(ticket:, to: "quality_check")
    end
  end

  test "allows quality check when all requested parts are fulfilled" do
    ticket = create_ticket(status: "repair")
    supplier = Supplier.create!(name: "Test supplier #{SecureRandom.hex(3)}")
    part = Part.create!(sku: "TEST-#{SecureRandom.hex(3)}", name: "Brake pads", supplier:, stock_quantity: 4, reorder_threshold: 1)
    ticket.ticket_parts.create!(part:, quantity_requested: 2, quantity_fulfilled: 2)

    Maintenance::Transition.call(ticket:, to: "quality_check")
    assert_equal "quality_check", ticket.reload.status
  end

  test "validates every valid transition across the repair state machine" do
    VALID_TRANSITIONS.each do |from_status, valid_targets|
      valid_targets.each do |to_status|
        ticket = create_ticket(status: from_status)
        actor = create_user

        # Ensure parts are fulfilled if testing transition into quality_check
        if to_status == "quality_check"
          supplier = Supplier.create!(name: "Supplier #{SecureRandom.hex(3)}")
          part = Part.create!(sku: "SKU-#{SecureRandom.hex(3)}", name: "Filter", supplier:, stock_quantity: 1, reorder_threshold: 0)
          ticket.ticket_parts.create!(part:, quantity_requested: 1, quantity_fulfilled: 1)
        end

        result = Maintenance::Transition.call(ticket:, to: to_status, actor:, note: "Testing #{from_status} -> #{to_status}")

        assert_equal to_status, result.reload.status, "Expected ticket to transition from #{from_status} to #{to_status}"
        assert_not_nil result.started_at
        if to_status == "ready"
          assert_not_nil result.completed_at
        else
          assert_nil result.completed_at
        end

        event = result.ticket_status_events.sole
        assert_equal from_status, event.from_status
        assert_equal to_status, event.to_status
      end
    end
  end

  test "rejects every invalid transition across the entire state machine matrix" do
    ALL_STATUSES.each do |from_status|
      valid_targets = VALID_TRANSITIONS.fetch(from_status, [])
      invalid_targets = ALL_STATUSES - valid_targets

      invalid_targets.each do |to_status|
        ticket = create_ticket(status: from_status)

        error = assert_raises(Maintenance::Transition::InvalidTransition, "Expected #{from_status} -> #{to_status} to be rejected") do
          Maintenance::Transition.call(ticket:, to: to_status)
        end

        assert_match(/Cannot move ticket from #{from_status} to #{to_status}/, error.message)
        assert_equal from_status, ticket.reload.status
        assert_empty ticket.ticket_status_events
      end
    end
  end

  test "terminal states ready and cancelled reject transitions to all statuses" do
    %w[ready cancelled].each do |terminal_status|
      ALL_STATUSES.each do |target_status|
        ticket = create_ticket(status: terminal_status)
        assert_raises(Maintenance::Transition::InvalidTransition) do
          Maintenance::Transition.call(ticket:, to: target_status)
        end
        assert_equal terminal_status, ticket.reload.status
      end
    end
  end

  test "rejects transitions to unknown arbitrary statuses" do
    ticket = create_ticket(status: "inspection")
    assert_raises(Maintenance::Transition::InvalidTransition) do
      Maintenance::Transition.call(ticket:, to: "in_the_cloud")
    end
    assert_equal "inspection", ticket.reload.status
    assert_empty ticket.ticket_status_events
  end
end
