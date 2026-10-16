ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/fleet_test_helpers"

class ActiveSupport::TestCase
  include FleetTestHelpers
  parallelize(workers: 1)
end
