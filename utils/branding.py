import json
import streamlit as st
from pathlib import Path
from utils import tenant_db as db
from utils.tenant_state import get_active_tenant

CONFIG_PATH = Path("config/branding_config.json")

@st.cache_data(ttl=60)
def _load_json_fallback():
    try:
        if CONFIG_PATH.exists():
            return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception:
        pass
    return {
        "logo_url": None,
        "brand_primary": "#111827",
        "brand_secondary": "#6b7280",
    }

@st.cache_data(ttl=60)
def _load_branding_for(tenant_id: str):
    r = db.table("tenants").select("logo_url,brand_primary,brand_secondary").eq("id", tenant_id).limit(1).execute()
    row = (r.data or [{}])[0]
    fb = _load_json_fallback()
    return {
        "logo_url": row.get("logo_url") or fb.get("logo_url"),
        "primary": row.get("brand_primary") or fb.get("brand_primary", "#111827"),
        "secondary": row.get("brand_secondary") or fb.get("brand_secondary", "#6b7280"),
    }

def load_branding():
    tid = get_active_tenant()
    if not tid:
        return _load_json_fallback()
    return _load_branding_for(tid)

def apply_branding_to_sidebar():
    b = load_branding()
    if b.get("logo_url"):
        st.sidebar.image(b["logo_url"], use_column_width=True)

def inject_brand_colors():
    b = load_branding()
    primary = b["primary"]
    secondary = b["secondary"]
    st.markdown(
        f"""
        <style>
        :root {{
            --brand-primary: {primary};
            --brand-secondary: {secondary};
        }}
        /* Buttons */
        .stButton > button {{
          background: var(--brand-primary) !important;
          color: #fff !important;
          border: 1px solid rgba(0,0,0,0.05) !important;
        }}
        .stButton > button:hover {{
          filter: brightness(0.92);
        }}
        /* Links & focus colors can adopt secondary */
        a, a:visited {{
          color: var(--brand-secondary);
        }}
        /* Optional: selected row shading for AgGrid (subtle) */
        .ag-theme-streamlit .ag-row-selected {{
          background-color: #0000000f !important;
        }}
        </style>
        """,
        unsafe_allow_html=True,
    )
