import streamlit as st
import pandas as pd
from utils.supabase import supabase
import io

st.set_page_config(page_title="Import Ingredients", layout="wide")
st.title("📥 Import Ingredients from CSV")

# === Upload CSV ===
uploaded_file = st.file_uploader("Upload Ingredients CSV", type=["csv"])

if uploaded_file:
    try:
        df = pd.read_csv(uploaded_file)
    except Exception as e:
        st.error(f"❌ Failed to read CSV: {e}")
        st.stop()

    # 🧹 Clean up any leftover 'errors' column from previous download
    if "errors" in df.columns:
        df = df.drop(columns=["errors"])

    # === Display Preview ===
    st.subheader("👀 Preview")
    st.dataframe(df.head(), use_container_width=True)

    # === Required columns
    required_fields = [
        "ingredient_code", "name", "ingredient_type",
        "package_qty", "package_uom", "package_cost",
        "yield_pct", "status", "category"
    ]
    missing_cols = [col for col in required_fields if col not in df.columns]
    if missing_cols:
        st.error(f"❌ Missing required columns: {', '.join(missing_cols)}")
        st.stop()

    # === Normalize + validate ===
    cat_res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    category_map = {row["name"]: row["id"] for row in cat_res.data}
    valid_statuses = {"active", "inactive"}
    valid_types = {"bought", "prepped"}

    inserts = []
    rejected = []
    duplicate_collisions = []

    df = df[required_fields].copy()
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

        # === Validations
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
        # Convert low % to base-100 early
        if 0 < yield_pct <= 1:
            yield_pct = round(yield_pct * 100, 6)

        # Now validate the final result
        if pd.isna(yield_pct) or yield_pct <= 0 or yield_pct > 100:
            issues.append("Invalid yield_pct")
        if status.lower() not in valid_statuses and status != "":
            issues.append("Invalid status")
        if not category_id:
            issues.append("Category not found")

        # === Check for duplicates
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
                "ingredient_type": ingredient_type if ingredient_type in valid_types else "Bought",
                "package_qty": round(package_qty, 6),
                "package_uom": package_uom,
                "package_cost": round(package_cost, 6),
                "yield_pct": round(yield_pct, 6),
                "status": status if status in valid_statuses else "Active",
                "category_id": category_id
            })

    # === Summary Output ===
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
        columns = [col for col in rejected_df.columns if col != "errors"] + ["errors"]
        csv = rejected_df[columns].to_csv(index=False).encode("utf-8")

        st.download_button(
            "⬇️ Download Rejected Rows CSV",
            data=csv,
            file_name="rejected_ingredients.csv",
            mime="text/csv"
        )

    # === Upload Button ===
    if inserts:
        if st.button("📤 Upload Ingredients to Database"):
            try:
                supabase.table("ingredients").insert(inserts).execute()
            except Exception as e:
                st.error(f"❌ Insert failed: {e}")
                st.stop()

            st.success(f"🎉 {len(inserts)} ingredients successfully imported.")

