import streamlit as st
import pandas as pd
from utils.supabase import supabase

st.set_page_config(page_title="Import Data", layout="wide")
st.title("📥 Import Ingredients from CSV")

# === Upload CSV ===
uploaded_file = st.file_uploader("Upload CSV File", type=["csv"])

if uploaded_file:
    try:
        df = pd.read_csv(uploaded_file)
    except Exception as e:
        st.error(f"❌ Failed to read CSV: {e}")
        st.stop()

    # === Display Preview ===
    st.subheader("👀 Preview")
    st.dataframe(df.head(), use_container_width=True)

    # === Required Fields
    required_fields = [
        "ingredient_code", "name", "ingredient_type", "package_qty",
        "package_uom", "package_cost", "yield_pct", "status", "category_id"
    ]
    missing = [col for col in required_fields if col not in df.columns]

    if missing:
        st.error(f"❌ Missing required columns: {', '.join(missing)}")
        st.stop()

    # === Validate + Prepare
    df = df[required_fields].copy()
    df = df.dropna(subset=["ingredient_code", "name"])  # Ensure essential values exist

    duplicates = []
    inserts = []

    for _, row in df.iterrows():
        code = row["ingredient_code"]
        existing = supabase.table("ingredients").select("id").eq("ingredient_code", code).execute()
        if existing.data:
            duplicates.append(code)
        else:
            inserts.append(row.to_dict())

    # === Summary
    st.markdown("### 📝 Import Summary")
    st.write(f"✅ Valid new rows: {len(inserts)}")
    st.write(f"⚠️ Duplicates skipped: {len(duplicates)}")
    if duplicates:
        st.write(", ".join(duplicates[:10]) + ("..." if len(duplicates) > 10 else ""))

    if inserts:
        if st.button("📤 Import Ingredients"):
            res = supabase.table("ingredients").insert(inserts).execute()
            if res.status_code == 201:
                st.success(f"🎉 {len(inserts)} ingredients imported successfully.")
            else:
                st.error("❌ Failed to insert data.")
