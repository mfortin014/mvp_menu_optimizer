# utils/data.py
import pandas as pd
import streamlit as st
from utils.supabase import supabase


# === Recipes ===

def load_recipes_summary():
    try:
        res = supabase.table("recipe_summary").select("*").execute()
        return pd.DataFrame(res.data) if res.data else pd.DataFrame()
    except Exception as e:
        print("Failed to load recipe summary:", e)
        return pd.DataFrame()


def load_recipe_list():
    res = supabase.table("recipes").select("name").execute()
    return [item["name"] for item in res.data] if res.data else []


def load_recipe_details(recipe_name: str) -> pd.DataFrame:
    recipe = supabase.table("recipes").select("id, price").eq("name", recipe_name).single().execute()
    if not recipe.data:
        return pd.DataFrame()

    recipe_id = recipe.data["id"]
    selling_price = recipe.data["price"]

    query = supabase.rpc("get_recipe_details", {"rid": recipe_id}).execute()
    df = pd.DataFrame(query.data) if query.data else pd.DataFrame()

    if not df.empty:
        df["selling_price"] = selling_price

    return df


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


# === Recipe Lines ===

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


# === Ingredients ===

def load_ingredient_master():
    try:
        data = supabase.table("ingredients").select("*").execute()
        return pd.DataFrame(data.data)
    except Exception as e:
        st.error(f"Failed to load ingredients: {e}")
        return pd.DataFrame()


def get_ingredient_id_by_name(name):
    res = supabase.table("ingredients").select("id").eq("name", name).single().execute()
    return res.data["id"] if res.data else None


# === Reference Tables ===

def get_active_ingredient_categories():
    res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    return res.data if res.data else []
