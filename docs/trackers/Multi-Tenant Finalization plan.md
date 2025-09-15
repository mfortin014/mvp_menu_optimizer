# Sur Le Feu — MVP Multi-Tenant Finalization Plan [X]/[ ] Tracker

## 0) Goals
- [ ] Lock multi-tenant UX everywhere (no cross-tenant leaks, consistent switching)
- [ ] Uniform soft-delete across all CRUD pages
- [ ] Per-client branding applied app-wide (zero page rewrites)
- [ ] Recipe Editor fully tenant-safe (inputs & writes)
- [ ] Add safety rails (audit scripts, cache discipline)

---

## 1) Work items (ordered to ship)

### A) Core tenant UX
- [X] One-page **Clients** (Switch + Manage)
- [X] Sticky mode switcher (radio), no tab reset on rerun
- [X] Single-default enforcement in app (unset others with `WHERE`) + DB partial unique index
- [X] Accurate blockers:
  - default → must be active
  - default client cannot be deactivated
- [X] Selection/rerender stability in Manage (no off-by-one; row-scoped widget keys)
- [X] **Clear selection** truly clears (skip-once flag to ignore grid selection)
- [X] Header **Loaded client** badge at top (no sidebar push-down)
- [X] Pre-auth client picker loads **DB default** and stays visible
- [ ] Centralize cache clear on tenant change (`set_active_tenant()` calls `st.cache_data.clear()`)

### B) Soft-delete across CRUD
- [ ] **Ingredients**: show-deleted toggle; Delete/Restore/Clear buttons (outside form); filter `deleted_at is null`
- [ ] **IngredientCategories**: same pattern
- [ ] **Recipes**: same pattern
- [ ] **RecipeEditor (lines)**: same pattern (delete/restore lines); tenant-safe queries
- [ ] **Sales** (if present): same pattern
- [ ] Common helpers in `utils/tenant_db.py`: `soft_delete(name,id)`, `undelete(name,id)`

### C) Branding
- [X] DB-driven branding loader with JSON fallback **hardened** (no KeyError)
- [X] Global CSS vars via `inject_brand_colors()` (buttons/links) + brand dot in header
- [ ] Call `inject_brand_colors()` at top of **every** page (currently partial)
- [ ] Optional: color `h1/h2` with brand primary (light accent)
- [ ] Optional: show tenant logo in sidebar on chosen pages (Home already uses it)

### D) Recipe Editor tenant safety
- [ ] Build ingredient/input dropdown from **`input_catalog`** view (tenant-filtered, excludes deleted)
- [ ] Ensure all reads/writes use `db.table(...)` proxy (no raw `supabase.table`)
- [ ] QA with two tenants: cannot select foreign ingredients; writes succeed

### E) Tooling & guardrails
- [ ] `scripts/audit_tenant_safety.py`: flag raw `supabase.table(`, `.delete(`, and suspect selects
- [ ] Verify `set_active_tenant()` triggers `st.cache_data.clear()` (avoid stale data after switch)
- [ ] (Optional) page smoke tests checklist/script

### F) Bulk-edit (optional, after core)
- [X] Clients bulk-edit **beta** with guardrails (single default, active/default rules)
- [ ] Extract reusable bulk-edit helper (diff + batch update)
- [ ] Apply to Ingredients/Recipes lists (optional)

---

## 2) Deliverables checklist
- [ ] Paste-ready patch blocks per page (Ingredients, IngredientCategories, Recipes, RecipeEditor, Sales?)
- [ ] Commit messages (conventional, one per page)
- [ ] No new DB migrations required (unless we opt for triggers on defaults/active)

---

## 3) Branch & commit convention
- Branch: `dev_feat-softdelete-branding-recipe-safety`
- Examples:
  - `feat(ingredients): soft-delete + restore + show-deleted filter [aigen]`
  - `feat(recipes): soft-delete + restore + show-deleted filter [aigen]`
  - `fix(recipe-editor): use input_catalog + db proxy for all reads/writes [aigen]`
  - `feat(ui): apply per-client colors app-wide via CSS vars [aigen]`
  - `chore(scripts): audit stray supabase calls & hard deletes [aigen]`
  - `chore(core): clear cache on tenant change in set_active_tenant [aigen]`

---

## 4) Acceptance checks (final QA)
- [ ] Switching clients never shows another client’s rows (spot-check all pages)
- [ ] Every CRUD page hides soft-deleted rows by default; toggle reveals; Delete/Restore behave
- [ ] Buttons/links adopt client colors on **every** page; header shows brand dot; logo loads when set
- [ ] Recipe Editor: ingredient dropdown is tenant-filtered; saving lines respects tenant & soft-delete
- [ ] No raw `supabase.table` writes/updates/deletes remain in pages (proxy only)

---

## 5) Notes
- Keep destructive actions **outside** `st.form` to avoid multi-submit weirdness.
- Clear cache on tenant switch avoids stale lists after changing clients.
- Keep single-default logic both in DB (partial unique index) **and** app (unset others before save) for belt-and-suspenders reliability.
