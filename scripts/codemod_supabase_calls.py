#!/usr/bin/env python3
import re
import sys
import pathlib
from utils import tenant_db as db

EXCLUDE = {".venv", "venv", "__pycache__", ".git", "node_modules"}

SEL = re.compile(r'(\bsupabase\.table\(\s*[\'"])([^\'"]+)([\'"]\s*\)\.select\()')
INS = re.compile(r'\bsupabase\.table\(\s*[\'"]([^\'"]+)[\'"]\s*\)\.insert\(')
UPS = re.compile(r'\bsupabase\.table\(\s*[\'"]([^\'"]+)[\'"]\s*\)\.upsert\(')

def skip(p: pathlib.Path) -> bool:
    return any(part in EXCLUDE for part in p.parts)

def main():
    changed = 0
    for p in pathlib.Path(".").rglob("*.py"):
        if skip(p): continue
        s = p.read_text(encoding="utf-8")
        o = s
        s = SEL.sub(r'db.table("\2").select(', s)
        s = INS.sub(r'db.insert("\1", ', s)
        s = UPS.sub(r'db.upsert("\1", ', s)
        if s != o:
            p.write_text(s, encoding="utf-8"); changed += 1
    print(f"Files changed: {changed}")

if __name__ == "__main__":
    main()