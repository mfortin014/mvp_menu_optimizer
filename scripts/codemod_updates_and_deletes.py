#!/usr/bin/env python3
import re, pathlib
from utils import tenant_db as db

EXCLUDE = {".venv", "venv", "__pycache__", ".git", "node_modules"}

UPD = re.compile(r'\bsupabase\.table\(\s*[\'"]([^\'"]+)[\'"]\s*\)\.update\(')
DEL = re.compile(r'\bsupabase\.table\(\s*[\'"]([^\'"]+)[\'"]\s*\)\.delete\(\s*\)')

def skip(p: pathlib.Path) -> bool:
    return any(part in EXCLUDE for part in p.parts)

def main():
    changed = 0
    for p in pathlib.Path(".").rglob("*.py"):
        if skip(p): continue
        s = p.read_text(encoding="utf-8")
        o = s
        s = UPD.sub(r'db.table("\1").update(', s)
        s = DEL.sub(r'db.table("\1").delete()', s)
        if s != o:
            p.write_text(s, encoding="utf-8")
            changed += 1
    print(f"Files changed: {changed}")

if __name__ == "__main__":
    main()