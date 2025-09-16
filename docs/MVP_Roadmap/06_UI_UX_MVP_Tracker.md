
# 06_UI_UX_MVP_Tracker — Streamlit App UI/UX Implementation
**Version:** 1.0  \n**Updated:** 2025-09-16 17:33  \n**Status:** Draft  \n**Owner:** UI/UX

> Each task has an **Owner Spec** tag: Foundation | Identity | Measure | Chronicle | Intake | Lexicon

---

## NOW (blockers for a coherent MVP)
- [ ] **Error discipline** — unify error surface via `render_error(err)` (Owner: Foundation)
- [ ] **Tenant badge & scope** — sticky loaded tenant badge; selectors scoped via views (Owner: Foundation)
- [ ] **Soft delete everywhere** — forms use Archive/Delete (soft); lists hide archived by default (Owner: Identity)
- [ ] **Number formatting util** — currency/percent/unit cost/package qty (Owner: Measure)
- [ ] **Recipe edit → Publish** — draft ribbon, Save publishes, badge updates (Owner: Chronicle)
- [ ] **As-of view** — timestamp picker + breakdown table (Owner: Chronicle)
- [ ] **UOM conversions UI** — Settings tab, show derived reverse, prevent dups (Owner: Measure)
- [ ] **Import wizard** — upload → validate → commit (Owner: Intake)
- [ ] **Event toasts** — cost updated / import completed / recipe recomputed (Owner: Foundation)
- [ ] **Parity export** — admin windowed CSV/JSON (Owner: Foundation)

---

## NEXT (important, not blocking)
- [ ] **Aliases panel** — add/remove normalized aliases, dedupe errors (Owner: Identity)
- [ ] **Duplicate finder (admin)** — suspected dupes by normalized code; manual merge (Owner: Identity)
- [ ] **Price widget** — history table + “Set New Price” (Owner: Chronicle)
- [ ] **Auto-prefill** — UOM & unit cost when picking ingredient/prep recipe (Owner: Measure)
- [ ] **Line ordering** — manual re-number; grid affordances (Owner: Chronicle)
- [ ] **Settings tabs** — General, Categories, UOM; link to Clients (Owner: Foundation)
- [ ] **CSV export naming** — consistent columns/names across pages (Owner: Foundation)

---

## LATER (polish & strictness)
- [ ] **Strict RLS (V008)** — claims-based policies; app token wiring (Owner: Foundation)
- [ ] **Locale switches** — display fallback logic; inline edit secondary locale (Owner: Lexicon)
- [ ] **Keyboard affordances** — Enter=Save, Esc=Cancel across all forms (Owner: Foundation)
- [ ] **Loading skeletons** — tables/forms (Owner: Foundation)
- [ ] **Grid selection sync** — across all pages; clear selection (Owner: Foundation)

---

## Page-specific checklists (merged from attached tracker)

### Clients
- [x] Sticky loaded client; stable radio toggle. (Foundation)  
- [x] Exclusive default; validation for default/active rules. (Foundation)  
- [ ] (Optional) Inline grid edit/save for batch changes. (Foundation)

### Ingredients
- [ ] Category dropdown loads + saves. (Identity)  
- [ ] Remove/repurpose **Ingredient Type** (prep-as-ingredient later). (Measure/Chronicle)  
- [ ] Soft delete wiring + hide archived. (Identity)  

### Ingredient Categories (Settings tab)
- [ ] Grid shows data; fix RLS error. (Foundation)  
- [ ] Soft delete. (Identity)  

### UOM Conversion (Settings tab)
- [x] Global table readable; write per permissions. (Measure)  
- [ ] Show derived reverse conversion or store both (choose **derive**). (Measure)  
- [ ] Prevent duplicates. (Measure)  

### Recipes (list)
- [ ] Grid uniformisation; soft delete; number formatting. (Foundation)  
- [ ] Cross-tenant safe selectors via views only. (Foundation)  

### Recipe Editor
- [ ] **Cost parity fix** — matches ingredient_costs math. (Measure)  
- [ ] Auto-prefill UOM + unit cost for ingredient/prep recipe. (Measure/Chronicle)  
- [ ] Manual line ordering (line_no). (Chronicle)  
- [ ] Draft ribbon; Save publishes, version badge updates. (Chronicle)  

### Settings (Overhaul)
- [ ] Tabs: General / Ingredient Categories / UOM Conversions (+ link to Clients). (Foundation)  
- [ ] Shared grid/form components. (Foundation)  
- [ ] Import/Export tools. (Intake/Foundation)  

---

## Harness (Streamlit glue & parity)
- [ ] **Client-only calls** — Refactor all Streamlit pages to use `MOClient` exclusively; no direct SQL/business logic in widgets. (Owner: Foundation)
- [ ] **Emit canonical events** — Verify services emit `ingredient.cost.updated`, `import.completed`, `recipe.recomputed` at the defined points. (Owners: Chronicle, Intake)
- [ ] **Parity export page** — Implement windowed export of `event_log` to CSV/JSON. (Owner: Foundation)

---

## QA & Acceptance (UI)
- [ ] No raw tracebacks; error dialogs/toasts show `code/message/details`.
- [ ] Selectors/queries are tenant-scoped; archived rows hidden by default.
- [ ] Ingredient editor shows normalized code preview; alias dedupe errors are clear.
- [ ] Line editor shows entered UOM **and** derived base units; extended cost visible; parity with backend math.
- [ ] Editing a published recipe and saving produces exactly one new published version; badges update.
- [ ] As-of view returns totals matching current recompute when `at=now()`.
- [ ] Import wizard blocks commit on validation failure and exports row-level errors; emits `import.completed` on success.
- [ ] Parity export downloads event rows for a chosen window.

---

## Links
- Specs: Foundation_MVP, Identity_MVP, Measure_MVP, Chronicle_MVP, Intake_MVP, Lexicon_MVP
- Backend invariants: tenant context, soft delete, idempotency, events
