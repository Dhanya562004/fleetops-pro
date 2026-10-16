require "test_helper"

class DataQuality::QuarantineLegacyRowsTest < ActiveSupport::TestCase
  test "marks imported anomalies as processed and reports issue counts" do
    LegacyImportRow.create!(entity_type: "part", external_id: "test-negative-stock", issue_code: "negative_stock", raw_payload: { stock_quantity: -3 })
    LegacyImportRow.create!(entity_type: "vehicle", external_id: "test-duplicate-vin", issue_code: "duplicate_vin", raw_payload: { vin: "FOPIN000000000001" })

    result = DataQuality::QuarantineLegacyRows.call

    assert_operator result.fetch("negative_stock"), :>=, 1
    assert_operator result.fetch("duplicate_vin"), :>=, 1
    assert_equal 2, LegacyImportRow.where.not(processed_at: nil).where(external_id: %w[test-negative-stock test-duplicate-vin]).count
  end
end
