require "test_helper"

class Lots::MoveVehicleTest < ActiveSupport::TestCase
  test "records a transfer and updates the current lot" do
    source = create_lot(name: "Source")
    destination = create_lot(name: "Destination")
    vehicle = create_vehicle(lot: source)

    result = Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: "Rebalance morning returns")

    assert_equal destination, result.reload.lot
    move = Move.sole
    assert_equal source, move.from_lot
    assert_equal destination, move.to_lot
    assert_equal "Rebalance morning returns", move.reason
  end

  test "refuses to exceed destination capacity without moving the vehicle" do
    source = create_lot(name: "Source", capacity: 2)
    destination = create_lot(name: "Full", capacity: 1)
    vehicle = create_vehicle(lot: source)
    create_vehicle(lot: destination)

    assert_raises(Lots::MoveVehicle::CapacityExceeded) do
      Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: "Capacity test")
    end
    assert_equal source, vehicle.reload.lot
    assert_empty Move.all
  end
end
