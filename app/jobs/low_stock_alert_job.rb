class LowStockAlertJob < ApplicationJob
  def perform
    User.where(role: %w[admin ops_manager], active: true).find_each do |recipient|
      Part.low_stock.find_each do |part|
        NotificationProcessingJob.perform_later(
          recipient_id: recipient.id,
          topic: "low_stock",
          idempotency_key: "low-stock:#{Date.current}:#{recipient.id}:#{part.id}",
          payload: { part_id: part.id, sku: part.sku, stock_quantity: part.stock_quantity }
        )
      end
    end
  end
end
