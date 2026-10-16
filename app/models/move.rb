class Move < ApplicationRecord
  belongs_to :vehicle
  belongs_to :from_lot, class_name: "Lot", optional: true
  belongs_to :to_lot, class_name: "Lot"
  belongs_to :moved_by, class_name: "User", optional: true

  validates :reason, presence: true
  validate :lots_must_differ

  private

  def lots_must_differ
    errors.add(:to_lot, "must be different from the current lot") if from_lot_id.present? && from_lot_id == to_lot_id
  end
end
