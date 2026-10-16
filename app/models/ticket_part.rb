class TicketPart < ApplicationRecord
  belongs_to :maintenance_ticket
  belongs_to :part

  validates :quantity_requested, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity_fulfilled, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :part_id, uniqueness: { scope: :maintenance_ticket_id }
  validate :fulfilled_quantity_does_not_exceed_request

  private

  def fulfilled_quantity_does_not_exceed_request
    return if quantity_fulfilled.to_i <= quantity_requested.to_i

    errors.add(:quantity_fulfilled, "cannot exceed quantity requested")
  end
end
