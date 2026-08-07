## gstack (REQUIRED — global install)

**Before doing ANY work, verify gstack is installed:**

```bash
test -d ~/.claude/skills/gstack/bin && echo "GSTACK_OK" || echo "GSTACK_MISSING"
```

If GSTACK_MISSING: STOP. Do not proceed. Tell the user:

> gstack is required for all AI-assisted work in this repo.
> Install it:
> ```bash
> git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
> cd ~/.claude/skills/gstack && ./setup --team
> ```
> Then restart your AI coding tool.

Do not skip skills, ignore gstack errors, or work around missing gstack.

Using gstack skills: After install, skills like /qa, /ship, /review, /investigate,
and /browse are available. Use /browse for all web browsing.
Use ~/.claude/skills/gstack/... for gstack file paths (the global path).

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec

## Project overview

HomeScope analyzes an address and returns a Location Score based on walkability,
schools, hospitals, transport, shopping, recreation, etc. Built for Portugal first.
The repo contains three independently deployable products that share the FastAPI
backend and its OSM/scoring pipeline:

- `mobile/` — the primary Flutter app (iOS + Android).
- `extension/`, `extension-v2/` — "NeighborLens" Chrome extensions (Manifest V3,
  vanilla JS, no build step) that surface the same property-intelligence data as a
  browser side panel. `extension-v2` is the active MapLibre-based rewrite.
- `backend/` — the FastAPI service consumed by both frontends.

## Commands

### Backend (FastAPI + Python 3.12)

```bash
./scripts/start_backend.sh          # docker compose up: api + postgres/postgis + redis
# or manually:
docker compose up                   # API at http://localhost:8000, docs at /docs

cd backend && pip install -r requirements.txt   # local (non-docker) install
uvicorn main:app --reload --port 8000           # run API locally against a running db/redis
```

### Backend tests

```bash
python -m pytest tests/unit/ -v                          # unit tests (scoring, overpass)
python -m pytest tests/unit/test_scoring_engine.py -v     # single file
python -m pytest tests/unit/test_scoring_engine.py::test_name -v  # single test
python -m pytest tests/integration/ -v                    # requires backend running on :8000
./scripts/test_api.sh                                     # quick curl-based smoke test
```

`tests/conftest.py` adds the repo root to `sys.path` so `backend/` modules
(`config`, `geocoding`, `services`, `scoring`, `ai`, `models`) import as top-level
packages — run pytest from the repo root, not from `backend/`.

### Mobile (Flutter 3 + Riverpod)

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # regen Freezed/JSON models
flutter run -d "iPhone 16" --dart-define=BACKEND_URL=http://localhost:8000
flutter test test/                          # all widget tests
flutter test test/path/to/widget_test.dart  # single file
flutter analyze                             # lint (flutter_lints)
```

`BACKEND_URL` must be passed via `--dart-define`; without it the app falls back to
the production Azure URL hardcoded in `mobile/lib/config/app_constants.dart`.

### Browser extension (extension-v2)

No build step — load `extension-v2/` directly as an unpacked extension
(`chrome://extensions` → Developer mode → Load unpacked). Edit `extension-v2/js/`
and reload the extension to pick up changes.

### Playwright E2E (tests/playwright)

```bash
cd tests/playwright && npm install
npx playwright test                 # runs specs/ against the extension/backend
```

## Architecture

### Backend request pipeline

`backend/api/routes/analyze.py` implements the primary `/api/v1/analyze` endpoint
as a four-stage pipeline, and is the best entry point for understanding how the
pieces fit together:

1. **Geocode** — `geocoding/nominatim.py` resolves an address to lat/lng via
   Nominatim (OpenStreetMap).
2. **Amenities** — `services/overpass_service.py` queries the Overpass API for
   nearby POIs (schools, transit, healthcare, etc.) within `radius`.
3. **Score** — `scoring/scoring_engine.py` applies weighted category scoring;
   weights come from `config/scoring_config.py` and are adjusted per user profile
   (family/student/professional/retired/investor).
4. **AI summary** — `ai/summary_generator.py` calls OpenAI (optional; falls back
   to templated text if `OPENAI_API_KEY` is unset).

The individual stages are also exposed as standalone endpoints
(`/geocode`, `/amenities`, `/score`, `/ai/summary`) for the mobile app's cache
layer to call independently. `services/routing_service.py` (OpenRouteService)
optionally replaces Haversine straight-line distances with real walking/driving
times — also optional and key-gated.

All external clients (Nominatim, Overpass, OpenRouteService) are async httpx
clients closed in `main.py`'s `lifespan` shutdown hook — new service clients
should follow the same pattern rather than opening per-request connections.

Country behavior (postal code patterns, default map center, Nominatim country
name) is data-driven from `mobile/assets/config/countries.json`; adding a country
should never require backend or Dart code changes.

### Mobile app structure

- `lib/providers/` — Riverpod providers are the state layer; `analysis_provider.dart`
  drives the main geocode→score→AI flow, backed by `services/cache_service.dart`
  (Hive) so repeat lookups skip the network.
- `lib/services/api_service.dart` — the only place that talks to the backend
  (Dio); `carris_service.dart` is a Lisbon-specific transit data integration.
- `lib/services/validation_service.dart` — country-aware address/postal
  validation driven by `countries.json`.
- `lib/models/` — Freezed data classes; run `build_runner` after changing any of
  these.
- Routing is centralized in `lib/config/app_router.dart` (go_router); theme in
  `app_theme.dart`.
- In-app purchases go through `purchases_flutter` (RevenueCat) via
  `lib/services/purchase_service.dart` and `lib/providers/pro_provider.dart`.

### Other directories

- `automation/` — Appium + vision-based automation for mobile QA, independent of
  the Flutter widget test suite.
- `database/migrations/` — raw PostgreSQL + PostGIS SQL, applied automatically by
  the `db` container on first start (`docker-entrypoint-initdb.d`); `backend/`
  also has its own `migrations/` for Alembic-managed schema changes — check which
  one a given schema change belongs to before adding a migration.
- CI/CD is two chained GitHub Actions workflows: `build.yml` builds and pushes the
  backend Docker image to GHCR on push to `main`; `deploy.yml` triggers on that
  workflow's completion and deploys `docker-compose.prod.yml` to an Azure Web App.
  There is no test gate in either workflow — tests are run manually.
