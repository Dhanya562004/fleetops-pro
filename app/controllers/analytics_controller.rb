class AnalyticsController < ApplicationController
  def show
    render inertia: "Analytics/Show", props: { metrics: FleetMetricsQuery.call, generated_at: Time.current.iso8601 }
  end
end
