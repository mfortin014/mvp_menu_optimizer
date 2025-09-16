
# 05_Lexicon_MVP — Minimal Multi‑Language (Specs)
**Version:** 1.0  
**Updated:** 2025-09-16 18:02  
**Scope:** MVP (Streamlit + Supabase/Postgres)  
**Out of scope:** FIRE codegen, LiveCanvas, Smith, full ICU/i18n tooling

---

## 1) Purpose & Principles
We need basic multi‑language support so **ingredient names/descriptions** display nicely in English/French today and remain **v1‑compatible** tomorrow. The design is intentionally thin:
- **Keep data canonical**: identity/uniqueness rides on `ingredient_code`, never on labels.
- **Localized fields are optional** with **tenant‑level default locale** and deterministic fallback.
- **No FIRE required**: Streamlit UI + SQL views + minimal helpers.
- **Contract‑first**: shapes align with v1 APLs so we can socket‑swap later.

---

## 2) Requirements (MVP)
### Functional
1. Store **localized name/description** per ingredient for locales `en`, `fr` (extensible later).
2. Each tenant defines a **default_locale** (`en` or `fr`). If the requested locale value is missing, **fallback** to default; if default missing, fallback to **any available** then to the code.
3. In lists and forms, show **current locale** label and indicate when a fallback is displayed.
4. CSV import accepts localized columns (optional): `name_en`, `name_fr`, `description_en`, `description_fr`.
5. Event logging: writes/updates of localized fields emit `ingredient.updated` **(reuse)** with `changed_fields` containing locale keys.

### Non‑Functional
- **Postgres collation/CI**: store text as `text` using Unicode; searches are case‑insensitive via `ILIKE`.
- **No duplicates**: uniqueness remains on `ingredient_code` (and vendor linkages), not on labels.
- **Extensible**: schema leaves room to add locales without table redesign; v1 can adopt ICU later.

---

## 3) Data Model
### Tables
**A. ingredients** (existing, unchanged keys)
- `ingredient_code text primary key`
- … other canonical fields …

**B. ingredient_i18n** (new)
- `ingredient_code text not null references ingredients(ingredient_code) on delete cascade`
- `locale text not null check (locale in ('en','fr'))`
- `name text`
- `description text`
- `updated_at timestamptz not null default now()`
- `updated_by text`
- **PK** (`ingredient_code`, `locale`)
- **Index** on (`locale`, `name`) for quick filtering

**C. tenant_settings** (extend if not present)
- `tenant_id text primary key`
- `default_locale text not null check (default_locale in ('en','fr'))`

### Views
**v_ingredient_label(locale text) →** returns label with fallback:
```sql
create or replace view v_ingredient_label as
select i.ingredient_code,
       coalesce(i18n.name,
                i18n_default.name,
                i.ingredient_code) as label,
       case when i18n.name is not null then 'exact'
            when i18n_default.name is not null then 'default_fallback'
            else 'code_fallback' end as label_quality,
       coalesce(i18n.description, i18n_default.description, null) as description
from ingredients i
left join ingredient_i18n i18n
  on i18n.ingredient_code = i.ingredient_code
 and i18n.locale = current_setting('app.locale', true)
left join ingredient_i18n i18n_default
  on i18n_default.ingredient_code = i.ingredient_code
 and i18n_default.locale = current_setting('app.default_locale', true);
```
> The app sets `app.locale` and `app.default_locale` per session (see §6).

---

## 4) API/Helpers (MVP, local adapters)
Even without HTTP APLs, mirror v1 shapes for easy swap later.

### Read (list/detail)
Input:
```json
{ "locale":"fr" }
```
Output (per ingredient):
```json
{ "ingredient_code":"TOM-14OZ", "label":"Tomates en dés 14oz",
  "label_quality":"exact|default_fallback|code_fallback",
  "description":"...", "locale":"fr" }
```

### Write (upsert localized fields)
Input:
```json
{ "ingredient_code":"TOM-14OZ", "locale":"fr",
  "name":"Tomates en dés 14oz", "description":"Boîte 14oz" }
```
Output:
```json
{ "ok":true, "updated_fields":["name","description"] }
```

**Uniform error shape:**
```json
{ "error": { "code":"INVALID_PAYLOAD|NOT_FOUND|CONFLICT", "message":"...", "details":{} } }
```

---

## 5) Streamlit UI Behavior
- **Ingredient list**: use `v_ingredient_label` to display `label`; show a subtle badge for `label_quality != 'exact'` (tooltip explains fallback).
- **Ingredient form**: tabs or accordions for locales (`en`, `fr`). Required: none; recommended: name in default locale.
- **Search**: text search runs against `label` via view; secondary search can target `ingredient_code`.
- **CSV Import**: optional columns `name_en`, `name_fr`, `description_en`, `description_fr`. Rows missing these still import cleanly.

---

## 6) Session & Locale Handling
On DB connect, set:
```sql
set app.default_locale = (select default_locale from tenant_settings where tenant_id = :tenant);
set app.locale = :ui_locale_preference; -- 'en' or 'fr'
```
If UI locale unset, fall back to `app.default_locale`.

---

## 7) Events (for parity)
Emit on localized writes (reuse `ingredient.updated` event type to avoid explosion of types):
```json
{
  "event_type":"ingredient.updated",
  "entity_type":"ingredient",
  "entity_id":"TOM-14OZ",
  "changed_fields":["name.fr","description.fr"],
  "payload":{
    "locale":"fr",
    "name":"Tomates en dés 14oz"
  }
}
```

---

## 8) Migration Plan
1. Create `ingredient_i18n` and extend `tenant_settings` with `default_locale`.
2. Backfill: for every ingredient with a current `name` column (if any), insert into `ingredient_i18n` with `locale=default_locale`.
3. Update ingestion to accept localized columns (if present).
4. Update Streamlit pages to consume the view and the helper API.

Rollback: drop `ingredient_i18n` (data loss limited to localized text), revert views/pages.

---

## 9) Security & RLS (future‑proofing)
- If RLS enabled, policies must constrain `ingredient_i18n` by tenant via join on `ingredients` (which carries tenant key).
- `updated_by` filled from app user; audit via existing `event_log` (see MVP readiness doc).

---

## 10) Testing & Acceptance
### Unit
- Upsert localized fields (new/overwrite), bad locale rejected, missing ingredient fails with NOT_FOUND.
### Integration
- Fallback ladder works in all 3 states: exact, default_fallback, code_fallback.
- CSV import with/without localized columns; partial rows import cleanly.
### UI
- Badge shows on fallback; search finds by localized label.
### Acceptance (Go/No‑Go)
- All tests pass; parity events appear; backfill leaves no NULL surprises for default locale.
- Zero schema changes required to add another locale later (table design already supports it).

---

## 11) Future v1 Extensions (explicitly not in MVP)
- ICU message formatting (plurals/gender), RTL support.
- Translation memory/glossary per tenant; review workflows.
- Locale negotiation via `Accept-Language` and per‑user preferences.
- Shared cross‑module i18n service.
