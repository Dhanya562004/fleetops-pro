class NightlyAnalyticsSnapshotJob < ApplicationJob
  def perform
    snapshot = AnalyticsSnapshot.find_or_initialize_by(snapshot_date: Date.current)
    return if snapshot.persisted?

    snapshot.metrics = FleetMetricsQuery.call
    snapshot.save!
  end
end
