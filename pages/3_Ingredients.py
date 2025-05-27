import streamlit as st
from utils.data import load_ingredient_master

def render():
    st.subheader("📦 Ingredient Master Table")
    
    df = load_ingredient_master()
    if df.empty:
        st.info("No ingredients found.")
        return

    st.dataframe(df, use_container_width=True)
