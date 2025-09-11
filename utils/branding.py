import streamlit as st
from utils import tenant_db as db

@st.cache_data(ttl=60)
def load_branding():
    r = db.table("tenants").select("logo_url,brand_primary,brand_secondary").limit(1).execute()
    row = (r.data or [{}])[0]
    return {
        "logo_url": row.get("logo_url"),
        "primary": row.get("brand_primary", "#111827"),
        "secondary": row.get("brand_secondary", "#6b7280"),
    }

def apply_branding_to_sidebar():
    b = load_branding()
    if b["logo_url"]:
        st.sidebar.image(b["logo_url"], use_column_width=True)
