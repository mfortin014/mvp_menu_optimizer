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
