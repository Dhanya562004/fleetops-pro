module FleetTestHelpers
  def create_user(role: "ops_manager")
    User.create!(name: "Test #{role}", email: "#{role}-#{SecureRandom.hex(4)}@fleetops.test", password: "test-password", role:)
  end

  def create_lot(name: "Test lot", capacity: 3)
    Lot.create!(name: "#{name} #{SecureRandom.hex(3)}", city: "Pune", capacity:)
  end

  def create_vehicle(lot: nil, status: "ready")
    Vehicle.create!(vin: "FOPIN#{SecureRandom.hex(6).upcase}", make: "Tata", model: "Nexon", year: 2024, status:, lot:, mileage: 12_000)
  end

  def create_ticket(vehicle: create_vehicle, technician: nil, status: "inspection")
    MaintenanceTicket.create!(vehicle:, technician:, title: "Brake inspection", category: "brakes", priority: "normal", status:, estimated_hours: 2)
  end
end
