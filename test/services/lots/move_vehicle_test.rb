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

  test "moves a vehicle that has no current lot assigned" do
    destination = create_lot(name: "Intake", capacity: 5)
    vehicle = create_vehicle(lot: nil)

    result = Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: "New acquisition intake")

    assert_equal destination, result.reload.lot
    move = Move.sole
    assert_nil move.from_lot
    assert_equal destination, move.to_lot
    assert_equal "New acquisition intake", move.reason
  end

  test "raises InvalidMove when destination lot is identical to current lot" do
    lot = create_lot(name: "Same Lot", capacity: 5)
    vehicle = create_vehicle(lot:)

    error = assert_raises(Lots::MoveVehicle::InvalidMove) do
      Lots::MoveVehicle.call(vehicle:, to_lot: lot, reason: "Accidental self move")
    end
    assert_equal "Vehicle is already at this lot", error.message
    assert_empty Move.all
  end

  test "records actor when an operator executes the move" do
    operator = create_user(role: "ops_manager")
    source = create_lot(name: "Source Lot")
    destination = create_lot(name: "Target Lot")
    vehicle = create_vehicle(lot: source)

    Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: "Maintenance dispatch", actor: operator)

    move = Move.sole
    assert_equal operator, move.moved_by
  end

  test "invalidates fleet_metrics cache when move succeeds" do
    memory_store = ActiveSupport::Cache::MemoryStore.new
    memory_store.write("fleet_metrics:v1", { "cached" => true })
    original_cache = Rails.cache
    Rails.cache = memory_store

    source = create_lot(name: "A")
    destination = create_lot(name: "B")
    vehicle = create_vehicle(lot: source)

    begin
      Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: "Cache test")
      assert_nil Rails.cache.read("fleet_metrics:v1")
    ensure
      Rails.cache = original_cache
    end
  end

  test "allows moving into destination until capacity is reached exactly" do
    dest = create_lot(name: "Exact Fit", capacity: 2)
    source = create_lot(name: "Spillover", capacity: 5)

    v1 = create_vehicle(lot: source)
    v2 = create_vehicle(lot: source)
    v3 = create_vehicle(lot: source)

    Lots::MoveVehicle.call(vehicle: v1, to_lot: dest, reason: "Slot 1")
    Lots::MoveVehicle.call(vehicle: v2, to_lot: dest, reason: "Slot 2 (full)")
    assert_equal 2, dest.vehicles.count

    assert_raises(Lots::MoveVehicle::CapacityExceeded) do
      Lots::MoveVehicle.call(vehicle: v3, to_lot: dest, reason: "Slot 3 (overflow)")
    end
    assert_equal 2, dest.vehicles.count
  end
end
