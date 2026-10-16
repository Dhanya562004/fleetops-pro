namespace :data_quality do
  desc "Report and quarantine known malformed legacy import rows"
  task investigate: :environment do
    result = DataQuality::QuarantineLegacyRows.call
    result.each { |issue, count| puts "Quarantined #{count} #{issue} legacy row(s)" }
    puts "No unprocessed legacy data issues" if result.empty?
  end
end
