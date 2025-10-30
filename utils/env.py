import os

import streamlit as st


def get_env() -> str:
    # 1) Local override (supports `bws run`, direnv, .env exports)
    v = os.environ.get("APP_ENV")
    if v and str(v).strip():
        return str(v).strip().lower()
    # 2) Streamlit Cloud (secrets)
    if "APP_ENV" in st.secrets:
        return str(st.secrets["APP_ENV"]).strip().lower()
    # 3) Default
    return "prod"


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
