require "test_helper"

class Maintenance::TransitionTest < ActiveSupport::TestCase
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

  test "rejects a transition outside the workflow graph" do
    ticket = create_ticket
    assert_raises(Maintenance::Transition::InvalidTransition) do
      Maintenance::Transition.call(ticket:, to: "ready")
    end
    assert_equal "inspection", ticket.reload.status
    assert_empty ticket.ticket_status_events
  end

  test "prevents quality check while a requested part is unfulfilled" do
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
end
