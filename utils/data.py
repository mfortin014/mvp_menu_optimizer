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
    """Fetches recipe performance data from Supabase view 'recipe_summary'."""
    try:
        res = supabase.table("recipe_summary").select("*").execute()
        if res.data:
            df = pd.DataFrame(res.data)
            return df
        return pd.DataFrame()
    except Exception as e:
        print("Failed to load recipe summary:", e)
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

def add_recipe(name, code, price, yield_qty, yield_uom, status):
    try:
        res = supabase.table("recipes").insert({
            "name": name,
            "recipe_code": code,
            "price": price,
            "base_yield_qty": yield_qty,
            "base_yield_uom": yield_uom,
            "status": status
        }).execute()
        return res.status_code == 201
    except Exception as e:
        print("Error adding recipe:", e)
        return False

def get_recipe_id_by_name(name):
    res = supabase.table("recipes").select("id").eq("name", name).single().execute()
    return res.data["id"] if res.data else None

def get_ingredient_id_by_name(name):
    res = supabase.table("ingredients").select("id").eq("name", name).single().execute()
    return res.data["id"] if res.data else None

def add_recipe_line(recipe_id, ingredient_id, qty, qty_uom, note):
    try:
        res = supabase.table("recipe_lines").insert({
            "recipe_id": recipe_id,
            "ingredient_id": ingredient_id,
            "qty": qty,
            "qty_uom": qty_uom,
            "note": note
        }).execute()
        return res.status_code == 201
    except Exception as e:
        print("Error adding recipe line:", e)
        return False
