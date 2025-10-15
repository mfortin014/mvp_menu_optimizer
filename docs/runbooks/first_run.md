# Runbook: First Clone → First Run

**Updated:** 2025-10-14

Purpose: help a new contributor bootstrap the MVP locally with **no plaintext secrets** on disk.

---

## 1. Prerequisites

- macOS/Linux (or WSL Ubuntu 22.04) with Python 3.11.
- Git + VS Code (recommended).
- **Bitwarden Secrets Manager** access to the `menu-optimizer-staging` project and a **Machine Token**.
- **bws** CLI installed and on `PATH`.
- **direnv** installed with the shell hook enabled (e.g., add `eval "$(direnv hook bash)"` to `~/.bashrc`).
- GitHub access to clone the repository.

> Local runs do **not** use `.env` or `.streamlit/secrets.toml`. Env vars are injected at shell runtime from Bitwarden via direnv. The app reads environment variables first (see `utils/secrets.py`) and falls back to `st.secrets` only in CI.

---

## 2. Clone the Repo

```bash
git clone git@github.com:mfortin014/mvp_menu_optimizer.git
cd mvp_menu_optimizer
```

---

## 3. Create a Virtual Environment & Install Deps

Your VS Code may auto-activate `.venv`. If not:

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements-dev.txt
```

---

## 4. Inject Staging Secrets from Bitwarden (no files on disk)

**Option A — simple per-session:**

```bash
export BWS_ACCESS_TOKEN='<paste-machine-token>'
direnv reload
```

**Option B — helper functions (optional; add to `~/.bashrc`):**

```bash
bws_on()  { local t; read -s -p "BWS token: " t; echo; [ -z "$t" ] && return 1; export BWS_ACCESS_TOKEN="$t"; direnv reload; unset t; }
bws_off() { unset BWS_ACCESS_TOKEN; direnv reload; }
```

Usage:

```bash
bws_on   # prompts, injects env from BWS for this terminal only
bws_off  # clears token + un-injects
```

**Verify (names only, values masked):**

```bash
env | grep -E '^(DATABASE_URL|SUPABASE_URL|SUPABASE_ANON_KEY|CHEF_PASSWORD)=' | sed 's/=.*$/=****/g'
```

---

## 5. Launch the App

From the **injected** terminal:

```bash
streamlit run Home.py
```

When done: `Ctrl+C`, then `bws_off` (or `unset BWS_ACCESS_TOKEN; direnv reload`).

---

## 6. Run Quality Gates Locally

```bash
ruff check .
black --check .
isort --check-only .
pytest tests/unit
pytest tests/smoke
```

All commands should pass before pushing a branch.

---

## 7. Sample Data (Optional)

- Lightweight fixtures live under `data/fixtures/`.
- Scripts (e.g., `dump_sample_data.sh`) honor `DATABASE_URL` from env.

---

## 8. Next Steps

- Review `docs/README.md` for policies and runbooks.
- Open a feature branch (`git checkout -b feature/<slug>`).
- Align your work with the relevant spec in `docs/specs/`.
