# ADR 0002: Service Objects for Multi-Record Operations

- Status: Accepted
- Date: 2026-10-16

## Context

Vehicle moves, repair transitions, and part fulfillment update multiple records and have transactional rules. Putting those decisions in controllers would make HTTP handlers hard to test and reuse.

## Decision

Expose named operations under `app/services`, each with a small `.call` entry point. Services own transactions, locking, audit records, and cache invalidation where appropriate. Models continue to own associations and local validation.

## Consequences

Controllers map params and results to HTTP responses. Service tests can exercise business rules without routing. The project avoids introducing a generic workflow framework for a small fixed state graph.
