#!/usr/bin/env python3
# repo_tree.py
from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Dict, List, Tuple

EXCLUDES_DEFAULT = {".git", ".venv", "node_modules", "__pycache__", ".idea", ".vscode"}

DirMap = Dict[Path, Tuple[List[Path], List[Path]]]


def build_dir_map(root: Path, excludes: set[str]) -> DirMap:
    """
    Build a mapping of each directory (relative to root) to its (dirs, files),
    already filtered and sorted. Excludes apply by name at any level.
    """
    dir_map: DirMap = {}
    root = root.resolve()

    for current, dirnames, filenames in os.walk(root, topdown=True):
        # Filter directories in-place so os.walk won't descend into excluded dirs
        dirnames[:] = [d for d in dirnames if d not in excludes]
        # Filter files by simple name match as well
        files = [f for f in filenames if f not in excludes]

        cur_path = Path(current)
        rel_dir = cur_path.relative_to(root)

        # Build relative Paths for children
        rel_dirs = sorted((rel_dir / d) for d in dirnames)
        rel_files = sorted((rel_dir / f) for f in files)

        dir_map.setdefault(rel_dir, ([], []))
        dir_map[rel_dir] = (rel_dirs, rel_files)

    # Ensure missing parents exist in map (in case root is empty, etc.)
    if Path(".") not in dir_map:
        dir_map[Path(".")] = ([], [])
    return dir_map


def render_tree(dir_map: DirMap) -> str:
    lines: List[str] = []
    lines.append(".")

    def draw(dir_path: Path, prefix: str = ""):
        dirs, files = dir_map.get(dir_path, ([], []))
        # Render directories first, then files
        items = [("dir", d) for d in dirs] + [("file", f) for f in files]

        for i, (kind, p) in enumerate(items):
            is_last = i == len(items) - 1
            connector = "└── " if is_last else "├── "
            lines.append(f"{prefix}{connector}{p.name}")

            if kind == "dir":
                # For the child directory, fetch its own children
                # and continue recursion with an extended prefix
                child_prefix = f"{prefix}{'    ' if is_last else '│   '}"
                draw(p, child_prefix)

    draw(Path("."))
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(
        description="Write a folder+file tree to a .txt file (like `tree`)."
    )
    ap.add_argument("path", nargs="?", default=".", help="Repo root (default: current dir)")
    ap.add_argument(
        "--out", default="repo_contents.txt", help="Output file (default: repo_contents.txt)"
    )
    ap.add_argument(
        "--exclude",
        default=",".join(sorted(EXCLUDES_DEFAULT)),
        help=f"Comma-separated names to exclude (default: {','.join(sorted(EXCLUDES_DEFAULT))})",
    )
    args = ap.parse_args()

    root = Path(args.path).resolve()
    excludes = {x.strip() for x in args.exclude.split(",")} if args.exclude else set()

    dir_map = build_dir_map(root, excludes)
    txt = render_tree(dir_map)

    Path(args.out).write_text(txt, encoding="utf-8")
    print(f"Wrote {args.out} (root: {root})")


if __name__ == "__main__":
    main()
