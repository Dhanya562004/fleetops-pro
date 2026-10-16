require "test_helper"
require "json"

class ViteProductionConfigTest < ActiveSupport::TestCase
  test "production assets are built at image build time, not during requests" do
    config = JSON.parse(Rails.root.join("config/vite.json").read)

    assert_equal false, config.dig("production", "autoBuild")
    assert_equal "vite", config.dig("production", "publicOutputDir")
  end
end
