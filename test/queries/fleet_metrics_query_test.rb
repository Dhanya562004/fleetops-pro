require "test_helper"

class FleetMetricsQueryTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @original_cache = Rails.cache
    @memory_store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache = @memory_store
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "cache miss executes query and stores result in Rails.cache" do
    assert_nil Rails.cache.read(FleetMetricsQuery::CACHE_KEY)

    metrics = FleetMetricsQuery.call

    assert_kind_of Hash, metrics
    assert metrics.key?("tickets_by_status")
    assert metrics.key?("availability_percent")
    assert metrics.key?("average_repair_hours")

    cached = Rails.cache.read(FleetMetricsQuery::CACHE_KEY)
    assert_equal metrics, cached
  end

  test "cache hit returns the cached payload without querying the database" do
    cached_payload = {
      "average_repair_hours" => 99.5,
      "average_downtime_hours" => 12.0,
      "availability_percent" => 88.0,
      "parts_shortage_waiting_hours" => 0.0,
      "tickets_by_status" => { "ready" => 42 }
    }
    Rails.cache.write(FleetMetricsQuery::CACHE_KEY, cached_payload, expires_in: 15.minutes)

    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end

    begin
      result = FleetMetricsQuery.call
      assert_equal 99.5, result["average_repair_hours"]
      assert_equal 88.0, result["availability_percent"]
      assert_equal({ "ready" => 42 }, result["tickets_by_status"])
      assert_empty queries, "Expected zero database queries on cache hit"
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  test "cache expires after 15 minutes TTL" do
    initial = FleetMetricsQuery.call
    assert_not_nil Rails.cache.read(FleetMetricsQuery::CACHE_KEY)

    # Travel 16 minutes into the future to exceed the 15.minute TTL
    travel 16.minutes do
      assert_nil Rails.cache.read(FleetMetricsQuery::CACHE_KEY)

      refreshed = FleetMetricsQuery.call
      assert_kind_of Hash, refreshed
      assert_not_nil Rails.cache.read(FleetMetricsQuery::CACHE_KEY)
    end
  end

  test "explicit cache deletion forces a cache miss and re-fetches" do
    first_call = FleetMetricsQuery.call
    assert_equal first_call, Rails.cache.read(FleetMetricsQuery::CACHE_KEY)

    Rails.cache.delete(FleetMetricsQuery::CACHE_KEY)
    assert_nil Rails.cache.read(FleetMetricsQuery::CACHE_KEY)

    second_call = FleetMetricsQuery.call
    assert_equal second_call, Rails.cache.read(FleetMetricsQuery::CACHE_KEY)
  end
end
