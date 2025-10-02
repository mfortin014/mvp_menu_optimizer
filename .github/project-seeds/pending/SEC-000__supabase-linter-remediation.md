<!--
seed-uid: SEC-000
title: Supabase database linter remediation (MVP)
type: Chore
area: db
priority: P0
status: Todo
project: main
children_uids: [SEC-001, SEC-002, SEC-003, SEC-004, SEC-005, SEC-006]
-->
## Because
Supabase Database Linter flags: (a) Security Definer views, (b) RLS disabled on two public tables, (c) mutable search_path functions, plus two console warnings.
## Done when
- [ ] Children SEC-001..SEC-006 are closed
- [ ] Staging manual run is green; smoke OK
- [ ] Linter shows 0 Errors / 0 search_path warnings
- [ ] Runbook added under docs/runbooks/
## Changelog
Security hardening for DB runtime permissions.
