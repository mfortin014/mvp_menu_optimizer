# components/auth_ui.py
"""
Authentication UI components for Supabase Auth.

Provides login, signup, password reset, and invitation acceptance flows.
"""

from __future__ import annotations

from typing import Optional

import streamlit as st

from utils.auth_session import clear_auth_session, set_auth_session
from utils.supabase_client import get_authenticated_client, supabase


def render_login_form() -> bool:
    """
    Render login form and handle authentication.

    Returns:
        True if login was successful, False otherwise
    """
    st.title("🔐 Login")

    with st.form("login_form"):
        email = st.text_input("Email", type="default")
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Login", use_container_width=True)

        if submitted:
            if not email or not password:
                st.error("Please enter both email and password.")
                return False

            try:
                response = supabase.auth.sign_in_with_password(
                    {"email": email, "password": password}
                )
                if response.session and response.user:
                    set_auth_session(
                        response.session.access_token,
                        response.session.refresh_token,
                        (
                            response.user.model_dump()
                            if hasattr(response.user, "model_dump")
                            else response.user
                        ),
                    )
                    st.success("Login successful!")
                    st.rerun()
                    return True
                else:
                    st.error("Login failed. Please check your credentials.")
                    return False
            except Exception as e:
                error_msg = str(e)
                if "Invalid login credentials" in error_msg or "Email not confirmed" in error_msg:
                    st.error("Invalid email or password.")
                else:
                    st.error(f"Login error: {error_msg}")
                return False

    # Password reset link
    st.markdown("---")
    with st.expander("Forgot password?"):
        render_password_reset()

    return False


def render_password_reset() -> None:
    """Render password reset form."""
    with st.form("password_reset_form"):
        email = st.text_input("Email", type="default", key="reset_email")
        submitted = st.form_submit_button("Send reset link", use_container_width=True)

        if submitted:
            if not email:
                st.error("Please enter your email address.")
                return

            try:
                supabase.auth.reset_password_for_email(email)
                st.success("Password reset link sent! Check your email.")
            except Exception as e:
                st.error(f"Error sending reset link: {str(e)}")


def render_invitation_acceptance(invitation_token: Optional[str] = None) -> bool:
    """
    Render invitation acceptance form.

    Args:
        invitation_token: Optional invitation token from URL

    Returns:
        True if invitation was accepted successfully, False otherwise
    """
    st.title("🎫 Accept Invitation")

    token = invitation_token or st.text_input(
        "Invitation Token", type="default", key="invitation_token"
    )

    if not token:
        st.info("Enter your invitation token to get started.")
        return False

    with st.form("invitation_form"):
        password = st.text_input("Set Password", type="password", key="invitation_password")
        password_confirm = st.text_input(
            "Confirm Password", type="password", key="invitation_password_confirm"
        )
        submitted = st.form_submit_button("Accept Invitation", use_container_width=True)

        if submitted:
            if not password or not password_confirm:
                st.error("Please enter and confirm your password.")
                return False

            if password != password_confirm:
                st.error("Passwords do not match.")
                return False

            if len(password) < 8:
                st.error("Password must be at least 8 characters long.")
                return False

            try:
                # Accept invitation and set password
                response = supabase.auth.verify_otp({"token": token, "type": "invite"})
                if response.session:
                    # Set session first, then use authenticated client to update password
                    set_auth_session(
                        response.session.access_token,
                        response.session.refresh_token,
                        (
                            response.user.model_dump()
                            if hasattr(response.user, "model_dump")
                            else response.user
                        ),
                    )
                    # Use authenticated client to update password
                    auth_client = get_authenticated_client(response.session.access_token)
                    auth_client.auth.update_user({"password": password})
                    st.success("Invitation accepted! You are now logged in.")
                    st.rerun()
                    return True
                else:
                    st.error("Invalid or expired invitation token.")
                    return False
            except Exception as e:
                error_msg = str(e)
                if "expired" in error_msg.lower():
                    st.error("This invitation link has expired. Please request a new one.")
                else:
                    st.error(f"Error accepting invitation: {error_msg}")
                return False

    return False


def render_logout_button() -> None:
    """Render logout button in sidebar or header."""
    if st.button("Logout", key="logout_button"):
        clear_auth_session()
        st.success("Logged out successfully.")
        st.rerun()
