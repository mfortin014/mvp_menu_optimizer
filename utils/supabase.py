# utils/supabase.py
import os

import streamlit as st
from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

# Read credentials from Streamlit secrets or .env file
SUPABASE_URL = st.secrets.get("SUPABASE_URL") or os.getenv("SUPABASE_URL")
SUPABASE_KEY = st.secrets.get("SUPABASE_KEY") or os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
