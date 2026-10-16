# Architecture

## Request Flow

For the React application, a browser request reaches a Rails route and controller. The controller authorizes the operation, calls a query or service object for work that changes state or aggregates data, then renders an Inertia page name and JSON props. Inertia Rails serializes the initial page response; the React resolver in `resources/js/entrypoints/application.tsx` lazy-loads the matching component from `resources/js/pages`.

Forms use Inertia's `useForm`/router helpers and return through Rails controllers. Rails owns validation, authorization, transactions, and redirects. The browser is not the source of truth for workflow or capacity rules.

The workshop activity route is intentionally different: Rails renders ERB, Turbo submits a server form and updates a frame, and Stimulus registers the activity controller. It has a separate `hotwire` layout and Vite entrypoint so it does not mount React.

## Folder Map

| Path | Responsibility |
| --- | --- |
| `app/models` | Associations, validations, scopes, database-facing invariants. |
| `app/controllers` | Authentication, authorization, request/response mapping, and page props. |
| `app/services` | Multi-record operations such as state transitions, transfers, part fulfillment, and quarantine. |
| `app/queries` | Hand-written SQL for read-heavy reports. |
| `app/jobs` | Retryable Solid Queue jobs. |
| `app/views` | Rails layout and the one server-rendered Hotwire screen. |
| `resources/js/pages` | Inertia page components, grouped by operational area. |
| `resources/js/components` | Shared layout, status display, and ticket parts controls. |
| `resources/js/stimulus` | Turbo/Stimulus boot and controller registration. |
| `db/migrate` | PostgreSQL schema, checks, foreign keys, and Solid Queue tables. |
| `test` | Minitest models/services/controllers/jobs plus Jest/RTL tests. |
| `docs/adr` | Short records of architecture choices. |

## Adding a Feature

1. Add or extend a Rails model association and migration. Put durable invariants in the database and readable validations in the model.
2. Put multi-record or state-changing behavior in `app/services`; keep controllers focused on authorization and HTTP behavior.
3. Add a query object for nontrivial reporting SQL and define its cache key/expiry/invalidation behavior.
4. Add a controller route and return props to a new page under `resources/js/pages`, or use the existing Hotwire route only when the feature specifically belongs on that older-style screen.
5. Add a Minitest for backend behavior and RTL coverage for user-visible behavior. Run the CI commands in the README.

## Design Boundaries

- PostgreSQL is authoritative for operational state. Redis only holds disposable cached aggregates.
- `Maintenance::Transition` owns the state graph; controllers cannot set a ticket state directly.
- `Lots::MoveVehicle` is the only path that changes a vehicle's lot and writes a `Move` record.
- Raw anomalous import payloads live in `legacy_import_rows`; invalid records are not inserted into constrained fleet tables.
- Role checks are server-side. Hiding a button in React is only a usability decision, not authorization.

## Known Gaps

There is no local PostgreSQL/Redis installation in the current environment, and Docker is unavailable. Database migrations, seed execution, Minitest, server-rendered screenshots, and production deployment still need verification in an environment with those services and host credentials.
