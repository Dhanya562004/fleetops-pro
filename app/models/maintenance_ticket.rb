class MaintenanceTicket < ApplicationRecord
  STATUSES = %w[inspection repair quality_check awaiting_parts ready cancelled].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :vehicle
  belongs_to :technician, class_name: "User", optional: true
  has_many :ticket_parts, dependent: :destroy
  has_many :parts, through: :ticket_parts
  has_many :ticket_comments, dependent: :destroy
  has_many :ticket_status_events, dependent: :destroy
  after_commit -> { Rails.cache.delete("fleet_metrics:v1") }, on: %i[create update destroy]

  validates :title, :category, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :estimated_hours, numericality: { greater_than_or_equal_to: 0 }
  validates :actual_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :blocked, -> { where(status: "awaiting_parts") }
  scope :active, -> { where.not(status: %w[ready cancelled]) }

  def parts_shortage?
    ticket_parts.includes(:part).any? do |request|
      remaining = request.quantity_requested - request.quantity_fulfilled
      remaining.positive? && request.part.stock_quantity < remaining
    end
  end

  def parts_fulfilled?
    ticket_parts.all? { |request| request.quantity_fulfilled >= request.quantity_requested }
  end
end
