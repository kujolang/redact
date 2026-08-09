#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$")


def slug(text: str) -> str:
    text = re.sub(r"[`*_~]", "", text.strip().lower())
    text = re.sub(r"[^\w\- ]", "", text, flags=re.UNICODE)
    return re.sub(r"[\s\-]+", "-", text).strip("-")


def anchors(path: Path) -> set[str]:
    found: set[str] = set()
    counts: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = HEADING_RE.match(line)
        if not match:
            continue
        base = slug(match.group(1))
        count = counts.get(base, 0)
        counts[base] = count + 1
        found.add(base if count == 0 else f"{base}-{count}")
    return found


errors: list[str] = []
markdown_files = sorted(
    path for path in ROOT.rglob("*.md") if ".git" not in path.parts
)
for source in markdown_files:
    content = source.read_text(encoding="utf-8")
    for raw_target in LINK_RE.findall(content):
        target = raw_target.strip().split()[0].strip("<>")
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        file_part, separator, fragment = target.partition("#")
        destination = source if file_part == "" else (source.parent / unquote(file_part)).resolve()
        try:
            destination.relative_to(ROOT)
        except ValueError:
            errors.append(f"{source.relative_to(ROOT)}: link escapes repository: {target}")
            continue
        if not destination.exists():
            errors.append(f"{source.relative_to(ROOT)}: missing target: {target}")
            continue
        if separator and destination.suffix.lower() == ".md" and fragment not in anchors(destination):
            errors.append(f"{source.relative_to(ROOT)}: missing anchor: {target}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print(f"Markdown link audit passed: {len(markdown_files)} files, zero broken local links")
