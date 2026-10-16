class MaintenanceTicketsController < ApplicationController
  before_action :set_ticket, only: %i[show update transition activity]
  before_action :authorize_ticket_mutation!, only: %i[update transition]

  def index
    tickets = MaintenanceTicket.includes(:vehicle, :technician, ticket_parts: :part).order(updated_at: :desc)
    tickets = tickets.where(status: params[:status]) if MaintenanceTicket::STATUSES.include?(params[:status])
    render inertia: "Tickets/Index", props: { tickets: tickets.limit(100).as_json(include: { vehicle: {}, technician: { only: %i[id name role] } }), statuses: MaintenanceTicket::STATUSES }
  end

  def show
    render inertia: "Tickets/Show", props: {
      ticket: @ticket.as_json(include: { vehicle: {}, technician: { only: %i[id name email role] }, ticket_parts: { include: { part: {} } } }),
      comments: @ticket.ticket_comments.includes(:user).order(:created_at).as_json(include: { user: { only: %i[id name email role] } }),
      events: @ticket.ticket_status_events.includes(:user).order(:created_at).as_json(include: { user: { only: %i[id name email role] } }),
      technicians: User.technician.where(active: true).order(:name).select(:id, :name, :email, :role),
      parts: Part.order(:name).select(:id, :sku, :name, :stock_quantity)
    }
  end

  def update
    @ticket.update!(technician_id: params.dig(:maintenance_ticket, :technician_id))
    redirect_to maintenance_ticket_path(@ticket), notice: "Ticket assignment updated"
  rescue ActiveRecord::RecordInvalid => error
    redirect_to maintenance_ticket_path(@ticket), alert: error.message
  end

  def transition
    Maintenance::Transition.call(ticket: @ticket, to: params[:to], actor: current_user, note: params[:note])
    redirect_to maintenance_ticket_path(@ticket), notice: "Ticket moved to #{params[:to].humanize}"
  rescue Maintenance::Transition::InvalidTransition, ActiveRecord::RecordInvalid => error
    redirect_to maintenance_ticket_path(@ticket), alert: error.message
  end

  def activity
    @comments = @ticket.ticket_comments.includes(:user).order(created_at: :desc)
    render :activity, layout: "hotwire"
  end

  private

  def set_ticket
    @ticket = MaintenanceTicket.includes(:vehicle, :technician, ticket_parts: :part).find(params[:id])
  end

  def authorize_ticket_mutation!
    return if current_user.admin? || current_user.ops_manager?
    return if current_user.technician? && @ticket.technician_id == current_user.id

    head :forbidden
  end
end
