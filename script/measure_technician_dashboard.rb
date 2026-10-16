require "json"

module TechnicianDashboardBenchmark
  module_function

  def legacy_query_shape
    User.technician.where(active: true).order(:name).map do |technician|
      technician.assigned_tickets.includes(:vehicle).active.order(priority: :desc, updated_at: :asc).load
    end
  end

  def batched_query_shape
    technicians = User.technician.where(active: true).order(:name).to_a
    tickets = MaintenanceTicket.includes(:vehicle)
      .where(technician_id: technicians.map(&:id))
      .active
      .order(priority: :desc, updated_at: :asc)
      .group_by(&:technician_id)
    technicians.map { |technician| tickets.fetch(technician.id, []) }
  end

  def measure
    query_count = 0
    subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
      query_count += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
    end
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
    elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000
    { query_count:, elapsed_ms: elapsed_ms.round(2) }
  end
end

TechnicianDashboardBenchmark.legacy_query_shape
TechnicianDashboardBenchmark.batched_query_shape
puts JSON.pretty_generate({
  technician_count: User.technician.where(active: true).count,
  active_ticket_count: MaintenanceTicket.active.count,
  baseline: TechnicianDashboardBenchmark.measure { TechnicianDashboardBenchmark.legacy_query_shape },
  optimized: TechnicianDashboardBenchmark.measure { TechnicianDashboardBenchmark.batched_query_shape }
})
