# Runbook: Smoke QA
**Updated:** 2025-09-18 21:28

Purpose: rehearse the Golden Path on every deploy without touching production data.

---

## Scope

### MVP now
- Target environment: **staging** Supabase + Streamlit deployment.
- Validation: GitHub Actions smoke tests (`pytest tests/smoke`) and a manual UI sanity check.

### v1 later
- Browser automation against staging + synthetic monitoring hooks in production.

---

## 1. Prepare Environment
1. Confirm staging credentials in GitHub → **Environments → staging**.  
2. Ensure the staging database has seed data (run the provisioning script or load `data/exports/2025-09-09`).

## 2. Run Automated Smoke Tests
```bash
pytest tests/smoke
```
Expected: quick pass (<5s). Tests only import modules, check version metadata, and parse fixtures — no network hits.

## 3. Manual UI Sanity Check
1. Deploy the latest commit to staging (CI does this on merge to `main`).  
2. Open the staging Streamlit URL.  
3. Verify:
   - App boots without auth errors.
   - Ingredient list loads for the default tenant.
   - Menu dashboard renders with data.

## 4. Capture Evidence
- Screenshot of staging app home screen.  
- CI link showing the smoke job succeeded.  
- Note any gaps in the runbook and log them in #DOCS_ISSUE.

## 5. Escalate Issues
- If automation fails → create a bug issue and block deploy.  
- If manual QA fails but smoke passes → flag the gap and open a follow-up task.
