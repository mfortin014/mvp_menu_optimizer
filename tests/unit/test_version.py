import re
from pathlib import Path


def test_version_follows_semver() -> None:
    version = Path("VERSION").read_text(encoding="utf-8").strip()
    assert re.fullmatch(r"\d+\.\d+\.\d+", version), "VERSION must be semantic (X.Y.Z)"
