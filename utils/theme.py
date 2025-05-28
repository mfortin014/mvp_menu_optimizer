import json
import os

CONFIG_PATH = os.path.join("config", "branding_config.json")

def load_theme():
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading theme config: {e}")
        return {}

theme = load_theme()

def get_primary_color():
    return theme.get("primary_color", "#1f77b4")

def get_secondary_color():
    return theme.get("secondary_color", "#FFCC00")

def get_logo_path():
    return theme.get("logo_path", "")
