require "csv"

class VehiclesController < ApplicationController
  before_action -> { require_role!("admin", "ops_manager") }, only: %i[create update destroy]
  before_action :set_vehicle, only: %i[show edit update destroy]

  def index
    vehicles = Vehicle.includes(:lot).search(params[:q])
    vehicles = vehicles.where(status: params[:status]) if Vehicle::STATUSES.include?(params[:status])
    vehicles = vehicles.where(lot_id: params[:lot_id]) if params[:lot_id].present?
    sort = %w[vin make model year status mileage].include?(params[:sort]) ? params[:sort] : "updated_at"
    direction = params[:direction] == "asc" ? "asc" : "desc"
    page = [ params[:page].to_i, 1 ].max

    render inertia: "Vehicles/Index", props: {
      vehicles: vehicles.order(sort => direction).limit(20).offset((page - 1) * 20).as_json(include: { lot: { only: %i[id name city] } }),
      lots: Lot.order(:name),
      filters: params.permit(:q, :status, :lot_id, :sort, :direction, :page).to_h,
      total: vehicles.count,
      page:
    }
  end

  def show
    render inertia: "Vehicles/Show", props: {
      vehicle: @vehicle.as_json(include: { lot: { only: %i[id name city] } }),
      tickets: @vehicle.maintenance_tickets.includes(:technician).order(created_at: :desc).as_json(include: { technician: { only: %i[id name role] } })
    }
  end

  def new
    render inertia: "Vehicles/Form", props: { vehicle: Vehicle.new, lots: Lot.order(:name) }
  end

  def create
    vehicle = Vehicle.new
    Lots::AssignVehicle.call(vehicle:, attributes: vehicle_params.to_h, actor: current_user)
    if vehicle.errors.empty?
      redirect_to vehicles_path, notice: "Vehicle added"
    else
      render inertia: "Vehicles/Form", props: { vehicle:, lots: Lot.order(:name) }, status: :unprocessable_entity
    end
  rescue Lots::AssignVehicle::CapacityExceeded => error
    render inertia: "Vehicles/Form", props: { vehicle:, lots: Lot.order(:name), form_error: error.message }, status: :unprocessable_entity
  end

  def edit
    render inertia: "Vehicles/Form", props: { vehicle: @vehicle, lots: Lot.order(:name) }
  end

  def update
    Lots::AssignVehicle.call(vehicle: @vehicle, attributes: vehicle_params.to_h, actor: current_user)
    if @vehicle.errors.empty?
      redirect_to vehicles_path, notice: "Vehicle updated"
    else
      render inertia: "Vehicles/Form", props: { vehicle: @vehicle, lots: Lot.order(:name) }, status: :unprocessable_entity
    end
  rescue Lots::AssignVehicle::CapacityExceeded => error
    render inertia: "Vehicles/Form", props: { vehicle: @vehicle, lots: Lot.order(:name), form_error: error.message }, status: :unprocessable_entity
  end

  def destroy
    if @vehicle.destroy
      redirect_to vehicles_path, notice: "Vehicle removed"
    else
      redirect_to vehicles_path, alert: @vehicle.errors.full_messages.to_sentence
    end
  end

  def export
    vehicles = Vehicle.includes(:lot).search(params[:q])
    vehicles = vehicles.where(status: params[:status]) if Vehicle::STATUSES.include?(params[:status])
    vehicles = vehicles.where(lot_id: params[:lot_id]) if params[:lot_id].present?
    csv = CSV.generate(headers: true) do |rows|
      rows << %w[VIN Make Model Year Status Lot Mileage]
      vehicles.order(:vin).find_each do |vehicle|
        rows << [ vehicle.vin, vehicle.make, vehicle.model, vehicle.year, vehicle.status, vehicle.lot&.name, vehicle.mileage ]
      end
    end
    send_data csv, filename: "fleet-vehicles-#{Date.current}.csv", type: "text/csv"
  end

  private

  def set_vehicle
    @vehicle = Vehicle.includes(:lot).find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:vin, :make, :model, :year, :status, :lot_id, :mileage)
  end
end
