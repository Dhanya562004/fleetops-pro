require "test_helper"

class NotificationProcessingJobTest < ActiveSupport::TestCase
  test "retries with the same idempotency key produce one processed notification" do
    recipient = create_user
    arguments = { recipient_id: recipient.id, topic: "low_stock", idempotency_key: "low-stock:test:#{recipient.id}", payload: { part_id: 7 } }

    2.times { NotificationProcessingJob.perform_now(**arguments) }

    assert_equal 1, Notification.where(idempotency_key: arguments[:idempotency_key]).count
    assert Notification.sole.processed_at?
  end
end
