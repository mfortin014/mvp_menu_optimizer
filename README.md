# Menu Optimizer

Optimize recipe costs and menus with tenant‑aware data and a clean Streamlit UI.

**Status:** stable on `main` at **mvp-0.6.0** (pre‑1.0 SemVer).  
**Branch model:** `main` (stable), `develop` (integration), short‑lived `feat/*` and `fix/*` branches.

---

## Quickstart

```bash
# 1) Python env
python -m venv .venv && source .venv/bin/activate

# 2) Install deps
pip install -r requirements.txt

# 3) Configure database connection (Postgres/Supabase)
# Create a file named .env with:
#   DATABASE_URL="postgresql://<user>:<pass>@<host>:5432/postgres?sslmode=require"

# 4) (Optional) seed/sample data for demos
./dump_sample_data.sh

# 5) Run the app
streamlit run Home.py
```

- Schema snapshots are generated via `dump_schema.sh` into `schema/`.
- Runtime secrets can also be placed in `.streamlit/secrets.toml` if preferred.

---

## Features (high‑level)

- Multi‑tenant data model with row‑level security (RLS).
- Tenant branding (colors/logo) and an **Active Client** badge.
- Recipe editor with recompute on edits.
- Import flows and **cost update** events.
- Clean UI state management (no surprise reruns).
- Schema dumps and migration markers for reproducible releases.

> Detailed specs and trackers live in **/docs** (see Docs Map).

---

## Tech Stack

- **Frontend:** Streamlit (Python)
- **Database:** Postgres / Supabase
- **CI:** GitHub Actions (minimal placeholder workflow)
- **Language/Tools:** Python 3.x

---

## Repo Structure (top level)

```
├─ components/        # UI building blocks
├─ pages/             # Streamlit pages (Recipes, Editor, Clients, ...)
├─ utils/             # tenant_db, branding, cache, version helper
├─ migrations/        # release markers + SQL notes
├─ schema/            # schema dumps (pg_dump via dump_schema.sh)
├─ scripts/           # helpers (bump_version, release_stamp)
├─ docs/              # specs, trackers, notes
├─ Home.py            # Streamlit entry point
├─ VERSION            # source of truth for app version
└─ dump_schema.sh     # exports schema/*.sql from $DATABASE_URL
```

---

## Configuration

Create `.env` in the repo root:
```
DATABASE_URL="postgresql://<user>:<pass>@<host>:5432/postgres?sslmode=require"
```
- `dump_schema.sh` reads `.env` to produce `schema/supabase_schema_<date>[_NN].sql`.
- For Streamlit secrets, you may also use `.streamlit/secrets.toml`.

---

## Docs Map

- **Specs:** `docs/specs/` (e.g., Recipes as Ingredients)
- **Trackers:** `docs/trackers/` (workplans, checklists)
- **Notes:** `docs/notes/` (meeting notes, ChatGPT conversations)
- **Changelog:** `CHANGELOG.md` (notable changes)
- **Releases:** Git tags `mvp-X.Y.Z` on `main`

---

## Versioning & Releases

- **Source of truth:** `VERSION` (also shown in the app header).  
- **Tags on main:** `mvp-X.Y.Z` (pre‑1.0 SemVer: bump **MINOR** for features, **PATCH** for fixes).  
- **Flow:** cut `release/X.Y.Z` from `develop` → harden → PR to `main` (**Squash**) → tag → back‑merge `main → develop` via PR.

CLI helpers:
```bash
scripts/bump_version.sh X.Y.Z
scripts/release_stamp.sh X.Y.Z   # adds migration marker + runs dump_schema.sh
```

---

## Contributing

- Branch names: `feat/<thing>`, `fix/<thing>`, `chore/<thing>`
- PRs required; CI must be green (placeholder action runs)
- Linear history on `main` (Squash merges)
- No secrets in code; use `.env` / repository secrets

---
