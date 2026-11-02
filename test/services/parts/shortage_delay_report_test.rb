require "test_helper"

class ShortageDelayReportTest < ActiveSupport::TestCase
  test "returns low-stock parts and blocked maintenance tickets with correct structure" do
    supplier = Supplier.create!(name: "Bosch Automotive #{SecureRandom.hex(3)}")
    low_stock_part = Part.create!(
      sku: "OIL-#{SecureRandom.hex(3)}",
      name: "Oil Filter",
      supplier:,
      stock_quantity: 1,
      reorder_threshold: 3,
      unit_cost: 15
    )
    in_stock_part = Part.create!(
      sku: "SPARK-#{SecureRandom.hex(3)}",
      name: "Spark Plug",
      supplier:,
      stock_quantity: 50,
      reorder_threshold: 10,
      unit_cost: 8
    )

    technician = create_user(role: "technician")
    vehicle = create_vehicle
    blocked_ticket = create_ticket(vehicle:, technician:, status: "awaiting_parts")
    TicketPart.create!(
      maintenance_ticket: blocked_ticket,
      part: low_stock_part,
      quantity_requested: 2,
      quantity_fulfilled: 0
    )

    ready_ticket = create_ticket(vehicle: create_vehicle, status: "ready")

    report = Parts::ShortageDelayReport.call

    assert_kind_of Hash, report
    assert report.key?(:parts)
    assert report.key?(:blocked_tickets)

    part_ids = report[:parts].map { |p| p["id"] }
    assert_includes part_ids, low_stock_part.id
    assert_not_includes part_ids, in_stock_part.id

    blocked_ticket_ids = report[:blocked_tickets].map { |t| t["id"] }
    assert_includes blocked_ticket_ids, blocked_ticket.id
    assert_not_includes blocked_ticket_ids, ready_ticket.id

    blocked_ticket_data = report[:blocked_tickets].find { |t| t["id"] == blocked_ticket.id }
    assert_equal vehicle.id, blocked_ticket_data["vehicle"]["id"]
    assert_equal technician.id, blocked_ticket_data["technician"]["id"]
    assert_equal 1, blocked_ticket_data["ticket_parts"].size
    assert_equal low_stock_part.id, blocked_ticket_data["ticket_parts"].first["part"]["id"]
  end
end
