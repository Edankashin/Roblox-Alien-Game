#!/usr/bin/env python3
"""Turn YouTube auto-caption files (.vtt) into plain text and keep media/youtube/INDEX.md (Mac job 28).

Standard library only:
  python3 -I tools/youtube_captions.py media/youtube                      # every <id>.en.vtt -> <id>.txt, then INDEX.md
  python3 -I tools/youtube_captions.py media/youtube --notes "research_notes/Roblox creature UI and Claude workflows"

The captions come from `yt-dlp --write-auto-sub --sub-lang en --skip-download --write-info-json -o "media/youtube/%(id)s.%(ext)s"`.
A text file has one line per cue: tags, timestamps and cue settings dropped, and a line equal to the one before it collapsed
(auto-captions repeat each line as the next one rolls in). INDEX.md lists id, title, channel, length and the notes that cite
the video (any .md under --notes holding its id); titles come from <id>.info.json when yt-dlp wrote one. Only the .txt files
and INDEX.md are committed; the .vtt and .info.json stay local.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re

TIMING = re.compile(r"^\d{2}:\d{2}(:\d{2})?\.\d{3}\s+-->\s+")
TAG = re.compile(r"<[^>]+>")
CITED = re.compile(r"(?:youtube\.com/watch\?v=|youtu\.be/)([A-Za-z0-9_-]{11})")


def vtt_lines(text: str) -> list[str]:
    """The spoken lines of a WebVTT file, in order, with consecutive duplicates collapsed."""
    out: list[str] = []
    in_header = True
    for raw in text.splitlines():
        line = raw.strip()
        if in_header:
            if not line:
                in_header = False
            continue
        if not line or TIMING.match(line) or line.isdigit() or line.startswith(("NOTE", "STYLE", "REGION")):
            continue
        line = " ".join(TAG.sub("", line).replace("&nbsp;", " ").replace("&amp;", "&").replace("&gt;", ">").replace("&lt;", "<").split())
        if line and (not out or out[-1] != line):
            out.append(line)
    return out


def citing_notes(video_id: str, notes: list[pathlib.Path]) -> list[str]:
    return sorted(p.stem for p in notes if video_id in p.read_text(encoding="utf-8", errors="replace"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folder", help="the folder holding <id>.en.vtt (and <id>.info.json)")
    ap.add_argument("--notes", default="research_notes/Roblox creature UI and Claude workflows", help="where the citing notes live")
    args = ap.parse_args()
    folder = pathlib.Path(args.folder)
    notes = sorted(pathlib.Path(args.notes).glob("*.md"))
    rows = []
    for vtt in sorted(folder.glob("*.vtt")):
        video_id = vtt.name.split(".")[0]
        lines = vtt_lines(vtt.read_text(encoding="utf-8", errors="replace"))
        (folder / ("%s.txt" % video_id)).write_text("\n".join(lines) + "\n", encoding="utf-8")
        rows.append(video_id)
    ids = set(rows)
    for info in folder.glob("*.info.json"):
        ids.add(info.name.split(".")[0])
    for note in notes:  # every video a note cites, so one YouTube no longer serves still has its row
        ids.update(CITED.findall(note.read_text(encoding="utf-8", errors="replace")))
    table = ["| Id | Title | Channel | Length | Captions | Cited in |", "|---|---|---|---|---|---|"]
    for video_id in sorted(ids, key=str.lower):
        info_path = folder / ("%s.info.json" % video_id)
        info = json.loads(info_path.read_text(encoding="utf-8")) if info_path.exists() else {}
        title = " ".join(str(info.get("title", "")).split()).replace("|", "/")
        seconds = info.get("duration")
        length = "%d:%02d" % divmod(int(seconds), 60) if seconds else ""
        has = "yes" if video_id in rows else ("none" if info else "video unavailable")
        cited = ", ".join(citing_notes(video_id, notes))
        table.append("| [%s](https://www.youtube.com/watch?v=%s) | %s | %s | %s | %s | %s |" % (
            video_id, video_id, title, str(info.get("channel", "")).replace("|", "/"), length, has, cited))
    head = [
        "# YouTube captions",
        "",
        "Auto-captions (English) of the videos the research cites, as plain text (`<id>.txt`, one line per cue). Made by",
        "`tools/youtube_captions.py` from `yt-dlp --write-auto-sub` (Mac job 28). \"none\" means YouTube served no English",
        "auto-captions for that video; \"video unavailable\" that YouTube no longer serves it.",
        "",
    ]
    (folder / "INDEX.md").write_text("\n".join(head + table) + "\n", encoding="utf-8")
    print("youtube_captions: %d text files, %d videos in INDEX.md" % (len(rows), len(ids)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
