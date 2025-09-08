# pages/Recipes.py
# == CHANGELOG (2025-09-08 / Group A) =========================================
# + Added: Status (All/Active/Inactive) and Type (All/Service/Prep) filters,
#          now rendered horizontally with no extra tooltips.
# + Added: KPI columns: Price, Total Cost, Cost %, Margin with formatting.
# + Added: CSV export that mirrors the visible grid (current filters + sort),
#          timestamped filename; disabled when empty with inline hint.
# ~ Changed: AgGrid modes to reflect live filtered/sorted data; apply grid sort
#            model explicitly to export if needed.
# - Removed: Prior blue "no rows" info banner (rely on grid's "No Rows To Show").
# =============================================================================

import streamlit as st
import pandas as pd
from datetime import datetime

from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode, DataReturnMode, JsCode
from utils.supabase import supabase

# Auth (kept as-is)
try:
    from utils.auth import require_auth
    require_auth()
except Exception:
    pass

st.set_page_config(page_title="Recipes", layout="wide")
st.title("📘 Recipes")

# -----------------------------
# Helpers
# -----------------------------

def fetch_recipes_df() -> pd.DataFrame:
    """Load base recipes using new schema fields."""
    res = supabase.table("recipes").select(
        "id, recipe_code, name, status, recipe_type, recipe_category, yield_qty, yield_uom, price"
    ).order("name").execute()
    df = pd.DataFrame(res.data or [])
    must_have = ["id", "recipe_code", "name", "status", "recipe_type",
                 "recipe_category", "yield_qty", "yield_uom", "price"]
    for c in must_have:
        if c not in df.columns:
            df[c] = None
    if not df.empty:
        for c in ("yield_qty", "price"):
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df


def fetch_recipe_summary_map() -> pd.DataFrame:
    """
    Pull summary rows (by recipe_id) for cost aggregation.
    We rely only on: recipe_id, total_cost (view may evolve).
    """
    res = supabase.table("recipe_summary").select("recipe_id, total_cost").execute()
    s = pd.DataFrame(res.data or [])
    if "total_cost" not in s.columns:
        s["total_cost"] = None
    return s


def assemble_grid_df(base_df: pd.DataFrame, summary_df: pd.DataFrame) -> pd.DataFrame:
    """
    Merge base recipes with summary costs, compute KPIs as numerics:
      cost_pct  = (total_cost/price)*100  (1 decimal)
      margin    = price - total_cost      (2 decimals)
    Keep numerics numeric for proper sorting; we add display formatting via AG Grid.
    """
    if base_df.empty:
        return pd.DataFrame(columns=[
            "recipe_code","name","status","recipe_type","recipe_category",
            "yield_qty","yield_uom","price","total_cost","cost_pct","margin"
        ])

    df = base_df.copy()
    s  = summary_df.rename(columns={"recipe_id": "id"}).copy()
    df = df.merge(s, on="id", how="left")

    def safe_ratio(cost, price):
        if pd.isna(cost) or pd.isna(price) or price is None or price <= 0:
            return None
        return round(float(cost) / float(price) * 100.0, 1)

    def safe_margin(cost, price):
        if pd.isna(cost) or pd.isna(price):
            return None
        return round(float(price) - float(cost), 2)

    df["cost_pct"] = df.apply(lambda r: safe_ratio(r.get("total_cost"), r.get("price")), axis=1)
    df["margin"]   = df.apply(lambda r: safe_margin(r.get("total_cost"), r.get("price")), axis=1)

    ordered = [
        "recipe_code","name","status","recipe_type","recipe_category",
        "yield_qty","yield_uom","price","total_cost","cost_pct","margin"
    ]
    return df[[c for c in ordered if c in df.columns]]


# -----------------------------
# Filters (horizontal, no tooltips)
# -----------------------------
f1, f2, _ = st.columns([1,1,1])

with f1:
    status_filter = st.radio(
        "Status",
        options=["All", "Active", "Inactive"],
        index=1,  # default Active
        horizontal=True,
    )

with f2:
    type_filter = st.radio(
        "Type",
        options=["All", "service", "prep"],
        index=0,
        horizontal=True,
    )

# -----------------------------
# Fetch & Filter
# -----------------------------
base_df    = fetch_recipes_df()
summary_df = fetch_recipe_summary_map()

if status_filter != "All":
    base_df = base_df[base_df["status"] == status_filter]
if type_filter != "All":
    base_df = base_df[base_df["recipe_type"] == type_filter]

grid_source_df = assemble_grid_df(base_df, summary_df)
display_df = grid_source_df.copy()  # may be empty; grid will show "No Rows To Show"

# -----------------------------
# Grid config (formatting via valueFormatter, sorting stays numeric)
# -----------------------------
gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)

# Right-align numerics
for col in ("yield_qty","price","total_cost","cost_pct","margin"):
    if col in display_df.columns:
        gb.configure_column(col, cellStyle={"textAlign": "right"})

# Friendly headers + value formatters (keep underlying dtype numeric)
fmt_currency_2 = JsCode("""function(params){ 
    if(params.value===null || params.value===undefined) return '';
    return '$' + Number(params.value).toFixed(2);
}""")
fmt_currency_5 = JsCode("""function(params){ 
    if(params.value===null || params.value===undefined) return '';
    return '$' + Number(params.value).toFixed(5);
}""")
fmt_percent_1 = JsCode("""function(params){ 
    if(params.value===null || params.value===undefined) return '';
    return Number(params.value).toFixed(1) + '%';
}""")

if "price" in display_df.columns:
    gb.configure_column("price", header_name="Price", valueFormatter=fmt_currency_2)
if "total_cost" in display_df.columns:
    gb.configure_column("total_cost", header_name="Total Cost", valueFormatter=fmt_currency_5)
if "cost_pct" in display_df.columns:
    gb.configure_column("cost_pct", header_name="Cost %", valueFormatter=fmt_percent_1)
if "margin" in display_df.columns:
    gb.configure_column("margin", header_name="Margin", valueFormatter=fmt_currency_2)

grid_options = gb.build()

# Return filtered data; update on filter/sort model changes
grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    data_return_mode=DataReturnMode.FILTERED,
    update_mode=GridUpdateMode.MODEL_CHANGED,
    fit_columns_on_grid_load=True,
    height=600,
    allow_unsafe_jscode=True,
)

# -----------------------------
# Export (mirror filters + sort)
# -----------------------------
st.markdown("### 📤 Export Recipes")

# Data as currently filtered in the grid:
export_snapshot = grid_response.get("data", pd.DataFrame())
if isinstance(export_snapshot, list):
    export_snapshot = pd.DataFrame(export_snapshot)
if export_snapshot is None:
    export_snapshot = pd.DataFrame()

# Try to mirror the grid's *sort model* explicitly (some st-aggrid builds don't apply sort to `data`)
grid_state = grid_response.get("grid_state", {}) or {}
sort_model = (
    grid_state.get("sortModel") or  # ag-Grid naming
    grid_state.get("sort") or       # some st-aggrid versions
    []
)

# Apply sort model to the snapshot if present
if isinstance(export_snapshot, pd.DataFrame) and not export_snapshot.empty and isinstance(sort_model, list) and len(sort_model) > 0:
    by_cols = []
    ascending = []
    for s in sort_model:
        col_id = s.get("colId") or s.get("col_id")
        direction = s.get("sort") or s.get("direction") or "asc"
        if col_id and col_id in export_snapshot.columns:
            by_cols.append(col_id)
            ascending.append(direction == "asc")
    if by_cols:
        export_snapshot = export_snapshot.sort_values(by=by_cols, ascending=ascending, kind="mergesort")

# Build export DF with friendly headers; keep values numeric (no $ or % in CSV)
export_df = export_snapshot.copy()
rename_map = {
    "price": "Price",
    "total_cost": "Total Cost",
    "cost_pct": "Cost %",
    "margin": "Margin",
    "recipe_code": "Recipe Code",
    "recipe_type": "Recipe Type",
    "recipe_category": "Recipe Category",
    "yield_qty": "Yield Quantity",
    "yield_uom": "Yield UOM",
    "status": "Status",
    "name": "Name",
}
export_df.rename(columns={k: v for k, v in rename_map.items() if k in export_df.columns}, inplace=True)

ts = datetime.now().strftime("%Y%m%d-%H%M")
fname = f"recipes_{status_filter.lower()}_{type_filter.lower()}_{ts}.csv"

is_empty = export_df.empty
btn = st.download_button(
    label="⬇️ Download CSV (matches grid)",
    data=(export_df.to_csv(index=False) if not is_empty else "".encode("utf-8")),
    file_name=fname,
    mime="text/csv",
    disabled=is_empty,
)
if is_empty:
    st.caption("Export is disabled because there are no rows in the current view.")

# -----------------------------
# Selection → Sidebar Form (preserved; Group B will enhance)
# -----------------------------
selected_row = grid_response.get("selected_rows")
edit_data = None
if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_code = selected_row.iloc[0].get("recipe_code")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_code = selected_row[0].get("recipe_code")
    else:
        selected_code = None

    if selected_code:
        match = base_df[base_df["recipe_code"] == selected_code]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

with st.sidebar:
    st.subheader("➕ Add or Edit Recipe")
    # NOTE: Group B will convert UOM input + price disable + inline buttons, etc.
    with st.form("recipe_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Recipe Code", value=edit_data.get("recipe_code", "") if edit_mode else "")

        status_options = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_index = status_options.index(selected_status) if selected_status in status_options else 0
        status = st.selectbox("Status", status_options, index=status_index)
        status = status if status != "— Select —" else None

        type_options = ["— Select —", "service", "prep"]
        selected_type = edit_data.get("recipe_type") if edit_mode else None
        type_index = type_options.index(selected_type) if selected_type in type_options else 0
        recipe_type = st.selectbox(
            "Recipe Type",
            type_options,
            index=type_index,
        )
        recipe_type = recipe_type if recipe_type != "— Select —" else None

        recipe_category = st.text_input("Recipe Category", value=edit_data.get("recipe_category", "") if edit_mode else "")

        yield_qty = st.number_input(
            "Yield Quantity",
            min_value=0.0, step=0.1,
            value=float(edit_data.get("yield_qty", 1.0)) if edit_mode and edit_data.get("yield_qty") is not None else 1.0
        )
        yield_uom = st.text_input("Yield UOM", value=edit_data.get("yield_uom", "") if edit_mode else "")

        price = st.number_input(
            "Price",
            min_value=0.0, step=0.01,
            value=float(edit_data.get("price", 0.0)) if edit_mode and edit_data.get("price") is not None else 0.0
        )

        submitted = st.form_submit_button("Save Recipe")
        errors = []
        if not name:
            errors.append("Name")
        if not code:
            errors.append("Recipe Code")
        if not status:
            errors.append("Status")
        if not recipe_type:
            errors.append("Recipe Type")
        if not yield_uom:
            errors.append("Yield UOM")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete the following fields: {', '.join(errors)}")
            else:
                if not edit_mode:
                    existing = supabase.table("recipes").select("id").eq("recipe_code", code).execute()
                    if existing.data:
                        st.error("❌ Recipe code already exists.")
                        st.stop()

                payload = {
                    "name": name,
                    "recipe_code": code,
                    "status": status,
                    "recipe_category": recipe_category or None,
                    "yield_qty": round(float(yield_qty), 6),
                    "yield_uom": yield_uom,
                    "price": round(float(price), 6),
                    "recipe_type": recipe_type
                }

                try:
                    if edit_mode:
                        supabase.table("recipes").update(payload).eq("id", edit_data["id"]).execute()
                        st.success("Recipe updated.")
                    else:
                        supabase.table("recipes").insert(payload).execute()
                        st.success("Recipe added.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Failed to save recipe: {e}")
