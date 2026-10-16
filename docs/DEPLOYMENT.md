# Deployment Runbook

## Important Availability Caveat

The requested combination of a public Hugging Face Docker Space and free, always-on hosting is not currently available as described. Hugging Face's current Spaces documentation says Docker Spaces require a paid plan; free CPU Spaces also sleep when unused. Render's Free web service spins down after 15 minutes idle, then takes about a minute to wake. Neon Free always scales its Postgres compute to zero after 5 minutes and has a finite monthly compute allowance. A GitHub Actions ping every ten minutes may reduce Render idle time, but it does not guarantee uptime and may consume up to roughly 720 of Render's 750 free workspace instance-hours each month if the pings keep the service awake. Check the provider pricing pages before deploying because limits change.

This runbook prepares the app for those platforms but does not claim it has been deployed. No host URL or secret values are present in this repository.

## Current Free Limits (checked 2026-10-16)

| Provider | Current free allowance / behavior | Practical consequence |
| --- | --- | --- |
| Hugging Face Spaces | Docker Spaces require PRO/Team/Enterprise per current Spaces overview; free CPU is listed for supported free Space types, and free hardware sleeps when unused. | The Docker app needs paid Hugging Face access; a scheduled ping cannot convert a paid Docker Space to free. |
| Render Free Web Service | 0.1 CPU / 512 MB RAM, 750 workspace instance-hours/month; spins down after 15 minutes idle. Filesystem is ephemeral. | Demo can sleep/wake slowly. Frequent pings can exhaust most workspace hours; uploaded/local files are not durable. |
| Render Free Postgres | 1 GB and expires 30 days after creation. | Not a long-lived primary database. Prefer Neon and only use this for a temporary trial. |
| Neon Free | 100 CU-hours/project/month; 1 GB Postgres storage/project; 5 GB egress/project/month; compute sleeps after 5 minutes idle; 10 branches/project. | A small seeded demo may fit, but migration/seeding and smoke traffic consume compute. Free is not always-on. |
| Upstash Redis Free | 250 MB and 500,000 commands/month on the pricing page. | The short-lived metrics cache should fit light demo usage; expiration is configured to avoid unbounded keys. |

Official references: [Hugging Face Spaces overview](https://huggingface.co/docs/hub/spaces-overview), [Render free services](https://render.com/docs/free), [Neon plans](https://neon.com/docs/introduction/plans), [Upstash Redis pricing](https://upstash.com/pricing/redis).

## Deploy to Hugging Face Spaces (Docker SDK)

This requires a paid Hugging Face plan for a Docker Space under current terms.

1. Sign in to Hugging Face and open **Spaces**.
2. Select **Create new Space**.
3. Enter a Space name, select **Docker** as the SDK, and choose **Public** visibility for a public demo. Create the Space.
4. Open the Space's **Settings** tab, then **Variables and secrets**.
5. Add secrets named `RAILS_MASTER_KEY`, `DATABASE_URL`, and `REDIS_URL`. Add `SECRET_KEY_BASE` as a secret if the platform does not provide Rails credentials. Do not put the values in GitHub files or the README.
6. Set variable `SEED_ON_BOOT=true` for the first deploy only. Set `SOLID_QUEUE_IN_PUMA=true` and `PORT=7860` if the platform expects its standard exposed Space port; the Docker image accepts `PORT`.
7. Connect/push the GitHub repository from the Space's Git settings or follow the Space repository instructions. Confirm the first build reaches **Running**.
8. Visit the Space's public embed URL and append `/up`; expect an HTTP success response.
9. After confirming demo data exists, set `SEED_ON_BOOT=false` in Space settings and restart/redeploy. Seed users all share `DEMO_PASSWORD` (default demo value shown in README); set `DEMO_PASSWORD` before the first seed if changing it.
10. Add the GitHub repository variable `DEMO_BASE_URL` to the repository's **Settings > Secrets and variables > Actions > Variables** for the scheduled health-check workflow.

If the host uses port 7860, set that `PORT` value as a variable; the Docker CMD binds through `config/puma.rb`.

## Render Free (Backup, Sleeping)

1. Sign in at Render and choose **New > Web Service**.
2. Connect the GitHub repository and select the project root.
3. Choose **Docker** as the runtime and the **Free** compute plan. Expect idle spin-down and ephemeral local disk.
4. Add environment variables/secrets in **Environment**: `RAILS_MASTER_KEY`, `DATABASE_URL` pointing to Neon, `REDIS_URL` pointing to Upstash, `SECRET_KEY_BASE`, `RAILS_ENV=production`, `RAILS_SERVE_STATIC_FILES=true`, `SOLID_QUEUE_IN_PUMA=true`, and `SEED_ON_BOOT=true` for first deployment.
5. Set the health check path to `/up` if the dashboard offers one.
6. Click **Create Web Service** and wait for the first image build. Check logs for `db:prepare` and seed summary output.
7. Open the assigned `onrender.com` URL and visit `/up` and `/session/new`.
8. Turn `SEED_ON_BOOT` off in the Render environment and redeploy after seed data and logins are confirmed.
9. Set GitHub variable `DEMO_BASE_URL` to the Render base URL. The 10-minute workflow is best effort only and can consume free workspace hours.

## Neon Postgres

1. Sign in to Neon and select **Create project**.
2. Choose a region close to the app host, PostgreSQL, and a project name such as `fleetops-pro`.
3. Open **Connect** and select the `neondb` database and the owner role. Copy the pooled connection string only into the host's secret named `DATABASE_URL`.
4. Keep the connection string's SSL parameters. Do not commit it or put it into `.env.example`.
5. The container's `db:prepare` runs migrations at startup. Monitor Neon compute/storage against the free quotas above.

## Upstash Redis

1. Sign in to Upstash and choose **Create Database > Redis**.
2. Choose a region near the app/Neon project and the Free plan.
3. Open the database's **Connect** section and copy the `rediss://` Redis URL with TLS/authentication into the host's secret named `REDIS_URL`.
4. Confirm cache operations work in Rails logs. Monitor command/storage quotas.

## GitHub Actions Ping

The `.github/workflows/keepalive.yml` workflow runs every ten minutes and reads the repository variable `DEMO_BASE_URL`. Set it under **Repository > Settings > Secrets and variables > Actions > Variables > New repository variable**. The ping only proves `/up` answered; it does not prove a logged-in workflow screen works or guarantee the provider will keep a free instance awake.

## Secrets and First Boot

`RAILS_MASTER_KEY`, `DATABASE_URL`, `REDIS_URL`, and `SECRET_KEY_BASE` belong in the host secrets manager. Never copy production values into `.env.example` or commit credentials. `SEED_ON_BOOT=true` runs safe-to-rerun seeds after `db:prepare`; set it back to `false` after the first successful seed. `DEMO_PASSWORD` can override the documented demo password before seeding.

## Smoke Test

Once the app is deployed, set `FLEETOPS_BASE_URL` and `FLEETOPS_DEMO_PASSWORD` in the local shell and run:

```sh
ruby script/smoke_test.rb
```

The script signs in as the ops manager, retains the session cookie and CSRF token, and requests the dashboard plus vehicle, lot, shortage, technician, ticket, and analytics screens. No smoke-test output is claimed until a live URL and credentials exist.
