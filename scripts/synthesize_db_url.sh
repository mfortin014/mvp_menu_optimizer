#!/usr/bin/env bash
set -euo pipefail

# Inputs:
# - Non-secrets (prefer env vars in GitHub Environments): SUPABASE_PROJECT_ID, DB_HOST, DB_PORT (default 5432), DB_NAME (default postgres)
# - Secret: DB_PASSWORD
# - Optional: DB_USER (if not provided, derive from DB_NAME.SUPABASE_PROJECT_ID)
#
# Behavior:
# - Derive DB_USER if missing
# - Percent-encode the password and assemble DATABASE_URL
# - Append sslmode=require
# - Do NOT echo secrets; write to $GITHUB_ENV

: "${DB_HOST:?missing}"
: "${DB_PASSWORD:?missing}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-postgres}"

# Derive DB_USER if not set but we have SUPABASE_PROJECT_ID
if [[ -z "${DB_USER:-}" ]]; then
  : "${SUPABASE_PROJECT_ID:?missing SUPABASE_PROJECT_ID (needed to derive DB_USER)}"
  DB_USER="${DB_NAME}.${SUPABASE_PROJECT_ID}"
fi

# Optionally publish SUPABASE_URL to the job env if project id is present
if [[ -n "${SUPABASE_PROJECT_ID:-}" ]]; then
  {
    printf 'SUPABASE_URL=%s\n' "https://${SUPABASE_PROJECT_ID}.supabase.co"
  } >>"$GITHUB_ENV"
fi

encoded_url="$(
python - <<'PY'
import os, urllib.parse
u=os.environ["DB_USER"]
p=os.environ["DB_PASSWORD"]
h=os.environ["DB_HOST"]
port=os.environ.get("DB_PORT","5432")
d=os.environ.get("DB_NAME","postgres")
print(f"postgresql://{u}:{urllib.parse.quote(p, safe='')}@{h}:{port}/{d}")
PY
)"

# Enforce SSL for Supabase
if [[ "$encoded_url" == *"?"* ]]; then
  encoded_url="${encoded_url}&sslmode=require"
else
  encoded_url="${encoded_url}?sslmode=require"
fi

{
  printf 'DATABASE_URL=%s\n' "$encoded_url"
} >>"$GITHUB_ENV"
