# 🔐 Authentication Troubleshooting & Resolution Log

This document chronicles the debugging process undertaken to secure and restore functionality to the Menu Optimizer MVP after an authentication refactor and API key leak. It is intended to serve both as a reference and a cautionary record.

---

## 1. 🔓 Problem Overview

* The original `secrets.toml` was accidentally pushed to GitHub, leaking the Supabase anon public key.
* Supabase Role Level Security (RLS) was enabled mid-MVP but without the full user/role-based infrastructure to support it.
* A series of back-and-forth iterations over authentication (including Supabase's `auth.sign_in_with_password`) failed to produce a reliable working login due to missing JWT configs, misaligned Supabase project setup, and incorrect redirect behaviors.

---

## 2. 🧼 GitHub Secret Leak Scrubbing

To prevent misuse of the exposed anon key, we scrubbed the git history:

### ✅ Steps Taken:

1. **Install BFG Repo-Cleaner**: Used [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) to remove secrets from git history.

2. **Delete the leaked secrets file**:

   ```bash
   git rm --cached -r .streamlit/secrets.toml
   echo ".streamlit/secrets.toml" >> .gitignore
   git commit -m "Remove secrets.toml from repo"
   ```

3. **Run BFG to scrub history**:

   ```bash
   java -jar bfg.jar --delete-files secrets.toml
   ```

4. **Clean and force-push the scrubbed repo**:

   ```bash
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force
   ```

5. **Verify**: Confirmed the secrets file was no longer present in any commit via `git log` and GitHub history.

---

## 3. 🔑 Regenerating Supabase Keys

To invalidate the compromised anon key:

* Navigated to **Project Settings → API → Service Role & JWT Secrets**.
* Clicked **"Generate new JWT secret"**.
* This automatically regenerated **both** the `anon` and `service_role` keys.
* Updated the new `anon` key in:

  * Local `.streamlit/secrets.toml`
  * Streamlit Cloud app secrets

⚠️ **Note**: This step was not clearly documented in Supabase, and was a source of major confusion and delay.

---

## 4. 🔁 Reverting to Pre-RLS Simplicity

After hours of failed attempts to implement secure Supabase login via RLS + JWT, we:

* **Reverted back to the original MVP architecture** using `st.secrets["SUPABASE_KEY"]` and `create_client()` from Supabase Python SDK.
* **Manually disabled all RLS policies** in the Supabase GUI.
* **Switched back to Chef-only login** using a hardcoded password in `.streamlit/secrets.toml`.

Example:

```toml
CHEF_PASSWORD = "mysupersecret"
```

In `auth.py`:

```python
if password == st.secrets.get("CHEF_PASSWORD"):
    st.session_state.authenticated = True
```

---

## 5. 🧠 Lessons Learned

### ✅ What Worked

* Reverting to a simplified, hardcoded login model.
* Manually disabling RLS to restore API access.
* Regenerating keys to invalidate the leak.
* Git scrub using BFG.

### ❌ What Didn’t

* Attempting to layer full Supabase user auth + RLS without proper frontend handling or API claims propagation.
* Using `st.switch_page()` as a redirect workaround – led to infinite loops.

---

## 6. ✅ Current State (Post-Restore)

* 🟢 MVP works again with a Chef-only login model.
* 🟢 `.streamlit/secrets.toml` now excluded from git and git history scrubbed.
* 🟢 Supabase keys rotated and updated.
* 🔴 No RLS or multi-user auth implemented yet.

---

## 7. 🪪 Next Steps (Future Hardening)

* ✅ Create a proper `users` table and implement a tiered RLS model.
* ✅ Only enable RLS once all session management + row ownership logic is ready.
* ⚠️ Investigate switching to a real framework (e.g., Next.js + Supabase or App Router stack).
* 🔒 Always verify secrets management before sharing repos or demos.

---

**Document last updated:** 2025-06-30
