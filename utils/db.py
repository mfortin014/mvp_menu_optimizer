from __future__ import annotations

import sys
from contextlib import ExitStack, redirect_stderr, redirect_stdout
from functools import lru_cache
from io import StringIO
from typing import Any, Callable, Optional

from sqlalchemy import create_engine
from sqlalchemy.engine import URL, Engine

DEFAULT_DRIVER = "postgresql"
ENGINE_DRIVER = "postgresql+psycopg"


@lru_cache(maxsize=1)
def _lazy_get_secret() -> Callable[..., Any]:
    """
    Import utils.secrets lazily to avoid Streamlit's CLI warning
    when this module is executed from the shell (e.g., python -m utils.db).
    """
    buffer = StringIO()
    with ExitStack() as stack:
        stack.enter_context(redirect_stderr(buffer))
        stack.enter_context(redirect_stdout(buffer))
        from utils.secrets import get as get_secret  # noqa: WPS433 (runtime import)
    return get_secret


def _get_secret(name: str, default: Any = None, *, required: bool = False) -> Any:
    return _lazy_get_secret()(name, default, required=required)


def database_url(driver: Optional[str] = None) -> str:
    """
    Single source of truth for building a Postgres URL.
    Always synthesize from DB_* secrets:
      - DB_HOST (required)
      - DB_PORT (default 5432)
      - DB_NAME (default postgres)
      - DB_USER (required, or derive as <DB_NAME>.<SUPABASE_PROJECT_ID>)
      - DB_PASSWORD (required)
    Enforces sslmode=require via URL query.

    Args:
        driver: Optional SQLAlchemy drivername (e.g., "postgresql+psycopg").
                Defaults to "postgresql" for CLI consumers like pg_dump/psql.
    """
    host = _get_secret("DB_HOST", required=True)
    port = int(_get_secret("DB_PORT", default="5432"))
    name = _get_secret("DB_NAME", default="postgres", required=True)

    user = _get_secret("DB_USER")
    if not user:
        proj = _get_secret("SUPABASE_PROJECT_ID", required=True)
        user = f"{name}.{proj}"

    password = _get_secret("DB_PASSWORD", required=True)

    url = URL.create(
        drivername=driver or DEFAULT_DRIVER,
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
    return create_engine(database_url(ENGINE_DRIVER), pool_pre_ping=True)


if __name__ == "__main__":
    # CLI helper for shell scripts:
    #   DBURL="$(python -m utils.db)"
    # Prints the full URL (with sslmode=require) to stdout.
    sys.stdout.write(database_url())
