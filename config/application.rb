require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module FleetOpsPro
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :primary } }
    config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
    config.generators.system_tests = nil
  end
end
