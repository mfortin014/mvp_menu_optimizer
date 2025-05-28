import streamlit as st
import pandas as pd
import altair as alt

from utils.data import load_recipes_summary
from utils.theme import get_primary_color, get_logo_path

# Set page meta
st.set_page_config(page_title="Home", layout="wide")

# Branding
st.image(get_logo_path(), width=120)
st.markdown(f"<h1 style='color:{get_primary_color()}'>Home</h1>", unsafe_allow_html=True)
st.caption("This page combines visual performance analysis with recipe profitability and sales stats.")

# Load data
data = load_recipes_summary()  # Expected: recipe, popularity, profitability, sales, cost, margin...

# --- SECTION 1: Menu Performance Matrix ---
st.markdown("## 📈 Menu Performance Matrix")
if data.empty:
    st.info("Performance data is not available yet. Connect sales and cost data to enable this chart.")
else:
    matrix_chart = alt.Chart(data).mark_circle(size=100).encode(
        x=alt.X('popularity:Q', title='Popularity (Units Sold)'),
        y=alt.Y('profitability:Q', title='Profitability (Margin %)'),
        tooltip=['recipe', 'popularity', 'profitability'],
        color=alt.value(get_primary_color())
    ).properties(
        width=700,
        height=500,
        title="Menu Item Positioning"
    ).interactive()

    st.altair_chart(matrix_chart, use_container_width=True)

# --- SECTION 2: Key Performance Indicators ---
st.markdown("## 📊 Key Performance Indicators")
if data.empty:
    st.info("No aggregated recipe data available yet.")
else:
    total_recipes = len(data)
    avg_margin = data['profitability'].mean()
    total_sales = data['popularity'].sum()

    col1, col2, col3 = st.columns(3)
    col1.metric("Total Recipes", f"{total_recipes}")
    col2.metric("Average Margin", f"{avg_margin:.0%}")
    col3.metric("Total Units Sold", f"{int(total_sales)}")

# --- SECTION 3: Recipes Table ---
st.markdown("## 📋 Recipe Portfolio with Stats")
if data.empty:
    st.info("No recipe data available to display in the table.")
else:
    display_cols = ['recipe', 'popularity', 'profitability']  # extend later with: price, cost, revenue, category
    df = data[display_cols].copy()
    df.rename(columns={
        'recipe': 'Recipe',
        'popularity': 'Units Sold',
        'profitability': 'Margin %'
    }, inplace=True)

    st.dataframe(df, use_container_width=True)
