# utils/data.py
from __future__ import annotations

import pandas as pd
import streamlit as st
from typing import Dict, List, Optional, Any

from utils.supabase import supabase


# -----------------------------
# Helpers
# -----------------------------

def _to_df(res) -> pd.DataFrame:
    return pd.DataFrame(res.data) if getattr(res, "data", None) else pd.DataFrame()


# -----------------------------
# Recipe Summary / Dashboard
# -----------------------------

@st.cache_data(ttl=60)
def load_recipes_summary() -> pd.DataFrame:
    """
    Loads recipe portfolio metrics from the `recipe_summary` view.
    Makes Home.py resilient by synthesizing columns if the view doesn't expose them yet:
      - cost := total_cost
      - margin_dollar := price - cost
      - profitability := margin_dollar / price
      - popularity := 0 if absent (until sales upload exists)
    """
    try:
        res = supabase.table("recipe_summary").select("*").execute()
        df = _to_df(res)

        if df.empty:
            return df

        # Normalize field names expected by Home.py
        if "recipe" not in df.columns:
            for cand in ("name", "recipe_name"):
                if cand in df.columns:
                    df.rename(columns={cand: "recipe"}, inplace=True)
                    break

        if "cost" not in df.columns and "total_cost" in df.columns:
            df["cost"] = df["total_cost"]

        # Derived columns if absent
        if "margin_dollar" not in df.columns:
            df["margin_dollar"] = (df.get("price") - df.get("cost")).fillna(0.0)

        if "profitability" not in df.columns:
            # Avoid div/0 explosions
            price = df.get("price").replace({0: pd.NA})
            df["profitability"] = (df["margin_dollar"] / price).fillna(0.0)

        if "popularity" not in df.columns:
            df["popularity"] = df.get("units_sold", 0).fillna(0)

        return df
    except Exception as e:
        print("Failed to load recipe summary:", e)
        return pd.DataFrame()


# -----------------------------
# Recipes (master)
# -----------------------------

def load_recipe_list() -> List[str]:
    res = supabase.table("recipes").select("name").order("name").execute()
    return [r["name"] for r in (res.data or [])]


def get_recipe_id_by_name(name: str) -> Optional[str]:
    res = supabase.table("recipes").select("id").eq("name", name).single().execute()
    return res.data["id"] if res.data else None


def load_recipe_details(recipe_name: str) -> pd.DataFrame:
    """
    Uses existing get_recipe_details(rid uuid) RPC. We first resolve the recipe id by name,
    then call the RPC and augment it with selling_price for convenience.
    """
    recipe = supabase.table("recipes").select("id, price").eq("name", recipe_name).single().execute()
    if not recipe.data:
        return pd.DataFrame()

    rid = recipe.data["id"]
    selling_price = recipe.data["price"]

    query = supabase.rpc("get_recipe_details", {"rid": rid}).execute()
    df = _to_df(query)
    if not df.empty:
        df["selling_price"] = selling_price
    return df


def add_recipe(
    name: str,
    code: str,
    price: float,
    yield_qty: float,
    yield_uom: str,
    status: str,
    recipe_type: str = "service",
    recipe_category: Optional[str] = None,
) -> bool:
    """
    Inserts a recipe using the *new* fields and required `recipe_type`.
    """
    try:
        payload = {
            "name": name,
            "recipe_code": code,
            "price": round(float(price or 0), 6),
            "yield_qty": round(float(yield_qty or 0), 6),
            "yield_uom": yield_uom,
            "status": status,
            "recipe_type": recipe_type,
        }
        if recipe_category:
            payload["recipe_category"] = recipe_category

        res = supabase.table("recipes").insert(payload).execute()
        return getattr(res, "status_code", 400) in (200, 201)
    except Exception as e:
        print("Error adding recipe:", e)
        return False


def update_recipe(
    recipe_id: str,
    *,
    name: Optional[str] = None,
    code: Optional[str] = None,
    price: Optional[float] = None,
    yield_qty: Optional[float] = None,
    yield_uom: Optional[str] = None,
    status: Optional[str] = None,
    recipe_type: Optional[str] = None,
    recipe_category: Optional[str] = None,
) -> bool:
    """
    Partial update helper for recipes.
    """
    data: Dict[str, Any] = {}
    if name is not None:
        data["name"] = name
    if code is not None:
        data["recipe_code"] = code
    if price is not None:
        data["price"] = round(float(price), 6)
    if yield_qty is not None:
        data["yield_qty"] = round(float(yield_qty), 6)
    if yield_uom is not None:
        data["yield_uom"] = yield_uom
    if status is not None:
        data["status"] = status
    if recipe_type is not None:
        data["recipe_type"] = recipe_type
    if recipe_category is not None:
        data["recipe_category"] = recipe_category

    if not data:
        return True  # nothing to do

    try:
        res = supabase.table("recipes").update(data).eq("id", recipe_id).execute()
        return getattr(res, "status_code", 400) in (200, 204)
    except Exception as e:
        print("Error updating recipe:", e)
        return False


# -----------------------------
# Input catalog (ingredients + prep recipes)
# -----------------------------

@st.cache_data(ttl=60)
def get_input_catalog() -> pd.DataFrame:
    """
    Returns the unified list of selectable inputs (active ingredients + active prep recipes).
    Backed by the `input_catalog` view introduced in the DB repair.
      Columns expected: id, source ('ingredient'|'recipe'), code, name, base_uom
    """
    try:
        res = supabase.table("input_catalog").select("*").order("name").execute()
        df = _to_df(res)
        # Canonical display label for UI dropdowns
        if not df.empty:
            df["label"] = df.apply(
                lambda r: f"{r.get('name','')} – {r.get('code','')} [{r.get('source','?')}]",
                axis=1,
            )
        return df
    except Exception as e:
        print("Failed to load input_catalog:", e)
        return pd.DataFrame()


# -----------------------------
# Recipe lines
# -----------------------------

def get_recipe_lines(recipe_id: str) -> pd.DataFrame:
    """
    Fetches raw lines and enriches them with display info from input_catalog.
    """
    lines = _to_df(
        supabase.table("recipe_lines")
        .select("*")
        .eq("recipe_id", recipe_id)
        .order("created_at")
        .execute()
    )
    if lines.empty:
        return lines

    catalog = get_input_catalog()[["id", "label", "base_uom"]].rename(
        columns={"id": "input_id", "label": "input_label", "base_uom": "input_base_uom"}
    )
    lines = lines.rename(columns={"ingredient_id": "input_id"})
    return lines.merge(catalog, on="input_id", how="left")


def add_recipe_line(
    recipe_id: str,
    input_id: str,
    qty: float,
    qty_uom: str,
    note: Optional[str] = None,
) -> bool:
    """
    Inserts a line referencing either an ingredient OR a prep recipe.
    NOTE: This assumes `recipe_lines.ingredient_id` is NOT constrained to ingredients only.
          If you still have an FK like `recipe_lines_ingredient_id_fkey` to `ingredients(id)`,
          drop it before using prep recipes as inputs.
    """
    payload = {
        "recipe_id": recipe_id,
        "ingredient_id": input_id,  # unified column for ingredient OR prep recipe id
        "qty": round(float(qty or 0), 6),
        "qty_uom": qty_uom,
    }
    if note:
        payload["note"] = note

    try:
        res = supabase.table("recipe_lines").insert(payload).execute()
        return getattr(res, "status_code", 400) in (200, 201)
    except Exception as e:
        print("Error adding recipe line:", e)
        return False


def delete_recipe_line(recipe_line_id: str) -> bool:
    try:
        res = supabase.table("recipe_lines").delete().eq("id", recipe_line_id).execute()
        return getattr(res, "status_code", 400) in (200, 204)
    except Exception as e:
        print("Error deleting recipe line:", e)
        return False


# -----------------------------
# Unit cost lookup (RPC)
# -----------------------------

def get_unit_costs_for_inputs(inputs: List[Dict[str, str]]) -> pd.DataFrame:
    """
    Calls RPC `get_unit_costs_for_inputs(inputs jsonb)` which should accept payload like:
      [{"input_id": "<uuid>", "qty_uom": "g"}, ...]
    Returns a dataframe with at least: input_id, unit_cost, base_uom
    """
    try:
        res = supabase.rpc("get_unit_costs_for_inputs", {"inputs": inputs}).execute()
        return _to_df(res)
    except Exception as e:
        print("Error in get_unit_costs_for_inputs RPC:", e)
        return pd.DataFrame()


# -----------------------------
# Ingredients (master)
# -----------------------------

@st.cache_data(ttl=60)
def load_ingredient_master() -> pd.DataFrame:
    try:
        res = supabase.table("ingredients").select("*").execute()
        return _to_df(res)
    except Exception as e:
        st.error(f"Failed to load ingredients: {e}")
        return pd.DataFrame()


def get_ingredient_id_by_name(name: str) -> Optional[str]:
    res = supabase.table("ingredients").select("id").eq("name", name).single().execute()
    return res.data["id"] if res.data else None


# -----------------------------
# Reference data (UOM, categories)
# -----------------------------

@st.cache_data(ttl=60)
def get_uom_list() -> List[str]:
    """
    Returns a flat list of UOMs from ref_uom_conversion (both from_uom and to_uom).
    Identity conversions should already exist (g->g, ml->ml, etc.).
    """
    try:
        res = supabase.table("ref_uom_conversion").select("from_uom, to_uom").execute()
        df = _to_df(res)
        if df.empty:
            return []
        uoms = pd.unique(pd.concat([df["from_uom"], df["to_uom"]], ignore_index=True).dropna())
        return sorted(map(str, uoms))
    except Exception:
        return []


@st.cache_data(ttl=60)
def get_active_ingredient_categories() -> List[Dict[str, Any]]:
    res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    return res.data or []
