#!/usr/bin/env python3
import pathlib

EXCLUDE = {".venv", "venv", "__pycache__", ".git", "node_modules"}

def skip(p: pathlib.Path) -> bool:
    return any(part in EXCLUDE for part in p.parts)

def main():
    added = 0
    for p in pathlib.Path(".").rglob("*.py"):
        if skip(p): 
            continue
        t = p.read_text(encoding="utf-8")
        if "db." in t and "from utils import tenant_db as db" not in t:
            lines = t.splitlines()
            insert_at = 0
            for i, line in enumerate(lines[:50]):
                if line.startswith(("import ", "from ")):
                    insert_at = i + 1
            lines.insert(insert_at, "from utils import tenant_db as db")
            p.write_text("\n".join(lines), encoding="utf-8")
            added += 1
    print(f"Imports added: {added}")

if __name__ == "__main__":
    main()
