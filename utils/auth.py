import streamlit as st

def require_auth():
    if "authenticated" not in st.session_state:
        st.session_state.authenticated = False

    if not st.session_state.authenticated:
        st.title("🔐 Secure Access")
        password = st.text_input("Enter password:", type="password")
        if password == st.secrets.get("CHEF_PASSWORD"):
            st.session_state.authenticated = True
            st.success("Authenticated! You may continue.")
            st.rerun()
        elif password:
            st.error("Incorrect password")
            st.stop()
        else:
            st.stop()
