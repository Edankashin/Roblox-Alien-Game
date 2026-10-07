# Hands-off: running the project with as little manual work from Ethan as possible

Written 2026-10-07 after Ethan asked for a way to stop doing manual steps. Everything below uses official tools only (Roblox Open Cloud, Rojo, Roblox Studio's own MCP server, the Claude desktop app's computer use, the Codex CLI).

## Who does what

| Who | Does | How Ethan hears about it |
|---|---|---|
| Coordinator (the cloud Claude session) | Designs, builds and reviews the game; writes Codex cards; sends the Mac its jobs with `send_message`; reads Codex's reports from git | One message per finished block |
| The Mac's Claude session | Everything that needs the Mac: Studio through the Studio MCP server; the clicks MCP cannot make (Studio's Publish, the Test tab's Clients and Servers run) through computer use; the Open Cloud scripts with the key from its shell; starting Codex runs; pushing results | Reports to the coordinator; asks Ethan only for the approvals its own settings require |
| Codex | Tooling, tests, lints and reports from `Codex-Queue.md`; reports land in `Codex-Reports.md` in git, so nobody pastes them | Through the coordinator |
| Ethan | Approvals on the Mac, decisions, money, identity and legal steps, and playing the game (below) | Asked one line at a time |

## One-time setup (Ethan, about 15 minutes)

1. **Give the Open Cloud key three more permissions.** Creator Dashboard (create.roblox.com/dashboard) → left menu **Open Cloud** → **API Keys** → the key the Mac already uses → **Edit**. Under Access Permissions, for this experience add: **universe-places** with Write, **game-pass** with Read and Write, **developer-product** with Read and Write. Save. The key itself does not change and stays only in the Mac's `~/.zshrc`.
2. **Turn on computer use for the Mac's Claude app** (Claude desktop app settings), and when the session first asks to control Roblox Studio, allow it. It is used only for the buttons MCP cannot press.
3. **Keep the Mac available.** Plugged in, Roblox Studio and the Claude app open and signed in, and automatic sleep off while plugged in (System Settings → Battery or Energy → Options).
4. Tell the coordinator "setup done".

The Mac session still asks before it runs commands, uploads or publishes, as its settings require. How often it asks is Ethan's own setting in the Claude app on the Mac; the coordinator does not write or push permission rules for any session.

## What then runs without Ethan's hands

| Manual part today (owner guide) | Replaced by | Ready when |
|---|---|---|
| Part C: creating game passes and products, copying ids | `tools/create_products.py --apply` on the Mac (Codex card C22) writes the ids into `Shop.luau` and pushes; Ethan approves the run in the Mac window | C22 reviewed and step 1 above done |
| Parts A and H: publishing and republishing the three places | The Mac publishes from Studio with computer use now; later `tools/publish.py --apply` from the repo with no Studio at all (C23, plus the model table C24 and the coordinator's runtime model loader) | Now (Studio route); headless after C23, C24 and the loader |
| A8: the World 1 place id | The Mac reads it from Studio (`game.PlaceId`) or the Open Cloud universe and writes it into `Worlds.luau` | Now |
| Part D: two-player tests | The Mac runs Studio's Clients and Servers test with computer use and drives both windows | After step 2 |
| Part E: starting Codex and pasting its reports | The Mac starts `codex exec` with the batch prompt when the queue has open cards (exact command in [[Codex-Prompt]]); reports are already in git | **Working** since 2026-10-07 (C17 claimed by an unattended run) |
| Relaying messages between sessions | The coordinator and the Mac session message each other directly | Now |

## What stays Ethan's (by design, not by missing tooling)

- **Approvals on the Mac**: the Mac session's permission prompts are his to answer.
- **Decisions**: the coordinator asks one line at a time ("build playtime gifts? yes or no").
- **Money**: spending Robux on ads or sponsorships, payouts, and anything else that costs money.
- **Identity and legal**: the experience questionnaire and content maturity answers, privacy and compliance forms, two-step verification prompts, ID verification, and switching the game to public the first time. These are Ethan's account's legal statements; no tool should make them for him.
- **Playing it**: how the game feels to a person is the one input no tool replaces.

## Jobs that need computer use (found 2026-10-07)

The Mac's Claude Code CLI session drives Studio through the Studio MCP server (Luau, play mode, the in-game mouse and keyboard) but has no computer use: that exists only in the Claude desktop app. So these need a session started from the desktop app, where computer use is on: the device emulator checks (iPhone SE, iPad), opening another place (File, Open), Test, Clients and Servers with two players, the Manage Plugins screen and its prices, and File, Publish to Roblox.

To start it: Claude desktop app, the Code tab, choose the repo folder, then paste:

```
You are the computer-use session for the Roblox Alien Game repo in this folder. First read CLAUDE.md, docs/vault/02-how-we-work/Hands-Off.md and today's note in docs/vault/08-log/, then git pull. You do only the jobs that need clicks in Roblox Studio's own windows and menus; the CLI session keeps the Studio MCP checks. Your list, in order, steps from docs/TESTING.md: (1) open the home place (it syncs from home.project.json with rojo serve) and run milestone 42b step 5, then switch Studio's device emulator to iPhone SE and re-check the Shop's spin tiles (milestone 45 step 1) and the Gifts odds table; (2) Test tab, Clients and Servers, 2 players, and run the two-player steps of milestones 34, 36, 37 and 42e and owner guide Part D, driving both windows; (3) install these Studio plugins from the Creator Store (Toolbox, Plugins, or the store page, then Install): Stravant GapFill & Extrude, Stravant ResizeAlign, Stravant Redupe, Brushtool 2 and Archimedes v3. Free ones: install. A paid one: show Ethan the price in your window and buy only on his yes there. Then confirm each appears in Studio's Plugins tab, and update its row in docs/vault/02-how-we-work/Tools-Status.md; (4) only if all of (1) and (2) pass and the experience is still private: publish World 1, World 2 and home with File, Publish to Roblox, each synced from the branch head first. Ask Ethan before anything that spends Robux or changes account settings, and never touch the Open Cloud key. Write each result (pass or fail with what you saw) as bullets under a "## Computer-use session" heading in today's docs/vault/08-log/ note, commit and push after each numbered job; the coordinator reads them from git.
```


## Shop items

C22: `python3 -I tools/create_products.py --dry-run` reads the launch sections of Shop, names/descriptions from strings, prices from `robux`, and icon paths from owner guide Part C. It prints only launch items whose ID is still zero. Default mode is offline and changes nothing. `python3 -I tools/create_products.py --self-test` runs fake HTTP and temporary-file checks without using the shell key.

The Mac session runs `python3 -I tools/create_products.py --apply [--universe ID]` after review. The key stays in `ROBLOX_API_KEY` in that shell. Without `--universe`, apply resolves World 1's nonzero place ID (World 2 fallback). It lists every page of existing passes and products before creating anything, reuses an exact name match, refuses ambiguous duplicate names, and leaves an existing item's configuration unchanged. Review reused prices/icons separately. Missing images warn and are omitted. Each returned ID replaces only its zero numeric literal in Shop; writes are atomic and retained if a later item fails. A rerun finds a created item by name after an uncertain request. Do not run two creators concurrently; no remote transactional uniqueness API is assumed.

[Official game-pass reference](https://create.roblox.com/docs/cloud/reference/features/game-passes) and [developer-product reference](https://create.roblox.com/docs/cloud/reference/features/developer-products), verified 2026-10-07: multipart POST `/game-passes/v1/universes/{universeId}/game-passes` and `/developer-products/v2/universes/{universeId}/developer-products`; GET each path plus `/creator` for paginated configuration lists. Both need their read and write scopes. The script docstring records the fields and resolver path. Errors print only sanitized HTTP status/message; redirects are refused. A framework Python missing CA roots uses the OS CA file when available; TLS verification stays enabled. No live create/reuse was executed by Codex.
