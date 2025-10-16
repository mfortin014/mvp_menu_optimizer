"""
Helper utilities for accessing configuration secrets.

Preference order:
  1. Environment variables injected by direnv / Bitwarden (BWS)
  2. Streamlit secrets (for CI compatibility)
"""

from __future__ import annotations

import os
from typing import Any, Optional

try:
    import streamlit as st  # type: ignore
except ModuleNotFoundError:  # pragma: no cover - streamlit isn't always present for scripts
    st = None  # type: ignore


def _from_streamlit(name: str) -> Optional[Any]:
    if st is None:
        return None

    try:
        secrets_obj = getattr(st, "secrets", None)
    except Exception:
        return None

    if secrets_obj is None:
        return None

    # Prefer the mapping-style .get when available
    getter = getattr(secrets_obj, "get", None)
    if callable(getter):
        try:
            value = getter(name, None)
        except FileNotFoundError:
            return None
        except Exception:
            value = None
        if value is not None:
            return value

    try:
        return secrets_obj[name]
    except FileNotFoundError:
        return None
    except Exception:
        return None


def get(name: str, default: Any = None, *, required: bool = False) -> Any:
    """
    Retrieve a secret value, preferring environment variables over Streamlit secrets.

    Args:
        name: Environment / secret key to lookup.
        default: Fallback value when not present.
        required: If True, raise RuntimeError when the key is missing and no default provided.
    """
    if not name:
        raise ValueError("Secret name must be non-empty.")

    value = os.environ.get(name)
    if value is None:
        value = _from_streamlit(name)

    if value is None:
        value = default

    if required and value is None:
        raise RuntimeError(f"Missing required secret: {name}")

    return value


__all__ = ["get"]
