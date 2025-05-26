from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Replace with your actual DB URI from Supabase
DATABASE_URL = f"postgresql://postgres:[YOUR_DB_PASSWORD]@db.[YOUR_PROJECT].supabase.co:5432/postgres"

def get_engine():
    return create_engine(DATABASE_URL)
