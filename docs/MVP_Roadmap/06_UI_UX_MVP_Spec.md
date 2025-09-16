
# 06_UI_UX_MVP_Spec — Streamlit App UI/UX (Aligned to Foundation/Identity/Measure/Chronicle/Intake/Lexicon)
**Version:** 1.0  \n**Updated:** 2025-09-16 16:58  \n**Applies to:** Streamlit MVP (no FIRE)  \n**Scope:** Frontend behavior, component patterns, page contracts, and UI acceptance criteria **including** all items from *Menu_Optimizer_Roadmap_Tracker.md* (merged and normalized).

---

## 1) Purpose
Provide a lean but future-proof UI/UX spec that matches the backend invariants and engines:
- **Foundation_MVP:** error discipline, tenant context, event toasts, parity export.
- **Identity_MVP:** deterministic identity and soft-delete semantics surfaced in UI.
- **Measure_MVP:** item-scoped UOM, cost math visibility.
- **Chronicle_MVP:** recipe versions (draft/publish), price history, as-of costing.
- **Intake_MVP:** CSV upload → validate/quarantine → commit.
- **Lexicon_MVP:** minimal bilingual labels and fallbacks.

This document **consolidates** all UI tasks from the attached tracker into one spec for consistent implementation.

---

## 2) Design principles
1. **Contracts-first:** UI reflects the contracts and invariants; no business rules live in widgets.
2. **Predictable errors:** every failure renders `code/message/details`. No stack traces.
3. **Tenant-safe by design:** all selectors and pages are scoped to the loaded tenant and hide soft-deleted rows by default.
4. **Explain the math:** show base-unit conversions, unit costs, line costs; never hide the arithmetic.
5. **Low-friction editing:** draft-while-editing, one-click Save → Publish for recipes.
6. **Accessible & legible:** keyboard-first flows, focus states, reasonable contrast, consistent formatting.

---

## 3) Information Architecture & Navigation
- **Top-level pages:** Dashboard (optional), **Recipes**, **Ingredients**, **Settings**, **Clients**.
- **Settings tabs:** General (branding), **Ingredient Categories**, **UOM Conversions** (moved here), (optionally link to Clients).
- **Tenant badge:** in sidebar + header; “Change client” button jumps to Clients page (kept top-level).
- **Soft-delete convention:** archived rows hidden by default with “Show archived” toggle; detail shows a subtle “Archived” pill if applicable.

---

## 4) Component & Pattern Library (Streamlit)
### 4.1 Forms
- Layout: left **Form**, right **Grid**; consistent Save / Cancel / Delete row.
- Validation: disable Save until required fields valid; focus first invalid field on submit.
- Delete = **soft delete** (sets `deleted_at`), confirm dialog explains recovery path.

### 4.2 Grids
- Sticky header, sortable columns, quick filter; selected row highlighted and synced to form.
- “Clear selection” resets the form without navigation.
- Empty-state cards for empty tables.

### 4.3 Number formatting utilities
- Currency: `$ 0.00` (tenant currency).
- Percent: `0.0 %`.
- Unit cost: `$ 0.00000`.
- Package qty: integer if whole; else up to 5 decimals.
- Locale-aware separators when feasible.

### 4.4 Error & Toasts
- One `render_error(err)` to display uniform error shape.
- Success/error toasts with consistent copy (“Saved”, “Updated”, “Archived”, “Validation error”).

### 4.5 Event toasts (Foundation)
- When events are emitted: show ephemeral toasts:
  - `ingredient.cost.updated`
  - `import.completed`
  - `recipe.recomputed`

---

## 5) Page Requirements (merged with Roadmap items)

### 5.1 Clients
- Sticky loaded client; exclusive default; cannot deactivate default or set inactive as default.
- Mode toggle as stable radio.
- Branding (logo/colors) render in chrome (sidebar badge + header).

### 5.2 Ingredients
- Form fields: **ingredient_code** (normalized preview), **name** (labels move to Lexicon), **base_unit (g/ml/unit)**.
- Aliases panel: add/remove rows (type+value), normalized, dedupe errors surfaced.
- Category dropdown wired (fix blank state); soft delete and hide archived.
- Grid headers humanized; selection ↔ form sync.

### 5.3 Ingredient Categories (Settings tab)
- Move to **Settings** › Ingredient Categories.
- Grid loads data (fix RLS error), soft delete enabled.

### 5.4 UOM Conversions (Settings tab)
- Global read table (tenant-readable); write allowed per permissions.
- Display **derived reverse** conversion (do **not** store both directions).
- Prevent duplicates; consistent grid & form.

### 5.5 Recipes (list)
- Uniform grid; soft delete; number formatting; cross-tenant-safe selectors via views only.

### 5.6 Recipe Editor (Chronicle)
- **Draft ribbon** when editing a published recipe; Save → **Publish** (atomic new version).
- Header badge: “Current vN (effective YYYY-MM-DD hh:mm)”; for drafts, “Draft”.
- Lines grid:
  - Qty + UOM editor; **derived base units** helper line; unit cost (current) and **extended cost** column.
  - Manual **line ordering** (line_no) with re-number logic.
  - Auto-prefill UOM and unit cost when selecting ingredient or prep recipe.
- Price widget: table of price rows with “Set New Price” action (creates new history row).

### 5.7 As-of Cost View (Chronicle)
- Timestamp picker; compute cost/price/margin using published recipe version and ingredient costs effective at timestamp.
- Breakdown table: ingredient → qty/uom → base qty → unit cost at ts → line cost.

### 5.8 Import Wizard (Intake)
- 3-step wizard:
  1) **Upload** (choose file; optional mapping profile) with 10-row preview.
  2) **Validate** (show counts; error table with row/column/error code/sample).
  3) **Commit** (summary and `import.completed` event id).
- **Nice-to-have**: save/apply per-tenant mapping profiles.

### 5.9 Admin: Parity Export (Foundation)
- Page to export `event_log` window (CSV/JSON) for parity testing.

### 5.10 Localization (Lexicon)
- Show bilingual fields (en/fr) for ingredient label/description with fallback rules.
- Identity never derives from label; UI hints communicate this.

---

## 6) Accessibility & Performance
- Keyboard: Enter = Save (when valid), Esc = cancel edit; focus management on errors.
- Minimum contrast and font sizes; consistent spacing.
- Lightweight loading skeletons for grids/forms.
- No blocking recomputes on navigation; long work signaled with spinner/toast.

---

## 7) Acceptance Criteria (UI)
- Error discipline: every failure shows uniform error; no Python tracebacks.
- Tenant safety: all selectors are tenant-scoped; archived hidden by default.
- Measure clarity: every recipe line shows entered UOM **and** derived base units; extended cost visible.
- Chronicle UX: editing a published recipe yields **one** new published version on Save; badges update.
- As-of correctness: `at=now()` equals current recompute; changing timestamp switches windows correctly.
- Intake resiliency: bad file never commits; row-level errors exportable; good file commits and emits event.
- Parity export returns event rows within a chosen window.
- Number formatting consistent across pages.

---

## 8) Mapping to Engine Owners (for dev handoff)
- **Foundation_MVP:** errors, toasts, parity export, soft-delete UI conventions, tenant badge.
- **Identity_MVP:** ingredient code normalization UX; alias panel; duplicate finder/merge action.
- **Measure_MVP:** base unit selector; conversion helper; unit/extended cost display.
- **Chronicle_MVP:** version badge/ribbon; Save→Publish; price widget; as-of view.
- **Intake_MVP:** wizard steps, validation table, summaries, profiles.
- **Lexicon_MVP:** bilingual fields & fallback messaging.

---

## 9) Items imported from *Menu_Optimizer_Roadmap_Tracker.md*
All checklist items from Plans 1–5 and Page-Specific sections have been absorbed and normalized above:
- **Plan 1 (Tenant + Soft Delete):** soft delete everywhere; selectors scoped; Categories wiring; default client rules; branding; migrations.  
- **Plan 2 (Uniformisation):** grid selection syncing; form layout; headers humanized; number formatting; Settings tab move.  
- **Plan 3 (Polishing):** color leaks removed; unified toasts; CSV export naming; CSV import parser w/ preview.  
- **Plan 4 (Wiring):** tenant proxy/views; permissive RLS now; strict claims (V008) planned; migration runner; helper SQL funcs tenant-aware.  
- **Plan 5 (Data & Costing):** unit-cost parity fix; auto-prefill; line ordering; reverse conversion policy (derive).  
- **Page-specific checklists:** Clients, Ingredients, Ingredient Categories, UOM Conversion, Recipes, Recipe Editor, Settings—all reflected in sections 5.1–5.10.
