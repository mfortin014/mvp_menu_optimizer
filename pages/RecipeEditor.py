import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode
from utils.auth import require_auth
require_auth()

st.set_page_config(page_title="Recipe Editor", layout="wide")
st.title("📝 Recipe Editor")

# === Helper Functions ===
def fetch_recipes():
    res = supabase.table("recipes") \
        .select("id, name") \
        .eq("status", "Active") \
        .order("name") \
        .execute()
    return res.data or []

def fetch_line_item_options():
    ing_res = supabase.table("ingredients") \
        .select("id, ingredient_code, name") \
        .eq("status", "Active") \
        .order("name") \
        .execute()
    recipe_res = supabase.table("recipes") \
        .select("id, recipe_code, name, is_ingredient, status") \
        .eq("status", "Active") \
        .eq("is_ingredient", True) \
        .order("name") \
        .execute()

    options = []
    for row in (ing_res.data or []):
        label = f"[{row['ingredient_code']}] {row['name']} (Ingredient)"
        options.append({"label": label, "id": row["id"], "source": "ingredient"})

    for row in (recipe_res.data or []):
        label = f"[{row['recipe_code']}] {row['name']} (Recipe)"
        options.append({"label": label, "id": row["id"], "source": "recipe"})

    return options

def fetch_uoms():
    res = supabase.table("ref_uom_conversion") \
        .select("from_uom") \
        .execute()
    return sorted({r["from_uom"] for r in (res.data or [])})

def fetch_unit_costs():
    res = supabase.table("ingredient_costs") \
        .select("ingredient_id, unit_cost") \
        .execute()
    return {row["ingredient_id"]: row["unit_cost"] for row in (res.data or [])}

# === Recipe Selection ===
recipes = fetch_recipes()
name_to_id = {r["name"]: r["id"] for r in recipes}
options = ["— Select —"] + [r["name"] for r in recipes]
selected_name = st.selectbox("Select Recipe", options)
recipe_id = name_to_id.get(selected_name)

if not recipe_id:
    st.info("Please select a recipe to view and edit.")
    st.stop()

# === Header Metrics ===
summary_res = supabase.table("recipe_summary") \
    .select("recipe, price, cost, margin_dollar, profitability") \
    .eq("recipe_id", recipe_id) \
    .execute()
if summary_res.data:
    summ = summary_res.data[0]
    col1, col2, col3, col4 = st.columns([2, 2, 2, 4])
    col1.metric("Recipe", summ["recipe"])
    price = summ["price"]
    cost = summ["cost"]
    cost_pct = (cost / price) * 100 if price else 0
    margin = summ["margin_dollar"]

    col2.metric("Price", f"${price:.2f}")
    col3.metric("Cost (% of price)", f"{cost_pct:.1f}%")
    col4.metric("Margin", f"${margin:.2f}")

else:
    st.warning("No summary available for this recipe.")

# === Load Recipe Lines with Costs & Notes ===
rlc_res = supabase.table("recipe_line_costs") \
    .select("*") \
    .eq("recipe_id", recipe_id) \
    .execute()
df = pd.DataFrame(rlc_res.data or [])
notes_res = supabase.table("recipe_lines") \
    .select("id, note") \
    .eq("recipe_id", recipe_id) \
    .execute()
notes_map = {row["id"]: row["note"] for row in (notes_res.data or [])}
unit_cost_map = fetch_unit_costs()

if df.empty:
    display_df = pd.DataFrame(columns=["ingredient", "qty", "qty_uom", "unit_cost", "line_cost", "note"])
else:
    ingredients_lookup = {o["id"]: o["label"] for o in fetch_line_item_options() if o["source"] == "ingredient"}
    df["ingredient"] = df["ingredient_id"].map(ingredients_lookup)
    df["note"] = df["recipe_line_id"].map(notes_map)
    df["unit_cost"] = df["ingredient_id"].map(unit_cost_map)
    display_df = df[["recipe_line_id", "ingredient", "qty", "qty_uom", "unit_cost", "line_cost", "note"]]

for col in ["unit_cost", "line_cost"]:
    if col in display_df.columns:
        display_df[col] = display_df[col].map(lambda x: f"${x:.5f}" if pd.notnull(x) else "")


# === AgGrid Table ===
gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
gb.configure_column("recipe_line_id", hide=True)
grid_options = gb.build()
grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=500,
    allow_unsafe_jscode=True
)

# === Handle Selection for Edit ===
selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_recipe_line_id = selected_row.iloc[0].get("recipe_line_id")
        row = df[df["recipe_line_id"] == selected_recipe_line_id]
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_recipe_line_id = selected_row[0].get("recipe_line_id")
        row = df[df["recipe_line_id"] == selected_recipe_line_id]
    else:
        selected_recipe_line_id = None

    if selected_recipe_line_id:
        match = df[df["recipe_line_id"] == selected_recipe_line_id]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

# === Sidebar Form ===
with st.sidebar:
    st.subheader("➕ Add or Edit Recipe Line")
    with st.form("line_form"):
        options = fetch_line_item_options()
        option_labels = ["— Select —"] + [o["label"] for o in options]
        default_label = next((o["label"] for o in options if o["id"] == edit_data.get("ingredient_id")), None) if edit_mode else None
        default_index = option_labels.index(default_label) if default_label in option_labels else 0
        selected_label = st.selectbox("Ingredient", option_labels, index=default_index)
        selected = next((o for o in options if o["label"] == selected_label), None)
        ingredient_id = selected["id"] if selected and selected["source"] == "ingredient" else None
        if selected and selected["source"] == "recipe":
            st.info("Recipe-as-ingredient saving not yet supported")

        qty = st.number_input(
            "Quantity", min_value=0.0, step=0.1,
            value=float(edit_data.get("qty", 1.0)) if edit_mode else 1.0
        )
        uom_opts = ["— Select —"] + fetch_uoms()
        default_uom = edit_data.get("qty_uom") if edit_mode else None
        uom_index = uom_opts.index(default_uom) if default_uom in uom_opts else 0
        qty_uom = st.selectbox("UOM", uom_opts, index=uom_index)

        unit_cost_display = unit_cost_map.get(ingredient_id)
        st.text_input("Unit Cost", value=f"{unit_cost_display:.6f}" if unit_cost_display else "", disabled=True)

        note = st.text_area("Note", value=edit_data.get("note", "") if edit_mode else "")

        submit_label = "Save" if edit_mode else "Add Ingredient"
        submitted = st.form_submit_button(submit_label)

        errors = []
        if not ingredient_id:
            errors.append("Ingredient")
        if not qty_uom:
            errors.append("UOM")
        if submitted:
            if errors:
                st.error(f"⚠️ Please complete: {', '.join(errors)}")
            else:
                payload = {
                    "recipe_id": recipe_id,
                    "ingredient_id": ingredient_id,
                    "qty": qty,
                    "qty_uom": qty_uom,
                    "note": note or None
                }
                if edit_mode:
                    supabase.table("recipe_lines").update(payload).eq("id", edit_data["recipe_line_id"]).execute()
                    st.success("Line updated.")
                else:
                    supabase.table("recipe_lines").insert(payload).execute()
                    st.success("Line added.")
                st.rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.rerun()
        if st.button("Delete"):
            supabase.table("recipe_lines").delete().eq("id", edit_data["recipe_line_id"]).execute()
            st.success("Line deleted.")
            st.rerun()

# === CSV Export ===
st.markdown("### 📥 Export Recipe Lines")
if "recipe_line_id" in display_df.columns:
    exp_df = display_df.drop(columns=["recipe_line_id"]).copy()
else:
    exp_df = display_df.copy()

exp_df[["line_cost", "unit_cost"]] = exp_df[["line_cost", "unit_cost"]].round(6)
st.download_button(
    label="Download Lines as CSV",
    data=exp_df.to_csv(index=False),
    file_name=f"{selected_name.replace(' ', '_')}_lines.csv",
    mime="text/csv"
)
