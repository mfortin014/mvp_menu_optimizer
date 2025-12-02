<!--
title: Implement Supabase Auth — Replace password-based authentication
labels: ["security", "auth", "feature"]
uid: supabase-auth-implementation
type: Feature
status: Draft
priority: P1
area: identity
series: "Throughput"
work_type: Standalone
story_points: 13
-->

# Implement Supabase Auth — Replace password-based authentication

## Intent

Replace the current insecure password-based authentication system (single shared `CHEF_PASSWORD`) with proper Supabase Auth integration. This enables:
- Individual user accounts with email/password authentication
- JWT-based sessions with tenant-scoped access
- Admin user management and invitations
- Database-level security via RLS policies using JWT claims

## Current State

- Single shared password (`CHEF_PASSWORD` secret) for all users
- Session state stored in `st.session_state.authenticated`
- Tenant selection happens before authentication
- Database has `profiles` and `user_tenant_memberships` tables ready
- RLS is enabled but uses permissive policies (`using (true)`)
- Migration plan V010 exists for JWT-claim RLS but not implemented

## Implementation Plan

### Phase 1: Supabase Auth Integration
- Update `utils/supabase_client.py` to support authenticated sessions with JWT tokens
- Create `utils/auth_session.py` for session management (get_current_user, set_auth_session, clear_auth_session)
- Create `components/auth_ui.py` with login form, password reset, and invitation acceptance UI
- Replace password-based auth in `utils/auth.py` with Supabase Auth login flow

### Phase 2: User Invitation System
- Create `utils/user_invitations.py` for admin user invitation management using service role key
- Create `pages/UserManagement.py` for admin UI to invite users, manage memberships, and view users
- Create migration to sync `auth.users` with `profiles` table and auto-create profiles on user signup

### Phase 3: Replace Password Auth
- Update all pages (Home.py, pages/*.py) to use new `require_auth()` and remove old password auth
- Update tenant selection to happen after authentication and filter by user memberships
- Remove `CHEF_PASSWORD` from codebase and update `env_and_secrets.md` documentation

### Phase 4: JWT-Based Tenant Access
- Update `utils/tenant_db.py` to use authenticated Supabase client with JWT tokens
- Implement tenant switching with JWT refresh
- Create migration V017 to implement tenant-scoped RLS policies using JWT claims (V010 plan)

### Phase 5: Testing & Documentation
- Add unit tests for `auth_session.py` and `user_invitations.py`, update smoke tests
- Update `first_run.md` and other docs to reflect new authentication flow

## Acceptance Criteria

- [ ] Users can log in with email/password via Supabase Auth
- [ ] JWT tokens are stored in session state and used for authenticated requests
- [ ] Admin users can invite new users to tenants with role assignment
- [ ] Tenant selection only shows tenants the user has access to
- [ ] All pages use new authentication system (no password-based auth remains)
- [ ] RLS policies enforce tenant isolation using JWT claims
- [ ] Profile rows are automatically created when users sign up
- [ ] `CHEF_PASSWORD` is removed from codebase and documentation
- [ ] Documentation updated to reflect new authentication flow

## Migration Strategy

Big bang cutover:
- All changes deployed together
- Old password auth removed immediately
- Users must be invited before they can access the system
- Existing sessions will be invalidated on deploy

## Rollback Plan

- Keep old `utils/auth.py` code in git history
- Can temporarily restore password-based auth if needed
- Database migrations are reversible (drop policies, restore permissive ones)

## References

- Migration plan: `migrations/MIGRATION_PLAN__V010_tenant_claim_rls.md`
- Policy: `docs/policy/env_and_secrets.md`
- Branching: `docs/policy/branching_and_prs.md`

