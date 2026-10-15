---
tags: [vault, hub]
aliases: [Vault readme]
---
# Knowledge vault

What the team and Claude have agreed and learned, written down so every session starts from the same standard. Plain markdown; this folder is the team's Obsidian vault (open `docs/vault` in Obsidian), and reads the same in the repo. Claude reads the relevant note before UI, engine or asset work and writes corrections back in the same change (see `CLAUDE.md`).

Folders mirror the reference creator's vault: 00 start here (glossary), 01 game design, 02 how we work, 03 Studio and MCP, 04 Roblox engine, 05 UI design (refs, playbook, checklist, recipes, taste), 06 art pipelines, 07 this project, 08 the session log (one dated note per day).

Start here: [[Start-Here]] is the map of maps; then [[Handoff]] (everything about the project, for a new teammate or session), [[Setup-and-Tips]] (how everything was configured, and what we learned), [[Board]] (who is doing what; claim a row before starting) and [[Launch-Dashboard]] (the state of the launch on one screen).

Every folder has a hub note that lists its notes with a line each: [[Start-Here]], [[Game-Design]], [[How-We-Work]], [[Studio-and-MCP]], [[Roblox-Engine]], [[UI-Design]], [[Art-Pipelines]], [[Alien-Game]] and [[Log]].

House rules for a note: YAML frontmatter with `tags` (the folder's topic plus one or two of `pipeline`, `decision`, `research`, `ui`, `engine`, `log`, `plan`, `species`), `aliases` for a second name people use, and `up` linking its hub; at least one link in and one link out; a new note goes into its hub in the same change. `python3 -I tools/lint_vault.py` checks all of it (see [[Data-Lint]]) and runs inside `tools/lint.sh`.
