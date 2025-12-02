# utils/auth.py
"""
Authentication utilities for Supabase Auth.

Replaces the old password-based authentication with proper Supabase Auth integration.
"""

from __future__ import annotations

import streamlit as st

from components.auth_ui import render_login_form
from utils.auth_session import (
    ensure_tenant_selected,
    get_access_token,
    get_current_user,
    get_user_tenants,
    refresh_session,
)
from utils.tenant_state import get_active_tenant, set_active_tenant


def ensure_client_selected_post_auth():
    """
    Show tenant selector after authentication.
    Only shows tenants the user has access to.
    """
    user_tenants = get_user_tenants()
    if not user_tenants:
        st.error("You don't have access to any tenants. Please contact an administrator.")
        st.stop()

    # Build tenant options
    tenant_options = []
    tenant_id_by_name = {}
    name_by_id = {}

    for membership in user_tenants:
        tenant = membership.get("tenants", {})
        tenant_id = membership.get("tenant_id")
        tenant_name = tenant.get("name")
        if not tenant_name:
            # Fallback: use tenant_id if available, otherwise generic name
            if tenant_id:
                tenant_name = f"Tenant {tenant_id[:8]}"
            else:
                tenant_name = "Unknown Tenant"
        tenant_options.append(tenant_name)
        tenant_id_by_name[tenant_name] = tenant_id
        if tenant_id:
            name_by_id[tenant_id] = tenant_name

    if not tenant_options:
        st.error("No tenants available.")
        st.stop()

    # Determine default tenant
    current_tenant = get_active_tenant()
    default_tenant = next(
        (m.get("tenant_id") for m in user_tenants if m.get("tenants", {}).get("is_default")),
        user_tenants[0].get("tenant_id"),
    )

    if not current_tenant or current_tenant not in name_by_id:
        current_tenant = default_tenant
        set_active_tenant(current_tenant)

    current_name = name_by_id.get(current_tenant, tenant_options[0])

    st.subheader("Client")
    choice = st.selectbox(
        "Choose client",
        tenant_options,
        index=tenant_options.index(current_name) if current_name in tenant_options else 0,
        key="tenant_select_post_auth",
    )
    chosen_id = tenant_id_by_name[choice]

    if chosen_id != current_tenant:
        set_active_tenant(chosen_id)
        st.rerun()


def require_auth():
    """
    Require authentication before accessing the page.
    Shows login form if not authenticated, otherwise ensures tenant is selected.
    """
    # Check if we have a valid access token
    access_token = get_access_token()
    user = get_current_user()

    if not access_token or not user:
        # Not authenticated, show login form
        render_login_form()
        st.stop()

    # Check if token needs refresh (basic check - could be enhanced)
    # For now, we'll refresh on each page load if needed
    # In production, you might want to check token expiry
    if not refresh_session():
        # Token refresh failed, show login again
        render_login_form()
        st.stop()

    # Authenticated - ensure tenant is selected
    selected_tenant = ensure_tenant_selected()
    if not selected_tenant:
        st.error("You don't have access to any tenants. Please contact an administrator.")
        st.stop()

    # Show tenant selector if user has multiple tenants
    user_tenants = get_user_tenants()
    if len(user_tenants) > 1:
        ensure_client_selected_post_auth()
