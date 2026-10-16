require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  test "vehicle report exports filtered rows as CSV for a signed-in ops manager" do
    user = create_user
    available = create_vehicle(status: "ready")
    unavailable = create_vehicle(status: "in_repair")
    post session_path, params: { email: user.email, password: "test-password" }
    assert_redirected_to root_path

    get export_vehicles_path(format: :csv, status: "ready")

    assert_response :success
    assert_match "text/csv", response.media_type
    rows = CSV.parse(response.body, headers: true)
    assert_includes rows.map { |row| row["VIN"] }, available.vin
    refute_includes rows.map { |row| row["VIN"] }, unavailable.vin
    assert rows.all? { |row| row["Status"] == "ready" }
  end

  test "technicians cannot create vehicle records" do
    technician = create_user(role: "technician")
    post session_path, params: { email: technician.email, password: "test-password" }
    assert_redirected_to root_path

    vin = "FOPIN#{SecureRandom.hex(6).upcase}"
    assert_no_difference("Vehicle.count") do
      post vehicles_path, params: { vehicle: { vin:, make: "Tata", model: "Nexon", year: 2024 } }
    end

    assert_response :forbidden
  end
end
