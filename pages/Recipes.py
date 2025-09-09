# pages/Recipes.py
# == CHANGELOG ================================================================
# 2025-09-08 / Group A
# + Status/Type filters (horizontal), KPI columns (Price/Total Cost/Cost %/Margin),
#   CSV export mirrors current grid, disabled when empty.
#
# 2025-09-08 / Group B (fix pass)
# + Recipe Type select moved OUTSIDE the form so UOM + Price disable react instantly.
# + Service UOM list = ['Serving'] (still shows current non-Serving UOM for legacy rows).
# + Prep UOM excludes 'service'.
# + Price disables immediately when type='prep' (new or edit).
# + Buttons inline: Save / Delete / Clear; Save label simplified to 'Save'.
# ============================================================================

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
    """Pull summary rows (by recipe_id) for cost aggregation (we rely on recipe_id, total_cost)."""
    res = supabase.table("recipe_summary").select("recipe_id, total_cost").execute()
    s = pd.DataFrame(res.data or [])
    if "total_cost" not in s.columns:
        s["total_cost"] = None
    return s


def assemble_grid_df(base_df: pd.DataFrame, summary_df: pd.DataFrame) -> pd.DataFrame:
    """Merge base recipes with summary costs, compute KPIs as numerics."""
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


def fetch_uom_options() -> list:
    """Return sorted unique union of from_uom/to_uom from ref_uom_conversion."""
    res = supabase.table("ref_uom_conversion").select("from_uom, to_uom").execute()
    rows = res.data or []
    uoms = set()
    for r in rows:
        fu = r.get("from_uom"); tu = r.get("to_uom")
        if fu: uoms.add(str(fu))
        if tu: uoms.add(str(tu))
    if not uoms:
        uoms = {"Serving"}  # minimal defensive fallback; you said Serving exists
    return sorted(uoms)


def build_uom_choices(recipe_type: str | None, current_uom: str | None, all_uoms: list) -> list:
    """
    Type-aware UOM choices:
      - prep: all_uoms minus {'service'}
      - service: ['Serving'] only; ALSO include current_uom if different to display legacy rows
      - unknown: show all_uoms (put current first if present)
    """
    uoms = list(all_uoms)
    if recipe_type == "prep":
        choices = [u for u in uoms if u.lower() != "service"]
        return sorted(set(choices), key=str.lower)

    if recipe_type == "service":
        base = ["Serving"]
        if current_uom and current_uom not in base:
            base.append(current_uom)
        return base

    # Unknown / not chosen yet
    if current_uom and current_uom in uoms:
        return [current_uom] + [u for u in uoms if u != current_uom]
    return uoms


# -----------------------------
# Filters (horizontal)
# -----------------------------
f1, f2, _ = st.columns([1, 1, 1])

with f1:
    status_filter = st.radio("Status", options=["All", "Active", "Inactive"], index=1, horizontal=True)
with f2:
    type_filter = st.radio("Type", options=["All", "service", "prep"], index=0, horizontal=True)

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
display_df = grid_source_df.copy()

# -----------------------------
# Grid
# -----------------------------
gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)

# Right-align numerics
for col in ("yield_qty","price","total_cost","cost_pct","margin"):
    if col in display_df.columns:
        gb.configure_column(col, cellStyle={"textAlign": "right"})

# Formatters
fmt_currency_2 = JsCode("""function(p){ if(p.value==null) return ''; return '$'+Number(p.value).toFixed(2);}""")
fmt_currency_5 = JsCode("""function(p){ if(p.value==null) return ''; return '$'+Number(p.value).toFixed(5);}""")
fmt_percent_1  = JsCode("""function(p){ if(p.value==null) return ''; return Number(p.value).toFixed(1)+'%';}""")

if "price" in display_df.columns:      gb.configure_column("price", header_name="Price", valueFormatter=fmt_currency_2)
if "total_cost" in display_df.columns: gb.configure_column("total_cost", header_name="Total Cost", valueFormatter=fmt_currency_5)
if "cost_pct" in display_df.columns:   gb.configure_column("cost_pct", header_name="Cost %", valueFormatter=fmt_percent_1)
if "margin" in display_df.columns:     gb.configure_column("margin", header_name="Margin", valueFormatter=fmt_currency_2)

grid_options = gb.build()

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
# Export (mirrors filters; sort order not required by decision)
# -----------------------------
st.markdown("### 📤 Export Recipes")
export_snapshot = grid_response.get("data", pd.DataFrame())
if isinstance(export_snapshot, list):
    export_snapshot = pd.DataFrame(export_snapshot)
if export_snapshot is None:
    export_snapshot = pd.DataFrame()

export_df = export_snapshot.copy()
rename_map = {
    "price": "Price", "total_cost": "Total Cost", "cost_pct": "Cost %",
    "margin": "Margin", "recipe_code": "Recipe Code", "recipe_type": "Recipe Type",
    "recipe_category": "Recipe Category", "yield_qty": "Yield Quantity",
    "yield_uom": "Yield UOM", "status": "Status", "name": "Name",
}
export_df.rename(columns={k:v for k,v in rename_map.items() if k in export_df.columns}, inplace=True)

ts = datetime.now().strftime("%Y%m%d-%H%M")
fname = f"recipes_{status_filter.lower()}_{type_filter.lower()}_{ts}.csv"
is_empty = export_df.empty

st.download_button(
    label="⬇️ Download CSV (matches grid)",
    data=(export_df.to_csv(index=False) if not is_empty else "".encode("utf-8")),
    file_name=fname,
    mime="text/csv",
    disabled=is_empty,
)
if is_empty:
    st.caption("Export is disabled because there are no rows in the current view.")

# -----------------------------
# Determine selection (for edit)
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
        # Reload full row from DB for accurate edit payload
        orig_res = supabase.table("recipes").select(
            "id, recipe_code, name, status, recipe_type, recipe_category, yield_qty, yield_uom, price"
        ).eq("recipe_code", selected_code).limit(1).execute()
        if orig_res.data:
            edit_data = orig_res.data[0]
edit_mode = edit_data is not None

# -----------------------------
# Sidebar — Recipe Type (OUTSIDE form so UI reacts instantly)
# -----------------------------
with st.sidebar:
    st.subheader("➕ Add or Edit Recipe")

    type_options = ["— Select —", "service", "prep"]
    default_type = edit_data.get("recipe_type") if edit_mode else "service"
    type_index   = (type_options.index(default_type) if default_type in type_options else 1)
    selected_recipe_type = st.selectbox("Recipe Type", type_options, index=type_index, key="recipe_type_selector")
    selected_recipe_type = None if selected_recipe_type == "— Select —" else selected_recipe_type

    # -------------------------
    # Form (depends on selected_recipe_type)
    # -------------------------
    with st.form("recipe_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Recipe Code", value=edit_data.get("recipe_code", "") if edit_mode else "")

        status_options = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_index = status_options.index(selected_status) if selected_status in status_options else 0
        status = st.selectbox("Status", status_options, index=status_index)
        status = status if status != "— Select —" else None

        recipe_category = st.text_input("Recipe Category", value=edit_data.get("recipe_category", "") if edit_mode else "")

        yield_qty_val = float(edit_data.get("yield_qty", 1.0)) if edit_mode and edit_data.get("yield_qty") is not None else 1.0
        yield_qty = st.number_input("Yield Quantity", min_value=0.0, step=0.1, value=yield_qty_val)

        # --- UOM dropdown (type-aware) ---
        all_uoms = fetch_uom_options()
        current_uom = edit_data.get("yield_uom") if edit_mode else None
        uom_choices = build_uom_choices(selected_recipe_type, current_uom, all_uoms)

        # Include current explicitly if not in choices (defensive)
        if current_uom and current_uom not in uom_choices:
            uom_choices = [current_uom] + [u for u in uom_choices if u != current_uom]

        # Default index
        if edit_mode and current_uom:
            idx = next((i for i, u in enumerate(uom_choices) if u == current_uom), 0)
        else:
            # New row default for service: 'Serving'; otherwise first choice
            if selected_recipe_type == "service":
                desired = "Serving"
                idx = next((i for i, u in enumerate(uom_choices) if u == desired), 0)
            else:
                idx = 0

        yield_uom = st.selectbox("Yield UOM", options=uom_choices, index=idx)

        # Price — disabled live when prep
        price_val = float(edit_data.get("price", 0.0)) if edit_mode and edit_data.get("price") is not None else 0.0
        price = st.number_input("Price", min_value=0.0, step=0.01, value=price_val, disabled=(selected_recipe_type == "prep"))

        # Buttons inline
        c1, c2, c3 = st.columns(3)
        save_btn   = c1.form_submit_button("Save")
        delete_btn = c2.form_submit_button("Delete", disabled=not edit_mode)
        clear_btn  = c3.form_submit_button("Clear", disabled=True)  # Group C will handle

        if clear_btn:
            st.info("Clear behavior will be implemented in Group C.")

        # Validation
        errors = []
        if not name: errors.append("Name")
        if not code: errors.append("Recipe Code")
        if not status: errors.append("Status")
        if not selected_recipe_type: errors.append("Recipe Type")
        if not yield_uom: errors.append("Yield UOM")

        # Actions
        if delete_btn and edit_mode:
            try:
                supabase.table("recipes").update({"status": "Inactive"}).eq("id", edit_data["id"]).execute()
                st.success("Recipe set to Inactive.")
                st.rerun()
            except Exception as e:
                st.error(f"Failed to delete (soft): {e}")

        if save_btn:
            if errors:
                st.error(f"⚠️ Please complete: {', '.join(errors)}")
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
                    "recipe_type": selected_recipe_type
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
