class DashboardController < ApplicationController
  def show
    render inertia: "Dashboard/Show", props: {
      metrics: FleetMetricsQuery.call,
      urgent_tickets: MaintenanceTicket.includes(:vehicle, :technician).where(priority: "urgent").active.order(created_at: :asc).limit(6).as_json(include: { vehicle: {}, technician: { only: %i[id name role] } }),
      full_lots: Lot.includes(:vehicles).order(:name).select { |lot| lot.occupancy_percent >= 85 }
    }
  end
end
