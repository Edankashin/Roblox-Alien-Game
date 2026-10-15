"""Tests for tools/export_transcript.py: genuine turns kept, noise dropped, secrets redacted, notes idempotent.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). Builds a tiny fixture JSONL in a temporary folder; never reads a real transcript.
"""
from __future__ import annotations

import contextlib
import io
import json
import pathlib
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import export_transcript  # noqa: E402
import lint_vault  # noqa: E402

KEYLIKE = "aB3dE5gH7jK9mN1pQ3sT5vW7yZ9bC1dE3fG5hJ7k"  # 40 characters, mixed case: shaped like a key, not a real one
HUMAN = {"kind": "human"}


def user(ts, content, **extra):
    return {"type": "user", "timestamp": ts, "message": {"role": "user", "content": content}, **extra}


def assistant(ts, blocks, **extra):
    return {"type": "assistant", "timestamp": ts, "message": {"role": "assistant", "content": blocks}, **extra}


def tool(ts, name, **inp):
    return assistant(ts, [{"type": "tool_use", "id": "t1", "name": name, "input": inp}])


def lines(*extra_tools):
    rows = [
        {"type": "queue-operation", "operation": "enqueue", "timestamp": "2026-10-04T10:00:00Z", "content": "ignored"},
        user("2026-10-04T10:00:00Z", "Make the aliens cuter.\n\nAnd see [[Glossary]].", origin=HUMAN),
        assistant("2026-10-04T10:00:03Z", [{"type": "thinking", "thinking": "private reasoning"}]),
        assistant("2026-10-04T10:00:04Z", [{"type": "text", "text": f"On it. The key is {KEYLIKE} and the mail is a@b.co."}]),
        tool("2026-10-04T10:00:05Z", "Bash", command="ls /root/work/secret-dir/notes.txt && echo " + "x" * 80),
        user("2026-10-04T10:00:06Z", [{"type": "tool_result", "tool_use_id": "t1", "content": "RESULT BODY"}]),
        user("2026-10-04T10:00:07Z", "[SYSTEM NOTIFICATION] hello"),
        user("2026-10-04T10:00:08Z", "<task-notification>done</task-notification>", origin={"kind": "task-notification"}),
        user("2026-10-04T10:00:09Z", "Stop hook feedback: commit", isMeta=True),
        {"type": "attachment", "timestamp": "2026-10-04T10:00:10Z", "attachment": {
            "type": "queued_command", "prompt": "Also add weather.", "origin": HUMAN, "commandMode": "prompt"}},
        {"type": "attachment", "timestamp": "2026-10-04T10:00:11Z", "attachment": {
            "type": "queued_command", "prompt": "<task-notification>x", "origin": {"kind": "task-notification"}, "commandMode": "task-notification"}},
        assistant("2026-10-04T10:00:12Z", [{"type": "text", "text": "side"}], isSidechain=True),
        assistant("2026-10-04T10:00:13Z", [{"type": "text", "text": "API Error: limit"}], isApiErrorMessage=True),
    ]
    rows += [tool(f"2026-10-04T10:01:{i:02d}Z", "Read", file_path=f"/home/user/f{i}.txt") for i in range(12)]
    rows += [
        {"type": "system", "subtype": "compact_boundary", "timestamp": "2026-10-04T10:02:00Z"},
        user("2026-10-04T10:02:01Z", "This session is being continued... HUGE SUMMARY", isCompactSummary=True),
        user("2026-10-04T10:30:00Z", "token=abcdef and Authorization: Bearer xyz at /Users/ethan/Games/Alien/Tool.luau", origin=HUMAN),
        user("2026-10-05T01:00:00+00:00", "Next day.", origin=HUMAN),
    ]
    return [json.dumps(r) for r in rows + list(extra_tools)] + ["{not json"]


class ExportTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        root = pathlib.Path(self._tmp.name)
        self.src, self.out = root / "session.jsonl", root / "vault" / "09-transcripts"
        self.src.write_text("\n".join(lines()) + "\n", encoding="utf-8")

    def run_tool(self, session="Coordinator (cloud)"):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            export_transcript.main([str(self.src), "--out", str(self.out), "--session", session])
        return buf.getvalue()

    def day(self, name="2026-10-04-coordinator"):
        return (self.out / f"{name}.md").read_text(encoding="utf-8")

    def test_one_note_per_utc_day_with_frontmatter(self):
        self.run_tool()
        self.assertEqual(sorted(p.name for p in self.out.glob("*.md")), ["2026-10-04-coordinator.md", "2026-10-05-coordinator.md"])
        text = self.day()
        self.assertTrue(text.startswith('---\ntags: [log, transcript]\nup: "[[Transcripts]]"\n---\n'))
        self.assertIsNotNone(lint_vault.FRONT.match(text))

    def test_user_turns_kept_and_noise_dropped(self):
        self.run_tool()
        text = self.day()
        self.assertIn("> **Ethan:** Make the aliens cuter.", text)
        self.assertIn("> **Ethan:** Also add weather.", text)  # typed while the assistant worked
        self.assertIn("**Coordinator:**\n\nOn it.", text)
        for dropped in ("private reasoning", "RESULT BODY", "SYSTEM NOTIFICATION", "task-notification", "Stop hook", "HUGE SUMMARY",
                        "side", "API Error"):
            self.assertNotIn(dropped, text)

    def test_tool_lines_are_short_and_runs_collapse(self):
        self.run_tool()
        text = self.day()
        self.assertIn("- tool: Bash ls [redacted]/notes.txt && echo " + "x" * 8 + "\n", text)  # 40 characters of the first string field
        self.assertEqual(text.count("- tool: Read "), 10)
        self.assertIn("- tools: 2 more calls", text)
        self.assertNotIn("x" * 41, text)

    def test_headings_marker_and_link_escape(self):
        self.run_tool()
        text = self.day()
        self.assertEqual([ln for ln in text.splitlines() if ln.startswith("##### ")], ["##### 10:00", "##### 10:30"])
        self.assertIn("\n(context compacted)\n", text)
        self.assertIn("\\[\\[Glossary]]", text)
        self.assertEqual(lint_vault.targets(text), ["Transcripts", "Transcripts"])  # only the up link and the back link

    def test_secrets_are_redacted_and_counted(self):
        out = self.run_tool()
        text = self.day()
        for secret in (KEYLIKE, "a@b.co", "abcdef", "xyz", "ethan", "/Users", "/root", "secret-dir"):
            self.assertNotIn(secret, text)
        self.assertIn("[redacted]/Tool.luau", text)
        self.assertIn("token=[redacted]", text)
        self.assertIn("Authorization: Bearer [redacted]", text)
        self.assertIn("redactions", out)
        self.assertRegex(out, r"\b[5-9] redactions")

    def test_redact_rules(self):
        redact = export_transcript.redact
        self.assertEqual(redact("a" * 45), ("a" * 45, 0))  # one case only: not key-like
        self.assertEqual(redact("A1" * 25)[1], 0)
        self.assertEqual(redact("-" * 50)[1], 0)
        self.assertEqual(redact("see " + KEYLIKE + "x."), ("see [redacted].", 1))
        self.assertEqual(redact("export ROBLOX_API_KEY=abc123 && go"), ("export ROBLOX_API_KEY=[redacted] && go", 1))
        self.assertEqual(redact('ROBLOX_OPEN_CLOUD_KEY="a b"'), ("ROBLOX_OPEN_CLOUD_KEY=[redacted]", 1))
        self.assertEqual(redact("/root/.claude/projects/x/s.jsonl and /root"), ("[redacted]/s.jsonl and [redacted]", 2))
        self.assertEqual(redact("/Users/ethan"), ("[redacted]", 1))
        self.assertEqual(redact("/tmp/claude-0/-home-user-Game/abc/scratchpad/out.png"), ("[redacted]/out.png", 1))
        self.assertEqual(redact("/tmp/claude-0/"), ("[redacted]/", 1))
        self.assertEqual(redact("/home/user/Roblox-Alien-Game/src/a.luau"), ("/home/user/Roblox-Alien-Game/src/a.luau", 0))
        self.assertEqual(redact("PATH=/root/.rokit/bin:/usr/bin"), ("PATH=[redacted]/bin:/usr/bin", 1))

    def test_rerun_is_idempotent_and_updates_the_hub(self):
        self.out.mkdir(parents=True)
        (self.out / "Transcripts.md").write_text(f"---\ntags: [log]\n---\n# Transcripts\n\n{export_transcript.HUB_BEGIN}\n- stale\n{export_transcript.HUB_END}\n",
                                                 encoding="utf-8")
        self.run_tool()
        first = {p.name: p.read_bytes() for p in self.out.glob("*.md")}
        self.run_tool()
        self.assertEqual({p.name: p.read_bytes() for p in self.out.glob("*.md")}, first)
        hub = first["Transcripts.md"].decode("utf-8")
        self.assertIn("- [[2026-10-04-coordinator]]\n- [[2026-10-05-coordinator]]\n", hub)
        self.assertNotIn("stale", hub)

    def test_session_label_makes_the_slug(self):
        self.run_tool("Mac session")
        self.assertTrue((self.out / "2026-10-04-mac-session.md").is_file())
        self.assertIn("# Transcript: Mac session, 2026-10-04", self.day("2026-10-04-mac-session"))
        self.assertEqual(export_transcript.slugify("Coordinator (cloud)"), "coordinator")

    def test_a_long_day_splits_into_parts_and_a_shorter_rerun_removes_them(self):
        original = export_transcript.MAX_BYTES
        self.addCleanup(setattr, export_transcript, "MAX_BYTES", original)
        export_transcript.MAX_BYTES = 600
        self.run_tool()
        self.assertTrue((self.out / "2026-10-04-coordinator-part2.md").is_file())
        self.assertIn("(part 1 of ", self.day())
        self.assertIn("##### ", self.day("2026-10-04-coordinator-part2"))
        export_transcript.MAX_BYTES = original
        self.run_tool()
        self.assertFalse(list(self.out.glob("*-part*.md")))


if __name__ == "__main__":
    unittest.main()
