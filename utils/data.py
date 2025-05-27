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
    """Returns a simple list of recipe names for dropdown."""
    res = supabase.table("recipes").select("name").execute()
    if res.data:
        return [item["name"] for item in res.data]
    return []

def load_recipe_details(recipe_name: str) -> pd.DataFrame:
    """Returns full breakdown of a given recipe, including ingredient info and costing."""
    recipe = supabase.table("recipes").select("id, price").eq("name", recipe_name).single().execute()
    if not recipe.data:
        return pd.DataFrame()

    recipe_id = recipe.data["id"]
    selling_price = recipe.data["price"]

    query = supabase.rpc("get_recipe_details", {"rid": recipe_id}).execute()
    if not query.data:
        return pd.DataFrame()

    df = pd.DataFrame(query.data)
    df["selling_price"] = selling_price
    return df


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
