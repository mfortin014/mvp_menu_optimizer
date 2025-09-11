#!/usr/bin/env python3
import re, pathlib
from utils import tenant_db as db

EXCLUDE = {".venv", "venv", "__pycache__", ".git", "node_modules"}

TARGETS = {
    "ingredients", "recipes", "recipe_lines",
    "ingredient_costs", "input_catalog", "recipe_line_costs",
    "recipe_line_costs_base", "recipe_summary", "prep_costs",
    # add more if you create new tenant-scoped views
}

# matches supabase.table("name") even across spaces/newlines
TAB_CALL = re.compile(r'supabase\s*\.\s*table\s*\(\s*([\'"])([^\'"]+)\1\s*\)', re.MULTILINE)

def skip(p: pathlib.Path) -> bool:
    return any(part in EXCLUDE for part in p.parts)

def main():
    changed = 0
    for p in pathlib.Path(".").rglob("*.py"):
        if skip(p): 
            continue
        s = p.read_text(encoding="utf-8")
        o = s

        def repl(m):
            quote, name = m.group(1), m.group(2)
            if name in TARGETS:
                return f'db.table({quote}{name}{quote})'
            return m.group(0)  # leave as-is (e.g., tenants, ref_uom_conversion)

        s = TAB_CALL.sub(repl, s)

        if s != o:
            p.write_text(s, encoding="utf-8")
            changed += 1

    print(f"Files changed: {changed}")

if __name__ == "__main__":
    main()