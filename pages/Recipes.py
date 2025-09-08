# pages/Recipes.py
# == CHANGELOG (2025-09-08 / Group A) =========================================
# + Added: Status (All/Active/Inactive) and Type (All/Service/Prep) filters.
# + Added: KPI columns in the grid: Cost (% of price) and Margin ($).
# + Added: CSV export that mirrors the current grid (filters + sort) with
#          a timestamped filename and empty-state safeguards.
# ~ Changed: AgGrid update/data-return modes so export uses the live grid data.
# ~ Changed: Data assembly to merge recipe rows with recipe_summary for KPIs.
# - Removed: Nothing. Form code and previous layout kept intact by design.
# =============================================================================

import streamlit as st
import pandas as pd
from datetime import datetime

from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode, DataReturnMode
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
    """
    Load base recipe rows from DB. Uses new schema fields: yield_qty, yield_uom, recipe_type.
    """
    res = supabase.table("recipes").select(
        "id, recipe_code, name, status, recipe_type, recipe_category, yield_qty, yield_uom, price"
    ).order("name").execute()
    df = pd.DataFrame(res.data or [])
    # Ensure expected columns exist even if DB lags; keeps UI resilient.
    must_have = ["id", "recipe_code", "name", "status", "recipe_type",
                 "recipe_category", "yield_qty", "yield_uom", "price"]
    for c in must_have:
        if c not in df.columns:
            df[c] = None
    # Normalize numerics
    if not df.empty:
        for c in ("yield_qty", "price"):
            try:
                df[c] = pd.to_numeric(df[c], errors="coerce")
            except Exception:
                pass
    return df


def fetch_recipe_summary_map() -> pd.DataFrame:
    """
    Pulls summary rows (by recipe_id) so we can compute KPIs on the grid.
    View shape may vary; we only rely on: recipe_id, total_cost.
    If cost_pct/margin exist, we still recompute to keep math consistent.
    """
    res = supabase.table("recipe_summary").select(
        "recipe_id, total_cost"
    ).execute()
    s = pd.DataFrame(res.data or [])
    if "total_cost" not in s.columns:
        s["total_cost"] = None
    return s


def assemble_grid_df(base_df: pd.DataFrame, summary_df: pd.DataFrame) -> pd.DataFrame:
    """
    Merge base recipes with summary costs, compute KPIs.
    - cost_pct: (total_cost / price) * 100  (rounded to 1 decimal)
    - margin:   price - total_cost          (rounded to 2 decimals)
    """
    if base_df.empty:
        return pd.DataFrame(columns=[
            "recipe_code", "name", "status", "recipe_type", "recipe_category",
            "yield_qty", "yield_uom", "price", "total_cost", "cost_pct", "margin"
        ])

    df = base_df.copy()
    s = summary_df.copy()

    # Merge summary on id -> recipe_id
    df = df.merge(
        s.rename(columns={"recipe_id": "id"}),
        on="id", how="left"
    )

    # Compute KPIs safely
    def safe_ratio(cost, price):
        if pd.isna(cost) or pd.isna(price) or price is None or price <= 0:
            return None
        try:
            return round((float(cost) / float(price)) * 100.0, 1)
        except Exception:
            return None

    def safe_margin(cost, price):
        if pd.isna(cost) or pd.isna(price):
            return None
        try:
            return round(float(price) - float(cost), 2)
        except Exception:
            return None

    df["cost_pct"] = df.apply(lambda r: safe_ratio(r.get("total_cost"), r.get("price")), axis=1)
    df["margin"]   = df.apply(lambda r: safe_margin(r.get("total_cost"), r.get("price")), axis=1)

    # Display order (we keep numerics as numerics for proper sorting)
    ordered_cols = [
        "recipe_code", "name", "status", "recipe_type", "recipe_category",
        "yield_qty", "yield_uom", "price", "total_cost", "cost_pct", "margin"
    ]
    # Keep only what exists
    ordered_cols = [c for c in ordered_cols if c in df.columns]
    return df[ordered_cols]


def empty_info(message="No recipes match the current filters."):
    st.info(message)


# -----------------------------
# Filters (Group A)
# -----------------------------
# Default behavior: show Active by default; type defaults to All.
filters_col1, filters_col2, filters_col3 = st.columns([1, 1, 6])

with filters_col1:
    status_filter = st.radio(
        "Status",
        options=["Active", "All", "Inactive"],  # default Active
        index=0,
        horizontal=False,
        help="Show recipes by status. Export is disabled on empty results."
    )

with filters_col2:
    type_filter = st.radio(
        "Type",
        options=["All", "service", "prep"],
        index=0,
        horizontal=False,
        help="Filter by recipe type (service/prep)."
    )

with filters_col3:
    st.markdown(" ")  # spacer for layout


# -----------------------------
# Fetch & Filter
# -----------------------------
base_df = fetch_recipes_df()
summary_df = fetch_recipe_summary_map()

# Apply status filter
if status_filter != "All":
    base_df = base_df[base_df["status"] == status_filter]

# Apply type filter
if type_filter != "All":
    base_df = base_df[base_df["recipe_type"] == type_filter]

grid_source_df = assemble_grid_df(base_df, summary_df)

# Empty-safe handling up front
if grid_source_df.empty:
    empty_info()
    # We still render an empty grid so UI layout stays stable
    display_df = pd.DataFrame(columns=[
        "recipe_code", "name", "status", "recipe_type", "recipe_category",
        "yield_qty", "yield_uom", "price", "total_cost", "cost_pct", "margin"
    ])
else:
    display_df = grid_source_df.copy()

# -----------------------------
# AgGrid Table
# -----------------------------
gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)

# Single selection (kept as-is for integration with the sidebar form below)
gb.configure_selection("single", use_checkbox=False)

# Right-align numeric-looking columns
for col in ("yield_qty", "price", "total_cost", "cost_pct", "margin"):
    if col in display_df.columns:
        gb.configure_column(col, cellStyle={"textAlign": "right"})

# Friendly headers for KPI columns
if "cost_pct" in display_df.columns:
    gb.configure_column("cost_pct", header_name="Cost (% of price)")
if "margin" in display_df.columns:
    gb.configure_column("margin", header_name="Margin ($)")

grid_options = gb.build()

# IMPORTANT for CSV mirroring:
# - DataReturnMode.FILTERED ensures grid_response["data"] reflects the visible rows (filters).
# - GridUpdateMode.MODEL_CHANGED so the returned data updates on sort/filter changes.
grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    data_return_mode=DataReturnMode.FILTERED,
    update_mode=GridUpdateMode.MODEL_CHANGED,
    fit_columns_on_grid_load=True,
    height=600,
    allow_unsafe_jscode=True
)

# -----------------------------
# CSV Export (mirror the grid)
# -----------------------------
st.markdown("### 📤 Export Recipes")

# grid_response["data"] mirrors the current grid (filtered + current sort if provided by ag-grid)
export_snapshot = grid_response.get("data", pd.DataFrame())
is_empty = export_snapshot is None or (isinstance(export_snapshot, pd.DataFrame) and export_snapshot.empty)

if isinstance(export_snapshot, list):
    export_snapshot = pd.DataFrame(export_snapshot)

# Build a tidy export frame with readable headers
export_df = export_snapshot.copy()

# NOTE: keep numerics numeric so CSV is machine-friendly; headers are friendly via rename:
rename_map = {}
if "cost_pct" in export_df.columns:
    rename_map["cost_pct"] = "cost_pct_of_price"
if "margin" in export_df.columns:
    rename_map["margin"] = "margin_dollar"

export_df.rename(columns=rename_map, inplace=True)

# Filename encodes filter state and timestamp
ts = datetime.now().strftime("%Y%m%d-%H%M")
fname = f"recipes_{status_filter.lower()}_{type_filter.lower()}_{ts}.csv"

st.download_button(
    label="⬇️ Download CSV (matches grid)",
    data=(export_df.to_csv(index=False) if not is_empty else "".encode("utf-8")),
    file_name=fname,
    mime="text/csv",
    disabled=is_empty,   # Disable when no rows to avoid confusion
    help="Exports exactly what you see in the grid (current filters & sort)."
)

# -----------------------------
# Selection → Sidebar Form (kept from prior behavior; no Group A changes below)
# -----------------------------

# NOTE: AgGrid may return selected rows as list[dict] or as DataFrame
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

# -----------------------------
# Sidebar Form (Add / Edit) — preserved for Group A
# -----------------------------
with st.sidebar:
    st.subheader("➕ Add or Edit Recipe")

    with st.form("recipe_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Recipe Code", value=edit_data.get("recipe_code", "") if edit_mode else "")

        status_options = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_index = status_options.index(selected_status) if selected_status in status_options else 0
        status = st.selectbox("Status", status_options, index=status_index)
        status = status if status != "— Select —" else None

        # recipe_type (required) — kept as-is for now (Group B will add UOM logic)
        type_options = ["— Select —", "service", "prep"]
        selected_type = edit_data.get("recipe_type") if edit_mode else None
        type_index = type_options.index(selected_type) if selected_type in type_options else 0
        recipe_type = st.selectbox(
            "Recipe Type",
            type_options,
            index=type_index,
            help="Prep recipes are used as ingredients in other recipes. Service recipes are sold to customers."
        )
        recipe_type = recipe_type if recipe_type != "— Select —" else None

        recipe_category = st.text_input("Recipe Category", value=edit_data.get("recipe_category", "") if edit_mode else "")

        # Renamed fields: yield_qty / yield_uom (Group B will convert this to a dropdown)
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
                # Uniqueness check on code for INSERT path
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
