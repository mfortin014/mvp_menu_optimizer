import streamlit as st
import pandas as pd
from utils.supabase import supabase
from io import StringIO
from datetime import datetime

st.set_page_config(page_title="📥 Import Data", layout="wide")
st.title("📥 Import Data from CSV")

# === Select Object Type ===
object_type = st.selectbox("Select object to import", ["Ingredients", "Recipes"])

# === UOM Cache ===
valid_uoms = set()

# === INGREDIENTS ===
if object_type == "Ingredients":
    uploaded_file = st.file_uploader("Upload Ingredients CSV", type=["csv"], key="ingredients_upload")

    if uploaded_file:
        uom_res = supabase.table("ref_uom_conversion").select("from_uom").execute()
        valid_uoms = {r["from_uom"] for r in uom_res.data} if uom_res.data else set()
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
            "ingredient_code", "name", "ingredient_type",
            "package_qty", "package_uom", "package_cost",
            "yield_pct", "status", "category"
        ]
        missing_cols = [col for col in required_fields if col not in df.columns]
        if missing_cols:
            st.error(f"❌ Missing required columns: {', '.join(missing_cols)}")
            st.stop()

        # === Setup
        cat_res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
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
            if 0 < yield_pct <= 1:
                yield_pct = round(yield_pct * 100, 6)
            if pd.isna(yield_pct) or yield_pct <= 0 or yield_pct > 100:
                issues.append("Invalid yield_pct")
            if status.lower() not in valid_statuses and status != "":
                issues.append("Invalid status")
            if not category_id:
                issues.append("Category not found")

            exists = supabase.table("ingredients").select("*").eq("ingredient_code", ingredient_code).execute()
            if exists.data:
                existing_row = exists.data[0]
                duplicate_collisions.append({
                    "ingredient_code": ingredient_code,
                    "source": {
                        "name": name,
                        "ingredient_type": ingredient_type,
                        "package_cost": package_cost
                    },
                    "existing": {
                        "name": existing_row["name"],
                        "ingredient_type": existing_row["ingredient_type"],
                        "package_cost": existing_row["package_cost"]
                    }
                })
                continue

            if issues:
                rejected_row = row.to_dict()
                rejected_row["errors"] = "; ".join(issues)
                rejected.append(rejected_row)
            else:
                inserts.append({
                    "ingredient_code": ingredient_code,
                    "name": name,
                    "ingredient_type": ingredient_type if ingredient_type.lower() in valid_types else "Bought",
                    "package_qty": round(package_qty, 6),
                    "package_uom": package_uom,
                    "package_cost": round(package_cost, 6),
                    "yield_pct": round(yield_pct, 6),
                    "status": status if status.lower() in valid_statuses else "Active",
                    "category_id": category_id
                })

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
                mime="text/csv"
            )

        if inserts:
            if st.button("📤 Upload Ingredients to Database"):
                try:
                    supabase.table("ingredients").insert(inserts).execute()
                    st.success(f"🎉 {len(inserts)} ingredients successfully imported.")
                except Exception as e:
                    st.error(f"❌ Insert failed: {e}")


# === RECIPES ===
elif object_type == "Recipes":
    uploaded_file = st.file_uploader("Upload Recipes CSV", type=["csv"], key="recipes_upload")

    if uploaded_file:
        uom_res = supabase.table("ref_uom_conversion").select("from_uom").execute()
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
            r["recipe_code"]: r for r in supabase.table("recipes").select("*").execute().data
        }

        inserts = []
        rejects = []

        for _, row in df.iterrows():
            issues = []
            recipe_code = str(row.get("recipe_code", "")).strip()
            name = str(row.get("name", "")).strip()
            status = str(row.get("status", "Active")).strip().capitalize()
            base_yield_qty = row.get("base_yield_qty", 1.0)
            base_yield_uom = str(row.get("base_yield_uom", "")).strip()
            price = row.get("price", None)

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

            if base_yield_uom and base_yield_uom not in valid_uoms:
                issues.append(f"Invalid base_yield_uom: {base_yield_uom}")

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
                inserts.append({
                    "recipe_code": recipe_code,
                    "name": name,
                    "status": status,
                    "base_yield_qty": base_yield_qty,
                    "base_yield_uom": base_yield_uom or None,
                    "price": price,
                })

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
                mime="text/csv"
            )

        if inserts:
            if st.button("📤 Upload Recipes to Database"):
                try:
                    supabase.table("recipes").insert(inserts).execute()
                    st.success(f"🎉 {len(inserts)} recipes successfully imported.")
                except Exception as e:
                    st.error(f"❌ Insert failed: {e}")
