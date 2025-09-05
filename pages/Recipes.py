# pages/Recipes.py
import streamlit as st
import pandas as pd
from datetime import datetime

from st_aggrid import AgGrid  # keep it minimal; avoid passing Enums/builders
from utils.supabase import supabase

# Optional auth guard
try:
    from utils.auth import require_auth
    require_auth()
except Exception:
    pass

st.set_page_config(page_title="Recipes", layout="wide")
st.title("📒 Recipes")

# -----------------------------
# Helpers
# -----------------------------

def get_uom_options() -> list[str]:
    res = supabase.table("ref_uom_conversion").select("from_uom, to_uom").execute()
    rows = res.data or []
    uoms = set()
    for r in rows:
        if r.get("from_uom"): uoms.add(r["from_uom"])
        if r.get("to_uom"): uoms.add(r["to_uom"])
    if not uoms:
        uoms = {"g", "ml", "unit"}
    return sorted(uoms)

def fetch_recipes(status_filter: str = "Active", type_filter: str = "All") -> list[dict]:
    q = supabase.table("recipes").select(
        "id, recipe_code, name, status, recipe_type, yield_qty, yield_uom, price"
    )
    if status_filter in ("Active", "Inactive"):
        q = q.eq("status", status_filter)
    if type_filter in ("service", "prep"):
        q = q.eq("recipe_type", type_filter)
    q = q.order("name")
    return q.execute().data or []

def fetch_summary_map(recipe_ids: list[str]) -> dict:
    if not recipe_ids:
        return {}
    res = supabase.table("recipe_summary").select(
        "recipe_id, total_cost, price, margin"
    ).in_("recipe_id", recipe_ids).execute()
    rows = res.data or []
    out = {}
    for r in rows:
        rid = r.get("recipe_id")
        if rid:
            price = float(r.get("price") or 0.0)
            cost = float(r.get("total_cost") or 0.0)
            margin = float(r.get("margin") or (price - cost))
            out[rid] = {"price": price, "total_cost": cost, "margin": margin}
    return out

def upsert_recipe(editing: bool, recipe_id: str | None, payload: dict):
    t = supabase.table("recipes")
    if editing and recipe_id:
        t.update(payload).eq("id", recipe_id).execute()
    else:
        t.insert(payload).execute()

def soft_delete_recipe(recipe_id: str):
    supabase.table("recipes").update({"status": "Inactive"}).eq("id", recipe_id).execute()

# -----------------------------
# Session keys for grid reset
# -----------------------------

if "recipes_grid_key" not in st.session_state:
    st.session_state["recipes_grid_key"] = 0

# -----------------------------
# Filters & table
# -----------------------------

colA, colB = st.columns([1.2, 1])
with colA:
    scope = st.radio("Status", options=["All", "Active", "Inactive"], index=1, horizontal=True)
with colB:
    type_scope = st.radio("Recipe Type", options=["All", "service", "prep"], index=0, horizontal=True)

rows = fetch_recipes(scope, type_scope)
df = pd.DataFrame(rows)

for c in ["id", "recipe_code", "name", "status", "recipe_type", "yield_qty", "yield_uom", "price"]:
    if c not in df.columns:
        df[c] = None

# KPIs for service recipes
summary_map = fetch_summary_map(df["id"].dropna().tolist())

def _kpi_for(rid, price, rtype):
    if rtype != "service":
        return "", ""
    s = summary_map.get(rid)
    if not s:
        return "", ""
    price = float(price or s["price"])
    cost = float(s["total_cost"])
    margin = float(s["margin"])
    cost_pct = (cost / price * 100.0) if price else 0.0
    return f"{cost_pct:.1f}%", f"${margin:.2f}"

if df.empty:
    df["Cost (% of price)"] = pd.Series(dtype="object")
    df["Margin"] = pd.Series(dtype="object")
else:
    df["Cost (% of price)"], df["Margin"] = zip(*[
        _kpi_for(row.get("id"), row.get("price"), row.get("recipe_type"))
        for _, row in df.iterrows()
    ])

display_cols = [
    "id", "recipe_code", "name", "status", "recipe_type",
    "yield_qty", "yield_uom", "price", "Cost (% of price)", "Margin"
]
table_df = df.reindex(columns=display_cols).copy()

# ---- PLAIN JSON gridOptions (no Python functions/enums) ----
grid_options = {
    "defaultColDef": {
        "sortable": True,
        "filter": True,
        "resizable": True,
        "floatingFilter": True,
    },
    "columnDefs": [{"field": c} for c in table_df.columns],
    "rowSelection": "single",
    "suppressRowClickSelection": False,
}

grid = AgGrid(
    table_df,
    gridOptions=grid_options,
    update_mode="SELECTION_CHANGED",        # pass strings (not Enums)
    data_return_mode="FILTERED_AND_SORTED", # pass strings (not Enums)
    fit_columns_on_grid_load=True,
    height=460,
    key=f"recipes_grid_{st.session_state['recipes_grid_key']}",
    allow_unsafe_jscode=False,              # keep clean
    enable_enterprise_modules=False,
)

sel = grid.get("selected_rows", [])
selected_id = sel[0]["id"] if sel and "id" in sel[0] else None

st.divider()

# -----------------------------
# Sidebar form (Add / Update / Delete / Clear)
# -----------------------------

uom_options = ["— Select —"] + get_uom_options()
status_options = ["Active", "Inactive"]
type_options = ["service", "prep"]

with st.sidebar:
    st.subheader("✏️ Add or Edit Recipe")

    editing = selected_id is not None
    if editing:
        current = df[df["id"] == selected_id].iloc[0].to_dict()
    else:
        current = {
            "recipe_code": "",
            "name": "",
            "status": "Active",
            "recipe_type": "service",
            "yield_qty": 1.0,
            "yield_uom": None,
            "price": 0.0,
        }

    with st.form("recipe_form", clear_on_submit=True):
        recipe_code = st.text_input("Code", value=current.get("recipe_code") or "")
        name = st.text_input("Name", value=current.get("name") or "")
        status_val = st.selectbox("Status", options=status_options, index=status_options.index(current.get("status", "Active")))
        recipe_type = st.selectbox("Recipe Type", options=type_options, index=type_options.index(current.get("recipe_type", "service")))

        c1, c2 = st.columns(2)
        yield_qty = c1.number_input("Yield Qty", min_value=0.0, step=0.1, value=float(current.get("yield_qty") or 1.0))

        default_uom = current.get("yield_uom")
        if default_uom is None or default_uom not in uom_options:
            default_uom = "— Select —"
        yield_uom = c2.selectbox("Yield UOM", options=uom_options, index=uom_options.index(default_uom))

        price_val = st.number_input(
            "Price",
            min_value=0.0, step=0.25,
            value=float(current.get("price") or 0.0),
            disabled=(recipe_type == "prep"),
        )

        col1, col2, col3 = st.columns(3)
        add_or_update = col1.form_submit_button("Update" if editing else "Add Recipe")
        delete_btn    = col2.form_submit_button("Delete", disabled=(not editing))
        clear_btn     = col3.form_submit_button("Clear")

        def _validate():
            errs = []
            if not recipe_code:
                errs.append("Code")
            if not name:
                errs.append("Name")
            if yield_uom == "— Select —":
                errs.append("Yield UOM")
            return errs

        if delete_btn and editing:
            soft_delete_recipe(selected_id)
            st.success("Recipe archived.")
            st.session_state["recipes_grid_key"] += 1
            st.experimental_rerun()

        if clear_btn:
            st.session_state["recipes_grid_key"] += 1
            st.experimental_rerun()

        if add_or_update:
            missing = _validate()
            if missing:
                st.error(f"Please complete: {', '.join(missing)}")
            else:
                payload = {
                    "recipe_code": recipe_code.strip(),
                    "name": name.strip(),
                    "status": status_val,
                    "recipe_type": recipe_type,
                    "yield_qty": round(float(yield_qty), 3),
                    "yield_uom": None if yield_uom == "— Select —" else yield_uom,
                    "price": 0.0 if recipe_type == "prep" else round(float(price_val), 2),
                }
                upsert_recipe(editing, selected_id, payload)
                st.success("Recipe saved.")
                st.session_state["recipes_grid_key"] += 1
                st.experimental_rerun()

# -----------------------------
# CSV export (table view)
# -----------------------------

st.markdown("### 📥 Export recipes")
# Prefer the grid's filtered/sorted data when available
export_df = pd.DataFrame(grid.get("data", []))
if export_df.empty:
    export_df = table_df.copy()

export_df = export_df.drop(columns=["id"], errors="ignore")
ts = datetime.now().strftime("%Y-%m-%d_%H-%M")
st.download_button(
    label="Download CSV",
    data=export_df.to_csv(index=False),
    file_name=f"recipes_{scope.lower()}_{type_scope.lower()}_{ts}.csv",
    mime="text/csv",
)
