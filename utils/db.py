from sqlalchemy import create_engine
from sqlalchemy.engine import URL, Engine, make_url

from utils.secrets import get as get_secret


def _compute_database_url() -> str:
    """
    Prefer DATABASE_URL if present (keeps CI/back-compat).
    Otherwise synthesize it from DB_* components, letting SQLAlchemy
    percent-encode the password safely.
    """
    url = get_secret("DATABASE_URL")
    if url:
        parsed = make_url(url)
        if parsed.drivername in {"postgresql", "postgresql+psycopg2", "postgres"}:
            parsed = parsed.set(drivername="postgresql+psycopg")
        return str(parsed)

    host = get_secret("DB_HOST", required=True)
    port = int(get_secret("DB_PORT", default="5432"))
    name = get_secret("DB_NAME", default="postgres", required=True)
    user = get_secret("DB_USER", required=True)
    password = get_secret("DB_PASSWORD", required=True)

    safe = URL.create(
        drivername="postgresql+psycopg",  # or "postgresql" if using psycopg2
        username=user,
        password=password,  # raw; will be encoded correctly in the URL
        host=host,
        port=port,
        database=name,
    )
    return str(safe)


def get_engine() -> Engine:
    return create_engine(_compute_database_url(), pool_pre_ping=True)
