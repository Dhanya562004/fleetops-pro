require "test_helper"

class Parts::RequestForTicketTest < ActiveSupport::TestCase
  test "short stock blocks repair and fulfillment resumes the ticket" do
    vehicle = create_vehicle(status: "in_repair")
    ticket = create_ticket(vehicle:, status: "repair")
    supplier = Supplier.create!(name: "Test supplier #{SecureRandom.hex(3)}")
    part = Part.create!(sku: "TEST-#{SecureRandom.hex(3)}", name: "Alternator belt", supplier:, stock_quantity: 0, reorder_threshold: 2)

    request = Parts::RequestForTicket.call(ticket:, part:, quantity: 1)
    assert_equal "awaiting_parts", ticket.reload.status
    assert_equal "awaiting_parts", vehicle.reload.status

    part.update!(stock_quantity: 1)
    Parts::FulfillRequest.call(ticket_part: request, quantity: 1)

    assert_equal 0, part.reload.stock_quantity
    assert_equal "repair", ticket.reload.status
    assert_equal "in_repair", vehicle.reload.status
    assert_not ticket.parts_shortage?
  end
end
