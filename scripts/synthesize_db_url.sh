#!/usr/bin/env bash
set -euo pipefail

# Requires env: DB_HOST, DB_USER, DB_PASSWORD
# Optional: DB_PORT (default 5432), DB_NAME (default postgres)
: "${DB_HOST:?missing}"; : "${DB_USER:?missing}"; : "${DB_PASSWORD:?missing}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-postgres}"

# Use Python to percent-encode the password and assemble the URL.
# IMPORTANT: do not echo the URL to stdout (to avoid logs); write to $GITHUB_ENV.
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

# Export for this job without printing the value
{
  printf 'DATABASE_URL=%s\n' "$encoded_url"
} >>"$GITHUB_ENV"
