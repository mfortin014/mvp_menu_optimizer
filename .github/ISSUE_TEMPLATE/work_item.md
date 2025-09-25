---
name: Work Item
about: Start work with a clear intent and acceptance bullets; keep Project fields in GitHub Projects (not here)
title: "<short title>"
assignees: []
---

## Because
Who benefits and why now? One or two sentences max.

## Outcome (one sentence)
What will be true when this is done?

## Done when (acceptance bullets)
- [ ] …
- [ ] …

## Links
- **Doc/Spec:**  
- **PR (if opened):**  
- **Related Issues:**  

## Tasks — in repo
- [ ] …

## Tasks — external (GitHub settings, Supabase, etc.)
- [ ] …

<details>
<summary><strong>Flags / Migrations / Observability (optional)</strong></summary>

**Flags (if any)**  
Owner • default (OFF/ON) • kill switch • planned removal date

**Migrations (if any)**  
Expand → Migrate → Contract; reference `migrations/sql/V***__*.sql`

**Observability**  
Smoke checks + key metrics/events to watch; deploy marker name
</details>

<details>
<summary><strong>Risk & rollback (brief)</strong></summary>

Worst likely failure and how we’d roll back or disable safely.
</details>

<details>
<summary><strong>Out of scope (guardrails)</strong></summary>

- …
- …
</details>

**Notes**  
Create a short-lived branch named `<type>/<short-slug>` (e.g., `feat/add-tenant-wizard`).  
Open a Draft PR early and reference this Issue. When ready, include “Closes #<issue>” in the PR.
