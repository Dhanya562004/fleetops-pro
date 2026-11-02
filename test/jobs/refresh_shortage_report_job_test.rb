require "test_helper"
require "sidekiq/testing"

class RefreshShortageReportJobTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.fake!
    RefreshShortageReportJob.clear
    Sidekiq.redis { |r| r.del(RefreshShortageReportJob::CACHE_KEY) }
  end

  teardown do
    RefreshShortageReportJob.clear
    Sidekiq.redis { |r| r.del(RefreshShortageReportJob::CACHE_KEY) }
  end

  test "the job enqueues and runs" do
    assert_equal 0, RefreshShortageReportJob.jobs.size

    RefreshShortageReportJob.perform_async
    assert_equal 1, RefreshShortageReportJob.jobs.size
    assert_equal "reports", RefreshShortageReportJob.jobs.last["queue"]

    RefreshShortageReportJob.drain
    assert_equal 0, RefreshShortageReportJob.jobs.size

    cached = Sidekiq.redis { |r| r.get(RefreshShortageReportJob::CACHE_KEY) }
    assert_not_nil cached
  end

  test "the cache key is written with the correct expiry" do
    RefreshShortageReportJob.new.perform

    Sidekiq.redis do |r|
      assert_equal 1, r.exists(RefreshShortageReportJob::CACHE_KEY)
      ttl = r.ttl(RefreshShortageReportJob::CACHE_KEY)
      assert_operator ttl, :>, 0
      assert_operator ttl, :<=, 300
    end
  end

  test "running the job twice produces the same result (idempotency)" do
    RefreshShortageReportJob.new.perform
    first_result = Sidekiq.redis { |r| r.get(RefreshShortageReportJob::CACHE_KEY) }

    RefreshShortageReportJob.new.perform
    second_result = Sidekiq.redis { |r| r.get(RefreshShortageReportJob::CACHE_KEY) }

    assert_not_nil first_result
    assert_equal first_result, second_result
  end

  test "the job handles an empty shortage set without error" do
    singleton = Parts::ShortageDelayReport.singleton_class
    original_method = singleton.instance_method(:call)
    singleton.define_method(:call) { { parts: [], blocked_tickets: [] } }

    begin
      assert_nothing_raised do
        RefreshShortageReportJob.new.perform
      end

      cached = Sidekiq.redis { |r| r.get(RefreshShortageReportJob::CACHE_KEY) }
      assert_not_nil cached
      parsed = JSON.parse(cached)
      assert_equal([], parsed["parts"])
      assert_equal([], parsed["blocked_tickets"])
    ensure
      singleton.define_method(:call, original_method)
    end
  end
end
