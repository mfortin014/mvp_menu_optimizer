
# 99_Parked_MVP_specs — Post‑MVP Feature Specifications
**Version:** 1.0  
**Updated:** 2025-09-16 18:09  
**Scope:** Features explicitly parked for post‑MVP (targeting Forge v1).  
**Audience:** Engineers and product owners transitioning from MVP (Streamlit+Supabase) to Forge v1.  
**Assumptions:** Forge v1 uses contract‑first development (Contracts → FIRE codegen for services/UI), RLS on, event/audit logging enforced.

> These specs express the *v1 design intent* so we avoid dead ends during MVP. Where relevant, we note expected APLs (Application Procedure calls), events, tables, and acceptance for go/no‑go.

---

## Contents
1. Component Unification (from `Component Unification.md`)
2. Snapshot + TimeSeries Diff (from `snapshot_TimeSeriesDiff.md`)
3. Universal Identity & Dedupe (from `universal_identity_and_dedupe.md`)
4. Advanced Ingestion Pipeline (from `data_ingestion.md` — beyond MVP slice)
5. Advanced Multi‑Language (from `multi-language.md` — beyond MVP slice)
6. Advanced SCD (from `SCD.md` — beyond MVP slice)
7. Advanced UOM & Packaging (from `UOM_Overhaul_item_scoped_conversion.md` — beyond MVP slice)
8. Advanced Ingredient Identity (from `Ingredient_Identity.md` — beyond MVP slice)

---

## 1) Component Unification (Parked)
**Goal:** Unify semantically identical components across sources (menus, BOMs, catalogs) with variant inheritance and governance.
### Scope (v1)
- **Component Graph:** `component` → `component_variant` → `component_instance` with typed edges (equivalent_of, derived_from, supersedes).
- **Canonicalization:** one canonical `component_id` per logical object; map legacy aliases from sources.
- **Governance:** review queue for merges/splits; lineage preserved.
### Data Model (sketch)
- `component(id, kind, canonical_name, attrs jsonb, active, created_at)`  
- `component_alias(component_id, source, external_id, label)`  
- `component_variant(id, component_id, label, attrs jsonb)`  
- `component_link(src_id, dst_id, rel enum('equivalent_of','derived_from','supersedes'), confidence numeric)`
### APLs / Events
- `component.define`, `component.merge`, `component.split`, `component.variant.upsert`  
- Events: `component.merged`, `component.split`, `component.alias.linked`
### Acceptance
- Given N sources with duplicates, the system proposes k merges; approved merges create exactly one canonical id; lineage and reversibility proven via events and audit.

---

## 2) Snapshot + TimeSeries Diff (Parked)
**Goal:** Capture periodic snapshots of multi‑table domains and compute diffs/patches between them.
### Scope (v1)
- **Snapshot:** consistent cut of selected tables (ingredients, recipes, prices).
- **Diff Engine:** compute entity‑level adds/updates/deletes; emit patch artifacts.
- **Replay:** backfill and patch replay with audit.
### Data Model
- `snapshot(id, domain, taken_at, taken_by, checksum)`  
- `snapshot_item(snapshot_id, entity_type, entity_id, hash, payload jsonb)`  
- `snapshot_diff(id, src_snapshot, dst_snapshot, stats jsonb)`  
- `snapshot_patch(diff_id, entity_type, entity_id, op enum('add','update','delete'), before jsonb, after jsonb)`
### APLs / Events
- `snapshot.create`, `snapshot.diff`, `snapshot.patch.apply`  
- Events: `snapshot.created`, `snapshot.diff.completed`, `snapshot.patch.applied`
### Acceptance
- For a seeded dataset, diff output is deterministic (stable ordering, hashes); applying patch transforms src → dst exactly; full trace written to audit/event logs.

---

## 3) Universal Identity & Dedupe (Parked)
**Goal:** Move beyond deterministic rules to fuzzy/ML‑assisted matching across tenants and sources.
### Scope (v1)
- **Candidate Generator:** tokenization, phonetic keys, numeric normalization, embeddings (optional).
- **Scoring:** weighted features (name, package size, brand, supplier, GTIN) → match score.
- **Human‑in‑the‑Loop:** review UI with accept/merge/split and confidence tracking.
### Data Model
- `identity_node(id, type, attrs jsonb)`   // ingredient, supplier, product code, GTIN  
- `identity_edge(src_id, dst_id, rel enum('same_as','possible_same','conflicts_with'), score numeric, source)`  
- `match_candidate(entity_type, entity_id, candidate_id, score, features jsonb, state enum('new','review','accepted','rejected'))`
### APLs / Events
- `identity.candidate.upsert`, `identity.match.accept`, `identity.match.reject`, `identity.merge`  
- Events: `identity.candidate.created`, `identity.merged`, `identity.rejected`
### Acceptance
- On a labeled evaluation set, precision/recall thresholds are met; review actions update graph consistently; no cross‑tenant leakage under RLS.

---

## 4) Advanced Ingestion Pipeline (Parked beyond MVP slice)
**Goal:** Durable, observable ingestion for files and feeds with mapping profiles, scheduling, and streaming.
### Scope (v1)
- **Connectors:** SFTP, HTTPS, webhook receivers, cloud object stores.
- **Profiles:** per‑tenant column mapping + transforms; versioned and reusable.
- **Orchestration:** async jobs with retries, dead‑letter queue, quarantine UI.
- **Schema Inference:** header/type guesses + human confirmation.
### Data Model
- `ingest_connector(id, type, cfg jsonb, active)`  
- `ingest_profile(id, tenant_id, domain, mapping jsonb, transforms jsonb, version int)`  
- `ingest_job(id, connector_id, profile_id, status, stats jsonb, started_at, finished_at)`  
- `ingest_quarantine(job_id, row_num, errors jsonb, payload jsonb)`
### APLs / Events
- `ingest.connector.create`, `ingest.profile.upsert`, `ingest.run`, `ingest.quarantine.resolve`  
- Events: `ingest.job.started|completed|failed`, `ingest.row.quarantined`
### Acceptance
- A scheduled job fetches a file, validates via profile, quarantines errors, and commits clean rows; retries and DLQ visible; audit includes every state transition.

---

## 5) Advanced Multi‑Language (Parked beyond MVP slice)
**Goal:** Rich internationalization with ICU messages, RTL, and translation workflows.
### Scope (v1)
- **ICU Messages:** plural/gender formatting; parameterized strings.
- **Translation Memory:** per‑tenant glossary; suggestions and approvals.
- **Locale Negotiation:** `Accept‑Language` + per‑user preference; RTL support.
### Data Model
- `i18n_message(key, default_message, context, tags)`  
- `i18n_translation(key, locale, message, state enum('draft','review','approved'), updated_by, updated_at)`  
- `i18n_glossary(term, locale, canonical, notes)`
### APLs / Events
- `i18n.message.upsert`, `i18n.translation.submit|approve`, `i18n.export`  
- Events: `i18n.translation.approved`, `i18n.glossary.updated`
### Acceptance
- ICU rendering passes snapshot tests for plurals/gender; RTL layouts meet contrast/focus rules; workflow enforces review before production.

---

## 6) Advanced SCD (Parked beyond MVP slice)
**Goal:** Extend SCD from ingredients to recipes & lines, with **bitemporal** support and compaction.
### Scope (v1)
- **Entities:** `recipes`, `recipe_lines`, possibly pricing rules.  
- **Bitemporal:** valid time + system time; point‑in‑time queries.  
- **Compaction:** configurable retention + roll‑ups.
### Data Model (pattern)
- `*_history( business_key..., valid_from, valid_to, sys_from, sys_to, is_current, payload jsonb )`  
- PIT helpers: `as_of(valid_ts, sys_ts)` views.
### APLs / Events
- `scd.backfill`, `scd.compact`, `scd.pit.query`  
- Events: `scd.version.created`, `scd.compacted`
### Acceptance
- For curated scenarios, PIT queries reproduce expected states; compaction maintains PIT correctness; audit maps write → history row(s).

---

## 7) Advanced UOM & Packaging (Parked beyond MVP slice)
**Goal:** Dimensional analysis and packaging/yield models beyond item‑scoped conversions.
### Scope (v1)
- **Composite Units:** case→unit→g/ml with density and pack factors.  
- **Yield/Waste:** cooked vs raw conversions, shrink factors.  
- **Catalogs:** tenant unit catalogs with governance and versioning.
### Data Model
- `uom_dimension(id, name)`  
- `uom_unit(id, dimension_id, symbol, to_base_expr text)`  
- `uom_conversion_profile(id, tenant_id, item_id?, formula jsonb, effective_from, effective_to)`  
- `packaging_spec(item_id, cases_per, units_per_case, net_weight_g, drain_weight_g, yield_pct)`
### APLs / Events
- `uom.catalog.upsert`, `uom.profile.assign`, `uom.convert`  
- Events: `uom.catalog.updated`, `uom.profile.assigned`
### Acceptance
- Unit tests for chained conversions are deterministic; costing uses normalized forms; changes are versioned and auditable.

---

## 8) Advanced Ingredient Identity (Parked beyond MVP slice)
**Goal:** Supplier sync, external IDs (GTIN/GS1), and full merge/split lineage UI.
### Scope (v1)
- **Adapters:** supplier catalog synchronization (pull or webhook).  
- **External IDs:** GTIN/GS1, distributor SKUs, manufacturer IDs.  
- **Lineage Viewer:** visualize merges/splits over time.
### Data Model
- `supplier_adapter(id, kind, cfg jsonb, active)`  
- `ingredient_external_id(ingredient_code, scheme, value, verified_by, verified_at)`  
- `merge_lineage(op_id, ts, actor, before jsonb, after jsonb, rationale)`
### APLs / Events
- `ingredient.alias.harvest`, `ingredient.external.link`, `ingredient.merge`, `ingredient.split`  
- Events: `ingredient.external.linked|verified`, `ingredient.merged|split`
### Acceptance
- On sync, new aliases/external IDs produce identity candidates; merges preserve event lineage; verification required before external IDs become canonical.

---

## Cross‑Cutting Non‑Functionals (apply to all parked features)
- **Security/RBAC:** role‑gated APLs; cross‑tenant isolation via RLS.  
- **Observability:** request tracing, event/audit logs, DLQs where async is used.  
- **Performance Budgets:** latency SLOs on read APLs; bounded batch sizes on writes.  
- **Migrations:** forward‑only with reversible scripts where practical; seed data for demos.  
- **Testing:** contract tests from JSON Schemas; golden datasets for diff/PIT correctness; e2e flows for governance UIs.

---

## Dependencies & Sequencing (recommended for v1)
1. **Identity/Ingredients stable** (MVP baseline) → 7/8 rely on it.  
2. **Advanced Ingestion** before Component Unification (feeds data to unify).  
3. **SCD Advanced** before Snapshot/Diff (history correctness first).  
4. **Multi‑Language Advanced** can land anytime after Lexicon_MVP.  
5. **UOM Advanced** after Measure_MVP and ingredient densities are known.

---

## Exit Criteria (to move items out of “Parked”)
- Contract Pack entries (schemas/APLs/events) merged with tests.  
- FIRE codegen targets updated (services and minimal UI) where applicable.  
- Backfills/migrations rehearsed; rollback plans documented.  
- Observability and RBAC checks pass in staging under tenant constraints.
