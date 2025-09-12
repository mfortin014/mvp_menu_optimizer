# utils/branding.py
import json
import streamlit as st
from pathlib import Path
from utils import tenant_db as db
from utils.tenant_state import get_active_tenant

CONFIG_PATH = Path("config/branding_config.json")
_DEFAULT_PRIMARY = "#111827"
_DEFAULT_SECONDARY = "#6b7280"

@st.cache_data(ttl=60)
def _load_json_fallback():
    try:
        if CONFIG_PATH.exists():
            return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception:
        pass
    # accept both shapes for safety
    return {
        "logo_url": None,
        "primary": _DEFAULT_PRIMARY,
        "secondary": _DEFAULT_SECONDARY,
        "brand_primary": _DEFAULT_PRIMARY,
        "brand_secondary": _DEFAULT_SECONDARY,
    }

def _normalize(logo_url, prim, sec, fb):
    primary = prim or fb.get("brand_primary") or fb.get("primary") or _DEFAULT_PRIMARY
    secondary = sec or fb.get("brand_secondary") or fb.get("secondary") or _DEFAULT_SECONDARY
    logo = logo_url or fb.get("logo_url")
    return {"logo_url": logo, "primary": primary, "secondary": secondary}

@st.cache_data(ttl=60)
def load_branding():
    fb = _load_json_fallback()
    tid = get_active_tenant()
    if not tid:
        return _normalize(None, None, None, fb)

    r = db.table("tenants").select("logo_url,brand_primary,brand_secondary").eq("id", tid).limit(1).execute()
    row = (r.data or [{}])[0]
    return _normalize(
        row.get("logo_url"),
        row.get("brand_primary"),
        row.get("brand_secondary"),
        fb,
    )

def apply_branding_to_sidebar():
    b = load_branding()
    if b.get("logo_url"):
        st.sidebar.image(b["logo_url"], use_column_width=True)

def inject_brand_colors():
    b = load_branding()
    primary = b.get("primary") or _DEFAULT_PRIMARY
    secondary = b.get("secondary") or _DEFAULT_SECONDARY
    st.markdown(
        f"""
        <style>
        :root {{
            --brand-primary: {primary};
            --brand-secondary: {secondary};
        }}
        .stButton > button {{
          background: var(--brand-primary) !important;
          color: #fff !important;
          border: 1px solid rgba(0,0,0,0.05) !important;
        }}
        .stButton > button:hover {{ filter: brightness(0.92); }}
        a, a:visited {{ color: var(--brand-secondary); }}
        .ag-theme-streamlit .ag-row-selected {{ background-color: #0000000f !important; }}
        </style>
        """,
        unsafe_allow_html=True,
    )
