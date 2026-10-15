#!/usr/bin/env python3
"""Export a Claude Code session transcript (JSONL) into the vault, one note per UTC day.

Standard library only:  python3 -I tools/export_transcript.py <session.jsonl> --out docs/vault/09-transcripts --session "Coordinator (cloud)"
One `YYYY-MM-DD-<slug>.md` per day (`-part2`... past 1 MB): Ethan's messages in full, the assistant's text, one short line per
tool call, a marker at each compaction. Tool results, thinking, hooks, notifications and sub-agent lines are dropped; secrets are
redacted (see `redact`) and counted. Re-running rewrites the day files and the day list in the `Transcripts.md` hub.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from vault_note import write_note

MAX_BYTES, GAP, RUN_SHOWN, ARG_CHARS = 1_000_000, timedelta(minutes=10), 10, 40
SKIP_START = ("[SYSTEM NOTIFICATION", "<system-reminder", "<task-notification", "<agent-message", "<cross-session-message",
              "<command-name>", "<local-command", "[Request interrupted", "Stop hook feedback", "Caveat:")
HUB_BEGIN, HUB_END = "<!-- transcripts:begin -->", "<!-- transcripts:end -->"
R = "[redacted]"
VALUE = r"""("[^"\n]*"|'[^'\n]*'|[^\s"'&;,)\]}]+)"""
SECRETS = re.compile(r"(?i)(authorization\s*:\s*(?:(?:bearer|basic|token)\s+)?|ROBLOX_(?:API|OPEN_CLOUD)_KEY\s*[=:]\s*|key=|token=)" + VALUE)
PREFIXED = re.compile(r"\b(?:sk-[\w-]{16,}|gh[pousr]_\w{20,}|github_pat_\w{20,}|AKIA[0-9A-Z]{16})")
TOKEN = r"[A-Za-z0-9_\-]"  # a 40+ character run of these is key-like when it mixes upper and lower case
LONG_RUN = re.compile(rf"(?<!{TOKEN})(?={TOKEN}*[a-z])(?={TOKEN}*[A-Z]){TOKEN}{{40,}}")
EMAIL = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+")
HOME_PATH = re.compile(r"(?<![\w.~\-])(/(?:Users|root|tmp/claude-0)(?:/[^\s'\"`<>()|;:,*?\[\]{}]+)*)")


def redact(text: str) -> tuple[str, int]:
    """Return (text with secrets replaced by [redacted], number of replacements)."""
    hits = [0]

    def hit(value: str = R) -> str:
        hits[0] += 1
        return value
    def home_path(m):  # keep the basename; the account's own folder has none worth keeping
        path = m.group(1).rstrip(".")
        parts = path.split("/")[1:]
        rest = parts[2:] if parts[0] in ("Users", "tmp") else parts[1:]
        return hit(R + "/" + rest[-1] if rest else R) + m.group(1)[len(path):]

    text = SECRETS.sub(lambda m: m.group(1) + hit(), text)
    for pattern in (PREFIXED, LONG_RUN, EMAIL):
        text = pattern.sub(lambda m: hit(), text)
    return HOME_PATH.sub(home_path, text), hits[0]


def slugify(label: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", re.sub(r"\(.*?\)", "", label).lower()).strip("-") or "session"


def moment(stamp: str) -> datetime:
    t = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    return (t if t.tzinfo else t.replace(tzinfo=timezone.utc)).astimezone(timezone.utc)


def human_text(src: dict, content) -> str | None:
    """The words of a genuine user turn (`src` carries origin and flags), or None for tool results and harness notices."""
    kind = src["origin"].get("kind") if isinstance(src.get("origin"), dict) else None
    if kind not in (None, "human") or src.get("isMeta") or src.get("isCompactSummary") or src.get("commandMode", "prompt") != "prompt":
        return None
    if isinstance(content, list):
        blocks = [b for b in content if isinstance(b, dict)]
        if any(b.get("type") == "tool_result" for b in blocks):
            return None
        content = "\n".join(b.get("text", "") if b.get("type") == "text" else f"[{b.get('type', 'attachment')}]" for b in blocks)
    if not isinstance(content, str):
        return None
    text = re.sub(r"<system-reminder>.*?</system-reminder>", "", content, flags=re.S).strip()
    return text if text and not text.startswith(SKIP_START) else None


def events(path):
    """Yield (datetime, kind, a, b): kind is user (a=text), coord (a=text), tool (a=name, b=arg) or compact."""
    last = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            try:
                o = json.loads(raw)
            except ValueError:
                continue
            if not isinstance(o, dict) or o.get("isSidechain"):
                continue
            last = o.get("timestamp") or last
            kind = o.get("type")
            att = o["attachment"] if isinstance(o.get("attachment"), dict) else {}
            msg = o["message"] if isinstance(o.get("message"), dict) else {}
            if not last:
                continue
            dt = moment(last)
            if kind == "summary" or (kind == "system" and o.get("subtype") == "compact_boundary"):
                yield dt, "compact", "", ""
            elif kind == "user" or att.get("type") == "queued_command":  # a typed turn, or one typed while the assistant worked
                src, content = (o, msg.get("content")) if kind == "user" else (att, att.get("prompt"))
                text = human_text(src, content)
                if text:
                    yield dt, "user", text, ""
            elif kind == "assistant" and not o.get("isApiErrorMessage") and msg.get("model") != "<synthetic>":
                content = msg.get("content")
                for b in [{"type": "text", "text": content}] if isinstance(content, str) else content or []:
                    if not isinstance(b, dict):
                        continue
                    if b.get("type") == "text" and str(b.get("text", "")).strip():
                        yield dt, "coord", str(b["text"]).strip(), ""
                    elif b.get("type") == "tool_use":
                        args = b.get("input")
                        first = next((v for v in args.values() if isinstance(v, str)), "") if isinstance(args, dict) else ""
                        yield dt, "tool", str(b.get("name", "tool")), " ".join(first[:400].split())


def quote(text: str) -> str:
    lines = text.splitlines() or [""]
    return "> **Ethan:** " + lines[0] + "".join("\n> " + ln if ln else "\n>" for ln in lines[1:])


def close_fences(text: str) -> str:  # an odd number of fence lines would swallow the rest of the note
    odd = sum(ln.strip().startswith(("```", "~~~")) for ln in text.splitlines()) % 2
    return text + "\n```" * odd


def blocks_for(evs, clean):
    """Turn one day's events into (datetime, speaker, text) blocks; speaker is head, user, coord or mark."""
    out, run, prev = [], [], None

    def flush():
        shown = [f"- tool: {name} {clean(arg, ARG_CHARS)}".rstrip() for name, arg, _ in run[:RUN_SHOWN]]
        if len(run) > RUN_SHOWN:
            shown.append(f"- tools: {len(run) - RUN_SHOWN} more calls")
        if run:
            out.append((run[0][2], "coord", "\n".join(shown)))
        run.clear()

    for dt, kind, a, b in evs:
        if prev is None or dt - prev > GAP:
            flush()
            out.append((dt, "head", f"##### {dt:%H:%M}"))
        prev = dt
        if kind == "tool":
            run.append((a, b, dt))
            continue
        flush()
        if kind == "user":
            out.append((dt, "user", quote(clean(a))))
        elif kind == "coord":
            out.append((dt, "coord", close_fences(clean(a))))
        else:
            out.append((dt, "mark", "(context compacted)"))
    flush()
    return out


def assemble(blocks):
    """Group blocks into parts of at most MAX_BYTES (a new part opens with a time heading); label the assistant's turns."""
    parts, cur, size, who = [], [], 0, None
    label = lambda speaker: ["**Coordinator:**"] if speaker == "coord" and who != "coord" else []
    cost = lambda paras: sum(len(s.encode("utf-8")) + 2 for s in paras)
    for dt, speaker, text in blocks:
        add = label(speaker) + [text]
        if cur and size + cost(add) > MAX_BYTES:
            parts.append(cur)
            cur, size, who = [], 0, None
            add = ([] if speaker == "head" else [f"##### {dt:%H:%M}"]) + label(speaker) + [text]
        cur, size = cur + add, size + cost(add)
        who = speaker if speaker in ("user", "coord") else None
    return parts + [cur] if cur else parts


def update_hub(out: Path) -> bool:
    hub = out / "Transcripts.md"  # the day list between its markers is rewritten from the notes on disk
    if not hub.is_file() or HUB_BEGIN not in hub.read_text(encoding="utf-8"):
        return False
    rows = [f"- [[{p.stem}]]" for p in sorted(out.glob("*.md")) if re.match(r"\d{4}-\d{2}-\d{2}-", p.name)]
    block = HUB_BEGIN + "\n" + "\n".join(rows) + "\n" + HUB_END
    pattern = re.escape(HUB_BEGIN) + ".*?" + re.escape(HUB_END)
    hub.write_text(re.sub(pattern, lambda m: block, hub.read_text(encoding="utf-8"), flags=re.S), encoding="utf-8")
    return True


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Export a Claude Code transcript into the vault, one note per UTC day.")
    ap.add_argument("jsonl", help="the session transcript (.jsonl)")
    ap.add_argument("--out", required=True, help="the folder to write, e.g. docs/vault/09-transcripts")
    ap.add_argument("--session", default="Coordinator", help='the label, e.g. "Coordinator (cloud)" or "Mac session"')
    args = ap.parse_args(argv)
    redactions = [0]

    def clean(text, limit=None):
        text, n = redact(text)
        redactions[0] += n
        return text[:limit].replace("[[", "\\[\\[")  # a transcript line must never become a vault link

    days = {}
    for ev in events(args.jsonl):
        days.setdefault(ev[0].date().isoformat(), []).append(ev)
    out, slug, written = Path(args.out), slugify(args.session), 0
    intro = "Times are UTC. Append-only history made by `tools/export_transcript.py`; never edited by hand. Back to [[Transcripts]]."
    for day, evs in sorted(days.items()):
        parts = assemble(blocks_for(evs, clean))
        names = [f"{day}-{slug}" + (f"-part{i}" if i > 1 else "") for i in range(1, len(parts) + 1)]
        for i, (name, part) in enumerate(zip(names, parts), 1):
            title = f"# Transcript: {args.session}, {day}" + (f" (part {i} of {len(parts)})" if len(parts) > 1 else "")
            write_note(out / f"{name}.md", f"{title}\n\n{intro}\n\n" + "\n\n".join(part) + "\n", ["log", "transcript"], up="Transcripts")
        written += len(parts)
        for stale in out.glob(f"{day}-{slug}-part*.md"):
            if stale.stem not in names:
                stale.unlink()
    hub = update_hub(out)
    print(f"export_transcript: {written} notes, {redactions[0]} redactions" + ("" if hub else " (no hub markers, day list not updated)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
