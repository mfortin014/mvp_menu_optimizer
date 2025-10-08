# Changelog
All notable changes to this project will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
[Compare](https://github.com/mfortin014/mvp_menu_optimizer/compare/mvp-0.6.0...HEAD)

- **Added:** 23 change(s)
- **Fixed:** 26 change(s)
- **Changed:** 6 change(s)
- **Documentation:** 5 change(s)
- **Chore:** 8 change(s)
- **Style:** 1 change(s)
- **Reverted:** 2 change(s)
- **Other:** 10 change(s)

### Added
- Unit and smoke test scaffolds under `tests/` with lightweight fixtures for CI.

### Documentation
- Phase-1 operational docs: repo structure, migrations discipline, first-run and smoke runbooks, specs index.
- Refreshed README to highlight MVP workflows and doc entry points.

### Chore
- CI workflow installs dev dependencies and executes unit/smoke pytest suites on PRs.

## [0.6.0] - 2025-09-16
[Tag: mvp-0.6.0](https://github.com/mfortin014/mvp_menu_optimizer/releases/tag/mvp-0.6.0)

### Added
- Multi-tenant architecture: tenant-aware DB proxy for reads/writes; single default client constraint; RLS policies and views; migration set V001–V011.
- Client management UI: unified **Clients** page, **Tenant Manager** (list/add/edit/activate/deactivate/switch), pre‑auth client picker with DB default, **Active Client** badge.
- Tenant branding: DB-driven logo/colors; global brand colors across UI.
- Configurable default tenant (env + DB fallback); sample data + schema dumps via `dump_schema.sh`.
- Release hygiene: `VERSION` source of truth, migration markers, and helper scripts (`bump_version.sh`, `release_stamp.sh`).

### Fixed
- Client page state: reliable hydration and selection, enforce single default, prevent deactivating the default client.
- UI stability: clear form state without rehydration glitches; sticky focus issues; grid selection edge cases.
- Branding loader: always return safe defaults (no KeyError/None).

### Changed
- Tenant resolution now uses session/env; removed per‑page tenant dropdown in favor of the **Active Client** badge and centralized switching.
- Consolidated navigation and forms for a simpler, predictable flow.

### Documentation
- MVP roadmap, feature specs, and trackers updated; schema snapshots added under `schema/`.
