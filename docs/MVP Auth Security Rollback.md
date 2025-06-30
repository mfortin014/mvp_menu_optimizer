# MVP Authentication & Security: RLS Rollback Recap

## 🧭 Context

This document summarizes the authentication and security adjustments made to the Menu Optimizer MVP during late June 2025. The goal was to ensure Chef could access and test the MVP in a secure yet minimal-friction environment.

---

## ⚠️ Initial Trigger

* The Supabase `anon` public key was accidentally committed to GitHub.
* Concern: Unauthorized users could potentially write to the database since RLS (Row-Level Security) was disabled.

---

## 🚧 Attempted Secure Setup

1. **Enabled RLS** on core tables.
2. **Set up Supabase Auth** with email/password login.
3. Implemented `require_login()` flow to redirect users to the login page.
4. Refactored multiple pages to rely on `st.session_state.access_token`.
5. Created login UI with `sign_in_with_password()` (later tried `sign_up()` too).

### Major Problems Encountered

* Could not generate new `anon` public key easily.
* Magic link redirect led to MVP’s login form (no password setup).
* Could not login even after user was marked as confirmed in Supabase.
* Circular redirects and `Not authenticated` errors persisted.
* Frustrating dev loop and loss of execution focus.

---

## 🧹 Rollback Strategy

**Objective:** Remove all Auth/RLS complexity and go back to a working MVP.

### Actions Taken

* Reverted `dev_require_login` branch.
* Restored `main` branch (which used the simple password auth with `st.secrets`).
* Disabled RLS via Supabase GUI for all affected tables.
* Regenerated Supabase keys (`anon` and `service`) and updated:

  * `secrets.toml` (local dev)
  * Streamlit Cloud project secrets (production)
* Restarted the local Streamlit app (important!) to refresh secrets.

### Result

✅ MVP works again with the original simple login system.
✅ Chef can now access the app.
✅ Database writes are controlled by limiting the `anon` key to a single known user.

---

## 🔐 Current Security Status (Post-Rollback)

| Feature               | Status                    |
| --------------------- | ------------------------- |
| Supabase RLS          | **Disabled**              |
| Supabase Auth (email) | Not in use                |
| Login via `secrets`   | ✅ Active                  |
| `anon` key exposure   | ✅ Regenerated and safe    |
| Write access scope    | ✅ Limited to app use only |

---

## 🗂️ Lessons Learned

* Supabase Auth + RLS is **not trivial** to bolt onto a running MVP.
* `st.switch_page()` has major limitations (must point to registered page names).
* Streamlit does **not reload secrets** automatically — restart the app.
* Regenerating the **service key** also regenerates the **anon** key.
* MVP execution speed matters more than over-securing in early testing.

---

## 📌 Next Steps

* ✅ Let Chef test the MVP as-is.
* 🧪 After validation, plan RLS + Auth from scratch with better tooling.
* 🛠️ Migrate to proper infra (React + Supabase + secure auth) in later phase.

---

## 📁 File Reference

This rollback affects:

* `Login.py`
* `utils/auth.py`
* All pages that had `require_login()` or token-based data fetching

---

## ✅ Final State Summary

The MVP now runs with simple, contained auth. Chef can test. Dev can resume.

No more spirals.

We move forward. 🏁
