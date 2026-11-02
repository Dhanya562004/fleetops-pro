class RefreshShortageReportJob
  include Sidekiq::Job

  sidekiq_options queue: "reports"

  CACHE_KEY = "fleetops:shortage_report"
  EXPIRY = 5.minutes.to_i

  def perform
    report = Parts::ShortageDelayReport.call
    parts_count = report[:parts]&.size || 0
    blocked_count = report[:blocked_tickets]&.size || 0
    shortages_count = parts_count + blocked_count

    payload = report.to_json

    Sidekiq.redis do |redis|
      redis.set(CACHE_KEY, payload, ex: EXPIRY)
    end

    logger.info("Refreshed parts shortage report: #{shortages_count} shortages processed (#{parts_count} low-stock parts, #{blocked_count} blocked tickets)")
    shortages_count
  end
end
