#!/bin/bash
set -e

# Ensure .env file exists
if [ ! -f .env ]; then
  echo "❌ .env file not found. Please create it with your SUPABASE_URL."
  exit 1
fi

# Load SUPABASE_URL from .env
source <(grep SUPABASE_URL .env)

# Create schema directory if it doesn't exist
mkdir -p schema

# Dump schema to file
echo "🔄 Dumping Supabase schema to schema/supabase_schema.sql..."
pg_dump "$SUPABASE_URL" \
  --schema-only \
  --no-owner \
  --no-privileges \
  --file=schema/supabase_schema.sql

echo "✅ Schema successfully exported."
