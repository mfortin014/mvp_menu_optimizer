import streamlit as st
from utils.tenant_state import get_active_tenant

def cache_by_tenant(ttl: int = 60):
    def wrap(fn):
        @st.cache_data(ttl=ttl)
        def _inner(_tid, *args, **kwargs):
            return fn(*args, **kwargs)
        def caller(*args, **kwargs):
            return _inner(get_active_tenant("no-tenant"), *args, **kwargs)
        return caller
    return wrap
