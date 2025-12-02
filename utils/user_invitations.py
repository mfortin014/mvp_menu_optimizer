# utils/user_invitations.py
"""
User invitation utilities for admin operations.

Uses Supabase Admin API (service role key) to invite users and manage memberships.
"""

from __future__ import annotations

from typing import Optional

from utils.supabase_client import get_admin_client


def invite_user(
    email: str, tenant_id: str, role: str = "viewer", redirect_url: Optional[str] = None
) -> dict:
    """
    Invite a user to a tenant via Supabase Auth.

    Args:
        email: User's email address
        tenant_id: UUID of the tenant to invite to
        role: Role to assign (viewer, editor, admin)
        redirect_url: Optional redirect URL after invitation acceptance

    Returns:
        Dict with invitation details

    Raises:
        Exception: If invitation fails
    """
    admin_client = get_admin_client()

    # Invite user via Supabase Auth
    invite_response = admin_client.auth.admin.invite_user_by_email(
        email,
        options={
            "redirect_to": redirect_url,
            "data": {
                "tenant_id": tenant_id,
                "role": role,
            },
        },
    )

    if not invite_response.user:
        raise Exception("Failed to create invitation")

    user_id = invite_response.user.id

    # Create user_tenant_membership
    membership_response = (
        admin_client.table("user_tenant_memberships")
        .insert(
            {
                "user_id": user_id,
                "tenant_id": tenant_id,
                "role": role,
            }
        )
        .execute()
    )

    if not membership_response.data:
        raise Exception("Failed to create tenant membership")

    return {
        "user_id": user_id,
        "email": email,
        "tenant_id": tenant_id,
        "role": role,
        "invited_at": invite_response.user.invited_at,
    }


def list_pending_invitations(tenant_id: Optional[str] = None) -> list[dict]:
    """
    List pending invitations (users who haven't accepted yet).

    Args:
        tenant_id: Optional filter by tenant

    Returns:
        List of pending invitation dicts
    """
    admin_client = get_admin_client()

    # Get memberships for the tenant(s)
    memberships_query = admin_client.table("user_tenant_memberships").select("*, tenants(*)")

    if tenant_id:
        memberships_query = memberships_query.eq("tenant_id", tenant_id)

    memberships = memberships_query.execute()

    # Filter for users who might be pending (invited but not confirmed)
    # Note: This is a best-effort approach. A better solution would track
    # invitation status in user_tenant_memberships or a separate invitations table.
    pending = []
    for membership in memberships.data or []:
        # Check if user exists and is confirmed
        user_id = membership.get("user_id")
        if user_id:
            try:
                # Use admin API to get user details
                user_response = admin_client.auth.admin.get_user_by_id(user_id)
                if user_response and user_response.user:
                    user = user_response.user
                    # Check if user was invited but hasn't confirmed
                    if user.invited_at and not user.email_confirmed_at:
                        pending.append(
                            {
                                "user_id": user_id,
                                "email": user.email or "N/A",
                                "tenant_id": membership.get("tenant_id"),
                                "tenant_name": membership.get("tenants", {}).get("name"),
                                "role": membership.get("role"),
                                "invited_at": (
                                    user.invited_at.isoformat() if user.invited_at else None
                                ),
                            }
                        )
            except Exception:
                # User might not exist or other error - skip
                pass

    return pending


def revoke_invitation(user_id: str) -> bool:
    """
    Revoke a pending invitation by deleting the user and membership.

    Args:
        user_id: UUID of the user to revoke

    Returns:
        True if successful, False otherwise
    """
    admin_client = get_admin_client()

    try:
        # Delete membership first
        admin_client.table("user_tenant_memberships").delete().eq("user_id", user_id).execute()

        # Delete user from auth (this will cascade or we handle it)
        admin_client.auth.admin.delete_user(user_id)

        return True
    except Exception:
        return False


def list_users(tenant_id: Optional[str] = None) -> list[dict]:
    """
    List all users and their tenant memberships.

    Args:
        tenant_id: Optional filter by tenant

    Returns:
        List of user dicts with membership info
    """
    admin_client = get_admin_client()

    query = admin_client.table("user_tenant_memberships").select("*, tenants(*), profiles(*)")

    if tenant_id:
        query = query.eq("tenant_id", tenant_id)

    response = query.execute()
    return response.data or []


def update_user_role(user_id: str, tenant_id: str, role: str) -> bool:
    """
    Update a user's role in a tenant.

    Args:
        user_id: UUID of the user
        tenant_id: UUID of the tenant
        role: New role (viewer, editor, admin)

    Returns:
        True if successful, False otherwise
    """
    admin_client = get_admin_client()

    try:
        admin_client.table("user_tenant_memberships").update({"role": role}).eq(
            "user_id", user_id
        ).eq("tenant_id", tenant_id).execute()
        return True
    except Exception:
        return False


def remove_user_from_tenant(user_id: str, tenant_id: str) -> bool:
    """
    Remove a user from a tenant (delete membership).

    Args:
        user_id: UUID of the user
        tenant_id: UUID of the tenant

    Returns:
        True if successful, False otherwise
    """
    admin_client = get_admin_client()

    try:
        admin_client.table("user_tenant_memberships").delete().eq("user_id", user_id).eq(
            "tenant_id", tenant_id
        ).execute()
        return True
    except Exception:
        return False
