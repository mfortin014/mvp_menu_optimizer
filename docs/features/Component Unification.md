industry-agnostic design for a Component Unification feature inside the ingestion module that: (a) ingests hundreds of mixed Excel BOMs, (b) proposes likely duplicates, (c) lets humans confirm/deny, and (d) builds a clean component library while mapping every source row back to its canonical component.

Goals

Consolidate messy BOM spreadsheets (4 “families,” one quite inconsistent) into a single component library with internal part numbers.

Human-in-the-loop matching: the system suggests; users confirm, split, or reject.

Preserve lineage: every source row remains traceable back to its original BOM/SKU.

Make it repeatable: saved mappings, reusable rules, and learning from decisions.

Inputs & Constraints

Hundreds of Excel files, each = one SKU/BOM worksheet; 4 template families, evolving over time.

No stable part numbers; names, attributes, and units vary; some multilingual/typos.

Need to produce: canonical components + variants (when differences are meaningful), and BOM lines remapped to those components.

Data Model (staging + matching + canonical)

Staging (raw, per ingest job)

stg_bom_file(job_id, source_system, file_id, family, detected_schema, checksum, imported_at)

stg_bom_header(job_id, file_id, source_sku, title, notes, currency, …)

stg_bom_line(job_id, file_id, line_no, raw_name, raw_desc, raw_uom, raw_qty, raw_pkg, raw_color, raw_size, raw_material, raw_supplier, …, payload jsonb)

Feature extraction (normalized)

stg_component_features(job_id, file_id, line_no,

name_norm (lowercased, stopwords stripped, diacritics removed)

tokens (token set), phonetic (Double Metaphone)

attrs_norm (normalized material/color/size), uom_norm, qty_norm_in_base, pkg_norm

hashes (e.g., name+attrs, name+uom+size)

vector (optional: text embedding later)
)

Match graph (candidates)

match_candidate(job_id, a_ref, b_ref, block_key, score, reasons jsonb, status enum('proposed','accepted','rejected','needs_split'))

a_ref/b_ref reference stg_component_features rows.

Clusters (proposed “same” groups)

match_cluster(job_id, cluster_id, confidence, representative_ref, size)

match_cluster_member(job_id, cluster_id, ref_id)

Canonical library & mapping

component(id, tenant_id, code, name, base_uom, …) ← internal part numbers (auto)

component_variant(id, component_id, supplier_id, pkg_size, pkg_uom, attributes, …)

component_alias(tenant_id, source_system, file_id, line_no, source_sku, canonical_component_id, canonical_variant_id null, decided_by, decided_at)
(The “map back” table—your Rosetta stone.)

bom_line_canonical(bom_id, line_no, component_id, variant_id, qty_in_base, …) (rebuilt from staging using the alias map)

Matching Pipeline (multi-pass, explainable)

0) Family detection & schema mapping

Auto-detect the file “family” using header signatures; load a family-specific mapping preset.

For the inconsistent family, prompt for a one-time mapping tweak; save as a revised preset.

1) Normalization

Clean text: lowercase, strip punctuation/stopwords, remove diacritics, unify spacing.

Parse attributes: material (“ABS”, “brass”), size (“3 mm”), color (“turquoise”), count/pack (“12x1 L” → 12; 1 L), then normalize units (g/ml/unit; mm/in) using your UOM engine.

Vendor hints: keep supplier strings and any SKU-like tokens for later tie-breaks.

2) Blocking (fast candidate narrowing)

Generate multiple block keys to avoid O(N²):

name 3-gram signature (e.g., the top 3 trigrams),

phonetic + size bucket (Double Metaphone of head term + rounded size),

material + color bucket.

Only compare rows within the same block key(s).

3) Scoring (hybrid heuristics)

String similarity: Jaro–Winkler / token-set ratio between name_norm fields.

Attribute match: exact/close match on material/color; numeric proximity on normalized sizes.

UOM comparability: penalize if units not convertible (per your conversion engine).

Supplier hints: lightweight boost if supplier names align.

Optional embeddings: later, cosine similarity on description vectors.

Score = weighted sum; store reasons (e.g., { "name": 0.78, "size": 0.9, "material": 1.0 }) for explainability.

4) Clustering

Build clusters from pairwise links above threshold (connected components / union–find).

Compute cluster confidence (mean score, density).

Split heuristics: if a cluster shows multimodal sizes (e.g., 3 mm vs 30 mm), pre-flag needs_split.

5) Variant detection vs. true duplicates

If items share name/material but differ package/format (e.g., 1 kg bag vs 25 kg sack), suggest variants under one component.

If items differ by a critical attribute (e.g., size 3 mm vs 6 mm beads), suggest separate components (same family/category).

Human-in-the-Loop UI (review once, reuse forever)

Queue & triage

Sorted by cluster confidence (highest first) and expected BOM impact (where-used count).

Filters: “needs_split”, “size conflict”, “supplier conflict”, “low confidence”.

Cluster panel

Left: proposed canonical summary (name, base uom, key attrs).

Middle: members grid with provenance (file, SKU, original row), key fields highlighted; chips for material/color/size.

Right: decisions:

Accept as one component → optionally choose canonical name; pick or auto-create variants for pack/format differences.

Split by rule (e.g., by size threshold, by supplier) → UI previews new sub-clusters.

Reject merge → mark specific pairs “not same”; they won’t be proposed again.

Explainability

Show why these rows matched: token overlaps, size comparisons, normalized UOMs, supplier hints.
(Critical for user trust.)

Batch actions

Approve all members except outliers; “promote outliers to new component” in one click.

Outcomes (on approve)

Create component with auto code (CMP-001234).

Create component_variant rows as needed.

Write component_alias mapping for every source row.

Rebuild impacted BOM lines into canonical form and surface cost deltas.

After Decision: Learning & Governance

Learning

Persist positive/negative pairs:

match_label(job_id, a_ref, b_ref, label bool, features jsonb) → future training set.

Synonym dictionary:

When users edit canonical names, harvest synonyms (e.g., “glue stick”, “gluestick”).

Feed synonyms back into normalization for the next import.

Governance

Every merge/split recorded with decided_by, decided_at, and the rule used.

Undo: allow “split component” to revert a mistaken merge; update mappings accordingly.

Idempotency: if files reappear, component_alias prevents dupes.

Edge Cases & Policies

Ambiguous homonyms (“cap”: bottle cap vs. capacitor): enforce category hints in scoring; require human decision.

Multilingual names: use the i18n design; normalize both FR/EN tokens and aliases.

Unit chaos: if non-convertible (e.g., “set” vs “kg”), force variant creation with explicit mapping, or block with a guided fix (add item-specific conversion or reclassify).

Missing attributes: let high name confidence + supplier SKU carry the match, but flag low-attribute rows for final review.

Integration with the Engine (ties to existing features)

UOM & conversions: reuse your convertibility checks to penalize impossible matches and to normalize size/qty for scoring.

Variants: the “variant vs component” logic aligns with your existing variant model; just call the same creation flows.

SCD: when a canonical component is created, future price/packaging changes go through SCD2 on component_variant.

Where-used: once canonical, run impact analysis on all SKUs whose BOM lines remap—show blast radius and cost/margin shifts.

Ingestion: treat this as a post-staging reconciliation step before publish. The ingestion job’s “publish” step materializes canonical components and remapped BOMs.

Rollout Plan (pragmatic)

Phase A (base): normalization, blocking, heuristic scoring, clustering, review UI, publish to canonical + alias map.

Phase B (variants): automatic variant suggestions; size/material split rules; batch actions.

Phase C (learning): collect labeled pairs; add synonym dictionaries; optional embeddings for tricky names.

Phase D (automation): auto-accept clusters above a very high threshold with rollback capability.

Success Metrics

Duplicate reduction: (# canonical components) / (# source component rows).

Coverage: % BOM lines successfully remapped to canonical components.

Human effort: median time per cluster; # auto-accepted clusters.

Accuracy: post-merge correction rate (should trend down).

Business impact: variance reduction in component cost reporting; speed to first consolidated portfolio view.