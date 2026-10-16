class PartsController < ApplicationController
  def shortages
    render inertia: "Parts/Shortages", props: {
      parts: Part.low_stock.includes(:supplier).order(:stock_quantity).as_json(include: { supplier: { only: %i[id name] } }),
      blocked_tickets: MaintenanceTicket.blocked.includes(:vehicle, :technician, ticket_parts: :part).order(updated_at: :asc).as_json(include: { vehicle: {}, technician: { only: %i[id name role] }, ticket_parts: { include: { part: {} } } })
    }
  end
end
