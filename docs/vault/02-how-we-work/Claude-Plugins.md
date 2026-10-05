# Claude Code plugins and skills for this project

What the Roblox AI-dev community installs (reference video ZPL8Hb7yS, batch 4), and what we do with each. Rule from the Studio page applies here too: one registration per tool, at project scope, and nothing installed by a script. Each install is one deliberate command in the Mac terminal, followed by a dry run that proves it does not fight `CLAUDE.md`, `.mcp.json` or the vault.

| Tool | What it is | Our decision | Command |
|---|---|---|---|
| Roblox Studio MCP | Claude sees and edits the open place | In (see `03-studio-and-mcp/Connection.md`) | already in `.mcp.json` |
| Blender MCP | Claude builds and edits models in Blender | In (see `06-art-pipelines/Blender-MCP.md`) | already in `.mcp.json` |
| Roblox Dev (ivar-anon) | Luau toolkit: exploit-proof remotes, safe DataStores, strict typing, client/server split | Adopt after a dry run: it matches our server-authority and strict-mode rules; check it does not override CLAUDE.md | `/plugin marketplace add ivar-anon/roblox-dev` then `/plugin install roblox-dev@roblox-dev` |
| Roblox Studio skill (ShiroKSH) | Building and placement: maps, arenas, object placement, level design | Adopt for World 2 map work, through the Mac session | `/plugin marketplace add ShiroKSH/skills` then `/plugin install roblox-studio@skills` |
| Superpowers | Plans more before big features | Try on the World 2 build only; say "use Superpowers for this" | `/plugin install superpowers@claude-plugins-official` |
| Roblox Claude Skills | Map, UI, debugging, API help, cleanup, setup; Rojo-flavoured | Skip: it conflicted with the creator's other skills and overlaps the two above | |
| Graphify | Knowledge graph of the project | Skip: the vault and the sourcemap do this for a project our size | `pip install graphifyy`, `graphify install`, `/graphify` |
| Ponytail | "Lazy senior dev" YAGNI mode | Skip: CLAUDE.md already asks for the smallest change; token saving unproven | |
| Agent Skills | A general skills collection | Skip until a specific skill is missing | |

## Our own skills

Project skills live in `.claude/skills/<name>/SKILL.md` and load automatically when the task matches.

- `import-model`: importing a GLB or FBX from `assets/models/` into Studio and wiring it to a species. Written from the creator's "model importing" skill, which cut a three-to-five-minute Claude import to one step.

## Dry-run checklist before adopting a plugin

1. Install on the Mac in the repo, in project scope.
2. Start a fresh Claude Code session; `/mcp` still lists `Roblox_Studio` and `blender`; `/plugin` lists the new one.
3. Ask for a one-line change that CLAUDE.md governs (a number into `src/shared/data`, a string into the strings table) and confirm the plugin did not steer it elsewhere.
4. `./tools/analyze.sh` prints `analyze: clean`.
5. Record the result here with the date; remove the plugin if any step fails.
