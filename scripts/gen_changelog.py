#!/usr/bin/env python3
"""
Generate CHANGELOG.md from git history using (loose) Conventional Commits,
grouped per tag and aligned with "Keep a Changelog".

Usage examples:
  python3 scripts/gen_changelog.py --all
  python3 scripts/gen_changelog.py --since-tag mvp-0.6.0
  python3 scripts/gen_changelog.py --output CHANGELOG.md
  python3 scripts/gen_changelog.py --all --unreleased-summary

Notes:
- The first tag section now includes commits from the repository root up to that tag.
- Unreleased can be rendered as a short summary (counts per section) with --unreleased-summary.
"""

import argparse
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Tuple, Dict, Optional

# --- git helpers -------------------------------------------------------------

def git(args: List[str], cwd: str = ".") -> str:
    out = subprocess.check_output(["git"] + args, cwd=cwd)
    return out.decode("utf-8", errors="replace").strip()

def git_lines(args: List[str], cwd: str = ".") -> List[str]:
    s = git(args, cwd)
    return [line for line in s.splitlines() if line.strip()]

def repo_https_url() -> Optional[str]:
    try:
        url = git(["remote", "get-url", "origin"])
    except Exception:
        return None
    # Normalize to https://github.com/owner/repo
    if url.startswith("git@github.com:"):
        owner_repo = url.split(":", 1)[1].rstrip(".git")
        return f"https://github.com/{owner_repo}"
    if url.startswith("https://github.com/"):
        return url.rstrip(".git")
    return None

def tag_list(tag_prefix: str) -> List[str]:
    try:
        return git_lines(["tag", "--list", f"{tag_prefix}*", "--sort=version:refname"])
    except subprocess.CalledProcessError:
        return []

def tag_date(tag: str) -> str:
    try:
        ts = git(["log", "-1", "--format=%cs", tag])
    except subprocess.CalledProcessError:
        ts = datetime.today().strftime("%Y-%m-%d")
    return ts

def root_commit() -> str:
    roots = git_lines(["rev-list", "--max-parents=0", "HEAD"])
    return roots[-1] if roots else git(["rev-parse", "HEAD"])

def commit_range_commits(rng: str) -> List[Dict[str, str]]:
    fmt = r"%H%x1f%h%x1f%cs%x1f%an%x1f%s%x1e"
    out = git(["log", "--no-merges", f"--pretty=format:{fmt}", rng])
    commits = []
    if not out.strip():
        return commits
    for rec in out.split("\x1e"):
        if not rec.strip():
            continue
        parts = rec.split("\x1f")
        if len(parts) < 5:
            continue
        full, short, date, author, subject = parts[:5]
        commits.append({"sha": full, "short": short, "date": date, "author": author, "subject": subject.strip()})
    return commits

# --- categorization ----------------------------------------------------------

TYPE_MAP = {
    "feat": "Added",
    "fix": "Fixed",
    "perf": "Changed",
    "refactor": "Changed",
    "docs": "Documentation",
    "test": "Tests",
    "build": "Build",
    "ci": "CI",
    "chore": "Chore",
    "revert": "Reverted",
    "style": "Style",
}

IGNORE_SUBJECT_PATTERNS = [
    r"^release\(",            # release(x.y.z): ...
    r"^chore\(release\)",     # chore(release): ...
    r"^bump version",         # bump version
]

def categorize(subject: str) -> Tuple[str, str, Optional[str]]:
    s = subject.strip()

    for pat in IGNORE_SUBJECT_PATTERNS:
        if re.search(pat, s, flags=re.I):
            return ("(ignore)", s, None)

    m = re.match(r"^(feat|fix|perf|refactor|docs|style|test|build|ci|chore|revert)(\([^)]+\))?!?:\s*(.+)", s, flags=re.I)
    if m:
        typ = m.group(1).lower()
        scope = m.group(2)
        desc = m.group(3).strip()
        section = TYPE_MAP.get(typ, "Other")
        return (section, desc, scope)

    return ("Other", s, None)

# --- render ------------------------------------------------------------------

SECTION_ORDER = [
    "Added",
    "Fixed",
    "Changed",
    "Documentation",
    "Build",
    "CI",
    "Tests",
    "Chore",
    "Style",
    "Reverted",
    "Other",
]

def render_release(title: str, date: str, entries: Dict[str, List[str]], compare_url: Optional[str], summary_only: bool = False) -> str:
    lines = []
    hdr = f"## [{title}] - {date}" if title != "Unreleased" else f"## [Unreleased]"
    lines.append(hdr)
    if compare_url:
        lines.append(f"[Compare]({compare_url})")
    lines.append("")

    if summary_only:
        total = sum(len(v) for v in entries.values())
        if total == 0:
            lines.append("_No notable changes._\n")
            return "\n".join(lines)

        # Short per-section counts
        for section in SECTION_ORDER:
            items = entries.get(section, [])
            if items:
                lines.append(f"- **{section}:** {len(items)} change(s)")
        lines.append("")
        return "\n".join(lines)

    any_entries = False
    for section in SECTION_ORDER:
        items = entries.get(section, [])
        if not items:
            continue
        any_entries = True
        lines.append(f"### {section}")
        lines.extend(items)
        lines.append("")
    if not any_entries:
        lines.append("_No notable changes._\n")
    return "\n".join(lines).rstrip() + "\n"

def make_compare_link(base_url: Optional[str], a: str, b: str) -> Optional[str]:
    if not base_url:
        return None
    return f"{base_url}/compare/{a}...{b}"

# --- main --------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", default="CHANGELOG.md")
    ap.add_argument("--tag-prefix", default="mvp-")
    ap.add_argument("--since-tag", help="Generate for commits after this tag up to HEAD")
    ap.add_argument("--all", action="store_true", help="Generate sections for all tags + Unreleased")
    ap.add_argument("--unreleased-summary", action="store_true", help="Render Unreleased as section counts only")
    args = ap.parse_args()

    base_url = repo_https_url()
    tags = tag_list(args.tag_prefix)
    root = root_commit()

    sections = []  # (title, range, compare_link, date, summary_only)
    if args.all and tags:
        prev = None
        for i, t in enumerate(tags):
            if prev is None:
                rng = f"{root}..{t}"   # include first tag properly
            else:
                rng = f"{prev}..{t}"
            sections.append((t, rng, make_compare_link(base_url, prev or root, t), tag_date(t), False))
            prev = t
        # Unreleased
        sections.append(("Unreleased", f"{tags[-1]}..HEAD", make_compare_link(base_url, tags[-1], "HEAD"), datetime.today().strftime("%Y-%m-%d"), args.unreleased_summary))
    elif args.since_tag:
        sections.append(("Unreleased", f"{args.since_tag}..HEAD", make_compare_link(base_url, args.since_tag, "HEAD"), datetime.today().strftime("%Y-%m-%d"), args.unreleased_summary))
    elif tags:
        last = tags[-1]
        sections.append((last, f"{root}..{last}", make_compare_link(base_url, root, last), tag_date(last), False))
        sections.append(("Unreleased", f"{last}..HEAD", make_compare_link(base_url, last, "HEAD"), datetime.today().strftime("%Y-%m-%d"), args.unreleased_summary))
    else:
        sections.append(("Unreleased", "HEAD", None, datetime.today().strftime("%Y-%m-%d"), args.unreleased_summary))

    out_lines = []
    out_lines.append("# Changelog")
    out_lines.append("All notable changes to this project will be documented here.\n")
    out_lines.append("The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).\n")

    # newest first
    for title, rng, compare_link, date, summary_only in reversed(sections):
        commits = commit_range_commits(rng) if rng else []
        entries: Dict[str, List[str]] = {}
        for c in commits:
            section, desc, scope = categorize(c["subject"])
            if section == "(ignore)":
                continue
            bullet = f"- {desc} ({c['short']})"
            if scope:
                bullet = f"- {desc} _{scope}_ ({c['short']})"
            entries.setdefault(section, []).append(bullet)

        out_lines.append(render_release(title, date, entries, compare_link, summary_only))
        out_lines.append("")

    Path(args.output).write_text("\n".join(out_lines).strip() + "\n", encoding="utf-8")
    print(f"Wrote {args.output}")

if __name__ == "__main__":
    main()
