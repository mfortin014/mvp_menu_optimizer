import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from utils.supabase import supabase
from utils.auth import require_auth

require_auth()

st.set_page_config(page_title="Recipes", layout="wide")
st.title("📘 Recipes")

# -----------------------------
# Helpers
# -----------------------------

def fetch_recipes_df() -> pd.DataFrame:
    """
    Load recipes for display & editing.
    Uses the new schema fields: yield_qty, yield_uom, recipe_type.
    """
    res = supabase.table("recipes").select("*").order("name").execute()
    df = pd.DataFrame(res.data or [])
    if df.empty:
        return pd.DataFrame(columns=[
            "recipe_code", "name", "status", "recipe_type", "recipe_category",
            "yield_qty", "yield_uom", "price"
        ])

    # Numeric formatting helpers (for display/export only)
    if "yield_qty" in df.columns:
        df["yield_qty"] = df["yield_qty"].astype(float)

    if "price" in df.columns:
        df["price"] = df["price"].astype(float)

    # Ensure expected columns exist (graceful if DB is slightly behind)
    for col in ("recipe_type", "recipe_category", "yield_qty", "yield_uom"):
        if col not in df.columns:
            df[col] = None

    return df


def format_for_grid(df: pd.DataFrame) -> pd.DataFrame:
    """
    Format a display DataFrame for AgGrid without mutating the raw DB values.
    """
    if df.empty:
        return df

    display = df.copy()

    # Format decimals as strings for right alignment control
    if "yield_qty" in display.columns:
        display["yield_qty"] = display["yield_qty"].map(lambda x: f"{x:.2f}" if pd.notnull(x) else "")

    if "price" in display.columns:
        display["price"] = display["price"].map(lambda x: f"{x:.2f}" if pd.notnull(x) else "")

    ordered_cols = [
        "recipe_code", "name", "status", "recipe_type", "recipe_category",
        "yield_qty", "yield_uom", "price"
    ]
    # Keep only existing columns in that order
    ordered_cols = [c for c in ordered_cols if c in display.columns]

    return display[ordered_cols]


# -----------------------------
# Fetch & Display
# -----------------------------

df = fetch_recipes_df()
display_df = format_for_grid(df)

gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)

# Right-align numeric-looking columns
for col in ("yield_qty", "price"):
    if col in display_df.columns:
        gb.configure_column(col, cellStyle={"textAlign": "right"})

grid_options = gb.build()

grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=600,
    allow_unsafe_jscode=True
)

# -----------------------------
# CSV Export
# -----------------------------

st.markdown("### 📤 Export Recipes")
export_df = display_df.copy()
st.download_button(
    label="Download Recipes as CSV",
    data=export_df.to_csv(index=False),
    file_name="recipes_export.csv",
    mime="text/csv"
)

# -----------------------------
# Handle Selection
# -----------------------------

selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    # AgGrid can return a list (dicts) or a DataFrame depending on configuration
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_code = selected_row.iloc[0].get("recipe_code")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_code = selected_row[0].get("recipe_code")
    else:
        selected_code = None

    if selected_code:
        match = df[df["recipe_code"] == selected_code]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

# -----------------------------
# Sidebar Form (Add / Edit)
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

        # NEW: recipe_type (required)
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

        # Renamed fields: yield_qty / yield_uom
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
