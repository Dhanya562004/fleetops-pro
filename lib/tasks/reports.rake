namespace :reports do
  desc "Enqueue Sidekiq job to refresh the parts-shortage delay report"
  task refresh_shortage: :environment do
    job_id = RefreshShortageReportJob.perform_async
    puts "Enqueued RefreshShortageReportJob (jid: #{job_id}) on 'reports' queue"
  end
end
