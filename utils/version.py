from pathlib import Path

__all__ = ["__version__"]
__version__ = (
    Path(__file__).resolve().parents[1].joinpath("VERSION").read_text().strip()
)
