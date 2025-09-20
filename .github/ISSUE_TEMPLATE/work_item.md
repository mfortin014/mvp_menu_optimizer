---
name: Work Item
about: Start work with a clear intent and acceptance bullets (Feature/Bug/Chore/Policy/Runbook)
title: "<type>: <short title>"
labels: []
assignees: []
---

Because  
What problem or outcome are we targeting? Who benefits, and why now?

Type  
Choose one: Feature · Bug · Chore · Policy · Runbook · Spec

Area  
<intake | identity | measure | chronicle | lexicon | ui | db | ci | policy | runbooks>

Outcome (one sentence)  
What will be true when this is done?

Done when (acceptance bullets)  
- [ ] …
- [ ] …

Links  
Doc/Spec:  
PR (if opened):  
Related Issues:

Tasks — in repo  
- [ ] …

Tasks — external (GitHub settings, Supabase, etc.)  
- [ ] …

Flags / Migrations / Observability (if applicable)  
- Flags: owner, default, kill switch, removal date  
- Migrations: expand → migrate → contract plan  
- Observability: smoke checks + key metrics to watch

Risk & rollback (brief)  
Worst likely failure, and how we’d roll back or disable safely.

Project fields (fill in Project view)  
Status = Todo (Specs start as Draft) · Type = <Feature|Bug|Chore|Policy|Runbook|Spec> · Priority = <P0|P1|P2|P3> · Target Release = mvp-<X.Y.Z> · Area = <area>

Notes  
Use a branch named `<type>/<short-slug>` (e.g., `feat/add-tenant-wizard`). Open a Draft PR early and reference this Issue. The PR should include “Closes #<issue>” when ready.
