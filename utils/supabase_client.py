# utils/supabase_client.py
from __future__ import annotations

from supabase import Client, create_client

from utils.secrets import get as get_secret

SUPABASE_URL = get_secret("SUPABASE_URL", required=True)
SUPABASE_ANON_KEY = get_secret("SUPABASE_ANON_KEY", required=True)
SUPABASE_SERVICE_KEY = get_secret("SUPABASE_SERVICE_KEY", required=False)

# Anonymous client (for unauthenticated operations)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)


def get_authenticated_client(access_token: str) -> Client:
    """
    Create an authenticated Supabase client using a JWT access token.

    Args:
        access_token: JWT access token from Supabase Auth

    Returns:
        Authenticated Supabase client
    """
    # Create a new client instance
    client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

    # Set the Authorization header on the postgrest client's session
    # This is the internal HTTP client that Supabase uses
    if hasattr(client, "postgrest") and hasattr(client.postgrest, "session"):
        if hasattr(client.postgrest.session, "headers"):
            client.postgrest.session.headers.update(
                {"Authorization": f"Bearer {access_token}", "apikey": SUPABASE_ANON_KEY}
            )
        elif hasattr(client.postgrest, "headers"):
            # Alternative location for headers
            client.postgrest.headers.update(
                {"Authorization": f"Bearer {access_token}", "apikey": SUPABASE_ANON_KEY}
            )

    return client


def get_admin_client() -> Client:
    """
    Create an admin Supabase client using the service role key.
    This bypasses RLS and should only be used for admin operations.

    Returns:
        Admin Supabase client with service role key

    Raises:
        RuntimeError: If SUPABASE_SERVICE_KEY is not configured
    """
    if not SUPABASE_SERVICE_KEY:
        raise RuntimeError("SUPABASE_SERVICE_KEY is not configured. Required for admin operations.")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


__all__ = [
    "supabase",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "get_authenticated_client",
    "get_admin_client",
]
