# utils/supabase_client.py
from __future__ import annotations

from supabase import Client, create_client

from utils.secrets import get as get_secret

SUPABASE_URL = get_secret("SUPABASE_URL", required=True)
SUPABASE_ANON_KEY = get_secret("SUPABASE_ANON_KEY", required=True)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

__all__ = ["supabase", "SUPABASE_URL", "SUPABASE_ANON_KEY"]
