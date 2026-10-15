#!/usr/bin/env python3
"""Audit the Obsidian vault in docs/vault: links, orphans, hubs, frontmatter, logs.

Standard library only. Run `python3 -I tools/lint_vault.py` (add -v to list every finding).
Exit 1 on broken [[links]] only; everything else is a warning with counts.
Notes are matched by file stem, case-sensitive, the Obsidian way. Links may carry
|alias, #heading and ^block parts, or a folder path (`[[05-ui-design/refs/README]]`).
Fenced code and `inline code` are ignored, so a note may show link syntax safely.
"""
import re
import sys
from pathlib import Path

VAULT = Path(__file__).resolve().parent.parent / "docs" / "vault"
LINK = re.compile(r"!?\[\[([^\]\n]+)\]\]")
FENCE = re.compile(r"^(```|~~~)")
INLINE = re.compile(r"`[^`\n]*`")
FRONT = re.compile(r"\A---\n(.*?)\n---\n", re.S)
LOG = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def body_lines(text):
    """Yield (line, in_code) pairs with fenced code flagged."""
    fenced = False
    for line in text.split("\n"):
        if FENCE.match(line.strip()):
            fenced = not fenced
            yield line, True
        else:
            yield line, fenced


def strip_code(text):
    return "\n".join("" if code else INLINE.sub("", line) for line, code in body_lines(text))


def targets(text):
    """Return the raw link targets (before |alias, #heading, ^block) in a note body."""
    found = []
    for raw in LINK.findall(strip_code(text)):
        t = re.split(r"[|#^]", raw, maxsplit=1)[0].strip()
        if t:
            found.append(t)
    return found


def main():
    verbose = "-v" in sys.argv
    notes = {p: p.read_text(encoding="utf-8") for p in sorted(VAULT.rglob("*.md"))}
    files = {p.name for p in VAULT.rglob("*") if p.is_file()}
    by_stem, by_path = {}, {}
    for p in notes:
        by_stem.setdefault(p.stem, []).append(p)
        by_path[p.relative_to(VAULT).with_suffix("").as_posix()] = p

    def resolve(t):
        if t.endswith(".md"):
            t = t[:-3]
        if "/" in t:
            return by_path.get(t.strip("/"))
        hits = by_stem.get(t)
        return min(hits, key=lambda q: len(q.parts)) if hits else None  # a bare duplicate name: shortest path wins

    out_links, inbound, broken = {}, {p: set() for p in notes}, []
    for p, text in notes.items():
        out_links[p] = set()
        for t in targets(text):
            if "." in t and not t.endswith(".md"):  # an embed or link to an image or other file
                if t.rsplit("/", 1)[-1] not in files:
                    broken.append((p, t))
                continue
            dest = resolve(t)
            if dest is None:
                broken.append((p, t))
            elif dest != p:
                out_links[p].add(dest)
                if not (p.parent.name == "08-log" and LOG.match(p.stem)):
                    inbound[dest].add(p)

    rel = lambda p: p.relative_to(VAULT).as_posix()
    orphans = [p for p in notes if not inbound[p]]
    no_out = [p for p in notes if not out_links[p]]
    no_front = []
    for p, text in notes.items():
        m = FRONT.match(text)
        if not m or not re.search(r"^tags:", m.group(1), re.M):
            no_front.append(p)

    hubless, hub_gaps = [], []
    for folder in sorted(d for d in VAULT.iterdir() if d.is_dir()):
        inside = [p for p in notes if folder in p.parents]
        if not inside:
            continue
        topic = re.sub(r"^\d+-", "", folder.name).lower()
        hubs = [p for p in inside if p.parent == folder and p.stem.lower() == topic]
        if not hubs:
            hubless.append(folder.name)
            continue
        hub = hubs[0]
        hub_gaps += [(hub, p) for p in inside if p != hub and p not in out_links[hub]]

    unlinked = []
    for p, text in notes.items():
        if p.parent.name != "08-log" or not LOG.match(p.stem):
            continue
        sections, head = {}, None
        for line, code in body_lines(text):
            if not code and line.startswith("## "):
                head = line
                sections[head] = []
            elif head:
                sections[head].append(line)
        for head, lines in sections.items():
            if not targets("\n".join(lines)):
                unlinked.append((p, head))

    problems = [
        ("orphan notes", [rel(p) for p in orphans]),
        ("notes with no outbound link", [rel(p) for p in no_out]),
        ("folders without a hub note", hubless),
        ("hub links missing", [f"{rel(h)} -> {rel(p)}" for h, p in hub_gaps]),
        ("notes missing frontmatter tags", [rel(p) for p in no_front]),
        ("log headings with no link", [f"{rel(p)}: {h}" for p, h in unlinked]),
    ]
    for p, t in broken:
        print(f"vault: BROKEN [[{t}]] in {rel(p)}")
    warned = [(name, items) for name, items in problems if items]
    if verbose:
        for name, items in warned:
            print(f"vault: {name}:")
            for item in items:
                print(f"  {item}")
    if broken:
        print(f"vault: {len(broken)} broken link(s)", file=sys.stderr)
    if warned:
        counts = ", ".join(f"{len(items)} {name}" for name, items in warned)
        print(f"vault: warnings: {counts} (run with -v to list)")
    if not broken and not warned:
        print("vault: clean")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
