class LegacyImportRow < ApplicationRecord
  validates :entity_type, :external_id, :issue_code, presence: true

  scope :unprocessed, -> { where(processed_at: nil) }
end
