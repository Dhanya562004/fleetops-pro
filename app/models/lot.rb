class Lot < ApplicationRecord
  has_many :vehicles, dependent: :nullify
  has_many :departures, class_name: "Move", foreign_key: :from_lot_id, dependent: :restrict_with_error
  has_many :arrivals, class_name: "Move", foreign_key: :to_lot_id, dependent: :restrict_with_error

  validates :name, :city, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }

  def occupancy
    vehicles.size
  end

  def occupancy_percent
    (occupancy.to_f / capacity * 100).round
  end

  def at_capacity?
    occupancy >= capacity
  end
end
