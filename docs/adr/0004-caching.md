# ADR 0004: Short-Lived Cached Fleet Aggregates

- Status: Accepted
- Date: 2026-10-16

## Context

Fleet reports combine counts and durations across tickets, events, and vehicles. Re-running these aggregates for every dashboard visit is unnecessary for a small internal tool, but operational data should not remain stale for long.

## Decision

`FleetMetricsQuery` executes hand-written PostgreSQL CTE/window-function SQL and caches the result through `Rails.cache` for 15 minutes. Changes to vehicles, tickets, and parts expire the stable versioned key.

## Consequences

A dashboard can show a result up to 15 minutes old if an invalidation path is missed or Redis is unavailable. The query is PostgreSQL-specific by design. Query-plan and cache-hit measurements are still pending a working database environment.
