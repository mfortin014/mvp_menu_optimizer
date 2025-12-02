import os

import streamlit as st


def get_env() -> str:
    # 1) Local override (supports `bws run`, direnv, .env exports)
    v = os.environ.get("APP_ENV")
    if v and str(v).strip():
        return str(v).strip().lower()
    # 2) Streamlit Cloud (secrets) - handle missing secrets.toml gracefully
    try:
        if "APP_ENV" in st.secrets:
            return str(st.secrets["APP_ENV"]).strip().lower()
    except FileNotFoundError:
        # secrets.toml doesn't exist (local development without secrets file)
        # This is fine - we'll check if it was set via env var above
        pass
    except Exception:
        # Other errors accessing secrets (e.g., secrets not initialized)
        pass
    # 3) Fail-safe: require explicit environment specification
    # Never default to prod to prevent accidental production access
    raise RuntimeError(
        "APP_ENV must be explicitly set. "
        "Set it via environment variable (e.g., APP_ENV=test), Streamlit secrets, or add the APP_ENV secret to your Bitwarden project. "
        "This prevents accidentally running against the wrong environment. "
        'For local development, use: APP_ENV=<env> bws run --project-id="$<ENV>" -- streamlit run Home.py'
    )


def env_label() -> str:
    e = get_env()
    return {
        "prod": "PRODUCTION",
        "production": "PRODUCTION",
        "preview": "PREVIEW",
        "preprod": "PRE-PROD",
        "qa": "QA",
        "uat": "UAT",
        "test": "TEST",
        "dev": "DEV",
    }.get(e, e.upper())


def is_prod() -> bool:
    return get_env() in {"prod", "production"}
