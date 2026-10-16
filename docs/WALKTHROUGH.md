# Interview Walkthrough

## Two-Minute Pitch

I built FleetOps Pro as a fictional fleet operations tool focused on the handoffs that keep a vehicle out of service: lot capacity, repair workflow, technician assignment, and missing parts. I used Rails 8 and PostgreSQL for the domain and transactional rules, then React with TypeScript and Inertia for the main internal screens. One workshop activity page stays server-rendered with Turbo and Stimulus to show how a newer React surface can coexist with a more traditional Rails screen.

The most important rules live on the server. A lot transfer locks the vehicle and both affected lots before it checks capacity and records a move. Repair transitions go through a service object that validates the allowed next state and writes an audit event. A shortage blocks repair work and is visible on the dashboard rather than being buried in inventory data. For reporting, a query object uses PostgreSQL CTEs and a window function; Rails.cache stores the result briefly, and model/service writes invalidate it.

The project has focused Minitest and Jest tests, Docker and CI configuration, and a seeded fictional fleet. GitHub Actions passed 15 Minitest runs with 59 assertions and one Jest/RTL test on PR #1. I could not run the database suite locally because this workspace has no usable PostgreSQL service and Docker is unavailable, and I have not measured query counts or elapsed times. I would be precise about those gaps rather than presenting unverified numbers as results.

## Three Hard Problems

1. **Capacity under concurrent moves.** A simple count followed by an update can oversubscribe a lot when two requests arrive together. The move service locks the vehicle and lots in a stable ID order, checks destination occupancy inside the transaction, writes the `Move`, and updates the vehicle atomically.
2. **Workflow and inventory consistency.** State changes and part fulfillment touch multiple records. `Maintenance::Transition`, `Parts::RequestForTicket`, and `Parts::FulfillRequest` use transactions, enforce the explicit status graph, update vehicle status, and create audit events. A ticket stays blocked only while remaining requested quantity exceeds available stock.
3. **Bad imported records without weakening production constraints.** The seeded anomalies live as raw payloads in `legacy_import_rows`. The live tables retain unique, foreign-key, status, and nonnegative checks. The quarantine task reports and marks examined rows but does not guess how to reconcile ambiguous business data.

## Trade-Offs and Known Limitations

- Inertia keeps Rails routing and server authorization central while React handles the dense operations UI, but pages depend on the Rails app and are not independently deployable.
- Redis reports are cached for 15 minutes to reduce repeated aggregate work. That is a deliberate freshness trade-off; model/service invalidation shortens stale windows after writes.
- Solid Queue shares the primary PostgreSQL database to fit the one-database free deployment scenario. Queue load therefore competes with application queries.
- The README's free-hosting options are not always-on: current Hugging Face Docker Spaces require paid access, Render Free spins down, and Neon Free scales compute to zero. A scheduled ping is best-effort and may consume nearly all included Render workspace hours.
- Database migrations, seeding, Minitest, browser screenshots, smoke tests, CI status, and actual performance measurements remain unverified until the required services and host credentials exist.
- There is no production importer, mail provider, or real company dataset. Notifications are persisted and idempotent but not delivered through an external channel.

## Likely Questions and Answers

1. **Why Inertia instead of a separate API?** Rails owns sessions, authorization, routes, and write-side rules; Inertia sends page props without a second API client and keeps the React experience tightly paired with Rails.
2. **Why service objects?** Transfers, state changes, and part fulfillment span multiple records and need transactions/audits. Named operations make these behaviors independently testable and keep controllers about HTTP.
3. **How does the capacity check handle concurrent requests?** The service locks the vehicle and source/destination lots before checking occupancy and updating the destination. This prevents two transfer transactions from both relying on the same stale free-space count.
4. **How are invalid workflow transitions prevented?** The transition service has an explicit graph, validates the requested edge, and updates ticket, vehicle, and event within one transaction. The model and database also restrict allowed statuses.
5. **What happens when a part is missing?** A ticket part request checks stock. If the request cannot be covered, the ticket and vehicle become `awaiting_parts`; the dashboard and shortage screen show the blocked work. Fulfillment decrements inventory and resumes repair when all requests can proceed.
6. **Why are some rules in SQL constraints and others in Rails?** Rails validations give useful error messages; database constraints protect data from every writer, including scripts, jobs, and future code paths.
7. **How is analytics cached?** `FleetMetricsQuery` reads a small report through one SQL CTE query, cached in `Rails.cache` for 15 minutes. Related writes expire the cache key. The numbers still need measured query-plan verification on PostgreSQL.
8. **How are jobs idempotent?** Notification creation uses a unique idempotency key, and the processor returns when an existing notification is already processed. This protects against retries producing duplicate records.
9. **Why keep one Hotwire page?** The activity view is a deliberately traditional Rails flow using ERB, Turbo, and Stimulus. It demonstrates familiarity with an older Rails interaction pattern without mixing it into every screen.
10. **What would you improve next?** Run the full database suite and CI, capture real query/time measurements, verify the Docker build, and deploy only after host quotas/secrets are configured. I would then add end-to-end browser coverage and a durable notification delivery adapter.
