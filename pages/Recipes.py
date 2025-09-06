# pages/Recipes.py
import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

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
    """Collect unique UOMs from ref_uom_conversion (both from_uom and to_uom)."""
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
    """Return {recipe_id: {'total_cost': x, 'price': y, 'margin': z}} for service recipes present in recipe_summary."""
    if not recipe_ids:
        return {}
    res = supabase.table("recipe_summary").select("recipe_id, total_cost, price, margin").in_("recipe_id", recipe_ids).execute()
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
# Filters & table
# -----------------------------

colA, colB, colC = st.columns([1.2, 1, 1])

with colA:
    scope = st.radio("Status", options=["All", "Active", "Inactive"], index=1, horizontal=True)
with colB:
    type_scope = st.radio("Recipe Type", options=["All", "service", "prep"], index=0, horizontal=True)

rows = fetch_recipes(scope, type_scope)
df = pd.DataFrame(rows)

# Always ensure columns exist
for c in ["id", "recipe_code", "name", "status", "recipe_type", "yield_qty", "yield_uom", "price"]:
    if c not in df.columns:
        df[c] = None

# Enrich with KPIs for service recipes (left join to recipe_summary)
summary_map = fetch_summary_map(df["id"].dropna().tolist())
def _kpi_for(rid, price, rtype):
    if rtype != "service":
        return "", ""  # KPIs not applicable for prep on this page
    s = summary_map.get(rid)
    if not s:
        return "", ""  # no summary row yet
    price = float(price or s["price"])
    cost = float(s["total_cost"])
    margin = float(s["margin"])
    cost_pct = (cost / price * 100.0) if price else 0.0
    return f"{cost_pct:.1f}%", f"${margin:.2f}"

df["Cost (% of price)"], df["Margin"] = zip(*[
    _kpi_for(row.get("id"), row.get("price"), row.get("recipe_type"))
    for _, row in df.iterrows()
])

# Build table view (keep id hidden but present so selection is reliable)
display_cols = ["id", "recipe_code", "name", "status", "recipe_type", "yield_qty", "yield_uom", "price", "Cost (% of price)", "Margin"]
table_df = df.reindex(columns=display_cols).copy()

gb = GridOptionsBuilder.from_dataframe(table_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
gb.configure_column("id", hide=True)
grid_options = gb.build()

grid = AgGrid(
    table_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=460,
)

sel = grid.get("selected_rows", [])
sel_df = pd.DataFrame(sel)
selected_id = sel_df.iloc[0]["id"] if not sel_df.empty and "id" in sel_df.columns else None

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

    with st.form("recipe_form", clear_on_submit=False):
        recipe_code = st.text_input("Code", value=current.get("recipe_code") or "")
        name = st.text_input("Name", value=current.get("name") or "")
        status_val = st.selectbox("Status", options=status_options, index=status_options.index(current.get("status", "Active")))
        recipe_type = st.selectbox("Recipe Type", options=type_options, index=type_options.index(current.get("recipe_type", "service")))

        c1, c2 = st.columns(2)
        yield_qty = c1.number_input("Yield Qty", min_value=0.0, step=0.1, value=float(current.get("yield_qty") or 1.0))

        # Yield UOM — correctly preselect if present
        default_uom = current.get("yield_uom")
        if default_uom is None or default_uom not in uom_options:
            default_uom = "— Select —"
        yield_uom = c2.selectbox("Yield UOM", options=uom_options, index=uom_options.index(default_uom))

        # Price — disabled when recipe_type == 'prep'
        price_disabled = (recipe_type == "prep")
        price_help = None
        price_val = st.number_input(
            "Price",
            min_value=0.0, step=0.25,
            value=float(current.get("price") or 0.0),
            disabled=price_disabled,
            help=price_help
        )

        # Buttons: Add OR Update, plus Delete and Clear always shown (Delete disabled unless editing)
        add_btn = update_btn = delete_btn = clear_btn = False
        if editing:
            col1, col2, col3 = st.columns(3)
            update_btn = col1.form_submit_button("Update")
            delete_btn = col2.form_submit_button("Delete", disabled=not editing)
            clear_btn  = col3.form_submit_button("Clear")
        else:
            col1, col2 = st.columns(2)
            add_btn = col1.form_submit_button("Add Recipe")
            # Show disabled Delete even when nothing selected + Clear to reset
            delete_btn = col2.form_submit_button("Delete", disabled=True)
            clear_btn  = st.form_submit_button("Clear")

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
            st.success("Recipe archived.")
            st.rerun()

        if clear_btn:
            st.rerun()

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
                    "price": 0.0 if recipe_type == "prep" else round(float(price_val), 2),
                }
                upsert_recipe(editing and update_btn, selected_id, payload)
                st.success("Recipe saved.")
                st.rerun()

# -----------------------------
# CSV export (table view)
# -----------------------------

st.markdown("### 📥 Export recipes")
export_df = table_df.drop(columns=["id"], errors="ignore").copy()
st.download_button(
    label="Download CSV",
    data=export_df.to_csv(index=False),
    file_name=f"recipes_{scope.lower()}_{type_scope.lower()}.csv",
    mime="text/csv",
)
