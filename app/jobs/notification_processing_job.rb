class NotificationProcessingJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(recipient_id:, topic:, idempotency_key:, payload: {})
    notification = Notification.create_or_find_by!(idempotency_key:) do |record|
      record.recipient_id = recipient_id
      record.topic = topic
      record.payload = payload
    end
    return if notification.processed_at?

    notification.update!(processed_at: Time.current)
  end
end
