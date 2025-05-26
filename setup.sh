#!/bin/bash

# ----------------------------------------
# Menu Optimizer – Streamlit + Supabase (WSL Scaffold)
# ----------------------------------------

set -e

# 1. Create base folder structure
mkdir -p .streamlit pages utils data

# 2. Create requirements.txt
cat <<EOF > requirements.txt
streamlit==1.35.0
pandas
sqlalchemy
matplotlib
openpyxl
psycopg2-binary
python-dotenv
EOF

# 3. Create app.py (entry point)
cat <<EOF > app.py
import streamlit as st
from pages import dashboard, recipes, ingredients

st.set_page_config(page_title="Menu Optimizer", layout="wide")
st.title("Menu Optimizer – MVP")

st.sidebar.title("Navigation")
page = st.sidebar.radio("Go to:", ["Dashboard", "Recipes", "Ingredients"])

if page == "Dashboard":
    dashboard.render()
elif page == "Recipes":
    recipes.render()
elif page == "Ingredients":
    ingredients.render()
EOF

# 4. Create individual pages with short descriptions
cat <<EOF > pages/1_Dashboard.py
def render():
    import streamlit as st
    st.subheader("📊 Popularity-Profitability Dashboard")
    st.write("Visualize recipes in a matrix to identify stars, dogs, and margin drivers.")
EOF

cat <<EOF > pages/2_Recipes.py
def render():
    import streamlit as st
    st.subheader("📋 Recipe Breakdown")
    st.write("Inspect recipe components, cost structure, and margins.")
EOF

cat <<EOF > pages/3_Ingredients.py
def render():
    import streamlit as st
    st.subheader("🧂 Ingredient Master Table")
    st.write("View all ingredient inputs, costs, and package sizing.")
EOF

# 5. Supabase connector stub
cat <<EOF > utils/db.py
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Replace with your actual DB URI from Supabase
DATABASE_URL = f"postgresql://postgres:[YOUR_DB_PASSWORD]@db.[YOUR_PROJECT].supabase.co:5432/postgres"

def get_engine():
    return create_engine(DATABASE_URL)
EOF

# 6. Streamlit secrets.toml with placeholders
cat <<EOF > .streamlit/secrets.toml
[supabase]
url = "https://your-project.supabase.co"
key = "ey_your_public_anon_key"
EOF

# 7. Optional: seed_supabase.py (CSV to Supabase)
cat <<EOF > seed_supabase.py
import pandas as pd
from sqlalchemy import create_engine
from utils.db import get_engine

engine = get_engine()

def upload_csv_to_table(csv_path, table_name):
    df = pd.read_csv(csv_path)
    df.to_sql(table_name, engine, if_exists='replace', index=False)
    print(f"✅ {table_name} uploaded")

# Example:
# upload_csv_to_table('data/sample_seed.csv', 'ingredients')
EOF

# 8. Git init (optional)
git init
cat <<EOF > .gitignore
.venv/
__pycache__/
*.db
.secrets.toml
EOF

echo "✅ Menu Optimizer scaffold created."
echo "📦 Next: create and activate a Python venv, then run:"
echo "   pip install -r requirements.txt"
echo "   streamlit run app.py"
