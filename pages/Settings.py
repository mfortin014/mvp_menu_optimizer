from datetime import datetime

import pandas as pd
import streamlit as st

from components.active_client_badge import render as client_badge
from utils import tenant_db as db
from utils.auth import require_auth
from utils.env import env_label, is_prod

# Page chrome
title_suffix = "" if is_prod() else f" — {env_label()}"
st.set_page_config(page_title=f"Settings{title_suffix}", layout="wide")

# Non-prod banner
if not is_prod():
    st.warning(f"{env_label()} environment — data and behavior may differ from production.")

require_auth()

client_badge(clients_page_title="Clients")
st.title("⚙️ Settings")


st.header("🔧 Backfill Missing Base UOMs")


def fetch_base_uom_map():
    res = db.table("ref_uom_conversion").select("from_uom, to_uom").execute()
    return (
        {row["from_uom"]: row["to_uom"] for row in res.data if row["to_uom"] in ["g", "ml"]}
        if res.data
        else {}
    )


# Run only when button clicked
if st.button("Run Maintenance"):
    st.info("Fetching ingredients...")
    res = db.table("ingredients").select("id, package_uom, base_uom").execute()
    rows = res.data if res.data else []

    base_uom_map = fetch_base_uom_map()
    updates = []

    for row in rows:
        if row["base_uom"]:
            continue  # already set

        package_uom = row.get("package_uom", "")
        norm_uom = package_uom.lower()

        if norm_uom in ["each", "unit"]:
            inferred = "unit"
        elif package_uom in base_uom_map:
            inferred = base_uom_map[package_uom]
        else:
            inferred = None

        if inferred:
            updates.append({"id": row["id"], "base_uom": inferred})

    if updates:
        for u in updates:
            db.table("ingredients").update({"base_uom": u["base_uom"]}).eq("id", u["id"]).execute()

        st.success(f"✅ Updated {len(updates)} ingredients with inferred base_uom.")
    else:
        st.info("Nothing to update — all ingredients already have base_uom.")

# === Import Section ===
st.header("📥 Import Data from CSV")
object_type = st.selectbox("Select object to import", ["Ingredients", "Recipes"])

valid_uoms = set()

if object_type == "Ingredients":
    uploaded_file = st.file_uploader(
        "Upload Ingredients CSV", type=["csv"], key="ingredients_upload"
    )
    if uploaded_file:
        uom_res = db.table("ref_uom_conversion").select("from_uom, to_uom").execute()
        valid_uoms = {r["from_uom"] for r in uom_res.data} if uom_res.data else set()
        base_uom_map = {
            r["from_uom"]: r["to_uom"] for r in uom_res.data if r["to_uom"] in ["g", "ml"]
        }

        try:
            df = pd.read_csv(uploaded_file)
        except Exception as e:
            st.error(f"❌ Failed to read CSV: {e}")
            st.stop()

        if "errors" in df.columns:
            df = df.drop(columns=["errors"])

        st.subheader("👀 Preview")
        st.dataframe(df.head(), use_container_width=True)

        required_fields = [
            "ingredient_code",
            "name",
            "ingredient_type",
            "package_qty",
            "package_uom",
            "package_cost",
            "yield_pct",
            "status",
            "category",
        ]
        missing_cols = [col for col in required_fields if col not in df.columns]
        if missing_cols:
            st.error(f"❌ Missing required columns: {', '.join(missing_cols)}")
            st.stop()

        cat_res = (
            db.table("ref_ingredient_categories")
            .select("id, name")
            .eq("status", "Active")
            .execute()
        )
        category_map = {row["name"]: row["id"] for row in cat_res.data}
        valid_statuses = {"active", "inactive"}
        valid_types = {"bought", "prepped"}

        inserts, rejected, duplicate_collisions = [], [], []
        for _, row in df.iterrows():
            issues = []
            ingredient_code = str(row["ingredient_code"]).strip()
            name = str(row["name"]).strip()
            ingredient_type = str(row["ingredient_type"]).strip().capitalize()
            package_qty = row["package_qty"]
            package_uom = str(row["package_uom"]).strip()
            package_cost = row["package_cost"]
            yield_pct = row["yield_pct"]
            status = str(row["status"]).strip().capitalize()
            category_name = str(row["category"]).strip()
            base_uom = str(row.get("base_uom", "")).strip().lower() or None
            category_id = category_map.get(category_name)

            if not ingredient_code or len(ingredient_code) > 100:
                issues.append("Invalid or missing ingredient_code")
            if not name or len(name) > 100:
                issues.append("Invalid or missing name")
            if ingredient_type.lower() not in valid_types and ingredient_type != "":
                issues.append("Invalid ingredient_type")
            if pd.isna(package_qty) or package_qty < 0:
                issues.append("Invalid package_qty")
            if not package_uom:
                issues.append("Missing package_uom")
            if pd.isna(package_cost) or package_cost < 0:
                issues.append("Invalid package_cost")
            if 0 < yield_pct <= 2:
                yield_pct = round(yield_pct * 100, 6)
            if pd.isna(yield_pct) or yield_pct <= 0 or yield_pct > 200:
                issues.append("Invalid yield_pct")
            if status.lower() not in valid_statuses and status != "":
                issues.append("Invalid status")
            if not category_id:
                issues.append("Category not found")

            # --- 🔁 Infer base_uom if not provided ---
            if not base_uom:
                if package_uom.lower() in ["each", "unit"]:
                    base_uom = "unit"
                elif package_uom in base_uom_map:
                    base_uom = base_uom_map[package_uom]

            exists = (
                db.table("ingredients").select("*").eq("ingredient_code", ingredient_code).execute()
            )
            if exists.data:
                existing_row = exists.data[0]
                duplicate_collisions.append(
                    {
                        "ingredient_code": ingredient_code,
                        "source": {
                            "name": name,
                            "ingredient_type": ingredient_type,
                            "package_cost": package_cost,
                        },
                        "existing": {
                            "name": existing_row["name"],
                            "ingredient_type": existing_row["ingredient_type"],
                            "package_cost": existing_row["package_cost"],
                        },
                    }
                )
                continue

            if issues:
                rejected_row = row.to_dict()
                rejected_row["errors"] = "; ".join(issues)
                rejected.append(rejected_row)
            else:
                inserts.append(
                    {
                        "ingredient_code": ingredient_code,
                        "name": name,
                        "ingredient_type": (
                            ingredient_type if ingredient_type.lower() in valid_types else "Bought"
                        ),
                        "package_qty": round(package_qty, 6),
                        "package_uom": package_uom,
                        "package_cost": round(package_cost, 6),
                        "yield_pct": round(yield_pct, 6),
                        "status": (status if status.lower() in valid_statuses else "Active"),
                        "category_id": category_id,
                        "base_uom": base_uom,  # ✅ include inferred value (if any)
                    }
                )

        st.subheader("📊 Import Summary")
        st.write(f"✅ Valid rows ready to import: {len(inserts)}")
        st.write(f"❌ Rows rejected due to validation: {len(rejected)}")
        st.write(f"⚠️ Rows skipped due to duplicate codes: {len(duplicate_collisions)}")

        if duplicate_collisions:
            with st.expander("🔁 View Duplicate Conflicts"):
                for dup in duplicate_collisions:
                    st.markdown(f"**{dup['ingredient_code']}**")
                    st.markdown(f"- Source : `{dup['source']}`")
                    st.markdown(f"- In DB  : `{dup['existing']}`")

        if rejected:
            rejected_df = pd.DataFrame(rejected)
            csv = rejected_df.to_csv(index=False)
            st.download_button(
                label="⬇️ Download Rejected Rows CSV",
                data=csv,
                file_name="rejected_ingredients.csv",
                mime="text/csv",
            )

        if inserts:
            if st.button("📤 Upload Ingredients to Database"):
                try:
                    db.insert("ingredients", inserts).execute()
                    st.success(f"🎉 {len(inserts)} ingredients successfully imported.")
                except Exception as e:
                    st.error(f"❌ Insert failed: {e}")

elif object_type == "Recipes":
    uploaded_file = st.file_uploader("Upload Recipes CSV", type=["csv"], key="recipes_upload")

    if uploaded_file:
        uom_res = db.table("ref_uom_conversion").select("from_uom").execute()
        valid_uoms = {r["from_uom"] for r in uom_res.data} if uom_res.data else set()

        try:
            df = pd.read_csv(uploaded_file)
        except Exception as e:
            st.error(f"❌ Failed to read CSV: {e}")
            st.stop()

        df = df.drop(columns=["errors"], errors="ignore")
        st.subheader("👀 Preview")
        st.dataframe(df.head(), use_container_width=True)

        required_fields = ["recipe_code", "name"]
        missing_cols = [col for col in required_fields if col not in df.columns]
        if missing_cols:
            st.error(f"❌ Missing required columns: {', '.join(missing_cols)}")
            st.stop()

        existing_codes = {
            r["recipe_code"]: r for r in db.table("recipes").select("*").execute().data
        }

        inserts, rejects = [], []

        for _, row in df.iterrows():
            issues = []
            recipe_code = str(row.get("recipe_code", "")).strip()
            name = str(row.get("name", "")).strip()
            status = str(row.get("status", "Active")).strip().capitalize()
            base_yield_qty = row.get("base_yield_qty", 1.0)
            base_yield_uom = str(row.get("base_yield_uom", "")).strip()
            price = row.get("price", None)
            recipe_category = str(row.get("recipe_category", "")).strip() or None

            if not recipe_code:
                issues.append("Missing recipe_code")
            elif len(recipe_code) > 32:
                issues.append("recipe_code too long")
            elif recipe_code in existing_codes:
                existing = existing_codes[recipe_code]
                if existing["name"] != name:
                    issues.append("Duplicate recipe_code with different name")

            if not name:
                issues.append("Missing name")
            elif len(name) > 100:
                issues.append("Name too long")

            if status not in ["Active", "Inactive"]:
                issues.append("Invalid status")

            try:
                if pd.isna(base_yield_qty):
                    base_yield_qty = 1.0
                else:
                    base_yield_qty = round(float(base_yield_qty), 4)
                    if base_yield_qty <= 0:
                        issues.append("base_yield_qty must be > 0")
            except Exception:
                issues.append("Invalid base_yield_qty")

            # Allow free-form UOMs for now (your model allows it), warn if weird
            if base_yield_uom and len(base_yield_uom) > 20:
                issues.append(f"base_yield_uom too long: {base_yield_uom}")

            try:
                if pd.notna(price):
                    price = round(float(price), 4)
                    if price < 0:
                        issues.append("price must be >= 0")
                else:
                    price = None
            except Exception:
                issues.append("Invalid price")

            if issues:
                row["errors"] = "; ".join(issues)
                rejects.append(row)
            else:
                inserts.append(
                    {
                        "recipe_code": recipe_code,
                        "name": name,
                        "status": status,
                        "base_yield_qty": base_yield_qty,
                        "base_yield_uom": base_yield_uom or None,
                        "price": price,
                        "recipe_category": recipe_category,
                    }
                )

        st.subheader("📊 Import Summary")
        st.write(f"✅ Rows ready to import: {len(inserts)}")
        st.write(f"❌ Rows rejected: {len(rejects)}")

        if rejects:
            failed_df = pd.DataFrame(rejects)
            csv = failed_df.to_csv(index=False)
            st.download_button(
                label="📤 Download Rejected Rows",
                data=csv,
                file_name=f"recipes_rejected_{datetime.now().strftime('%Y%m%d%H%M%S')}.csv",
                mime="text/csv",
            )

        if inserts:
            if st.button("📤 Upload Recipes to Database"):
                try:
                    db.insert("recipes", inserts).execute()
                    st.success(f"🎉 {len(inserts)} recipes successfully imported.")
                except Exception as e:
                    st.error(f"❌ Insert failed: {e}")

# === Export Section ===
st.divider()
st.header("📤 Export Data")

exp_ingr = db.table("ingredients").select("*").execute()
df_ingr = pd.DataFrame(exp_ingr.data or [])
if not df_ingr.empty:
    st.download_button(
        label="⬇️ Download Ingredients CSV",
        data=df_ingr.to_csv(index=False),
        file_name="ingredients_export.csv",
        mime="text/csv",
    )


exp_rec = db.table("recipes").select("*").execute()
df_rec = pd.DataFrame(exp_rec.data or [])
if not df_rec.empty:
    st.download_button(
        label="⬇️ Download Recipes CSV (headers only)",
        data=df_rec.to_csv(index=False),
        file_name="recipes_export.csv",
        mime="text/csv",
    )

st.divider()


st.markdown(
    """
### ⚠️ Scrub Dataset
This action will **permanently delete all ingredients, recipes, and recipe lines** from the database.
- This **cannot be undone**.
- Exported data will not include recipe lines (only recipe headers).
- Re-importing exported recipes will not restore their content.

To confirm, type `DELETE` and click the button below.
"""
)

confirm = st.text_input("Type DELETE to confirm")
if st.button("🧹 Scrub Dataset"):
    if confirm == "DELETE":
        try:
            db.table("recipe_lines").delete().neq("id", "").execute()
            db.table("recipes").delete().neq("id", "").execute()
            db.table("ingredients").delete().neq("id", "").execute()
            st.success("✅ Dataset scrubbed successfully.")
        except Exception as e:
            st.error(f"❌ Failed to scrub dataset: {e}")
    else:
        st.warning("Please type DELETE to confirm.")
