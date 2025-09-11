# pages/RecipeEditor.py
import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode
from utils.supabase import supabase
from components.active_client_badge import render as client_badge
from utils import tenant_db as db
from utils.cache import cache_by_tenant

# Auth wrapper (optional in MVP env)
try:
    from utils.auth import require_auth
    require_auth()
except Exception:
    pass

st.set_page_config(page_title="Recipe Editor", layout="wide")
client_badge(clients_page_title="Clients")
st.title("📝 Recipe Editor")


# -----------------------------
# Data helpers
# -----------------------------

def fetch_recipes_active():
    res = db.table("recipes") \
        .select("id, name, recipe_code, recipe_type, status") \
        .eq("status", "Active") \
        .order("name") \
        .execute()
    return res.data or []

def fetch_recipe_core(recipe_id: str) -> dict:
    """Single base recipe row with name, price, type, yield."""
    res = db.table("recipes").select(
        "name, price, recipe_type, yield_qty, yield_uom"
    ).eq("id", recipe_id).single().execute()
    return res.data or {}

def fetch_input_catalog():
    # Active ingredients + active prep recipes (backed by input_catalog view)
    res = db.table("input_catalog").select("*").execute()
    rows = res.data or []
    for r in rows:
        r["label"] = f"{r.get('name','')} – {r.get('code','')}"
    return rows

def fetch_all_recipe_lines_pairs():
    # For dependency graph (edges among recipes only)
    res = db.table("recipe_lines").select("recipe_id, ingredient_id").execute()
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

def fetch_recipe_summary_row(recipe_id: str):
    # Might return 0 rows (e.g., for prep recipes)
    res = db.table("recipe_summary").select("*").eq("recipe_id", recipe_id).execute()
    rows = res.data or []
    return rows[0] if rows else None

def fetch_prep_costs_row(recipe_id: str):
    res = db.table("prep_costs").select("*").eq("recipe_id", recipe_id).execute()
    rows = res.data or []
    return rows[0] if rows else None

def fetch_recipe_line_costs(recipe_id):
    res = db.table("recipe_line_costs") \
        .select("*") \
        .eq("recipe_id", recipe_id) \
        .execute()
    return res.data or []

def fetch_notes_map(recipe_id):
    res = db.table("recipe_lines") \
        .select("id, note") \
        .eq("recipe_id", recipe_id) \
        .execute()
    return {r["id"]: r.get("note") for r in (res.data or [])}

def fetch_uom_options():
    res = db.table("ref_uom_conversion").select("from_uom, to_uom").execute()
    rows = res.data or []
    uoms = set()
    for r in rows:
        if r.get("from_uom"): uoms.add(r["from_uom"])
        if r.get("to_uom"): uoms.add(r["to_uom"])
    return sorted(uoms)

def rpc_unit_cost_map(ids):
    if not ids:
        return {}
    # RPC: get_unit_costs_for_inputs(ids uuid[]) -> (id, unit_cost)
    res = supabase.rpc("get_unit_costs_for_inputs", {"ids": ids}).execute()
    rows = res.data or []
    return {r["id"]: r["unit_cost"] for r in rows if r.get("unit_cost") is not None}

def upsert_recipe_line(edit_mode, recipe_line_id, payload):
    tbl = db.table("recipe_lines")
    if edit_mode and recipe_line_id:
        tbl.update(payload).eq("id", recipe_line_id).execute()
    else:
        tbl.insert(payload).execute()

@cache_by_tenant(ttl=60)
def _load_recipe_picker():
    return db.table("recipes").select("id,name,recipe_code,status,recipe_type") \
            .eq("recipe_type","service").eq("status","Active").order("name").execute().data or []

# -----------------------------
# Recipe selection
# -----------------------------

recipes = fetch_recipes_active()
name_to_id = {
    (f"{r['name']} – {r['recipe_code']}" if r.get("recipe_code") else r["name"]): r["id"]
    for r in recipes
}
options = ["— Select —"] + list(name_to_id.keys())
selected_name = st.selectbox("Select Recipe", options, index=0)
recipe_id = name_to_id.get(selected_name)

if not recipe_id:
    st.info("Select a recipe to view and edit.")
    st.stop()

core = fetch_recipe_core(recipe_id)
rtype = core.get("recipe_type", "service")
rname = core.get("name") or selected_name.replace(" – ", " ")
price = float(core.get("price") or 0.0)
yield_qty = core.get("yield_qty")
yield_uom = core.get("yield_uom")

# -----------------------------
# Header KPIs (service vs prep)
# -----------------------------

if rtype == "prep":
    pc = fetch_prep_costs_row(recipe_id) or {}
    total_cost = float(pc.get("total_cost") or 0.0)
    base_uom = pc.get("base_uom") or ""
    unit_cost = float(pc.get("unit_cost") or 0.0)

    c1, c2, c3 = st.columns([2, 2, 2])
    c1.metric("Total Cost", f"${total_cost:.2f}")
    c2.metric("Yield", f"{yield_qty or 0:g} {yield_uom or ''}")
    c3.metric(f"Unit Cost ({base_uom})", f"${unit_cost:.6f}")
else:
    srow = fetch_recipe_summary_row(recipe_id) or {}
    cost = float(srow.get("total_cost") or srow.get("cost") or 0.0)
    margin = float(srow.get("margin") or srow.get("margin_dollar") or (price - cost))
    cost_pct = (cost / price) * 100 if price else 0.0

    c1, c2, c3, c4 = st.columns([2, 2, 2, 2])
    c1.metric("Recipe", rname)
    c2.metric("Price", f"${price:.2f}")
    c3.metric("Cost (% of price)", f"{cost_pct:.1f}%")
    c4.metric("Margin", f"${margin:.2f}")

st.divider()

# -----------------------------
# Load lines + unit costs
# -----------------------------

line_rows = fetch_recipe_line_costs(recipe_id)
df = pd.DataFrame(line_rows)

# Always have base columns so grid renders even if empty
for c in ("recipe_line_id", "ingredient_id", "qty", "qty_uom", "line_cost"):
    if c not in df.columns:
        df[c] = None

notes_map = fetch_notes_map(recipe_id)

# Catalog for labels (ingredients + prep recipes)
catalog_rows = fetch_input_catalog()
id_to_label = {r["id"]: r["label"] for r in catalog_rows}
df["ingredient"] = df["ingredient_id"].map(id_to_label).fillna("— missing or inactive —")
df["note"] = df["recipe_line_id"].map(notes_map)

# Unit cost for the referenced input (ingredient or prep)
unit_costs = rpc_unit_cost_map(list({rid for rid in df["ingredient_id"].dropna().unique()}))
df["unit_cost"] = df["ingredient_id"].map(unit_costs)

# Display table
display_cols = ["recipe_line_id", "ingredient", "qty", "qty_uom", "unit_cost", "line_cost", "note"]
display_df = df.reindex(columns=[c for c in display_cols if c in df.columns]).copy()
for col in ["unit_cost", "line_cost"]:
    if col in display_df.columns:
        display_df[col] = pd.to_numeric(display_df[col], errors="coerce").map(
            lambda x: f"${x:.6f}" if pd.notnull(x) else ""
        )

gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
if "recipe_line_id" in display_df.columns:
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

# Robust selection handling (AgGrid may return list or DataFrame)
sel = grid_response.get("selected_rows", [])
if isinstance(sel, list):
    sel_df = pd.DataFrame(sel)
elif isinstance(sel, pd.DataFrame):
    sel_df = sel
else:
    sel_df = pd.DataFrame()

edit_data = None
if not sel_df.empty:
    sel_id = sel_df.iloc[0].get("recipe_line_id")
    match = df[df["recipe_line_id"] == sel_id]
    if not match.empty:
        m = match.iloc[0]
        edit_data = {
            "recipe_line_id": m.get("recipe_line_id"),
            "ingredient_id": m.get("ingredient_id"),
            "qty": float(m.get("qty") or 1.0),
            "qty_uom": m.get("qty_uom"),
            "note": notes_map.get(m.get("recipe_line_id"), ""),
        }

# -----------------------------
# Sidebar form — Save-only (handles add & update)
# -----------------------------

with st.sidebar:
    st.subheader("➕ Add or Edit Recipe Line")

    # Build dependency guard: exclude current recipe and its ancestors
    all_lines = fetch_all_recipe_lines_pairs()
    all_recipe_ids = {r["id"] for r in recipes}
    ancestors = compute_ancestor_recipes(recipe_id, all_lines, all_recipe_ids)
    blocked_recipes = ancestors | {recipe_id}

    # Selection options from catalog, excluding blocked recipes
    filtered_catalog = [
        r for r in catalog_rows
        if not (r["source"] == "recipe" and r["id"] in blocked_recipes)
    ]
    filtered_catalog.sort(key=lambda r: r["label"].lower())

    label_to_id = {"— Select —": None}
    for r in filtered_catalog:
        label_to_id[r["label"]] = r["id"]

    with st.form("line_form", clear_on_submit=False):
        default_label = None
        if edit_data:
            default_label = id_to_label.get(edit_data["ingredient_id"])
        labels = list(label_to_id.keys())
        selected_label = st.selectbox(
            "Ingredient or Prep Recipe",
            options=labels,
            index=(labels.index(default_label) if default_label in labels else 0)
        )
        ingredient_id = label_to_id.get(selected_label)

        qty = st.number_input(
            "Quantity",
            min_value=0.0,
            step=0.1,
            value=(edit_data["qty"] if edit_data else 1.0)
        )

        uom_opts = ["— Select —"] + fetch_uom_options()
        default_uom = edit_data["qty_uom"] if edit_data else None
        qty_uom = st.selectbox("UOM", options=uom_opts, index=(uom_opts.index(default_uom) if default_uom in uom_opts else 0))

        # Display unit cost (server-side)
        unit_cost_display = rpc_unit_cost_map([ingredient_id]).get(ingredient_id) if ingredient_id else None
        st.text_input("Unit Cost (base unit)", value=(f"{unit_cost_display:.6f}" if unit_cost_display is not None else ""), disabled=True)

        note_val = edit_data["note"] if edit_data else ""
        note = st.text_area("Note (optional)", value=note_val)

        # Single button: Save (adds or updates depending on selection)
        save_btn = st.form_submit_button("Save")

        if save_btn:
            errors = []
            if not ingredient_id:
                errors.append("Ingredient/Recipe")
            if not qty_uom or qty_uom == "— Select —":
                errors.append("UOM")
            if errors:
                st.error(f"⚠️ Please complete: {', '.join(errors)}")
            else:
                payload = {
                    "recipe_id": recipe_id,
                    "ingredient_id": ingredient_id,  # ingredient OR prep recipe id
                    "qty": round(float(qty), 6),
                    "qty_uom": qty_uom,
                    "note": note or None
                }
                upsert_recipe_line(edit_data is not None, (edit_data or {}).get("recipe_line_id"), payload)
                st.success("Line saved.")
                st.rerun()

# -----------------------------
# CSV Export
# -----------------------------

st.markdown("### 📥 Export Recipe Lines")
export_df = display_df.drop(columns=["recipe_line_id"], errors="ignore").copy()

def _strip_money(x):
    try:
        return float(str(x).replace("$", "")) if isinstance(x, str) and x.startswith("$") else x
    except Exception:
        return x

for c in ["unit_cost", "line_cost"]:
    if c in export_df.columns:
        export_df[c] = export_df[c].map(_strip_money)

st.download_button(
    label="Download Lines as CSV",
    data=export_df.to_csv(index=False),
    file_name=f"{(rname or 'recipe').replace(' ', '_')}_lines.csv",
    mime="text/csv",
)