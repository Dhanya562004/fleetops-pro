require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  test "vehicle report exports filtered rows as CSV for a signed-in ops manager" do
    user = create_user
    create_vehicle(status: "ready")
    create_vehicle(status: "in_repair")
    post session_path, params: { email: user.email, password: "test-password" }

    get export_vehicles_path(format: :csv, status: "ready")

    assert_response :success
    assert_match "text/csv", response.media_type
    assert_includes response.body, "VIN,Make,Model,Year,Status,Lot,Mileage"
    assert_equal 2, response.body.lines.length
  end

  test "technicians cannot create vehicle records" do
    technician = create_user(role: "technician")
    post session_path, params: { email: technician.email, password: "test-password" }

    post vehicles_path, params: { vehicle: { vin: "FOPIN000000000011", make: "Tata", model: "Nexon", year: 2024 } }

    assert_response :forbidden
    assert_not Vehicle.exists?(vin: "FOPIN000000000011")
  end
end
