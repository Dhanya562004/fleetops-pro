require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  test "VIN must be unique and exactly 17 characters" do
    lot = create_lot
    vehicle = create_vehicle(lot:)
    duplicate = Vehicle.new(vin: vehicle.vin, make: "Tata", model: "Nexon", year: 2024, lot:)
    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :vin
  end

  test "negative mileage is rejected by model validation" do
    vehicle = Vehicle.new(vin: "FOPIN000000000002", make: "Tata", model: "Nexon", year: 2024, mileage: -1)
    assert_not vehicle.valid?
    assert_includes vehicle.errors.attribute_names, :mileage
  end
end
