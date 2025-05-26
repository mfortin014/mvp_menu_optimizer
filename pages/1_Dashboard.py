import streamlit as st
import pandas as pd
import altair as alt
from utils.data import load_recipes_summary  # to be created

def render():
    st.subheader("📊 Popularity-Profitability Dashboard")
    st.write("Visualize recipes in a matrix to identify Stars, Plowhorses, Puzzles, and Dogs.")

    data = load_recipes_summary()  # should contain recipe name, popularity, profitability

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
