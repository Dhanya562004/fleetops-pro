class TicketComment < ApplicationRecord
  belongs_to :maintenance_ticket
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2_000 }
end
