require "test_helper"

class Lots::AssignVehicleTest < ActiveSupport::TestCase
  test "rejects assigning a new vehicle to a full lot" do
    lot = create_lot(capacity: 1)
    create_vehicle(lot:)
    vehicle = Vehicle.new(vin: "FOPIN000000000099", make: "Tata", model: "Nexon", year: 2024, mileage: 0)

    assert_raises(Lots::AssignVehicle::CapacityExceeded) do
      Lots::AssignVehicle.call(vehicle:, attributes: { lot_id: lot.id })
    end
    assert_not vehicle.persisted?
  end
end
