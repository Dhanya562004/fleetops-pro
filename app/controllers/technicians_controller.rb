class TechniciansController < ApplicationController
  def index
    roster = current_user.technician? ? User.where(id: current_user.id) : User.technician.where(active: true)
    technicians = roster.order(:name).to_a
    tickets_by_technician = MaintenanceTicket.includes(:vehicle).where(technician_id: technicians.map(&:id)).active.order(priority: :desc, updated_at: :asc).group_by(&:technician_id)
    technicians = technicians.map do |technician|
      tickets = tickets_by_technician.fetch(technician.id, [])
      {
        id: technician.id,
        name: technician.name,
        specialty: technician.specialty,
        workload: tickets.size,
        blocked_count: tickets.count { |ticket| ticket.status == "awaiting_parts" },
        tickets: tickets.first(5).as_json(include: { vehicle: {} })
      }
    end
    render inertia: "Technicians/Index", props: { technicians: }
  end
end
