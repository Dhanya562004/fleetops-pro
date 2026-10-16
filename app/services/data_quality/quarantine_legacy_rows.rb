module DataQuality
  class QuarantineLegacyRows
    def self.call
      rows = LegacyImportRow.unprocessed.to_a
      rows.each { |row| row.update!(processed_at: Time.current) }
      rows.group_by(&:issue_code).transform_values(&:size)
    end
  end
end
