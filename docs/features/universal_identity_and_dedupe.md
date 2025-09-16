Universal Identity & Dedupe (industry-agnostic)
Purpose

Create reliable “golden records” across messy sources. Work for parts, suppliers, SKUs, recipes, customers—anything with repeated, slightly different rows scattered across files/systems.

Core building blocks

Dataset Registry
dataset(id, tenant_id, entity_type, source_system, schema, keys, created_at)
Registers what is coming in (CSV/Excel/Sheets/S3/DB export) and what it represents (component, supplier, etc.).

Staging Lake (immutable)
Raw files + parsed rows with provenance: file_id, row_num, checksum, and payload jsonb. Reproducible forever.

Normalizer
Pluggable cleaners per field type: text (case/diacritics/stopwords), numbers, UOMs, sizes, dates, currency, emails/phones, FR/EN tokenization.

Feature Store (per row)
Tokens, phonetics (Double Metaphone), n-grams, normalized attributes, signatures/hashes, optional embeddings. Everything explainable.

Matcher (pluggable)
Multi-pass blocking (e.g., top trigrams, phonetic+size bucket) + scoring (string sims, attribute agreement, UOM proximity, supplier hints, optional vectors). Reasons logged per pair.

Clusterer
Union-find to group candidates; confidence per cluster; split heuristics (e.g., 3 mm vs 30 mm).

Golden Record Store
Canonical entities with auto codes, plus variants if differences are meaningful.
Survivorship rules: which source wins for each field (freshest, highest trust, non-null, longest).

Alias Map (crosswalk)
alias(tenant_id, entity_type, source_system, file_id, row_ref, canonical_id, variant_id?, decided_by, decided_at)
Every source row stays traceable. Use it to rebuild BOMs, join reports, or push IDs back to source.

Human-in-the-loop Workbench
Queue of clusters → accept/split/reject with reasons shown (token overlaps, size deltas, UOM converts). Batch actions, undo, audit.

Learning Loop
Store labeled pairs (same/not) + features for active learning; grow synonym dictionaries from user edits; auto-accept ultra-high-confidence clusters.

Why this scales beyond BOMs

Entity-agnostic: only the normalizers & matchers change per field type.

Multi-source: same alias map links ERP, spreadsheet, vendor feed, POS export.

Multi-language: tokenization & synonyms for FR/EN sit in the normalizer; scoring stays the same.

Governance: everything is tenant-scoped with RLS; every merge/split is auditable and reversible.