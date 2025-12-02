# pages/UserManagement.py
"""
User Management page for admin users.

Allows admins to invite users, manage memberships, and view users.
"""

from __future__ import annotations

import streamlit as st

from components.active_client_badge import render as client_badge
from utils.auth import require_auth
from utils.auth_session import get_current_user, get_user_tenants
from utils.env import env_label, is_prod
from utils.supabase_client import get_admin_client
from utils.tenant_state import get_active_tenant
from utils.user_invitations import (
    invite_user,
    list_pending_invitations,
    list_users,
    remove_user_from_tenant,
    revoke_invitation,
    update_user_role,
)

# Page chrome
title_suffix = "" if is_prod() else f" — {env_label()}"
st.set_page_config(page_title=f"User Management{title_suffix}", layout="wide")

# Non-prod banner
if not is_prod():
    st.warning(f"{env_label()} environment — data and behavior may differ from production.")

require_auth()

# Check if user is admin
current_user = get_current_user()
user_tenants = get_user_tenants()
current_tenant_id = get_active_tenant()

# Check if user has admin/owner role in current tenant
is_admin = False
if current_tenant_id:
    for membership in user_tenants:
        if membership.get("tenant_id") == current_tenant_id:
            role = membership.get("role", "").lower()
            if role in ["admin", "owner"]:
                is_admin = True
                break

if not is_admin:
    st.error("You don't have permission to access this page. Admin or owner role required.")
    st.stop()

client_badge(clients_page_title="Clients")
st.title("👥 User Management")

# Get list of tenants for selection
admin_client = get_admin_client()
tenants_response = (
    admin_client.table("tenants")
    .select("id, name, code")
    .eq("is_active", True)
    .order("name")
    .execute()
)
tenants = tenants_response.data or []
tenant_options = {f"{t['name']} ({t.get('code', '')})": t["id"] for t in tenants}
tenant_names = list(tenant_options.keys())

# Tenant filter
st.subheader("Filter by Tenant")
selected_tenant_name = st.selectbox(
    "Select tenant",
    ["All Tenants"] + tenant_names,
    key="user_mgmt_tenant_filter",
)
selected_tenant_id = (
    tenant_options.get(selected_tenant_name) if selected_tenant_name != "All Tenants" else None
)

# Tabs for different operations
tab1, tab2, tab3 = st.tabs(["Users", "Invite User", "Pending Invitations"])

with tab1:
    st.subheader("Users and Memberships")
    users = list_users(tenant_id=selected_tenant_id)

    if users:
        # Display users in a table
        import pandas as pd

        display_data = []
        for user_membership in users:
            tenant = user_membership.get("tenants", {})
            profile = user_membership.get("profiles", {})
            display_data.append(
                {
                    "Email": profile.get("email", "N/A"),
                    "Tenant": tenant.get("name", "N/A"),
                    "Role": user_membership.get("role", "N/A"),
                    "User ID": user_membership.get("user_id", "N/A"),
                }
            )

        df = pd.DataFrame(display_data)
        st.dataframe(df, use_container_width=True, hide_index=True)

        # User actions
        st.subheader("Manage User")
        action_user_id = st.text_input("User ID", key="action_user_id")
        action_tenant_id = st.selectbox(
            "Tenant",
            tenant_names,
            key="action_tenant_select",
            format_func=lambda x: x,
        )
        action_tenant_uuid = tenant_options.get(action_tenant_id)

        col1, col2, col3 = st.columns(3)

        with col1:
            new_role = st.selectbox(
                "New Role", ["viewer", "editor", "admin", "owner"], key="new_role_select"
            )
            if st.button("Update Role"):
                if action_user_id and action_tenant_uuid:
                    if update_user_role(action_user_id, action_tenant_uuid, new_role):
                        st.success(f"Role updated to {new_role}")
                        st.rerun()
                    else:
                        st.error("Failed to update role")

        with col2:
            if st.button("Remove from Tenant", type="secondary"):
                if action_user_id and action_tenant_uuid:
                    if remove_user_from_tenant(action_user_id, action_tenant_uuid):
                        st.success("User removed from tenant")
                        st.rerun()
                    else:
                        st.error("Failed to remove user")

    else:
        st.info("No users found.")

with tab2:
    st.subheader("Invite New User")
    with st.form("invite_user_form"):
        invite_email = st.text_input("Email", type="default")
        invite_tenant = st.selectbox("Tenant", tenant_names, key="invite_tenant_select")
        invite_tenant_uuid = tenant_options.get(invite_tenant)
        invite_role = st.selectbox(
            "Role", ["viewer", "editor", "admin", "owner"], key="invite_role_select"
        )
        submitted = st.form_submit_button("Send Invitation", use_container_width=True)

        if submitted:
            if not invite_email:
                st.error("Please enter an email address.")
            elif not invite_tenant_uuid:
                st.error("Please select a tenant.")
            else:
                try:
                    result = invite_user(invite_email, invite_tenant_uuid, invite_role)
                    st.success(f"Invitation sent to {invite_email}")
                    st.json(result)
                except Exception as e:
                    st.error(f"Failed to send invitation: {str(e)}")

with tab3:
    st.subheader("Pending Invitations")
    pending = list_pending_invitations(tenant_id=selected_tenant_id)

    if pending:
        import pandas as pd

        pending_df = pd.DataFrame(pending)
        st.dataframe(pending_df, use_container_width=True, hide_index=True)

        st.subheader("Revoke Invitation")
        revoke_user_id = st.text_input("User ID to revoke", key="revoke_user_id")
        if st.button("Revoke Invitation", type="secondary"):
            if revoke_user_id:
                if revoke_invitation(revoke_user_id):
                    st.success("Invitation revoked")
                    st.rerun()
                else:
                    st.error("Failed to revoke invitation")
    else:
        st.info("No pending invitations.")
