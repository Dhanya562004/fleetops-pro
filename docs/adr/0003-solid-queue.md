# ADR 0003: Solid Queue on the Primary Database

- Status: Accepted
- Date: 2026-10-16

## Context

The app needs scheduled and retryable jobs but the portfolio deployment target has no paid worker process. Rails 8 includes Solid Queue, and the proposed free database is a single Neon PostgreSQL project.

## Decision

Use Solid Queue and place its queue tables in the primary database. In the hosted single-process mode, Puma loads the Solid Queue plugin. CI still uses a separate service container for PostgreSQL and Redis, but queue records share the app database.

## Consequences

No separate queue database is required. Job load competes with application queries, so the single-process setting is for a low-volume demo, not a production scaling recommendation. Queue migrations must run with the app schema.
