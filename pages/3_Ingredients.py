import streamlit as st
import pandas as pd
from utils.data import load_ingredient_master  # to be created

def render():
    st.subheader("🧾 Ingredient Master Table")
    st.write("View all ingredient inputs, costs, and how frequently they are used.")

    df = load_ingredient_master()
    st.dataframe(df, use_container_width=True)
