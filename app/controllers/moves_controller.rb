class MovesController < ApplicationController
  before_action -> { require_role!("admin", "ops_manager") }

  def create
    vehicle = Vehicle.find(params[:vehicle_id])
    destination = Lot.find(params[:lot_id])
    Lots::MoveVehicle.call(vehicle:, to_lot: destination, reason: params[:reason], actor: current_user)
    redirect_to lots_path, notice: "Vehicle moved to #{destination.name}"
  rescue Lots::MoveVehicle::CapacityExceeded, Lots::MoveVehicle::InvalidMove, ActiveRecord::RecordInvalid => error
    redirect_to lots_path, alert: error.message
  end
end
