
# ==== TENANT SWITCHER (MVP) ====
import os
import streamlit as st
from utils.supabase import create_client
from utils.tenancy import ensure_tenant, set_current_tenant

SUPABASE_URL = os.getenv("SUPABASE_URL", st.secrets.get("SUPABASE_URL", ""))
SUPABASE_KEY = os.getenv("SUPABASE_KEY", st.secrets.get("SUPABASE_KEY", ""))
_sb = create_client(SUPABASE_URL, SUPABASE_KEY)
tenant_id, tenant_name = ensure_tenant(_sb)

with st.sidebar:
    st.markdown("### Client")
    tenants = _sb.table("tenants").select("id,name").is_("deleted_at","null").order("name").execute().data or []
    if tenants:
        names = [t["name"] for t in tenants]
        ids = [t["id"] for t in tenants]
        idx = ids.index(tenant_id) if tenant_id in ids else 0
        choice = st.selectbox("Select active client", names, index=idx, key="tenant_selectbox")
        new_id = tenants[names.index(choice)]["id"]
        if new_id != tenant_id:
            set_current_tenant(new_id, choice); st.rerun()

import streamlit as st
import pandas as pd
import altair as alt

from utils.data import load_recipes_summary
from utils.theme import get_primary_color, get_logo_path
from utils.auth import require_auth
require_auth()

# Setup
st.set_page_config(page_title="Home", layout="wide")
with st.sidebar:
    st.image(get_logo_path(), use_column_width=True)
st.markdown(f"<h1 style='color:{get_primary_color()}'>🏠 Home</h1>", unsafe_allow_html=True)

# Load summary data
df = load_recipes_summary()

# --- SECTION 1: Menu Performance Matrix ---
st.subheader("📈 Menu Performance Matrix")
if df.empty:
    st.info("Performance data is not available yet.")
else:
    # Axis bounds logic
    min_profitability = min(-0.25, df['profitability'].min() * 0.95)
    max_profitability = max(0.25, df['profitability'].max() * 1.05)
    max_popularity = df['popularity'].max() * 1.05
    x_mid = max_popularity / 2

    # Mid-lines
    vline = alt.Chart(pd.DataFrame({'x': [x_mid]})).mark_rule(strokeDash=[4, 4], color='gray').encode(x='x:Q')
    hline = alt.Chart(pd.DataFrame({'y': [0]})).mark_rule(strokeDash=[4, 4], color='gray').encode(y='y:Q')

    # Base matrix chart
    matrix_chart = alt.Chart(df).mark_circle(size=100).encode(
        x=alt.X('popularity:Q', title='Units Sold', scale=alt.Scale(domain=[0, max_popularity])),
        y=alt.Y('profitability:Q', title='Profitability (%)', scale=alt.Scale(domain=[min_profitability, max_profitability])),
        tooltip=['recipe', 'price', 'cost', 'margin_dollar', 'profitability', 'popularity'],
        color=alt.value(get_primary_color())
    ).properties(
        width=700,
        height=500
    ).interactive()

    # Combine and apply config
    final_chart = (matrix_chart + vline + hline).configure_axis(grid=False)
    st.altair_chart(final_chart, use_container_width=True)


# --- SECTION 2: KPIs ---
st.subheader("📊 Key Performance Indicators")
if df.empty:
    st.info("No recipe data available.")
else:
    avg_price = df["price"].mean()
    avg_cost_pct = (df["cost"] / df["price"]).replace([float("inf"), -float("inf")], None).dropna().mean() * 100
    avg_margin_dollar = df["margin_dollar"].mean()

    col1, col2, col3 = st.columns(3)
    col1.metric("Avg Price", f"${avg_price:.2f}")
    col2.metric("Avg Cost (% of Price)", f"{avg_cost_pct:.1f}%")
    col3.metric("Avg Margin ($)", f"${avg_margin_dollar:.2f}")

from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

# --- SECTION 3: Recipe Table ---
st.subheader("📋 Recipe Portfolio with Metrics")
if df.empty:
    st.info("No recipe data available to display.")
else:
    df["Cost (% of Price)"] = (df["cost"] / df["price"]) * 100
    display_df = df[["recipe", "price", "Cost (% of Price)", "margin_dollar"]].copy()

    display_df.rename(columns={
        "recipe": "Recipe",
        "price": "Price ($)",
        "margin_dollar": "Margin ($)"
    }, inplace=True)

    # Round values
    for col in ["Price ($)", "Cost (% of Price)", "Margin ($)"]:
        display_df[col] = display_df[col].round(2)

    # Configure AgGrid
    gb = GridOptionsBuilder.from_dataframe(display_df)
    gb.configure_default_column(editable=False, filter=True, sortable=True)

    # Right-align numeric columns
    for col in ["Price ($)", "Cost (% of Price)", "Margin ($)"]:
        gb.configure_column(col, type=["numericColumn", "rightAligned"], valueFormatter="x.toFixed(2)")

    grid_options = gb.build()

    AgGrid(
        display_df,
        gridOptions=grid_options,
        update_mode=GridUpdateMode.NO_UPDATE,
        fit_columns_on_grid_load=True,
        allow_unsafe_jscode=True
    )
