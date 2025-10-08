# Runbook: First Clone → First Run
**Updated:** 2025-09-18 21:25

Purpose: help a new contributor bootstrap the MVP locally in under 30 minutes.

---

## Prerequisites

### MVP now
- macOS/Linux with Python 3.11 available (`pyenv` recommended).
- Access to Supabase credentials (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) for staging or a personal sandbox.
- GitHub access to clone the repository.

### v1 later
- Node 20+ (React client), Docker, and GitHub CLI for environment automation.

---

## 1. Clone the Repo
```bash
git clone git@github.com:mfortin014/mvp_menu_optimizer.git
cd mvp_menu_optimizer
```

## 2. Create a Virtual Environment
```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
```

## 3. Install Dependencies
```bash
pip install -r requirements-dev.txt
```
This installs the Streamlit app, lint/test tooling, and smoke dependencies.

## 4. Configure Environment Variables

### MVP now
1. Copy `.env.example` (or create `.env`) with Supabase keys.  
2. Mirror the same values in `.streamlit/secrets.toml` if you prefer Streamlit’s secrets store.  
3. Do **not** commit credential files.

### v1 later
- Use `mise` or `direnv` to keep secrets scoped per environment.

## 5. Pull Sample Data (Optional)
- Lightweight fixtures: `data/sample/` (CSV) for tests and demos (e.g., `ingredients.csv`).  
- Full Supabase dump: `data/sample_data/` for deeper local exploration (never edit in place).

## 6. Run Quality Gates Locally
```bash
ruff check .
black --check .
isort --check-only .
pytest tests/unit
pytest tests/smoke
```
All commands should pass before pushing a branch.

## 7. Launch the Streamlit App
```bash
streamlit run Home.py
```
Log in with staging credentials; confirm the dashboard loads and sample tenant data appears.

## 8. Next Steps
- Review `docs/README.md` for policies and runbooks.  
- Open a feature branch (`git checkout -b feature/<slug>`).  
- Align your work with the relevant spec in `docs/specs/`.
