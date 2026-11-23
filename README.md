[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/axonhub-1?utm_medium=integration&utm_source=button&utm_campaign=axonhub)

# Deploy and Host AxonHub on Railway

AxonHub is an open-source AI gateway (Apache-2.0). It puts one OpenAI-, Anthropic- and Gemini-compatible API in front of many LLM providers, routes requests between channels with failover and load balancing, and tracks usage, cost and traces per project, API key and user from a web admin console.

## About Hosting AxonHub

This template runs two services. **AxonHub** (v1.0.0-rc.4, official `looplj/axonhub` image pinned by digest) is built from the public repo `aalfath/axonhub-railway-template` and serves the API and admin console on a public Railway domain. **Postgres** (Railway's PostgreSQL, on its own volume) stores all channels, keys, users, usage logs and settings, so nothing is lost on redeploy. AxonHub runs its database migrations at start-up. On first boot the wrapper creates the owner account from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD`, so the public setup page can't be claimed by a stranger. A health check on `/health` gates each deploy.

## Common Use Cases

* One API endpoint and key for OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter and other providers, used by Claude Code, Codex, Cursor or your own apps
* Failover and load balancing between provider accounts, with model aliasing and per-key quotas
* Tracking token usage, cost and request traces per project, team member and API key

## Dependencies for AxonHub Hosting

* PostgreSQL (included, Railway's Postgres service)
* At least one LLM provider API key, added in the admin console after deploy

### Deployment Dependencies

* AxonHub source: https://github.com/looplj/axonhub
* AxonHub docs: https://axonhub.reveric.app
* Template repo: https://github.com/aalfath/axonhub-railway-template

### Implementation Details

After deploy:

1. Open the AxonHub service's public URL and sign in with `ADMIN_EMAIL` and the `ADMIN_PASSWORD` shown in the service's **Variables** tab. Change the password under your profile if you like.
2. Add a **Channel** for each provider (its base URL and API key), then create an **API key** for your clients.
3. Point clients at `https://YOUR-DOMAIN/v1` (OpenAI format) or `https://YOUR-DOMAIN/anthropic` (Anthropic format) with that key.

Variables on the AxonHub service:

| Variable | Default | Purpose |
|---|---|---|
| `ADMIN_EMAIL` | `admin@example.com` | Owner login created on first boot. Change it before deploy if you want your own address. |
| `ADMIN_PASSWORD` | generated | Owner password created on first boot. |
| `AXONHUB_DB_DSN` | reference to Postgres | Database connection over the private network. |
| `PORT` | `8090` | Port AxonHub listens on. |

`ADMIN_EMAIL` and `ADMIN_PASSWORD` are used only on the very first boot; changing them later does not change the account. Any other setting from upstream's `config.example.yml` can be set as an `AXONHUB_*` variable (for example `AXONHUB_LOG_LEVEL=debug`).

Resources: AxonHub idles at well under 100 MB of RAM and runs on Railway's smallest plan (tested at 0.5 GB / 1 vCPU per service). The wrapper caps the Go runtime at `GOMAXPROCS=2` and `GOMEMLIMIT=400MiB`; raise `GOMEMLIMIT` if you give the service more memory.

Updates: this template builds from `aalfath/axonhub-railway-template`. When we bump the pinned AxonHub version there, Railway shows an "update available" notice in your project, and you choose when to apply it. Read `CHANGELOG.md` first: breaking changes are listed at the top of each entry. Back up Postgres before major upgrades.

## Why Deploy AxonHub on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying AxonHub on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
