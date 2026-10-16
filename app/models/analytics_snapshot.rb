class AnalyticsSnapshot < ApplicationRecord
  validates :snapshot_date, presence: true, uniqueness: true
  validates :metrics, presence: true
end
