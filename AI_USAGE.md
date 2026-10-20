# AI Usage Log — FleetOps Pro

This document records AI-assisted development contributions, reviews, and architectural decisions in accordance with repository governance.

---

## Entry: Test Suite Hardening, Concurrency Verification, and CI Reporting

- **Date**: 2026-10-20
- **Author / Assistant**: Google Antigravity Agent
- **Repository**: `Dhanya562004/fleetops-pro`

### 1. What was Generated

1. **SimpleCov Integration (`Gemfile`, `Gemfile.lock`, `test/test_helper.rb`)**:
   - Added SimpleCov 1.3 under the `:test` group.
   - Configured `SimpleCov.start "rails"` at the top of `test/test_helper.rb` prior to application loading.
   - Verified line coverage: **63.70% (272 / 427 lines)**.

2. **Exhaustive Repair State Machine Tests (`test/services/maintenance/transition_test.rb`)**:
   - Generated unit tests covering all 10 valid transitions across the workflow graph (`inspection` &rarr; `repair`, `inspection` &rarr; `cancelled`, `repair` &rarr; `quality_check`, `repair` &rarr; `awaiting_parts`, `repair` &rarr; `cancelled`, `awaiting_parts` &rarr; `repair`, `awaiting_parts` &rarr; `cancelled`, `quality_check` &rarr; `repair`, `quality_check` &rarr; `ready`, `quality_check` &rarr; `cancelled`).
   - Generated tests covering all 26 invalid state combinations across the 6-state matrix (`inspection`, `repair`, `awaiting_parts`, `quality_check`, `ready`, `cancelled`), asserting `Maintenance::Transition::InvalidTransition`.
   - Verified conditional part fulfillment guard: tickets in `repair` cannot transition to `quality_check` if any requested parts are unfulfilled.
   - Verified audit event logging (`TicketStatusEvent`) and vehicle status synchronization.

3. **Domain Service Hardening (`test/services/lots/move_vehicle_test.rb`)**:
   - Added tests for moving vehicles without existing lot assignments (`from_lot: nil`).
   - Added tests rejecting self-lot moves (`Lots::MoveVehicle::InvalidMove`).
   - Added tests verifying operator attribution (`moved_by: actor`).
   - Added tests verifying automatic cache eviction (`Rails.cache.delete("fleet_metrics:v1")`).
   - Added tests validating exact capacity boundary transitions.

4. **Query Caching Tests (`test/queries/fleet_metrics_query_test.rb`)**:
   - Generated dedicated unit tests for `FleetMetricsQuery.call`:
     - **Cache Miss**: Executes SQL CTE query and stores result in `Rails.cache`.
     - **Cache Hit**: Subscribed to `sql.active_record` via `ActiveSupport::Notifications` to assert zero database queries on a cache hit.
     - **TTL Expiry**: Verified cache expiration after 15 minutes using `travel 16.minutes`.
     - **Cache Eviction**: Verified forced reload upon explicit cache key deletion.

5. **Multi-Threaded Concurrency Test (`test/services/lots/move_vehicle_concurrency_test.rb`)**:
   - Implemented a barrier-synchronized test with 5 threads competing to move vehicles into a lot with only 1 free space remaining.
   - Configured `self.use_transactional_tests = false` so each thread tests true PostgreSQL row-level locks on independent connection pool connections.
   - Verified that exactly 1 thread succeeds while the remaining 4 threads receive `Lots::MoveVehicle::CapacityExceeded`.
   - Verified that the lot never exceeds capacity.
   - Added explicit database teardown cleanup.

6. **Continuous Integration & Documentation (`.github/workflows/ci.yml`, `README.md`)**:
   - Updated GitHub Actions CI workflow to publish an automated step summary (`$GITHUB_STEP_SUMMARY`) displaying real test counts and line coverage.
   - Updated `README.md` with verified metrics (33 runs, 343 assertions, 0 failures, 63.70% coverage) and a dedicated section explaining concurrency handling.

### 2. What Was Reviewed

- **PostgreSQL Lock Ordering & Deadlock Prevention**:
  Reviewed `Lots::MoveVehicle` implementation to confirm that `Lot.where(id: lot_ids).order(:id).lock` sorts IDs deterministically before acquiring row locks, eliminating AB-BA deadlocks during concurrent reciprocal transfers.
- **Transactional Test Isolation vs. Thread Safety**:
  Reviewed the rationale for setting `self.use_transactional_tests = false`: Rails transactional fixtures isolate uncommitted rows to a single connection; concurrent worker threads checking out distinct pool connections require committed data and real PostgreSQL row locks (`SELECT ... FOR UPDATE`) to evaluate race conditions accurately.
- **SimpleCov Deprecation Fixes**:
  Reviewed SimpleCov initialization to avoid deprecated `add_filter` warnings, standardizing on the clean `SimpleCov.start "rails"` configuration.
- **Metric Verification**:
  Verified every reported test count, assertion count, file count, and line coverage percentage against direct console output.

### 3. Suggestions Rejected or Discarded

- **Rejected: Adding External Mocking Gems (`minitest-mock`)**:
  Discarded adding additional test gems for query assertions; used Rails native `ActiveSupport::Notifications.subscribe("sql.active_record")` instead, avoiding unnecessary dependencies.
- **Rejected: Mocked Concurrency with In-Memory Counters**:
  Discarded simulating concurrency using memory counters or thread sleeps; insisted on real multi-threaded database transactions against PostgreSQL 16 to validate actual row locks.
- **Rejected: Estimated or Estimated Coverage Targets**:
  Discarded placing estimated coverage badges or target percentages in documentation; reported only measured figures from the actual test runner.
