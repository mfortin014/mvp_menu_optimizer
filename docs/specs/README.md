# Specs Index
**Updated:** 2025-09-18 21:30

Purpose: map the specs that govern the Menu Optimizer MVP. Use this index before starting any feature work.

---

## Active Specs

### MVP now
- `spec_template.md` — scaffolding for new specs (copy → rename).  
- `Menu_Optimizer_Specs.md` — master backlog and MVP scope (authoritative checklist).  
- Component-specific specs live under `docs/specs/<area>/` when needed (e.g., `docs/specs/auth/login.Specs.md`).

### v1 later
- ADRs (`docs/adr/`) will link back once the architecture formalizes.  
- Multi-repo specs will land here with cross-links into OpsForge’s platform docs.

---

## How to Add a Spec
1. Copy `spec_template.md` to `docs/specs/<feature>.Specs.md`.  
2. Fill the **Deliverables** checklist and **Testing** notes.  
3. Reference related runbooks and policies.  
4. Update this index and `docs/README.md` with the new link.  
5. Tag the spec in GitHub issues/PRs.

---

## Hygiene
- Keep filenames consistent (`<Feature>.Specs.md`).  
- When a spec graduates to v1 scope, annotate sections with **MVP** vs **v1** callouts.  
- Archive deprecated specs under `archive/specs/` (do not delete history).

