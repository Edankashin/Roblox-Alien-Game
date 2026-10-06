# Agent rules (Codex, Cursor and any other agent)

This repo's rules for every coding agent are in `CLAUDE.md`; read it first and follow it exactly (strict Luau, server authority, every number in `src/shared/data`, every string in `src/shared/strings`, Scale-only UI from the Theme and Builder, one system per change, `./tools/analyze.sh` must print `analyze: clean` before a commit, never commit audio or frame dumps).

Good jobs for a second agent, so the Claude coordinator's tokens go to Luau systems and reviews:
- The Blender generators under `tools/blender/` (species, props, heroes, icons, plates) and their renders, thumbnails and notes.
- Python tooling under `tools/` (the Open Cloud uploader, materials, previews) with dry runs.
- Vault pages under `docs/vault/` when a run teaches something.

Hand-off format: one branch per job, a commit message that says what changed and why, a report under 300 words with triangle counts or key counts and the hash. The Open Cloud key lives only in the Mac's shell; never in a file, a commit or a report.
