# Performance Notes

## Targeted Page

The technician dashboard is the deliberately optimized slice. A per-technician ticket lookup would issue one assignment query for each of roughly 60 technicians, plus associated vehicle reads. The controller now loads the roster once, loads active tickets for all technician IDs in one query with `includes(:vehicle)`, groups in memory, and renders a bounded five-ticket preview per person.

The vehicle list separately uses `includes(:lot)` because the table displays lot names, and applies pagination before serialization. Indexes cover the status/priority, technician/status, vehicle/status, and VIN access paths.

## Measurement Status

I have not recorded before/after query counts or elapsed times. The current environment has no working local PostgreSQL credentials and Docker is unavailable, so reporting numeric measurements would be invented. The code structure has been improved, but the requested measured performance proof point is incomplete until `script/measure_technician_dashboard.rb` runs on a migrated, seeded PostgreSQL database.

Run the reproducible comparison:

```sh
bundle exec rails db:prepare
bundle exec rails db:seed
bundle exec rails runner script/measure_technician_dashboard.rb
```

The script reports SQL query count and monotonic elapsed milliseconds for the per-technician baseline and the batched/eager-loaded implementation. Record the emitted values here, along with Ruby/Rails versions, row counts, and whether the database cache was warm. Do not compare results from different data sizes as if they were equivalent.

| Implementation | SQL queries | Elapsed ms | Status |
| --- | ---: | ---: | --- |
| Per-technician baseline | Not measured | Not measured | Pending PostgreSQL run |
| Batched tickets + eager-loaded vehicles | Not measured | Not measured | Pending PostgreSQL run |

## Follow-up

Measure the report query with `EXPLAIN (ANALYZE, BUFFERS)` on a seeded database before claiming an index improvement. The migration includes indexes for common filters, but no query plan or latency result is claimed yet.
