#!/usr/bin/env python3
"""Write a generated vault note without losing its YAML frontmatter.

Standard library only. The generators (balance.py, deadcode.py, perf_report.py, save_budget.py,
lint_remotes.py) regenerate whole notes in docs/vault. `write_note` keeps the frontmatter block an
existing note already has (so hand-edited tags, aliases and up links survive a regeneration) and
writes the vault's standard block only when there is none. The body is written exactly as given.

Block format (the one tools/lint_vault.py expects, `tags` required):

    ---
    tags: [roblox-engine, engine, generated]
    aliases: [Remote contracts]
    up: "[[Roblox-Engine]]"
    ---
"""
from __future__ import annotations

from pathlib import Path
import re

# Same pattern as tools/lint_vault.py: a block that opens the file and closes on its own line.
FRONT = re.compile(r"\A---\n.*?\n---\n", re.S)
_PLAIN = re.compile(r"[,:\[\]#\"'{}&*!|>%@`]")


def _item(text: str) -> str:
    """One flow-sequence item, quoted only when a bare scalar would not parse."""
    if text != text.strip() or _PLAIN.search(text):
        return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return text


def frontmatter(tags: list[str], aliases: list[str] | None = None, up: str | None = None) -> str:
    """The standard block. `up` is a note name (`Roblox-Engine`) or an already-wrapped `[[Roblox-Engine]]`."""
    lines = ["---", "tags: [" + ", ".join(_item(t) for t in tags) + "]"]
    if aliases:
        lines.append("aliases: [" + ", ".join(_item(a) for a in aliases) + "]")
    if up:
        link = up if up.startswith("[[") else "[[" + up + "]]"
        lines.append('up: "' + link.replace('"', '\\"') + '"')
    lines.append("---")
    return "\n".join(lines) + "\n"


def write_note(path, body: str, tags: list[str], aliases: list[str] | None = None, up: str | None = None) -> str:
    """Write `body` to the note at `path` under its frontmatter and return the full text written.

    An existing note's frontmatter block is kept verbatim (tags, aliases and up arguments are then
    ignored); otherwise the standard block is built from the arguments. Parent folders are created.
    """
    path = Path(path)
    block = None
    if path.is_file():
        found = FRONT.match(path.read_text(encoding="utf-8"))
        if found:
            block = found.group(0)
    if block is None:
        block = frontmatter(tags, aliases, up)
    text = block + body
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return text
