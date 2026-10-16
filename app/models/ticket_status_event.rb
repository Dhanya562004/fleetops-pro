class TicketStatusEvent < ApplicationRecord
  belongs_to :maintenance_ticket
  belongs_to :user, optional: true

  validates :to_status, inclusion: { in: MaintenanceTicket::STATUSES }
end
