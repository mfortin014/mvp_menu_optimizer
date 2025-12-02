# utils/auth_session.py
"""
Session management utilities for Supabase Auth.

Handles storing and retrieving JWT tokens, user information, and tenant context
from Streamlit session state.
"""

from __future__ import annotations

from typing import Optional

import streamlit as st
import streamlit.components.v1 as components
from supabase import Client

from utils.supabase_client import get_authenticated_client, supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

# Session state keys
ACCESS_TOKEN_KEY = "supabase_access_token"
REFRESH_TOKEN_KEY = "supabase_refresh_token"
USER_KEY = "supabase_user"
USER_ID_KEY = "supabase_user_id"
HASH_PARAMS_KEY = "url_hash_params"
HASH_PROCESSED_KEY = "url_hash_processed"


def get_access_token() -> Optional[str]:
    """Get the current access token from session state."""
    return st.session_state.get(ACCESS_TOKEN_KEY)


def get_refresh_token() -> Optional[str]:
    """Get the current refresh token from session state."""
    return st.session_state.get(REFRESH_TOKEN_KEY)


def get_current_user() -> Optional[dict]:
    """
    Get the current authenticated user from session state.

    Returns:
        User dict with id, email, etc., or None if not authenticated
    """
    return st.session_state.get(USER_KEY)


def get_current_user_id() -> Optional[str]:
    """
    Get the current user's ID from session state.

    Note: This should match auth.uid() in the JWT token.
    If the user was created manually, ensure the user_id in
    user_tenant_memberships matches this value.
    """
    user = get_current_user()
    if user:
        user_id = user.get("id")
        if user_id:
            return user_id
    return st.session_state.get(USER_ID_KEY)


def set_auth_session(access_token: str, refresh_token: str, user: dict) -> None:
    """
    Store authentication session in Streamlit session state.

    Args:
        access_token: JWT access token
        refresh_token: Refresh token for token renewal
        user: User object from Supabase Auth
    """
    st.session_state[ACCESS_TOKEN_KEY] = access_token
    st.session_state[REFRESH_TOKEN_KEY] = refresh_token
    st.session_state[USER_KEY] = user
    st.session_state[USER_ID_KEY] = user.get("id")


def clear_auth_session() -> None:
    """Clear authentication session from Streamlit session state."""
    for key in [ACCESS_TOKEN_KEY, REFRESH_TOKEN_KEY, USER_KEY, USER_ID_KEY]:
        if key in st.session_state:
            del st.session_state[key]


def get_authenticated_supabase() -> Optional[Client]:
    """
    Get an authenticated Supabase client using the current session token.

    Returns:
        Authenticated Supabase client, or None if not authenticated
    """
    access_token = get_access_token()
    if not access_token:
        return None
    return get_authenticated_client(access_token)


def refresh_session() -> bool:
    """
    Refresh the access token using the refresh token if needed.
    Currently always attempts refresh - could be enhanced to check expiry.

    Returns:
        True if session is valid (or refresh was successful), False otherwise
    """
    access_token = get_access_token()
    refresh_token = get_refresh_token()

    # If we have an access token, assume it's valid for now
    # In production, you'd check JWT expiry here
    if access_token:
        return True

    # No access token, try to refresh
    if not refresh_token:
        return False

    try:
        response = supabase.auth.refresh_session(refresh_token)
        if response.session:
            set_auth_session(
                response.session.access_token,
                response.session.refresh_token,
                (
                    response.user.model_dump()
                    if hasattr(response.user, "model_dump")
                    else response.user
                ),
            )
            return True
    except Exception:
        # Refresh failed, clear session
        clear_auth_session()
        return False

    return False


def ensure_profile_exists(user_id: str) -> bool:
    """
    Ensure a profile exists for the given user_id.
    This is a safety check in case the trigger didn't fire.

    Returns:
        True if profile exists or was created, False otherwise
    """
    try:
        auth_client = get_authenticated_supabase()
        if not auth_client:
            return False

        # Check if profile exists
        profile_response = (
            auth_client.table("profiles").select("id").eq("id", user_id).limit(1).execute()
        )

        if profile_response.data:
            return True

        # Profile doesn't exist - try to get user info and create it
        # Note: This requires the user to have email in their auth session
        user = get_current_user()
        if not user:
            return False

        # Try to create profile (this might fail due to RLS, but worth trying)
        try:
            auth_client.table("profiles").insert(
                {
                    "id": user_id,
                    "email": user.get("email", ""),
                }
            ).execute()
            return True
        except Exception:
            # If insert fails, the trigger should handle it, or admin needs to create it
            return False
    except Exception:
        return False


def get_user_tenants() -> list[dict]:
    """
    Fetch the current user's tenant memberships.

    Returns:
        List of tenant membership dicts with tenant_id, role, etc.
    """
    user_id = get_current_user_id()
    if not user_id:
        return []

    # Ensure profile exists (safety check)
    ensure_profile_exists(user_id)

    try:
        # Use authenticated client to respect RLS
        auth_client = get_authenticated_supabase()
        if not auth_client:
            return []

        # Query memberships with filters for active, non-deleted memberships
        # Note: We can't filter on joined table columns directly, so we'll filter in Python
        response = (
            auth_client.table("user_tenant_memberships")
            .select("*, tenants(*)")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .is_("deleted_at", "null")
            .execute()
        )

        # Filter results to only include active, non-deleted tenants
        memberships = response.data or []
        filtered = []
        for membership in memberships:
            tenant = membership.get("tenants")
            if tenant and tenant.get("is_active") and not tenant.get("deleted_at"):
                filtered.append(membership)

        return filtered
    except Exception as e:
        # Log error for debugging
        import traceback

        from utils.env import is_prod

        error_msg = str(e)
        # Show user-friendly error message
        st.error(
            "Unable to load your tenant access. Please contact an administrator if this persists."
        )

        # Only show detailed debug info in non-production environments
        if not is_prod():
            with st.expander("Debug details (click to expand)"):
                st.code(traceback.format_exc())
                st.write(f"**Error:** {error_msg}")
                st.write(f"**User ID:** `{user_id}`")

                # Try to check if profile exists
                try:
                    auth_client_check = get_authenticated_supabase()
                    if auth_client_check:
                        profile_check = (
                            auth_client_check.table("profiles")
                            .select("id, email")
                            .eq("id", user_id)
                            .limit(1)
                            .execute()
                        )
                        st.write(f"**Profile exists:** {bool(profile_check.data)}")
                        if profile_check.data:
                            st.write(
                                f"**Profile email:** {profile_check.data[0].get('email', 'N/A')}"
                            )
                except Exception:
                    pass

                # Show current user info
                user = get_current_user()
                if user:
                    st.write(f"**User email:** {user.get('email', 'N/A')}")

                st.info(
                    "**Troubleshooting:**\n"
                    "1. Verify user_id in user_tenant_memberships matches auth.users.id\n"
                    "2. Ensure profile exists (V017 migration)\n"
                    "3. Check is_active=true and deleted_at is null\n"
                    "4. Verify RLS policies (V019 should fix recursion issues)"
                )
        return []


def _decode_jwt_payload(token: str) -> Optional[dict]:
    """
    Decode JWT payload without verification (for extracting user info from hash).

    Args:
        token: JWT token string

    Returns:
        Decoded payload dict or None if invalid
    """
    try:
        import base64
        import json

        # JWT format: header.payload.signature
        parts = token.split(".")
        if len(parts) != 3:
            return None

        # Decode payload (add padding if needed)
        payload = parts[1]
        padding = 4 - len(payload) % 4
        if padding != 4:
            payload += "=" * padding

        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded)
    except Exception:
        return None


def read_hash_params_from_cookie() -> dict:
    """
    Read hash parameters that were stored in a cookie by JavaScript.

    Returns:
        Dict of hash parameters or empty dict
    """
    try:
        # Try to read from cookie (if JS has stored it)
        # This is a fallback - primary method is direct JS injection
        return {}
    except Exception:
        return {}


def extract_and_store_hash_params() -> dict:
    """
    Extract URL hash/fragment parameters using JavaScript and store in session state.
    This injects JavaScript that reads window.location.hash and stores it via a mechanism
    that Python can access.

    Returns:
        Dict of hash parameters (e.g., {'access_token': '...', 'type': 'invite'})
    """
    # Check if already processed
    if HASH_PARAMS_KEY in st.session_state:
        return st.session_state[HASH_PARAMS_KEY]

    # Check if already marked as processed (meaning no hash was found)
    if st.session_state.get(HASH_PROCESSED_KEY, False):
        return {}

    # Use JavaScript to extract hash and store in cookie
    # Then Python can read the cookie on subsequent runs
    js_code = """
    <script>
    (function() {
        var hash = window.location.hash.substring(1);
        if (hash && hash.length > 0) {
            var params = {};
            var pairs = hash.split('&');
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split('=');
                if (pair.length === 2) {
                    var key = decodeURIComponent(pair[0]);
                    var value = decodeURIComponent(pair[1]);
                    params[key] = value;
                }
            }
            
            // Store in cookie (accessible to Python via browser)
            // Cookie expires in 1 minute (just enough time for Python to read it)
            var expires = new Date();
            expires.setMinutes(expires.getMinutes() + 1);
            document.cookie = 'streamlit_hash_params=' + encodeURIComponent(JSON.stringify(params)) 
                            + ';expires=' + expires.toUTCString() + ';path=/';
            
            // Also store in session state key for immediate access
            // We'll handle this via a form submission mechanism
            
            // Clear hash from URL
            if (window.history && window.history.replaceState) {
                window.history.replaceState(null, null, window.location.pathname + window.location.search);
            }
        }
    })();
    </script>
    """

    components.html(js_code, height=0)

    # For now, return empty dict - we'll check session state on next run
    # Or we can use a more direct approach with a callback component
    return {}


def handle_hash_redirect() -> bool:
    """
    Handle URL hash parameters by redirecting to query parameters.
    This allows Python to read the values via st.query_params.

    Returns:
        True if redirect was performed, False otherwise
    """
    # Check if we've already processed the hash
    if st.session_state.get(HASH_PROCESSED_KEY, False):
        return False

    # Inject JavaScript to read hash and redirect with query params
    js_code = """
    <script>
    (function() {
        var hash = window.location.hash.substring(1);
        if (hash && hash.length > 0) {
            // Parse hash parameters
            var params = {};
            var pairs = hash.split('&');
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split('=');
                if (pair.length === 2) {
                    var key = decodeURIComponent(pair[0]);
                    var value = decodeURIComponent(pair[1]);
                    params[key] = value;
                }
            }
            
            // If we have access_token with type=invite, redirect with query params
            if (params.access_token && params.type === 'invite') {
                var queryString = '?access_token=' + encodeURIComponent(params.access_token);
                if (params.refresh_token) {
                    queryString += '&refresh_token=' + encodeURIComponent(params.refresh_token);
                }
                queryString += '&type=invite';
                
                // Redirect to same page with query params instead of hash
                window.location.replace(window.location.pathname + queryString);
            }
        }
    })();
    </script>
    """

    components.html(js_code, height=0)
    st.session_state[HASH_PROCESSED_KEY] = True

    # Return True to indicate we're handling a redirect
    return True


def process_hash_params() -> Optional[dict]:
    """
    Process URL hash parameters if present.
    This injects JavaScript to read the hash and stores params in session state.
    Must be called early in the page load.

    Returns:
        Dict with access_token, refresh_token, type if found, None otherwise
    """
    # Check if already processed
    if HASH_PROCESSED_KEY in st.session_state:
        return st.session_state.get(HASH_PARAMS_KEY)

    # Inject JavaScript to read hash and store in sessionStorage
    # Then immediately try to read it back
    js_code = f"""
    <script>
    (function() {{
        var hash = window.location.hash.substring(1);
        if (hash && hash.length > 0) {{
            var params = {{}};
            var pairs = hash.split('&');
            for (var i = 0; i < pairs.length; i++) {{
                var pair = pairs[i].split('=');
                if (pair.length === 2) {{
                    var key = decodeURIComponent(pair[0]);
                    var value = decodeURIComponent(pair[1]);
                    params[key] = value;
                }}
            }}
            
            // Store in sessionStorage
            sessionStorage.setItem('{HASH_PARAMS_KEY}', JSON.stringify(params));
            
            // Clear hash from URL
            if (window.history && window.history.replaceState) {{
                window.history.replaceState(null, null, window.location.pathname + window.location.search);
            }}
        }}
    }})();
    </script>
    """

    components.html(js_code, height=0)

    # Try to read from sessionStorage via another JS call
    # We'll use a form mechanism or check on next run
    # For now, return None - we'll check sessionStorage on next component render
    return None


def get_hash_params() -> dict:
    """
    Get hash parameters from URL hash/fragment.
    Checks sessionStorage via JavaScript if not already in session state.

    Returns:
        Dict of hash parameters
    """
    # Return cached params if available
    if HASH_PARAMS_KEY in st.session_state:
        params = st.session_state[HASH_PARAMS_KEY]
        return params if params else {}

    # Try to read from sessionStorage
    read_js = f"""
    <script>
    (function() {{
        var stored = sessionStorage.getItem('{HASH_PARAMS_KEY}');
        if (stored) {{
            // Store in a data attribute so Python can potentially access it
            document.body.setAttribute('data-hash-params', stored);
            sessionStorage.removeItem('{HASH_PARAMS_KEY}');
        }}
    }})();
    </script>
    """

    components.html(read_js, height=0)

    # Mark as processed
    st.session_state[HASH_PROCESSED_KEY] = True

    # For now return empty - the params will be available via a different mechanism
    # We'll handle the hash directly in require_auth() by checking for it
    return {}


def setup_session_from_tokens(
    access_token: str, refresh_token: str, token_type: str = "invite"
) -> bool:
    """
    Set up authentication session from URL hash parameters.

    Args:
        access_token: Access token from hash
        refresh_token: Refresh token from hash
        token_type: Type parameter from hash (should be 'invite')

    Returns:
        True if session was set up successfully, False otherwise
    """
    if token_type != "invite":
        return False

    try:
        # Decode JWT to get user info
        payload = _decode_jwt_payload(access_token)
        if not payload:
            return False

        # Extract user info from JWT payload
        user_dict = {
            "id": payload.get("sub"),
            "email": payload.get("email", ""),
        }

        # Set up session
        set_auth_session(access_token, refresh_token or "", user_dict)
        return True
    except Exception:
        return False


def ensure_tenant_selected() -> Optional[str]:
    """
    Ensure a tenant is selected for the current user.
    If no tenant is selected, choose the first available or default tenant.

    Returns:
        Selected tenant ID, or None if user has no tenants
    """
    current_tenant = get_active_tenant()
    if current_tenant:
        # Verify user still has access to this tenant
        tenants = get_user_tenants()
        tenant_ids = [m.get("tenant_id") for m in tenants if m.get("tenant_id")]
        if current_tenant in tenant_ids:
            return current_tenant

    # No tenant selected or access lost, select first available
    tenants = get_user_tenants()
    if not tenants:
        return None

    # Prefer default tenant, otherwise first one
    default_tenant = next(
        (m.get("tenant_id") for m in tenants if m.get("tenants", {}).get("is_default")),
        None,
    )
    selected_tenant = default_tenant or tenants[0].get("tenant_id")
    if selected_tenant:
        set_active_tenant(selected_tenant)
    return selected_tenant
