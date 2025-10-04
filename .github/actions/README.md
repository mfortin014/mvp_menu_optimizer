# Reusable Actions Catalog

- **Generic (repo-agnostic, 'gh-*')**
  - gh-move-files-commit — move files, commit, push (stub in E1)
  - gh-open-pr — open/update PR (stub in E1)
  - gh-auto-merge-pr — enable auto-merge (stub in E1)
  - gh-link-hierarchy — native Sub-issues links (stub in E1)

- **GOC-specific (seed-aware, 'goc-*')**
  - goc-seed — parse seed, create/resolve issue, add to Project, write fields (stub in E1)
  - goc-project-set-fields — write Project fields only (stub in E1)

E1 = scaffolding only. These composites log inputs and exit 0. E2 will wire real logic from scripts/goc/.
