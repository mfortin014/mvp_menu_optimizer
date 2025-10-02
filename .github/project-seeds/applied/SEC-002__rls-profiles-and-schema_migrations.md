<!--
uid: SEC-002
parent_uid: SEC-000
title: Enable RLS on public.profiles and schema_migrations
type: Chore
area: db
priority: P0
status: Todo
project: main
-->

## Done when

- [ ] public.profiles owner-only SELECT/UPDATE (+ optional INSERT)
- [ ] public.schema_migrations RLS ON with deny-all policy

## Migrations

- [ ] V013\_\_rls_profiles_and_schema_migrations.sql committed and applied
