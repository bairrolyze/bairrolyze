# Production infrastructure — how the backend actually deploys and runs

This documents the **real**, currently-deployed backend infrastructure, as
verified and (in several cases) repaired live in production on 2026-11-08/09.
It intentionally does not try to reconcile every detail in
`docs/BUILD_AND_DEPLOY.md` §5–6, which describes a generic nginx/Docker
Compose deployment and a `ci.yml` that was never actually created — this repo
deploys Azure Container Apps directly from `.github/workflows/deploy.yml`.
Treat this file as the source of truth for the backend's production path.

## Architecture

- **Resource group**: `homescope-rg`, East US, Azure subscription
  `b0a85120-69d7-4842-a998-bb211b811f43`.
- **Container App**: `api-home-scope`
  (`api-home-scope.wonderfulplant-e443a025.eastus.azurecontainerapps.io`).
  One replica (scale-to-zero, `minReplicas: 0`) runs **three containers**
  sharing a pod/network namespace: `api-home-scope` (the FastAPI app, port
  8000), `db` (postgres, unused by the app's actual `DATABASE_URL` — see
  below), `redis` (local cache/job-store backend).
- **Image**: `ghcr.io/bairrolyze/home-scope:<git-sha>`, built and pushed by
  `.github/workflows/deploy.yml` on every push to `main` touching
  `backend/**` or `.github/workflows/**`.

### Known issue: misconfigured startup probes

All three containers (`api-home-scope`, `db`, `redis`) have an identical
startup/liveness/readiness probe checking `tcpSocket: {port: 8000}` — but
only `api-home-scope` actually listens on 8000. This "works" only because
containers in the same pod share a network namespace, so the `db`/`redis`
probes happen to succeed once `api-home-scope` binds 8000 — there's no
actual health check on Postgres or Redis themselves. This is fragile (see
the `ImagePullBackOff` incident below, where probe-failure spam obscured the
real error for a while) and should eventually be fixed with per-container
probes on the correct ports. Not fixed as part of this session.

## Deploy pipeline (`.github/workflows/deploy.yml`)

1. Build the backend image, push to GHCR (`docker/login-action` with the
   default repo-scoped `GITHUB_TOKEN`, which can only push packages under
   the repo's **own** owner — `bairrolyze`, not any other namespace).
2. OIDC login to Azure (`azure/login@v2`), no stored secret — trust is via a
   **federated identity credential** (see below).
3. `az containerapp update --image ghcr.io/bairrolyze/home-scope:<sha>` rolls
   a new revision.

### Azure auth: federated identity credential, not a classic App Registration

The `APIHOMESCOPE_AZURE_CLIENT_ID` GitHub secret points at a **User-Assigned
Managed Identity** (`managedEnvironment-homescoperg-a42ehomescope-rgOidc`,
appId `22eb934b-59c9-457e-8181-5232a1974b52`) — not a classic Azure AD App
Registration. Its federated credentials live under
`Microsoft.ManagedIdentity/userAssignedIdentities/.../federatedIdentityCredentials`
and are managed via `az identity federated-credential`, **not**
`az ad app federated-credential` (that command 404s for this identity type —
costly to figure out, don't repeat the detour).

The credential (`api-home-scope-fed`) was originally registered with
`subject: repo:rajesharyain/home-scope:ref:refs/heads/main` — the repo's
pre-rebrand owner/name. After the `bairrolyze` org transfer, GitHub started
presenting a **different** OIDC subject
(`repo:bairrolyze@316165732/bairrolyze@1275896336:ref:refs/heads/main` — note
the `@<numeric-id>` suffixes GitHub appends after a rename/transfer), which
didn't match, so every deploy failed Azure login with `AADSTS700213`. Fixed
by updating the federated credential's subject to the new value:

```bash
az identity federated-credential update \
  --name "api-home-scope-fed" \
  --identity-name "managedEnvironment-homescoperg-a42ehomescope-rgOidc" \
  --resource-group homescope-rg \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:bairrolyze@316165732/bairrolyze@1275896336:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"
```

**If the repo is renamed or transferred again, this will break again** —
GitHub's `@<id>` suffixing behavior around renames means the subject may
need updating. If Azure login starts failing with `AADSTS700213`, check the
failed run's logs for the "Federated token details" block — it prints the
exact subject GitHub presented, which is what needs to go in the credential.

### Registry pull credential (separate from the push credential above)

The Container App's own registry credential (used by Azure to *pull* the
image after `az containerapp update`) is configured independently of the
GitHub Actions push credential:

```bash
az containerapp show --name api-home-scope --resource-group homescope-rg \
  --query "properties.configuration.registries"
```

This was originally `username: rajesharyain` with a password secret that
stopped working after the `bairrolyze` org transfer — the push side
(`GITHUB_TOKEN`) worked fine, but Azure's pull failed with
`ImagePullBackOff` (visible only via `az containerapp replica list
--revision <name>`, not in the deploy workflow logs — the GitHub Actions run
reports success as soon as `az containerapp update` returns, regardless of
whether the resulting revision actually activates). Currently patched by
rotating in a personal access token (via `gh auth token`, scope
`read:packages`) as the registry password:

```bash
az containerapp registry set --name api-home-scope --resource-group homescope-rg \
  --server ghcr.io --username rajesharyain --password "<token with read:packages>"
```

**This is a stopgap, not the permanent fix.** The `ghcr.io/bairrolyze/home-scope`
package is currently **private**, which is why it needs a credential at all.
GitHub doesn't expose package visibility via REST API — the permanent fix is
changing it to public through the web UI (package page → Settings → Danger
Zone → Change visibility), matching the already-public `bairrolyze/bairrolyze`
repo. Once public, the registry credential can be removed entirely and this
whole class of credential-rot problem goes away. **Not done yet** — pending
whoever has admin on the `bairrolyze` org packages settings.

### Verifying a deploy actually worked

A green GitHub Actions run is **not sufficient** — `az containerapp update`
can return success while the resulting revision fails to activate. Always
confirm with:

```bash
az containerapp revision list --name api-home-scope --resource-group homescope-rg \
  --query "[].{name:name, active:properties.active, trafficWeight:properties.trafficWeight, replicas:properties.replicas, healthState:properties.healthState, runningState:properties.runningState}" \
  -o table
```

The newest revision should show `trafficWeight: 100`, `replicas: >=1` (or
`0` only once genuinely idle-scaled, i.e. after having been `Running`),
`healthState: Healthy`. If it shows `replicas: 0` with `runningState:
ActivationFailed`, traffic silently falls back to the last revision that did
successfully activate — requests keep succeeding, serving stale code, with
no obvious error. Check why with:

```bash
az containerapp logs show --name api-home-scope --resource-group homescope-rg --type system --tail 300
```

## Admin endpoints

`POST /api/v1/admin/warm-cache` (and any future `/api/v1/admin/*` route) is
gated by the `X-API-Key` header matching `settings.admin_api_key`, sourced
from the `ADMIN_API_KEY` env var. This value is kept in sync in two places —
rotate both together if it ever needs to change:

- Azure Container App env var (`az containerapp update --container-name
  api-home-scope --set-env-vars "ADMIN_API_KEY=<value>"`)
- GitHub Actions secret `ADMIN_API_KEY` (used by `warm-cache.yml`)

## Amenities cache warming

`services/cache_warmer.py` geocodes and fetches amenities for every region's
top searched areas (per `services/popularity_store.py`, which only has data
once real searches happen — nothing to warm on a fresh deployment).
`.github/workflows/warm-cache.yml` calls this weekly (Monday 03:00 UTC, plus
manual `workflow_dispatch`), matching the amenities cache's 7-day TTL
(`AMENITIES_CACHE_TTL_SECONDS` in `overpass_service.py`).

This exists because the public Overpass mirrors
(`overpass-api.de` + two fallbacks, see `OVERPASS_MIRRORS`) are shared,
capacity-limited infrastructure that reject high-volume automated traffic
outright under load — confirmed failing across all three endpoints
simultaneously during this session. Cache warming reduces how often real
user traffic depends on a live Overpass call succeeding, but doesn't fix an
Overpass outage already in progress, and doesn't help on a cache miss for an
area nobody has searched yet. The real long-term fix (self-hosting Overpass,
or switching to a paid POI provider) is still an open decision — not
implemented.

## Local-only reference

Azure login email, tenant ID, and other account details are in
`.local/azure-notes.md` (gitignored, never committed) — see that file, not
this one, for anything you'd need to re-authenticate.
