import pandas as pd
import streamlit as st
from supabase import create_client, Client
import os
from dotenv import load_dotenv

load_dotenv()

# Read from secrets or environment variables
SUPABASE_URL = st.secrets["SUPABASE_URL"] if "SUPABASE_URL" in st.secrets else os.getenv("SUPABASE_URL")
SUPABASE_KEY = st.secrets["SUPABASE_KEY"] if "SUPABASE_KEY" in st.secrets else os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def load_recipes_summary():
    """
    Load a summary table with columns: recipe, popularity, profitability
    """
    try:
        data = supabase.table("recipe_summary").select("*").execute()
        df = pd.DataFrame(data.data)
        return df
    except Exception as e:
        st.error(f"Failed to load recipe summary: {e}")
        return pd.DataFrame()


def load_recipe_list():
    """
    Return a list of recipe names for dropdowns.
    """
    try:
        data = supabase.table("recipes").select("name").execute()
        return [row["name"] for row in data.data]
    except Exception as e:
        st.error(f"Failed to load recipe list: {e}")
        return []


def load_recipe_details(recipe_name):
    """
    Load ingredients, quantities, unit costs, selling price for a given recipe.
    """
    try:
        data = supabase.rpc("get_recipe_details", {"recipe_name": recipe_name}).execute()
        return pd.DataFrame(data.data)
    except Exception as e:
        st.error(f"Failed to load details for '{recipe_name}': {e}")
        return pd.DataFrame()


def load_ingredient_master():
    """
    Load full list of ingredients with prices and usage stats.
    """
    try:
        data = supabase.table("ingredients").select("*").execute()
        return pd.DataFrame(data.data)
    except Exception as e:
        st.error(f"Failed to load ingredients: {e}")
        return pd.DataFrame()
