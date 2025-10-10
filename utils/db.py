from sqlalchemy import create_engine

from utils.secrets import get as get_secret

DATABASE_URL = get_secret("DATABASE_URL", required=True)


def get_engine():
    return create_engine(DATABASE_URL)
