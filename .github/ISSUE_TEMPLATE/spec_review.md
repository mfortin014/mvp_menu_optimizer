---
name: Spec Review
about: Lightweight intake to review and accept a spec into MVP scope
title: "Spec: <short-title>"
labels: ["spec"]
assignees: []
---

Because  
Briefly explain why this spec is needed now and who benefits.

Doc link  
While in review, paste the PR URL or branch file path (e.g., https://github.com/<repo>/pull/123 or the branch file URL). After acceptance, update to the main-branch path (e.g., docs/specs/04_Intake_MVP_Specs.md).

Acceptance bullets  
- [ ] Behavior and scope are clear (what users can do)  
- [ ] Out of scope explicitly listed  
- [ ] Flags (if needed): owner, default, kill switch, removal date  
- [ ] Migrations (if any): expand → migrate → contract plan exists  
- [ ] Observability: what we’ll watch after release (smoke + key metrics)

Dependencies / risks  
List notable risks, escalations, or cross-cutting dependencies.

Project fields  
Status = Draft; Type = Spec; Area = <intake|identity|measure|chronicle|lexicon|ui|db|ci|policy|runbooks>; Target Release = mvp-<X.Y.Z>

Links  
PR (if opened):  
Related Issues:
