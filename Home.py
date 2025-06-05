import streamlit as st
import pandas as pd
import altair as alt

from utils.data import load_recipes_summary
from utils.theme import get_primary_color, get_logo_path

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
    total_recipes = len(df)
    total_units_sold = df['popularity'].sum()
    avg_profitability = df['profitability'].mean()
    avg_margin_dollar = df['margin_dollar'].mean()

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total Recipes", total_recipes)
    col2.metric("Total Units Sold", int(total_units_sold))
    col3.metric("Avg Margin (%)", f"{avg_profitability:.0%}")
    col4.metric("Avg Margin ($)", f"${avg_margin_dollar:.2f}")

# --- SECTION 3: Recipe Table ---
st.subheader("📋 Recipe Portfolio with Metrics")
if df.empty:
    st.info("No recipe data available to display.")
else:
    display_df = df[[
        'recipe', 'price', 'cost', 'margin_dollar', 'profitability', 'popularity'
    ]].copy()

    display_df.rename(columns={
        'recipe': 'Recipe',
        'price': 'Price ($)',
        'cost': 'Cost ($)',
        'margin_dollar': 'Margin ($)',
        'profitability': 'Margin (%)',
        'popularity': 'Units Sold'
    }, inplace=True)

    display_df['Margin (%)'] = (display_df['Margin (%)'] * 100).round(1)
    st.dataframe(display_df, use_container_width=True)
