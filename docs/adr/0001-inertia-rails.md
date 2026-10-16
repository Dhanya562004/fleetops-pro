# ADR 0001: Inertia Rails for Internal Screens

- Status: Accepted
- Date: 2026-10-16

## Context

The primary users need dense, interactive operations screens, while Rails should continue to own routes, sessions, validation, and authorization. A separately versioned JSON API would add an API contract/client layer that this portfolio does not need.

## Decision

Use inertia-rails to send controller props to React + TypeScript pages, with Vite building the frontend. Keep one Rails-rendered Turbo/Stimulus activity page as an intentional legacy-style example.

## Consequences

Controllers remain the entry points for page data and React pages can use Inertia navigation/forms. The React app is coupled to Rails page names and props; shared contracts should stay explicit and be tested.
