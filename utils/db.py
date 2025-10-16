from __future__ import annotations

import sys

from sqlalchemy import create_engine
from sqlalchemy.engine import URL, Engine

from utils.secrets import get as get_secret


def database_url() -> str:
    """
    Single source of truth for building a Postgres URL.
    Always synthesize from DB_* secrets:
      - DB_HOST (required)
      - DB_PORT (default 5432)
      - DB_NAME (default postgres)
      - DB_USER (required, or derive as <DB_NAME>.<SUPABASE_PROJECT_ID>)
      - DB_PASSWORD (required)
    Enforces sslmode=require via URL query.
    """
    host = get_secret("DB_HOST", required=True)
    port = int(get_secret("DB_PORT", default="5432"))
    name = get_secret("DB_NAME", default="postgres", required=True)

    user = get_secret("DB_USER")
    if not user:
        proj = get_secret("SUPABASE_PROJECT_ID", required=True)
        user = f"{name}.{proj}"

    password = get_secret("DB_PASSWORD", required=True)

    url = URL.create(
        drivername="postgresql+psycopg",
        username=user,
        password=password,  # raw; SQLAlchemy percent-encodes on render
        host=host,
        port=port,
        database=name,
        query={"sslmode": "require"},
    )
    # include password visibly for downstream CLI consumers (pg_dump/psql)
    return url.render_as_string(hide_password=False)


def get_engine() -> Engine:
    return create_engine(database_url(), pool_pre_ping=True)


if __name__ == "__main__":
    # CLI helper for shell scripts:
    #   DBURL="$(python -m utils.db)"
    # Prints the full URL (with sslmode=require) to stdout.
    sys.stdout.write(database_url())
