# utils/auth_session.py
"""
Session management utilities for Supabase Auth.

Handles storing and retrieving JWT tokens, user information, and tenant context
from Streamlit session state.
"""

from __future__ import annotations

from typing import Optional

import streamlit as st
from supabase import Client

from utils.supabase_client import get_authenticated_client, supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

# Session state keys
ACCESS_TOKEN_KEY = "supabase_access_token"
REFRESH_TOKEN_KEY = "supabase_refresh_token"
USER_KEY = "supabase_user"
USER_ID_KEY = "supabase_user_id"


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
        # Log error for debugging - show in UI temporarily to help diagnose
        import traceback

        error_msg = str(e)
        # Show error details to help diagnose the issue
        st.error(f"Error fetching tenant memberships: {error_msg}")
        # Add expander for debug details
        with st.expander("Debug details (click to expand)"):
            st.code(traceback.format_exc())
            st.write(f"**User ID from session:** `{user_id}`")

            # Try to check if profile exists and get auth_client separately
            auth_client_check = None
            try:
                auth_client_check = get_authenticated_supabase()
                st.write(f"**Has authenticated client:** {auth_client_check is not None}")

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
                        st.write(f"**Profile email:** {profile_check.data[0].get('email', 'N/A')}")
            except Exception as profile_err:
                st.write(f"**Error checking profile:** {str(profile_err)}")

            # Show current user info
            user = get_current_user()
            if user:
                st.write(f"**Current user email:** {user.get('email', 'N/A')}")
                st.write(f"**Current user ID from auth:** {user.get('id', 'N/A')}")

            st.info(
                "**Troubleshooting tips:**\n"
                "1. Verify the user_id in user_tenant_memberships matches the auth.users.id\n"
                "2. Ensure the profile exists (V017 migration should create it)\n"
                "3. Check that is_active=true and deleted_at is null in the membership\n"
                "4. Verify RLS policies allow access (user_tenant_memberships_select_own policy)"
            )
        return []


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
