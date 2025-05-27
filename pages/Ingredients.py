import streamlit as st
from utils.data import load_ingredient_master

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("📦 Ingredient Master Table")

df = load_ingredient_master()
if df.empty:
    st.info("No ingredients found.")
else:
    st.dataframe(df, use_container_width=True)
