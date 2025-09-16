# Multi-language support

Here’s a tight, future-proof multi-language design that fits our engine (COPPER) and the “skins” (Menu Optimizer, PLM), without overcooking the MVP.

### Goals (what “good” looks like)
- Bilingual from day one (EN/FR) with clean fallbacks.
- Separation of concerns: business logic stays language-neutral; labels and human-readable text are data.
- Works across skins: the same engine powers Restaurant and Manufacturing with tenant-specific labels.
- Quebec-friendly: French can be default/primary per tenant; parity in exports.
----
#### Data model (minimal + extensible)
##### 1. Global/UI labels (for skinning)
We already planned a label_map for concept names. Make it multilingual.
```
-- Label keys (concepts/fields), per tenant or global (tenant_id NULL)
create table label_map (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,                  -- NULL = global default
  concept_key text not null,       -- e.g., 'component', 'assembly', 'yield_alt_uom'
  icon_key text,
  color_token text
);

create table label_map_i18n (
  label_map_id uuid references label_map(id) on delete cascade,
  lang text not null check (lang in ('en','fr')),
  singular text not null,
  plural text,
  help_text text,
  primary key (label_map_id, lang)
);
```
Tie-in: This is how “ingredient” becomes “component” or “recette/assembly” per tenant & skin. UI reads label_map_i18n for the active language.

##### 2. Entity field translations (data you/chef enter)

Use a generic translation table instead of widening entities.
```
-- Translations for names/descriptions on real entities
create table i18n_text (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,                       -- RLS-safe
  entity text not null check (entity in ('ingredient','ingredient_variant','recipe','recipe_version','party','ref_uom','category')),
  entity_id uuid not null,
  field text not null check (field in ('name','display_name','description','notes','menu_section')),
  lang text not null check (lang in ('en','fr')),
  value text not null,
  unique (tenant_id, entity, entity_id, field, lang)
);
```

Tie-in:
- Ingredients/recipes/variants get multilingual names/notes.
- Ref tables like ref_uom and category get human labels via i18n_text (entity = 'ref_uom', etc.).
- We don’t version translations with SCD; they’re display-only. (If you ever need historical labels in exports, you can snapshot strings alongside numbers at activation.)

##### 3. Tenant & user language prefs
```
alter table tenants add column default_lang text not null default 'fr';
alter table users   add column lang         text; -- NULL = inherit tenant
```
Resolution order: user.lang → tenant.default_lang → 'en' (or 'fr' for QC tenants).

### Runtime resolution (simple & deterministic)
- Server/API (or SQL views): Whenever returning an entity, LEFT JOIN i18n_text twice (requested lang + fallback) and coalesce.
Example for ingredients (pseudo):
```
select i.*,
       coalesce(n_req.value, n_fallback.value, i.code) as name_display
from ingredients i
left join i18n_text n_req
  on n_req.tenant_id=i.tenant_id and n_req.entity='ingredient' and n_req.entity_id=i.id
 and n_req.field='name' and n_req.lang = $req_lang
left join i18n_text n_fallback
  on n_fallback.tenant_id=i.tenant_id and n_fallback.entity='ingredient' and n_fallback.entity_id=i.id
 and n_fallback.field='name' and n_fallback.lang = $tenant_default_lang;
```
- UI: One language toggle in the header; it sets $req_lang. All labels/fields re-render via the same views/queries.

---

### Searching & sorting (don’t neglect this)
- Enable unaccent and use accent-insensitive search.
- Store language-specific tsvectors for names/descriptions to support EN/FR stemming.
```
create extension if not exists unaccent;

-- Example materialized search column for ingredients
alter table ingredients add column search_vec tsvector;
create index on ingredients using gin (search_vec);

-- Maintain via trigger:
-- search_vec := to_tsvector(coalesce(fr_value,'') || ' ' || coalesce(en_value,''));
```

Tie-in: Users can find “crème” or “creme” and get hits; FR/EN stemming improves results. This is UX gold in bilingual contexts.

---

### Exports & reports (Quebec compliance patterns)
- Per-export language choice: export_lang IN ('fr','en','bilingual').
- Bilingual PDFs/CSVs: Either duplicate columns (Name (FR), Name (EN)) or generate a two-page PDF (FR then EN).
- Default for QC tenants: export_lang='fr' with bilingual as a visible option.

---

### Interplay with other features
- Skins (Restaurant/PLM): The same label keys are translated per tenant in label_map_i18n. Switching a preset loads a different default label set; tenants can override.
- SCD / snapshots: Numeric facts (costs, yields) are language-agnostic. Snapshots stay clean. If you need immutable display strings in regulatory PDFs, optionally capture the display name at activation time.
- Recipe versions: Version headers (name/notes) use i18n_text with entity='recipe_version'. Comparing versions uses the user’s language to render strings; the math is unaffected.
- UOM & conversions: The codes stay stable (g, ml), but UI names (gramme/gram) come from i18n_text for ref_uom. No change to conversion logic.
- Identifiers: Supplier SKUs are not translated; they’re identifiers. Party names can have translations if you want localized display names.

---

### RLS & indexes (practical bits)
- i18n_text(tenant_id, entity, entity_id, field, lang) → composite index.
- Allow reads on global label maps (tenant_id NULL) via a permissive RLS policy that grants all tenants read on NULL-tenant rows.
- Cache aggressively per (tenant_id, lang) for label maps.
---
### Streamlit now, React later
- Streamlit MVP: put labels in a small loader that queries label_map_i18n + i18n_text. Keep a language switch in the sidebar.
- React: use i18next for UI chrome, but still source domain labels (concepts/fields) from label_map_i18n so presets/overrides work without redeploy.
---
### Authoring workflow (so content doesn’t lag)
- In any edit form with a “Name”, show FR and EN inputs side-by-side (tabs or two fields).
- If only one is filled, allow save, but flag missing translations in a tiny “language completeness” widget.
- Add an admin screen listing missing translations by entity/field.

### QA checklist (lite but real)
- Tenant in QC → UI defaults to FR; first-run exports are FR; search matches accents/No-accents.
- Toggle to EN and back: no numeric values change; only strings.
- With missing EN translation: FR shows, EN falls back to FR (or vice-versa) as designed.
- Bilingual export renders both columns correctly for names/notes/UOMs.
- This design keeps all language concerns data-driven and tenant-aware, plays nicely with versions/SCD/snapshots, and lets us “reskin” by simply swapping labels + visibility per industry—no forked code, no string hard-coding.