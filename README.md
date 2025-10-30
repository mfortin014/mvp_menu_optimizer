# Menu Optimizer — MVP Guide

Menu Optimizer helps Chef’s culinary consulting team track recipe costs, performance, and menu health. The MVP is delivered in **Streamlit** on top of **Supabase**. React/web workers arrive in v1.

---

## Quick Start (MVP)

1. Follow the runbook: [First Clone → First Run](docs/runbooks/first_run.md).
2. Launch the app with staging credentials: `streamlit run Home.py`.
3. Keep the quality gates green before opening a PR:
   - `ruff check .`
   - `black --check .`
   - `isort . --check-only`
   - `pytest tests/unit`
   - `pytest tests/smoke`

Need more detail? The docs index lives at [docs/README.md](docs/README.md).

---

## Documentation & Runbooks

### MVP now
- [Project Bible (Index)](docs/README.md) — authoritative map of all docs.
- [Repo Structure & Paths](docs/reference/repo_structure.md) — where things live.
- [CI/CD Policies](docs/policy/ci_minimal.md) and [Migrations & Schema Discipline](docs/policy/migrations_and_schema.md).
- [Smoke QA](docs/runbooks/smoke_qa.md) — staging checks and evidence.
- [Specs Index](docs/specs/README.md) — templates and active specs.

### v1 later
- React client docs, ADRs, and production hardening runbooks move in once the platform migrates.

---

## Quality & CI

GitHub Actions runs on every PR (`.github/workflows/ci.yml`):
- Ruff, Black, and isort in check mode.
- Unit tests (`tests/unit/`) for pure logic and guardrails.
- Smoke tests (`tests/smoke/`) that load lightweight fixtures only.
- Syntax compilation sweep to catch regressions without hitting the network.

On pushes to `main`, the workflow builds a single release artifact and promotes it via `deploy-staging` (auto) then `deploy-production` (manual approval in the GitHub `production` environment). After approval, fast-forward the protected `prod` branch so Streamlit Cloud (`surlefeu.streamlit.app`) serves the promoted commit. See [Release Playbook — Production promotion](docs/runbooks/release_playbook.md#4-production-promotion).

---

## Sample Data

- Lightweight fixtures for docs/tests: `data/fixtures/` (e.g., `ingredients.csv`).
- Full Supabase export: `data/exports/2025-09-09/` (read-only, ignored by Git).

Never commit local edits to either directory; create new fixtures instead.

---

## Project Structure (MVP excerpt)

```
.
├── Home.py
├── components/
├── data/
│   ├── fixtures/
│   └── exports/
├── docs/
├── migrations/
│   └── sql/
├── schema/
│   ├── current/
│   └── releases/
├── tests/
│   ├── smoke/
│   └── unit/
└── utils/
```

See [Repo Structure & Paths](docs/reference/repo_structure.md) for the full breakdown and naming rules.

---

## Tech Stack
- Frontend: [Streamlit](https://streamlit.io)
- Backend: [Supabase](https://supabase.com) (PostgreSQL + RPC)
- Tooling: Ruff, Black, isort, Pytest

---

## Roadmap Snapshots

- MVP: Streamlit app, Supabase staging/prod, manual deploys supported by runbooks.
- v1: React front-end, automated deploy pipeline, richer analytics schemas.
## Automation

Seed-driven GitHub workflows turn Markdown seeds into issues and Projects entries: pending -> created -> fields -> sub-issues -> applied.

- [CI — GitHub Object Creation Automation](docs/policy/ci_github_object_creation.md) documents tokens, permissions, and troubleshooting for the workflow.
- [Seed File Schema](docs/policy/seed_schema.md) outlines supported header keys, routing options, and quick-start examples.

---

## Known Issues / To Do

Track progress in GitHub Issues/Projects linked from the docs index.

---

## License
MIT
