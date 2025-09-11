import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from utils.auth import require_auth
from components.active_client_badge import render as client_badge
from utils import tenant_db as db

require_auth()
st.set_page_config(page_title="Ingredients", layout="wide")
client_badge(clients_page_title="Clients")
st.title("🥦 Ingredients")


# ---------- Data loaders ----------
def fetch_ingredients_df() -> pd.DataFrame:
    res = db.table("ingredients").select(
        "id,ingredient_code,name,ingredient_type,status,"
        "category_id,storage_type_id,"
        "package_qty,package_uom,base_uom,package_cost,yield_pct"
    ).order("name").execute()
    rows = res.data or []
    df = pd.DataFrame(rows)

    # Ensure expected columns exist even if empty (prevents KeyError)
    expected = [
        "id","ingredient_code","name","ingredient_type","status",
        "category_id","storage_type_id",
        "package_qty","package_uom","base_uom","package_cost","yield_pct"
    ]
    for c in expected:
        if c not in df.columns:
            df[c] = None
    return df

def fetch_cost_lookup() -> dict:
    res = db.table("ingredient_costs").select("ingredient_code,unit_cost").execute()
    return {r["ingredient_code"]: r["unit_cost"] for r in (res.data or [])}

def fetch_uoms() -> list[str]:
    # Global reference table; fine to read via db.table() (no tenant filter applied)
    res = db.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(r["from_uom"] for r in (res.data or [])))

def fetch_categories() -> list[dict]:
    res = db.table("ref_ingredient_categories").select("id,name").eq("status","Active").execute()
    return res.data or []

def fetch_storage_types() -> list[dict]:
    res = db.table("ref_storage_type").select("id,name").eq("status","Active").execute()
    return res.data or []

def fetch_base_uom_map() -> dict:
    # Best-effort “from → to” where base is g/ml for inference
    res = db.table("ref_uom_conversion").select("from_uom,to_uom").execute()
    return {r["from_uom"]: r["to_uom"] for r in (res.data or []) if r["to_uom"] in ["g","ml"]}

# ---------- Fetch ----------
uom_options   = fetch_uoms()
categories    = fetch_categories()
storage_types = fetch_storage_types()
category_lu   = {c["id"]: c["name"] for c in categories}
storage_lu    = {s["id"]: s["name"] for s in storage_types}
category_rev  = {v: k for k, v in category_lu.items()}
base_uom_map  = fetch_base_uom_map()
cost_lu       = fetch_cost_lookup()

df = fetch_ingredients_df()
df["category"]     = df["category_id"].map(category_lu)
df["storage_type"] = df["storage_type_id"].map(storage_lu)
df["unit_cost"]    = df["ingredient_code"].map(cost_lu)

# ---------- Display table ----------
column_order = [
    "name","ingredient_code","ingredient_type","package_qty","package_uom",
    "package_cost","yield_pct","status","category","storage_type","unit_cost","base_uom"
]
display_df = df[column_order if all(c in df.columns for c in column_order) else df.columns].copy()

gb = GridOptionsBuilder.from_dataframe(display_df)
grid_height = 600 if len(display_df) > 10 else None
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)

# Pretty formatting
if "package_cost" in display_df:
    display_df["package_cost"] = display_df["package_cost"].apply(lambda x: f"${x: .2f}" if pd.notnull(x) else "")
if "yield_pct" in display_df:
    display_df["yield_pct"] = display_df["yield_pct"].apply(lambda x: f"{x: .1f}%" if pd.notnull(x) else "")
if "unit_cost" in display_df:
    display_df["unit_cost"] = display_df["unit_cost"].apply(lambda x: f"${x: .5f}" if pd.notnull(x) else "")

for col in ["package_qty","package_cost","yield_pct","unit_cost"]:
    if col in display_df.columns:
        gb.configure_column(col, cellStyle={"textAlign": "right"})

grid_options = gb.build()
grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=grid_height,
    allow_unsafe_jscode=True,
)

# ---------- CSV export ----------
st.markdown("### 📤 Export Ingredients")
export_df = display_df.copy()
for col in ["package_qty","package_cost","yield_pct","unit_cost"]:
    if col in export_df.columns:
        export_df[col] = export_df[col].astype(str)
st.download_button(
    label="Download Ingredients as CSV",
    data=export_df.to_csv(index=False),
    file_name="ingredients_export.csv",
    mime="text/csv",
)

# ---------- Selection handling ----------
selected_row = grid_response["selected_rows"]
edit_data = None
if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        sel_code = selected_row.iloc[0].get("ingredient_code")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        sel_code = selected_row[0].get("ingredient_code")
    else:
        sel_code = None
    if sel_code:
        match = df[df["ingredient_code"] == sel_code]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

# ---------- Sidebar form ----------
with st.sidebar:
    st.subheader("➕ Add or Edit Ingredient")
    with st.form("ingredient_form"):
        name = st.text_input("Name", value=edit_data.get("name","") if edit_mode else "")
        code = st.text_input("Ingredient Code", value=edit_data.get("ingredient_code","") if edit_mode else "")

        type_opts = ["— Select —", "Bought", "Prepped"]
        selected_type = edit_data.get("ingredient_type") if edit_mode else None
        type_idx = type_opts.index(selected_type) if selected_type in type_opts else 0
        ingredient_type = st.selectbox("Ingredient Type", type_opts, index=type_idx)
        ingredient_type = None if ingredient_type == "— Select —" else ingredient_type

        package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1,
                                      value=float(edit_data.get("package_qty", 0.0)) if edit_mode else 0.0)

        uom_list = ["— Select —"] + uom_options
        selected_uom = edit_data.get("package_uom") if edit_mode else None
        uom_idx = uom_list.index(selected_uom) if selected_uom in uom_list else 0
        package_uom = st.selectbox("Package UOM", uom_list, index=uom_idx)
        package_uom = None if package_uom == "— Select —" else package_uom

        package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01,
                                       value=float(edit_data.get("package_cost", 0.0)) if edit_mode else 0.0)

        raw_yield = st.number_input("Yield (%)", min_value=0.0, max_value=200.0, step=1.0,
                                    value=float(edit_data.get("yield_pct", 100.0)) if edit_mode else 100.0)
        yield_pct = raw_yield * 100 if 0 < raw_yield <= 2 else raw_yield

        status_opts = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_idx = status_opts.index(selected_status) if selected_status in status_opts else 0
        status = st.selectbox("Status", status_opts, index=status_idx)
        status = None if status == "— Select —" else status

        category_names = ["— Select —"] + [c["name"] for c in categories]
        category_id_val = edit_data.get("category_id") if edit_mode else None
        pre_cat = category_lu.get(category_id_val)
        cat_idx = category_names.index(pre_cat) if pre_cat in category_names else 0
        picked_cat_name = st.selectbox("Category", category_names, index=cat_idx)
        category_id = next((c["id"] for c in categories if c["name"] == picked_cat_name), None) if picked_cat_name != "— Select —" else None

        storage_names = ["— Select —"] + [s["name"] for s in storage_types]
        storage_id_val = edit_data.get("storage_type_id") if edit_mode else None
        pre_store = storage_lu.get(storage_id_val)
        store_idx = storage_names.index(pre_store) if pre_store in storage_names else 0
        picked_storage = st.selectbox("Storage Type", storage_names, index=store_idx)
        storage_type_id = next((s["id"] for s in storage_types if s["name"] == picked_storage), None) if picked_storage != "— Select —" else None

        base_uom_opts = ["— Select —", "g", "ml", "unit"]
        selected_base = edit_data.get("base_uom") if edit_mode else None
        base_idx = base_uom_opts.index(selected_base) if selected_base in base_uom_opts else 0
        base_uom = st.selectbox("Base UOM (optional, inferred if blank)", base_uom_opts, index=base_idx)
        base_uom = None if base_uom == "— Select —" else base_uom
        if not base_uom and package_uom:
            normalized = package_uom.lower()
            if normalized in ["each", "unit"]:
                base_uom = "unit"
            elif package_uom in base_uom_map:
                base_uom = base_uom_map[package_uom]

        submitted = st.form_submit_button("Save Ingredient")
        errors = []
        if not name: errors.append("Name")
        if not code: errors.append("Ingredient Code")
        if not ingredient_type: errors.append("Ingredient Type")
        if not package_uom: errors.append("Package UOM")
        if not status: errors.append("Status")
        if not category_id: errors.append("Category")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete: {', '.join(errors)}")
            else:
                payload = {
                    "name": name,
                    "ingredient_code": code,
                    "ingredient_type": ingredient_type,
                    "package_qty": round(package_qty, 6),
                    "package_uom": package_uom,
                    "package_cost": round(package_cost, 6),
                    "yield_pct": round(yield_pct, 6),
                    "base_uom": base_uom,
                    "status": status,
                    "category_id": category_id,
                    "storage_type_id": storage_type_id,
                }
                if edit_mode:
                    db.table("ingredients").update(payload).eq("id", edit_data["id"]).execute()
                    st.success("Ingredient updated.")
                else:
                    db.insert("ingredients", payload).execute()
                    st.success("Ingredient added.")
                st.rerun()

    if edit_mode:
        cols = st.columns(2)
        if cols[0].button("Cancel"):
            st.rerun()
        if cols[1].button("Delete"):
            # Soft delete, not status flip
            db.soft_delete("ingredients", id=edit_data["id"]).execute()
            st.success("Ingredient deleted (soft).")
            st.rerun()
