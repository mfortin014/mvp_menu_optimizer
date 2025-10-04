# Seed Schema — Header Keys, Rules & Examples
Updated: 2025-10-04

Seeds are Markdown files with an **HTML comment header** that the seeder parses.
All arrays must be **JSON arrays**. Unknown keys are ignored.

## Supported keys (header)
- `title` (string, required)
- `labels` (string[] — JSON)
- `assignees` (string[] — JSON)
- `uid` (string, required — unique)
- `parent_uid` (string — link child → parent)
- `children_uids` (string[] — JSON — list of child UIDs for epics)
- `type` (string — maps to Project field **Type**)
- `status` (string — maps to **Status**)
- `priority` (string — maps to **Priority**)
- `target` (string — maps to **Target Release**)
- `area` (string — maps to **Area**)
- `doc` (string — maps to **Doc Link**)
- `pr` (string — maps to **PR Link**)
- `project` (`"test"` | `"main"`) — routing hint
- `project_url` (string — explicit Projects v2 URL; overrides `project`)

## Validation rules
- `uid` must be unique across the repo.  
- `labels`, `assignees`, `children_uids` **must** be JSON arrays (e.g., `["ci","phase:phase-0"]`).  
- If both `parent_uid` and `children_uids` are present, they should be consistent (no loops).  
- On create-only runs, existing issues (matched by embedded `<!-- seed-uid:... -->`) are **skipped**.

## Epic example (with children)
```md
<!--
title: Epic — GitHub Objects Creation
labels: ["ci","github-admin","phase:phase-0"]
assignees: []
uid: auto-gh-epic
type: Epic
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
children_uids: ["auto-gh-A","auto-gh-B","auto-gh-C","auto-gh-D"]
project: "main"
project_url: ""
doc: ""
pr: ""
-->
# Epic — GitHub Objects Creation
```

## Child example (with parent)
```md
<!--
title: Automation B — Native hierarchy via Sub-issues
labels: ["ci","github-admin","phase:phase-0"]
assignees: []
uid: auto-gh-B
parent_uid: auto-gh-epic
type: Chore
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
project: "test"
doc: ""
pr: ""
-->
# Automation B — Native hierarchy via Sub-issues
```

## Non-epic item (no hierarchy)
```md
<!--
title: Fix: clarify mapping for Priority=P1
labels: ["ci","phase:phase-0"]
assignees: []
uid: auto-gh-fix-priority
type: Chore
status: Todo
priority: P2
target: mvp-0.7.0
area: ci
project_url: "https://github.com/users/<user>/projects/<n>"
doc: ""
pr: ""
-->
# Fix: clarify mapping for Priority=P1
```

## Notes
- Routing: `project_url` (if set) wins; else `project` (“test”/“main”); else repo default.  
- The seeder writes a **Children** checklist in epic bodies as a human mirror.  
- Native hierarchy (Sub-issues) is handled by the **Hierarchy** workflow/action.
