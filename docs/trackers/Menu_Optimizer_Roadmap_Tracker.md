# Menu Optimizer — Roadmap & Tracker

_Last updated: now (generated)_

This document groups everything we discussed into 5 plans and a single master checklist.  
Use the checkboxes to track progress. When you check items off locally, commit the updated `.md` to version control.

---

## Plan 1 — Current Feature Scope (Multi‑tenant + Soft Delete)

**Goal:** rock‑solid tenant isolation across DB + app, plus consistent soft‑delete semantics everywhere.

- [x] Tenant switcher moved to a dedicated **Clients** page with “Switch client / Manage clients” modes and radio‑styled toggle.
- [x] Loaded client is sticky across page loads and navigation (no auto‑flips).
- [x] Default client behavior: DB `is_default=true` preferred; falls back to `.env` `DEFAULT_TENANT_ID` when needed.
- [x] Client switcher and manager filtered to **active** clients only.
- [x] Enforce “exactly one default client” (DB guard + app logic flips previous default → false).
- [x] Block invalid states:
  - [x] Cannot make a client **default** if it’s **inactive**.
  - [x] Cannot **deactivate** the default client.
- [x] Global UOM conversions (readable to all tenants) with safe upsert/update flow.
- [x] DB migrations V001–V009 applied + reusable `migrate.sh` in place.
- [x] Branding pulled from **tenants** (logo & colors), injected consistently (sidebar badge, clients page, etc.).
- [x] Active client badge simplified (no page_link reliance), positioned in sidebar + page header where appropriate.
- [ ] App‑side **soft delete** everywhere (forms show “Delete” → sets `deleted_at` / `is_deleted` and hides in lists).
- [ ] Ensure **all** list queries filter by `{tenant_id AND not deleted}` via the proxy helpers only.
- [ ] IngredientCategories page: wire data + fix RLS error (it currently shows empty and cannot insert).
- [ ] Recipe/Ingredient selectors in **Recipe Editor** filtered strictly to the loaded tenant via views/proxy.
- [ ] Close branch `dev_feat-multi-tenant-soft-delete-2` after verifying all checkboxes below; merge to `main` and tag `v0.2.0`.

---

## Plan 2 — Uniformisation (UX / Components / Tables)

**Goal:** consistent patterns for forms, grids, and interactions across pages.

- [ ] **Grid uniformisation:**
  - [x] Highlight selected row in Clients grid and sync to form.
  - [ ] Highlight & sync selection across _all_ grids (Ingredients, Recipes, Categories, UOM).
  - [ ] Provide “Clear selection” that resets form without navigating away.
- [ ] **Form pattern:**
  - [ ] Consistent layout (left form, right grid), consistent Save/Cancel/Delete button row.
  - [ ] Soft‑delete checkbox/button consistently named (“Archive” or “Delete (soft)”).  
- [ ] **Header labels** in grids are humanized (title case, no underscores) and consistent.
- [ ] **Number formatting** centralized (utility):  
  - [ ] Currency: `$ 0.00`  
  - [ ] Percent: `0.0 %`  
  - [ ] Unit cost: `$ 0.00000`  
  - [ ] Package Qty: integer → no decimals; else up to 5.  
  - [ ] Locale‑aware separators if feasible.
- [ ] **Settings** consolidation:
  - [ ] Convert **Ingredient Categories** and **UOM Conversion** into tabs under **Settings**.
  - [ ] Decide if **Clients** belongs inside Settings or remains a top‑level page (link with “Change client” button from headers).
- [ ] Review default/placeholder states: empty tables, empty forms, disabled Save when invalid.

---

## Plan 3 — Polishing (Quality of Life)

**Goal:** small improvements that remove friction and sharpen the feel.

- [x] Clients mode toggle restyled (sleek & stable radio).
- [ ] Remove hardcoded `primary_color` leaks (e.g., previous red dot) — all colors come from loaded tenant branding.
- [ ] Keep the **client picker** visible on the login page after a selection (it stays now; continue to monitor).
- [ ] Unified success/error toasts; consistent copy (“Saved”, “Updated”, “Archived”).  
- [ ] CSV export buttons use the same naming and column set across pages.
- [ ] CSV import: single parser with preview, per‑page adapters (Ingredients, UOM, Categories).

---

## Plan 4 — Wiring (Auth, RLS, Views, Scripts)

**Goal:** keep plumbing clean and future‑proof.

- [x] `tenant_db` proxy: auto‑injects `tenant_id` and soft‑delete filters for all table ops.
- [x] Views expose `tenant_id` where needed for app‑side filtering.
- [x] RLS policies permissive for MVP; plan strict tenant‑claim RLS as next step.
- [x] `migrate.sh` to apply ordered migrations with idempotent checks.
- [ ] **V008—Tenant claim RLS:** swap permissive policies to strict `tenant_id = auth.jwt() -> 'tenant_id'` where appropriate; stage rollout and app token wiring.
- [ ] Helper SQL funcs made tenant/soft‑delete aware (replace legacy ones like `get_recipe_details` / unify behind the new views).  
- [ ] CI hook to run `migrate.sh up` against local/dev DBs (dry‑run mode).

---

## Plan 5 — Data & Costing Correctness (You‑name‑it)

**Goal:** bulletproof costing and line logic, especially with prep recipes as ingredients.

- [ ] **Recipe Editor: unit cost bug** — fix costing math so it matches `ingredient_costs` view (e.g., Fish & Chips mismatch).
- [ ] Loading an ingredient or **prep recipe** should auto‑prefill:
  - [ ] UOM: ingredient `base_uom` or prep recipe’s yield base (converted).
  - [ ] Unit cost from `ingredient_costs` / `prep_costs` (derived via `recipe_summary`).
- [ ] Show “Ingredient Type” column in lines grid.
- [ ] **Manual line ordering** (line_no): update backend, show in grid, allow re‑numbering logic as specified.
- [ ] Decide on **UOM reverse conversions** strategy: store both directions or derive inverse on read (recommend derive inverse if `factor != 0`).

---

## Page‑Specific Checklist

### Clients
- [x] Sticky loaded client; toggle polish.  
- [x] Exclusive default; validation for default/active rules.  
- [ ] (Optional) Inline grid edit/save for batch changes.

### Ingredients
- [ ] Category dropdown loads + saves (fix blank state).  
- [ ] Remove or repurpose **Ingredient Type** now that prep‑as‑ingredient is coming.  
- [ ] Soft delete wiring + hide archived.  

### Ingredient Categories
- [ ] Grid shows data; RLS error fixed.  
- [ ] Tab under **Settings**.  
- [ ] Soft delete.  

### UOM Conversion
- [x] Global table: read by all, write allowed to chef.  
- [ ] Show derived reverse conversion or store both; prevent duplicates.  
- [ ] Tab under **Settings**.  

### Recipes
- [ ] List/grid uniformisation; soft delete.  
- [ ] Number formatting.  

### Recipe Editor
- [ ] Costing fix; auto‑prefill UOM + unit cost when picking ingredient or prep recipe.  
- [ ] Line ordering.  
- [ ] Cross‑tenant safe selectors via views only.

### Settings (Overhaul)
- [ ] Tabs: General, Ingredient Categories, UOM Conversions, (optionally Clients link).  
- [ ] Shared grid/form components.  
- [ ] Import/Export tools.

---

## Release & Git Process

- [ ] **Stabilize**: finish remaining items in Plan 1 (soft delete everywhere; Categories wiring; selectors).  
- [ ] **QA pass** across all pages using the number‑formatting utility and consistent headers.  
- [ ] **Merge & Tag**: close `dev_feat-multi-tenant-soft-delete-2` → merge to `main` → tag `v0.2.0`.  
- [ ] **Open next branches**:  
  - `feat/uniformisation` (Plan 2)  
  - `feat/polish` (Plan 3)  
  - `feat/wiring-rls-claims` (Plan 4 / V008)  
  - `feat/data-costing` (Plan 5)  

---

## Notes / Decisions

- Branding is tenant‑driven (logo + primary/secondary colors) with JSON deprecated; DB is source of truth.
- Clients remain a top‑level page; each page header includes a **Change client** shortcut to jump there.
- CSV import/export to be centralized; exports align column naming with grids.

---

## Quick Status Summary

- **Plan 1**: Mostly done; remaining: soft delete everywhere, Categories wiring, selectors sanity.  
- **Plan 2**: In progress — grids & forms to standardize; Settings tabs to build.  
- **Plan 3**: Polishing backlog.  
- **Plan 4**: MVP wiring done; strict-RLS (V008) pending.  
- **Plan 5**: Costing & line‑ordering backlog.

