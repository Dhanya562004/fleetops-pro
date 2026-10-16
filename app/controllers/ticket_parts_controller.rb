class TicketPartsController < ApplicationController
  before_action :set_ticket
  before_action :authorize_ticket_mutation!

  def create
    part = Part.find(params[:part_id])
    Parts::RequestForTicket.call(ticket: @ticket, part:, quantity: params[:quantity], actor: current_user)
    redirect_to maintenance_ticket_path(@ticket), notice: "Part request added"
  rescue ActiveRecord::RecordInvalid, ArgumentError => error
    redirect_to maintenance_ticket_path(@ticket), alert: error.message
  end

  def fulfill
    request = @ticket.ticket_parts.find(params[:id])
    Parts::FulfillRequest.call(ticket_part: request, quantity: params[:quantity], actor: current_user)
    redirect_to maintenance_ticket_path(@ticket), notice: "Part request fulfilled"
  rescue ActiveRecord::RecordInvalid, Parts::FulfillRequest::InsufficientStock, ArgumentError => error
    redirect_to maintenance_ticket_path(@ticket), alert: error.message
  end

  private

  def set_ticket
    @ticket = MaintenanceTicket.find(params[:maintenance_ticket_id])
  end

  def authorize_ticket_mutation!
    return if current_user.admin? || current_user.ops_manager?
    return if current_user.technician? && @ticket.technician_id == current_user.id

    head :forbidden
  end
end
