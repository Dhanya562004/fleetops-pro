class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  validates :topic, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: true
end
