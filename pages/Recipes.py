# pages/Recipes.py
import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from utils.supabase import supabase

# Optional auth guard for your environment
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
    """Collect unique UOMs from ref_uom_conversion (both from_uom and to_uom)."""
    res = supabase.table("ref_uom_conversion").select("from_uom, to_uom").execute()
    rows = res.data or []
    uoms = set()
    for r in rows:
        if r.get("from_uom"): uoms.add(r["from_uom"])
        if r.get("to_uom"): uoms.add(r["to_uom"])
    # sensible fallbacks if table is sparse
    if not uoms:
        uoms = {"g", "ml", "unit"}
    return sorted(uoms)

def fetch_recipes(status_filter: str = "Active") -> list[dict]:
    q = supabase.table("recipes").select(
        "id, recipe_code, name, status, recipe_type, yield_qty, yield_uom, price"
    )
    if status_filter == "Active":
        q = q.eq("status", "Active")
    q = q.order("name")
    return q.execute().data or []

def upsert_recipe(editing: bool, recipe_id: str | None, payload: dict):
    t = supabase.table("recipes")
    if editing and recipe_id:
        t.update(payload).eq("id", recipe_id).execute()
    else:
        t.insert(payload).execute()

def soft_delete_recipe(recipe_id: str):
    supabase.table("recipes").update({"status": "Inactive"}).eq("id", recipe_id).execute()

# -----------------------------
# Filters & table
# -----------------------------

left, right = st.columns([3, 1])
with right:
    scope = st.radio("Scope", options=["Active", "All"], index=0, horizontal=True)

rows = fetch_recipes(scope)
df = pd.DataFrame(rows)

# Ensure table columns exist even if empty
for c in ["id", "recipe_code", "name", "status", "recipe_type", "yield_qty", "yield_uom", "price"]:
    if c not in df.columns:
        df[c] = None

display_cols = ["recipe_code", "name", "status", "recipe_type", "yield_qty", "yield_uom", "price"]
table_df = df.reindex(columns=display_cols).copy()

gb = GridOptionsBuilder.from_dataframe(table_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
grid_options = gb.build()

grid = AgGrid(
    table_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=420,
)

# Map selected row back to full df to get the id
sel = grid.get("selected_rows", [])
sel_df = pd.DataFrame(sel)
selected_id = None
if not sel_df.empty:
    # match on a stable column; recipe_code+name is often unique, but safest is index to original df
    key_cols = ["recipe_code", "name"]
    mask = pd.Series([True] * len(df))
    for c in key_cols:
        if c in df.columns and c in sel_df.columns:
            mask &= (df[c] == sel_df.iloc[0].get(c))
    match = df[mask]
    if not match.empty:
        selected_id = match.iloc[0].get("id")

st.divider()

# -----------------------------
# Sidebar form (Add / Update / Delete / Clear)
# -----------------------------

uom_options = ["— Select —"] + get_uom_options()
status_options = ["Active", "Inactive"]
type_options = ["service", "prep"]

with st.sidebar:
    st.subheader("✏️ Add or Edit Recipe")

    # If a recipe is selected, preload values
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

    with st.form("recipe_form", clear_on_submit=False):
        recipe_code = st.text_input("Code", value=current.get("recipe_code") or "")
        name = st.text_input("Name", value=current.get("name") or "")
        status_val = st.selectbox("Status", options=status_options, index=status_options.index(current.get("status", "Active")))
        recipe_type = st.selectbox("Recipe Type", options=type_options, index=type_options.index(current.get("recipe_type", "service")))
        col_a, col_b = st.columns(2)
        yield_qty = col_a.number_input("Yield Qty", min_value=0.0, step=0.1, value=float(current.get("yield_qty") or 1.0))
        # UOM is dropdown from conversion table
        default_uom = current.get("yield_uom")
        if default_uom not in uom_options:
            default_uom = "— Select —"
        yield_uom = col_b.selectbox("Yield UOM", options=uom_options, index=uom_options.index(default_uom))

        price_val = st.number_input("Price (only relevant for service recipes)", min_value=0.0, step=0.25, value=float(current.get("price") or 0.0))

        # Buttons: Add (no selection) or Update/Delete/Clear (editing)
        add_btn = update_btn = delete_btn = clear_btn = False
        if editing:
            col1, col2, col3 = st.columns(3)
            update_btn = col1.form_submit_button("Update")
            delete_btn = col2.form_submit_button("Delete (soft)")
            clear_btn  = col3.form_submit_button("Clear")
        else:
            add_btn = st.form_submit_button("Add Recipe")

        # Actions
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
            st.success("Recipe archived (status = Inactive).")
            st.experimental_rerun()

        if clear_btn and editing:
            st.experimental_rerun()

        if add_btn or (update_btn and editing):
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
                    "price": round(float(price_val), 2),
                }
                upsert_recipe(editing and update_btn, selected_id, payload)
                st.success("Recipe saved.")
                st.experimental_rerun()

# -----------------------------
# CSV export (table view)
# -----------------------------

st.markdown("### 📥 Export recipes")
export_df = table_df.copy()
st.download_button(
    label="Download CSV",
    data=export_df.to_csv(index=False),
    file_name=f"recipes_{scope.lower()}.csv",
    mime="text/csv",
)
