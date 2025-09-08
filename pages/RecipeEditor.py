# pages/RecipeEditor.py
import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode
from utils.supabase import supabase
try:
    from utils.auth import require_auth
    require_auth()
except Exception:
    # If auth wrapper isn't present in this MVP env, proceed unauthenticated.
    pass

st.set_page_config(page_title="Recipe Editor", layout="wide")
st.title("📝 Recipe Editor")

# -----------------------------
# Helpers (local to this page)
# -----------------------------
def fetch_recipes_active():
    res = supabase.table("recipes") \
        .select("id, name, recipe_code, recipe_type, status") \
        .eq("status", "Active") \
        .order("name") \
        .execute()
    return res.data or []

def fetch_input_catalog():
    # Active ingredients + active prep recipes
    res = supabase.table("input_catalog").select("*").execute()
    rows = res.data or []
    # Build display labels "Name – CODE" while keeping source
    for r in rows:
        r["label"] = f"{r['name']} – {r['code']}"
    return rows

def fetch_all_recipe_lines_pairs():
    # For dependency graph (edges among recipes only)
    res = supabase.table("recipe_lines").select("recipe_id, ingredient_id").execute()
    return res.data or []

def compute_ancestor_recipes(current_recipe_id, all_lines, all_recipe_ids):
    """
    Ancestors = recipes that (directly or indirectly) use the current recipe.
    Build reverse edges: used_by[X] = set of recipes that include X.
    DFS from current_recipe_id following used_by to collect all ancestors.
    """
    used_by = {}
    for row in all_lines:
        rid = row["recipe_id"]
        iid = row["ingredient_id"]
        if iid in all_recipe_ids:
            used_by.setdefault(iid, set()).add(rid)

    ancestors = set()
    stack = [current_recipe_id]
    while stack:
        node = stack.pop()
        for parent in used_by.get(node, set()):
            if parent not in ancestors:
                ancestors.add(parent)
                stack.append(parent)
    return ancestors

def fetch_summary(recipe_id):
    res = supabase.table("recipe_summary") \
        .select("recipe, price, cost, margin_dollar, profitability") \
        .eq("recipe_id", recipe_id) \
        .execute()
    return (res.data or [None])[0]

def fetch_recipe_line_costs(recipe_id):
    res = supabase.table("recipe_line_costs") \
        .select("*") \
        .eq("recipe_id", recipe_id) \
        .execute()
    return res.data or []

def fetch_notes_map(recipe_id):
    res = supabase.table("recipe_lines") \
        .select("id, note") \
        .eq("recipe_id", recipe_id) \
        .execute()
    return {r["id"]: r.get("note") for r in (res.data or [])}

def fetch_uom_options():
    # Use the defined conversions as the allowed UOM list
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted({r["from_uom"] for r in (res.data or [])})

def rpc_unit_cost_map(ids):
    if not ids:
        return {}
    # RPC: get_unit_costs_for_inputs(ids uuid[]) -> (id, unit_cost)
    res = supabase.rpc("get_unit_costs_for_inputs", {"ids": ids}).execute()
    rows = res.data or []
    return {r["id"]: r["unit_cost"] for r in rows}

def upsert_recipe_line(edit_mode, recipe_line_id, payload):
    tbl = supabase.table("recipe_lines")
    if edit_mode and recipe_line_id:
        tbl.update(payload).eq("id", recipe_line_id).execute()
    else:
        tbl.insert(payload).execute()

# -----------------------------
# Recipe selection
# -----------------------------
recipes = fetch_recipes_active()
name_to_id = {f"{r['name']} – {r['recipe_code']}" if r.get("recipe_code") else r["name"]: r["id"] for r in recipes}
options = ["— Select —"] + list(name_to_id.keys())
selected_name = st.selectbox("Select Recipe", options, index=0)
recipe_id = name_to_id.get(selected_name)

if not recipe_id:
    st.info("Select a recipe to view and edit.")
    st.stop()

# -----------------------------
# Header metrics
# -----------------------------
summary = fetch_summary(recipe_id)
if summary:
    col1, col2, col3, col4 = st.columns([2, 2, 2, 4])
    col1.metric("Recipe", summary["recipe"])
    price = summary.get("price") or 0
    cost = summary.get("cost") or 0
    cost_pct = (cost / price) * 100 if price else 0
    margin = summary.get("margin_dollar") or 0
    col2.metric("Price", f"${price:.2f}")
    col3.metric("Cost (% of price)", f"{cost_pct:.1f}%")
    col4.metric("Margin", f"${margin:.2f}")
else:
    st.warning("No summary available for this recipe.")

st.divider()

# -----------------------------
# Load lines + unit costs
# -----------------------------
line_rows = fetch_recipe_line_costs(recipe_id)
df = pd.DataFrame(line_rows)
notes_map = fetch_notes_map(recipe_id)

# Map to display labels from catalog (ingredients + prep recipes)
catalog_rows = fetch_input_catalog()
id_to_label = {r["id"]: r["label"] for r in catalog_rows}
df["ingredient"] = df["ingredient_id"].map(id_to_label).fillna("— missing —")
df["note"] = df["recipe_line_id"].map(notes_map)

# Unit cost for the ingredient/recipe referenced in each line
unit_costs = rpc_unit_cost_map(list({r["ingredient_id"] for r in line_rows}))
df["unit_cost"] = df["ingredient_id"].map(unit_costs)

# Order columns for display (keep raw id hidden)
display_cols = ["recipe_line_id", "ingredient", "qty", "qty_uom", "unit_cost", "line_cost", "note"]
for col in ["unit_cost", "line_cost"]:
    if col in df.columns:
        df[col] = df[col].astype("float64", errors="ignore")
display_df = df.reindex(columns=[c for c in display_cols if c in df.columns])

for col in ["unit_cost", "line_cost"]:
    if col in display_df.columns:
        display_df[col] = display_df[col].map(lambda x: f"${x:.6f}" if pd.notnull(x) else "")

# -----------------------------
# AgGrid table + selection
# -----------------------------
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
    height=480,
    allow_unsafe_jscode=True,
)

selected_row = grid_response.get("selected_rows")
edit_data = None
if selected_row:
    if isinstance(selected_row, list) and len(selected_row) > 0:
        sel_id = selected_row[0].get("recipe_line_id")
        match = df[df["recipe_line_id"] == sel_id]
        if not match.empty:
            m = match.iloc[0]
            edit_data = {
                "recipe_line_id": m["recipe_line_id"],
                "ingredient_id": m["ingredient_id"],
                "qty": float(m["qty"]) if pd.notnull(m["qty"]) else 1.0,
                "qty_uom": m["qty_uom"],
                "note": notes_map.get(m["recipe_line_id"], ""),
            }

# -----------------------------
# Sidebar form (Add/Edit)
# -----------------------------
with st.sidebar:
    st.subheader("➕ Add or Edit Recipe Line")

    # Build dependency guard: exclude current recipe and its ancestors
    all_lines = fetch_all_recipe_lines_pairs()
    all_recipe_ids = {r["id"] for r in recipes}
    ancestors = compute_ancestor_recipes(recipe_id, all_lines, all_recipe_ids)
    blocked_recipes = ancestors | {recipe_id}

    # Build selection options from catalog, excluding blocked recipes
    filtered_catalog = [
        r for r in catalog_rows
        if not (r["source"] == "recipe" and r["id"] in blocked_recipes)
    ]
    # Keep options sorted by label
    filtered_catalog.sort(key=lambda r: r["label"].lower())

    label_to_id = {"— Select —": None}
    for r in filtered_catalog:
        label_to_id[r["label"]] = r["id"]

    with st.form("line_form", clear_on_submit=False):
        # Ingredient/prep recipe select
        default_label = None
        if edit_data:
            # Map current ingredient id to label (if it was filtered out, we still show the label)
            default_label = id_to_label.get(edit_data["ingredient_id"])
        selected_label = st.selectbox(
            "Ingredient or Prep Recipe",
            options=list(label_to_id.keys()),
            index=(list(label_to_id.keys()).index(default_label) if default_label in label_to_id else 0)
        )
        ingredient_id = label_to_id.get(selected_label)

        # Quantity
        qty = st.number_input(
            "Quantity",
            min_value=0.0,
            step=0.1,
            value=(edit_data["qty"] if edit_data else 1.0)
        )

        # UOM
        uom_opts = ["— Select —"] + fetch_uom_options()
        default_uom = edit_data["qty_uom"] if edit_data else None
        qty_uom = st.selectbox("UOM", options=uom_opts, index=(uom_opts.index(default_uom) if default_uom in uom_opts else 0))

        # Display unit cost (computed server-side)
        unit_cost_display = rpc_unit_cost_map([ingredient_id]).get(ingredient_id) if ingredient_id else None
        st.text_input("Unit Cost (base unit)", value=(f"{unit_cost_display:.6f}" if unit_cost_display is not None else ""), disabled=True)

        # Note
        note_val = edit_data["note"] if edit_data else ""
        note = st.text_area("Note (optional)", value=note_val)

        # Submit buttons
        submit_label = "Save" if edit_data else "Add Line"
        submitted = st.form_submit_button(submit_label)

        errors = []
        if not ingredient_id:
            errors.append("Ingredient/Recipe")
        if not qty_uom or qty_uom == "— Select —":
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
                upsert_recipe_line(edit_data is not None, (edit_data or {}).get("recipe_line_id"), payload)
                st.success("Line saved.")
                st.rerun()

    # Row actions
    if edit_data:
        col_a, col_b = st.columns(2)
        if col_a.button("Cancel"):
            st.rerun()
        if col_b.button("Delete", type="primary"):
            supabase.table("recipe_lines").delete().eq("id", edit_data["recipe_line_id"]).execute()
            st.success("Line deleted.")
            st.rerun()

# -----------------------------
# CSV Export
# -----------------------------
st.markdown("### 📥 Export Recipe Lines")
export_df = display_df.drop(columns=["recipe_line_id"], errors="ignore").copy()
# Strip $ for raw CSV numbers; also include raw numeric columns
def _strip_money(x):
    try:
        return float(str(x).replace("$", "")) if str(x).startswith("$") else x
    except Exception:
        return x
for c in ["unit_cost", "line_cost"]:
    if c in export_df.columns:
        export_df[c] = export_df[c].map(_strip_money)

st.download_button(
    label="Download Lines as CSV",
    data=export_df.to_csv(index=False),
    file_name=f"{(selected_name or 'recipe').replace(' ', '_')}_lines.csv",
    mime="text/csv",
)
