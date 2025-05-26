# Menu Optimizer – MVP (Sur Le Feu)

This is a lightweight, modular MVP built with **Streamlit** and **PostgreSQL** to help chefs and consultants like Chef optimize menus across multiple client restaurants. The app connects to **Supabase** for persistent data storage and is fully container- and cloud-ready.

## 🚀 Features

- Multi-page Streamlit app (`Dashboard`, `Recipes`, `Ingredients`)
- PostgreSQL database powered by Supabase
- Modular page structure with WSL2-friendly setup
- Production-ready dev environment (venv, linting, Git-enabled)
- Git commit standards embedded for consistent collaboration

---

## 🧱 Folder Structure

```
menu_optimizer/
│
├── .streamlit/              # Streamlit configuration (theme, secrets)
├── .vscode/                 # VSCode workspace and debug config
├── pages/                   # Modular page structure (Dashboard, Recipes, Ingredients)
├── data/                    # Future sample data loaders (seeders, CSVs)
├── utils/                   # Reusable utilities (database, helpers)
│
├── app.py                   # Main router for page rendering
├── requirements.txt         # Locked dependencies
├── seed_supabase.py         # Seeder script to populate Supabase
├── setup.sh                 # Bootstrap for WSL dev environment
├── README.md                # This file
```

---

## 🧪 Setup Instructions (WSL / Ubuntu 22.04)

```bash
# Clone repo and run bootstrap
git clone <repo-url> && cd menu_optimizer
bash setup.sh

# Create and activate virtual env
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set Supabase keys in `.streamlit/secrets.toml`
# Then run the app
streamlit run app.py
```

---

## ✅ Git Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) (adapted):

```
feat:     new feature
fix:      bug fix
chore:    tooling or non-prod change
refactor: structure or naming change
style:    linting, whitespace, no logic change
docs:     readme, spec, diagrams
test:     test files, coverage, test updates
```

**Examples**:

```bash
git commit -m "feat: add Supabase connection client"
git commit -m "refactor: modularize recipe form logic"
git commit -m "docs: create setup instructions in README"
```

---

## 🧭 Roadmap

- [ ] Supabase client setup
- [ ] Dashboard chart scaffold
- [ ] Ingredient browser with table + filters
- [ ] Recipe breakdown & edit view
- [ ] Auth + multi-tenant support

---

© 2025 Sur Le Feu | OpsForge Module