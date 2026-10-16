class FleetMetricsQuery
  CACHE_KEY = "fleet_metrics:v1"

  SQL = <<~SQL.freeze
    WITH completed_tickets AS (
      SELECT EXTRACT(EPOCH FROM (completed_at - started_at)) / 3600.0 AS repair_hours
      FROM maintenance_tickets
      WHERE status = 'ready' AND started_at IS NOT NULL AND completed_at IS NOT NULL
    ),
    status_totals AS (
      SELECT status, COUNT(*) AS ticket_count
      FROM maintenance_tickets
      GROUP BY status
    ),
    ranked_statuses AS (
      SELECT status, ticket_count,
             ROW_NUMBER() OVER (ORDER BY ticket_count DESC, status) AS status_rank
      FROM status_totals
    ),
    workflow_events AS (
      SELECT events.maintenance_ticket_id, events.to_status, events.created_at,
             LEAD(events.created_at) OVER (PARTITION BY events.maintenance_ticket_id ORDER BY events.created_at) AS next_event_at
      FROM ticket_status_events events
    ),
    workflow_intervals AS (
      SELECT tickets.vehicle_id, events.to_status,
             EXTRACT(EPOCH FROM (COALESCE(events.next_event_at, NOW()) - events.created_at)) / 3600.0 AS hours_in_state
      FROM workflow_events events
      JOIN maintenance_tickets tickets ON tickets.id = events.maintenance_ticket_id
      WHERE events.to_status IN ('repair', 'awaiting_parts', 'quality_check')
    ),
    downtime_by_vehicle AS (
      SELECT vehicle_id, SUM(hours_in_state) AS downtime_hours
      FROM workflow_intervals
      GROUP BY vehicle_id
    ),
    shortage_impact AS (
      SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600.0), 0) AS waiting_hours
      FROM maintenance_tickets
      WHERE status = 'awaiting_parts'
    )
    SELECT
      COALESCE((SELECT AVG(repair_hours) FROM completed_tickets), 0) AS average_repair_hours,
      COALESCE((SELECT AVG(downtime_hours) FROM downtime_by_vehicle), 0) AS average_downtime_hours,
      CASE WHEN COUNT(vehicles.id) = 0 THEN 0
           ELSE ROUND(100.0 * COUNT(vehicles.id) FILTER (WHERE vehicles.status = 'ready') / COUNT(vehicles.id), 1)
      END AS availability_percent,
      (SELECT waiting_hours FROM shortage_impact) AS parts_shortage_waiting_hours,
      COALESCE((SELECT jsonb_object_agg(status, ticket_count) FROM ranked_statuses), '{}'::jsonb) AS tickets_by_status
    FROM vehicles
  SQL

  def self.call
    Rails.cache.fetch(CACHE_KEY, expires_in: 15.minutes) do
      result = ActiveRecord::Base.connection.select_one(SQL)
      status_counts = result.fetch("tickets_by_status")
      parsed_status_counts = status_counts.is_a?(String) ? JSON.parse(status_counts) : status_counts
      result.merge("tickets_by_status" => parsed_status_counts)
    end
  end
end
