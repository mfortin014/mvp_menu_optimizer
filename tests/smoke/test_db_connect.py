import os

import pytest
from sqlalchemy import text

from utils.db import get_engine


@pytest.mark.smoke
def test_db_can_connect_and_select_1():
    # Ensure CI gave us a URL (don’t print it)
    assert os.getenv("DATABASE_URL"), "DATABASE_URL was not set in CI job"
    engine = get_engine()
    with engine.connect() as conn:
        val = conn.execute(text("SELECT 1")).scalar()
        assert val == 1
