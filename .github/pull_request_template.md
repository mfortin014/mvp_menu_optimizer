<!--
Intent-first PR template
Read the checklist; delete guidance before submitting.
Terms link to the Glossary: docs/reference/glossary.md
-->

# Because
<!-- One crisp sentence on the pain, risk, or opportunity.
Example: "Chef cannot save drafts across sessions, causing data loss on refresh." -->

# Changed
<!-- Minimal surfaces touched; be explicit about what you did NOT change. -->

# Result
<!-- User/system outcome. Screenshots or brief notes if applicable. -->

# Done when
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3 (optional)

# Out of scope
<!-- Temptations you explicitly skipped; create Issues for follow-ups. -->

# Flags
<!-- Feature flags changed/added. One per line: name, default, owner, planned removal date.
See: docs/policy/env_and_secrets.md -->
- flag: `example_flag`
  - default: OFF
  - owner: you
  - removal: `2025-12-31`

# Migrations
<!-- Note if schema/data changes follow Expand → Migrate → Contract.
Add script names like `migrations/sql/V00X__desc.sql`.
See: docs/policy/ci_cd_constitution.md -->
- Plan: Expand → Migrate → Contract
- Scripts: `V00X__add_column.sql`, `V00Y__backfill_values.sql`

# Observability
<!-- How this shows up in logs/metrics/events; add deploy markers as needed.
Include version, tenant_id, request_id, correlation_id. -->
- Deploy marker: yes / no
- Key metrics to watch: …
- Event name(s): …

# Risks / Rollback
<!-- What could go wrong and how to revert (artifact rollback or flag OFF). -->

# Changelog
<!-- One human sentence for release notes (Keep a Changelog style).
See: docs/policy/commits_and_changelog.md -->
Added — …
Changed — …
Fixed — …

---

## Meta

- Branch: `feat/short-slug` or `fix/short-slug` (see docs/policy/branching_and_prs.md)
- Conventional commit prefix for squash: `feat(scope): subject` (see docs/policy/commits_and_changelog.md)
- CI expectations (lint/tests/smoke): see docs/policy/ci_minimal.md
- Terms: see docs/reference/glossary.md
