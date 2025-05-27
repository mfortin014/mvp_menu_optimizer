import streamlit as st
import pandas as pd
import altair as alt
from utils.data import load_recipes_summary

st.set_page_config(page_title="Dashboard", layout="wide")
st.title("📊 Popularity-Profitability Dashboard")
st.write("Visualize recipes in a matrix to identify Stars, Plowhorses, Puzzles, and Dogs.")

data = load_recipes_summary()  # Should return recipe, popularity, profitability

if data.empty:
    st.info("No recipe summary available.")
else:
    chart = alt.Chart(data).mark_circle(size=100).encode(
        x='popularity:Q',
        y='profitability:Q',
        tooltip=['recipe', 'popularity', 'profitability'],
        color=alt.value("#1f77b4")
    ).properties(
        width=700,
        height=500
    ).interactive()

    st.altair_chart(chart)
