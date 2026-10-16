class Part < ApplicationRecord
  belongs_to :supplier
  has_many :ticket_parts, dependent: :restrict_with_error
  has_many :maintenance_tickets, through: :ticket_parts
  after_commit -> { Rails.cache.delete("fleet_metrics:v1") }, on: %i[create update destroy]

  validates :sku, :name, presence: true
  validates :sku, uniqueness: true
  validates :stock_quantity, :reorder_threshold, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  scope :low_stock, -> { where("stock_quantity <= reorder_threshold") }
end
