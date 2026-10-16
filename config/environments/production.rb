Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.force_ssl = ENV["FORCE_SSL"] == "true"
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.active_storage.service = :local
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  if ENV["RAILS_LOG_TO_STDOUT"].present? || ENV["RENDER"].present? || !Rails.env.local?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter || ::Logger::Formatter.new
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.log_tags = [ :request_id ]
end
