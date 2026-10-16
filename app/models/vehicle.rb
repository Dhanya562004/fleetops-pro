class Vehicle < ApplicationRecord
  STATUSES = %w[inspection_pending in_repair awaiting_parts quality_check ready out_of_service in_transit].freeze

  belongs_to :lot, optional: true
  has_many :maintenance_tickets, dependent: :restrict_with_error
  has_many :moves, dependent: :restrict_with_error
  after_commit -> { Rails.cache.delete("fleet_metrics:v1") }, on: %i[create update destroy]

  validates :vin, presence: true, uniqueness: true, length: { is: 17 }
  validates :make, :model, presence: true
  validates :year, numericality: { only_integer: true, greater_than_or_equal_to: 2000, less_than_or_equal_to: 2100 }
  validates :mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :available, -> { where(status: "ready") }
  scope :search, ->(term) {
    return all if term.blank?

    escaped = "%#{sanitize_sql_like(term.strip)}%"
    where("vin ILIKE :term OR make ILIKE :term OR model ILIKE :term", term: escaped)
  }
end
