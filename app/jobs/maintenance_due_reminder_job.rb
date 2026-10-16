class MaintenanceDueReminderJob < ApplicationJob
  def perform
    cutoff = 90.days.ago
    User.ops_manager.where(active: true).find_each do |recipient|
      Vehicle.where(status: "ready").where("last_inspected_at IS NULL OR last_inspected_at < ?", cutoff).find_each do |vehicle|
        NotificationProcessingJob.perform_later(
          recipient_id: recipient.id,
          topic: "maintenance_due",
          idempotency_key: "maintenance-due:#{Date.current}:#{recipient.id}:#{vehicle.id}",
          payload: { vehicle_id: vehicle.id, vin: vehicle.vin }
        )
      end
    end
  end
end
