class LotsController < ApplicationController
  def index
    render inertia: "Lots/Index", props: {
      lots: Lot.includes(:vehicles).order(:name).map do |lot|
        { id: lot.id, name: lot.name, city: lot.city, capacity: lot.capacity, occupancy: lot.occupancy, occupancy_percent: lot.occupancy_percent, at_capacity: lot.at_capacity? }
      end,
      vehicles: Vehicle.includes(:lot).where.not(lot_id: nil).order(:vin).map { |vehicle| { id: vehicle.id, vin: vehicle.vin, make: vehicle.make, model: vehicle.model, lot_id: vehicle.lot_id, lot: vehicle.lot.as_json(only: %i[id name city]) } }
    }
  end
end
