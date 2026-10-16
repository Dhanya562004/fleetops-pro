# Data Investigation Exercise

## Question

A fleet operations manager reports four suspicious legacy import records: a duplicate VIN, an `awaiting_parts` ticket older than several weeks, a vehicle referring to a missing lot, and a part with negative stock. Could these records enter the live FleetOps tables, and how should they be contained?

This is a synthetic investigation fixture. `db/seeds.rb` inserts the malformed examples as JSON payloads in `legacy_import_rows`; it does not corrupt the live tables. No external production data or actual production incident is represented.

## Investigation SQL

Inspect all unprocessed anomalies:

```sql
SELECT entity_type, external_id, issue_code, raw_payload, created_at
FROM legacy_import_rows
WHERE processed_at IS NULL
ORDER BY issue_code, created_at;
```

Check the duplicate VIN payload and its two external source row identifiers:

```sql
SELECT raw_payload ->> 'vin' AS vin,
       raw_payload -> 'import_row_ids' AS source_rows
FROM legacy_import_rows
WHERE issue_code = 'duplicate_vin' AND processed_at IS NULL;
```

Find stale tickets represented in the raw legacy payload:

```sql
SELECT external_id, raw_payload ->> 'status' AS imported_status,
       (raw_payload ->> 'updated_at')::timestamptz AS imported_updated_at
FROM legacy_import_rows
WHERE issue_code = 'stale_awaiting_parts'
  AND processed_at IS NULL
  AND (raw_payload ->> 'updated_at')::timestamptz < now() - interval '14 days';
```

Inspect dangling lot references and negative stock before mapping imports to domain rows:

```sql
SELECT external_id, raw_payload ->> 'vin' AS vin, raw_payload ->> 'lot_id' AS unknown_lot_id
FROM legacy_import_rows
WHERE issue_code = 'unknown_lot_reference' AND processed_at IS NULL;

SELECT external_id, raw_payload ->> 'sku' AS sku,
       (raw_payload ->> 'stock_quantity')::integer AS imported_stock
FROM legacy_import_rows
WHERE issue_code = 'negative_stock' AND processed_at IS NULL;
```

## Root Cause and Containment

The fixture represents unvalidated external rows arriving at an import boundary. This repository does not contain a production importer or real operational dataset, so the root cause is intentionally stated as a design scenario, not an observed production fact.

The live schema prevents the same classes of invalid writes: VIN uniqueness, foreign keys for lot references, a nonnegative stock check, and allowed status checks. `DataQuality::QuarantineLegacyRows` marks reviewed raw records with `processed_at` and leaves their source payload available for audit. Run it with:

```sh
bundle exec rake data_quality:investigate
```

The service is idempotent: already-processed rows are excluded by the `unprocessed` scope. `test/services/data_quality/quarantine_legacy_rows_test.rb` checks that anomaly types are counted and rows are marked processed. Database-backed execution still needs to be run against PostgreSQL.

## What the Fix Does Not Do

Quarantine is not an automatic merge policy. A person still needs to decide which duplicate VIN source row is authoritative, whether a stale ticket should be reopened, whether an unknown lot should map to a real lot, and how to reconcile a negative stock adjustment. The project deliberately avoids silently guessing those business decisions.
