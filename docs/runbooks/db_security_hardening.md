# DB Security Hardening & Linter Zero (MVP)

## Steps (staging → prod)

1. Apply migrations V012–V014 with ./migrate.sh up (dry-run first).
2. Console toggles:
   - Auth → Passwords → Leaked password protection = ON
   - Database → Upgrade to latest 17.6.1.011 patch
3. Re-run Database Linter: expect 0 Errors; no search_path Warnings.
4. Smoke: app boots; core flows work.

## Governance

- Future views: WITH (security_invoker = true)
- New functions: SET search_path = public, pg_temp or schema-qualify everything.
