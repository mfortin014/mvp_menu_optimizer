# utils/supabase.py
import os
from dotenv import load_dotenv
import streamlit as st
from supabase import create_client, Client

load_dotenv()

# Read credentials from Streamlit secrets or .env file
SUPABASE_URL = st.secrets.get("SUPABASE_URL") or os.getenv("SUPABASE_URL")
SUPABASE_KEY = st.secrets.get("SUPABASE_KEY") or os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def tenant_filter(q, tenant_id):
    return q.eq("tenant_id", tenant_id).is_("deleted_at","null")

def insert_with_tenant(client, table, payload, tenant_id):
    payload = dict(payload); payload["tenant_id"] = tenant_id
    return client.table(table).insert(payload)

def update_with_tenant(client, table, id_field, id_value, payload, tenant_id):
    payload = dict(payload); payload["tenant_id"] = tenant_id
    return client.table(table).update(payload).eq(id_field, id_value).eq("tenant_id", tenant_id)
