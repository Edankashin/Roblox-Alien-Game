---
tags: [start-here, setup, tips, tooling]
aliases: [Setup and tips, Mac memory]
up: "[[Start-Here]]"
---
# Setup and tips: how Ethan configured everything, and what we learned

Companion to [[Handoff]]. Part 1 is exactly what Ethan set up (accounts, his Claude sessions, the Mac, Studio, Blender, Open Cloud, Codex, Obsidian), in the order he did it, with the problems hit on the way. Part 2 is the short version for the collaborator. Part 3 is the tips and tricks the sessions learned between 2026-10-04 and 2026-10-10, grouped by tool. When you learn something new, add it here (or to its topic note) and link it from the day's log.

---

## Part 1. Ethan's setup

### 1.1 Accounts

| Account | Used for | Notes |
|---|---|---|
| Claude (paid plan with Claude Code) | Every Claude session below | Usage is weekly-limited; Ethan's week resets Mondays at 10:00 AM, and he sets an extra-usage budget when needed. Sessions should be frugal ([[Token-Economy]]) |
| ChatGPT, a second account (different email) | Codex CLI (the "Codex Astra" plan) | Codex has its own usage limit; a batch run stops when it is reached and resumes after the reset |
| Roblox `EDankashin` (user id 1492992374) | Owns the experience "Alien game" (universe 10769415131) | Creator Dashboard at create.roblox.com |
| GitHub `Edankashin` | Owns the repo `Edankashin/Roblox-Alien-Game` | The Claude GitHub app is connected so claude.ai/code can open the repo |

### 1.2 The cloud coordinator (Claude Code on the web)

- Started from claude.ai/code on the repo `Edankashin/Roblox-Alien-Game`, branch `claude/alien-system-research`. It runs in a Linux container in the cloud, so it has the repo but **not** the Mac, Studio, Blender or the Open Cloud key. Its network goes through a policy proxy: TikTok and create.roblox.com are blocked from it, GitHub works.
- One long conversation since 2026-10-04; when the context fills it is summarised automatically, which is why every lasting fact also goes into the repo (vault, TESTING, the log). The repo is the memory, not the chat.
- It installs its own toolchain in the container with `./tools/ci/install-tools.sh` (Linux x86_64 only: Rojo 7.7.1, luau-lsp 1.70.1, the Luau 0.741 interpreter for the tests) and then `export PATH=$HOME/.local/bin:$PATH`.
- It builds with subagents: Sonnet workers with a complete brief, often in an isolated git worktree (`.claude/worktrees/`, ignored), then reviews, runs every check, commits with the attribution trailer and pushes.
- It reaches the Mac session by messaging it directly (both are Ethan's Remote Control sessions on the same account), so Ethan no longer relays test results by hand.
- A stop hook in the cloud environment complains when a turn ends with uncommitted or unpushed files; the habit is to commit and push before ending every turn.

### 1.3 The Mac (MacBook, Apple silicon), in the order it was done

1. **Clone and toolchain.** `git clone https://github.com/Edankashin/Roblox-Alien-Game ~/Roblox-Alien-Game`, check out the branch, then `./tools/setup-mac.sh`: Homebrew, Node, Claude Code (2.1.269 at the time), Rokit 1.2.0 with Rojo 7.7.1 and luau-lsp from `rokit.toml`, the Rojo Studio plugin, ffmpeg, yt-dlp, uv, Blender with the MCP add-on, and the two Claude plugins in `.claude/settings.json` (claude-code-setup, claude-mem). **Restart the terminal after Rokit installs**, or `rojo` is not on PATH yet.
2. **Roblox Studio**, signed in as EDankashin, and the experience opened once (the setup script's Rojo-plugin step needs Studio to have run once; re-run the script after).
3. **Studio as an MCP server.** Open any place (the Assistant button only exists with a place open), Assistant (purple atom icon, top right) > three dots > Manage MCP Servers > MCP Servers > **Enable Studio as MCP server**.
   - **The problem hit:** Claude Code reported "Conflicting scopes": `Roblox_Studio` was registered three times (user, local and project scope), and the local one was broken because Studio's "Startup Command" is already a complete `claude mcp add` line and had been pasted after another one.
   - **The fix:** `claude mcp remove Roblox_Studio -s local` and `claude mcp remove Roblox_Studio -s user`, then `cd ~/Roblox-Alien-Game && claude`, answer **yes** to the project MCP server from the repo's `.mcp.json`, `/mcp` shows one connected `Roblox_Studio`, and Studio's MCP page shows the green dot "1 client connected". **Rule: one registration only, the project one.** ([[Connection]])
4. **Remote Control**, so the Mac session can be driven from the Claude app or claude.ai/code anywhere: `cd ~/Roblox-Alien-Game && claude remote-control`. The session then shows in the Claude app's session list under an auto-generated name (Ethan's is "mac-reactive-milner"); click it and type, or type in the Terminal window, both are the same session. It keeps running on the Mac, so the Mac must stay awake.
5. **Rojo.** `rojo serve` (World 1), `rojo serve world2.project.json` or `rojo serve home.project.json`; in Studio, Plugins tab > Rojo > Connect (localhost:34872), and accept the connection prompt.
6. **Blender MCP.** Blender 5.2.2; Edit > Preferences > Add-ons > enable "Interface: MCP for Blender"; in the 3D viewport press N > MCP for Blender tab > **Start MCP Server** (port 9876). It must be started again every time Blender is opened. Registered in `.mcp.json` as `uvx mcp-for-blender`.
7. **The Open Cloud API key** (Creator Dashboard > Open Cloud > API Keys > Create API Key): named `alien-game-assets`, Access Permissions first **Assets** Read and Write, later (2026-10-07) for this experience **universe-places** Write, **game-pass** Read and Write, **developer-product** Read and Write; IP allowlist left open. Copied once (Roblox shows it only once) straight into `~/.zshrc` on the Mac, never into a chat or the repo:
   - `ROBLOX_OPEN_CLOUD_KEY` and `ROBLOX_CREATOR_USER_ID` for `tools/upload_assets.py` (model and image uploads; a group upload reads `ROBLOX_CREATOR_GROUP_ID` instead of the user id),
   - `tools/create_products.py` and `tools/publish.py` read `ROBLOX_API_KEY` first and fall back to the same `ROBLOX_OPEN_CLOUD_KEY` (found 2026-10-14: only the latter is set on the Mac).
   Uploaded models wait in Roblox moderation for a few hours before they load.
8. **Owner guide steps done by hand** (`docs/OWNER-GUIDE.md`): Part A (published Frostbyte and the Home Planet as places, ids 112829778258240 and 73774874008460), A8 (World 1's id 93842567264184), Part B (Studio access to API services, so real saves work in Studio), Part C (nine products and passes created on the dashboard, ids pasted into `Shop.luau`), Part E (Codex runs). Part D (two-player test) was done by the computer-use session.
9. **Studio access to API services**: Game Settings > Security > Enable Studio Access to API Services (on), and `Config.UseDataStoreInStudio = true` in the code.
10. **Codex CLI.** It lives inside ChatGPT.app, not on PATH: `/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex`. Unattended batch run from the repo: `codex exec -C <repo> --add-dir <repo>/.git -s workspace-write -c sandbox_workspace_write.network_access=true - < prompt.txt > ~/codex-batch.log 2>&1 &` with the batch prompt from [[Codex-Prompt]]. Ethan approves the run in the Mac session's window.
11. **Obsidian.** Installed; Open folder as vault > `~/Roblox-Alien-Game/docs/vault`. Its per-machine settings (`.obsidian/`) are git-ignored. Its command line is off (not needed).
12. **The computer-use session.** Claude desktop app > Settings: computer use on. Then the **Code** tab > new session > choose the folder `~/Roblox-Alien-Game` > paste the prompt in [[Hands-Off]] ("Jobs that need computer use"). The first time, allow it to control Roblox Studio; switching between Studio's test-player windows also needed a Finder/Dock grant. It is a separate session from the Remote Control one: the CLI session keeps the Studio MCP work, the desktop one does only clicks MCP cannot make.
13. **Keep the Mac available** for the sessions: plugged in, Studio and the Claude app open and signed in, automatic sleep off while plugged in (System Settings > Battery > Options).
14. **Optional, not relied on:** Studio's own Assistant can run on Claude with an Anthropic API key (Assistant > three dots > Manage API Keys > Anthropic). It does not read the repo, so it is only for quick in-Studio questions.

### 1.4 Limits Ethan kept on purpose

- The Mac session asks before running commands, uploading or publishing; how often it asks is Ethan's own setting in his Claude app. No session writes permission rules for another (an attempt to commit an allowlist was blocked by the safety check, correctly), and a blanket "access to everything on this Mac" grant is not used.
- Claude sessions do not install plugins into themselves; Ethan types plugin install lines himself.
- Anything that costs Robux or money, and identity or legal steps (age and ID checks, the Experience Questionnaire, going public), are his.

---

## Part 2. The collaborator's setup, short version

Pick the setup that matches what you will do. All three can coexist.

| You want to | Set up |
|---|---|
| Work in Studio with Claude (tests, dressing, live edits) | Your own Mac or PC: clone, Rokit, Studio, the Rojo plugin, Claude Code started **inside the repo folder** (terminal `claude`, or the desktop app's Code tab on that folder), Studio as MCP server with the project registration only. [[Handoff]] 13.3 |
| Drive that session from your phone or the web | `claude remote-control` in the repo folder, then open it from the Claude app |
| Code and docs without Studio | A claude.ai/code session on the repo (Ethan grants the repo, [[Handoff]] 13.2); first command in it: `./tools/ci/install-tools.sh && export PATH=$HOME/.local/bin:$PATH` |
| Models | Blender 5.x with the MCP add-on, server started from the N panel |
| Read and edit the vault comfortably | Obsidian on `docs/vault` |

Do not run `tools/setup-mac.sh` blind: it installs software machine-wide and trusts the pinned tools without a prompt. Run its lines one at a time and approve each. Windows: Rokit, Rojo and Studio work; the Studio MCP server is `%LOCALAPPDATA%\Roblox\mcp.bat`, so keep a local, uncommitted edit of `.mcp.json`.

---

## Part 3. Tips and tricks

### Working with Claude

- **Start every session the same way:** "read CLAUDE.md, the Handoff, the Board and today's log, then git pull". The repo holds the state; a fresh session with those four reads is fully caught up.
- **One system per change; name the instance path** ("`StarterGui.Hud.TopBar.ShopButton`", not "the button"); **say where each script goes** (server, client, shared). Paste the error together with the action that caused it.
- **Plan first for anything over two files**, correct the plan, then build.
- **The questions round** ([[Prompting]]): end a brief with "do you have any questions for me to implement this?", answer, then ask "what else could you ask me to make this easier to follow through?". Put the answers into the brief.
- **Contracts first.** Types, data rows and strings are written before any build worker starts, so two workers never edit the same file.
- **Right model per job.** Planning, design and review on the bigger model; well-specified builds on Sonnet subagents with a complete brief, reading their files in one or two commands and reporting in under 300 words ([[Token-Economy]]).
- **`/compact` before a new milestone** when the conversation is long; nothing is lost because the vault and TESTING hold the state.
- **Measure spend:** `npx -y ccusage daily` once a week.
- **Ask "what did you actually run?"** when a session says something is verified. "Verified" means a check ran, not that the code looks right; Studio checks are only real when a Studio session ran the TESTING steps.
- **Two sessions never edit the same file at once.** Claim the system on the [[Board]] first.
- **Never paste a key into a chat.** Keys go into the shell profile on the machine that uses them.
- **Commit and push before you stop**; a session's container or a laptop can disappear.
- When Claude suggests a tool, it gets a row in [[Tools-Status]] the same day, and "adopt" is only done when someone verified the install.

### Studio and the Studio MCP server

- The Assistant button and the top bar (Home, Model, Avatar, UI, Script, Plugins) only exist once a place is open.
- The MCP page's green dot is lit only while a Claude Code session is running in the repo.
- `execute_luau` runs in the Edit, Client or Server datamodel. A `require` from the MCP context gets a **fresh copy** of a module, so read live server state through remotes or events, not by requiring the service.
- Dev chat commands from the Client datamodel: `TextChatService.TextChannels.RBXGeneral:SendAsync("/scrap 1000")`. Only the first `SendAsync` of a command-bar run is delivered, so send one command per run.
- Over the Studio MCP, wrap that `SendAsync` in `task.spawn(function() ... end)`: a bare call hangs the `execute_luau` call for 120 s and then fails ("Target is closed") although the command ran (found 2026-10-14).
- Typing `/` commands into the chat box can be mangled by its autocomplete ("/admin/visit Player1sit off"); use buttons or `SendAsync`.
- In Play, the command bar does not take Cmd+A or Cmd+Return: triple-click the line and press Run.
- An `execute_luau` call during Play once hung for five minutes and timed out; keep calls short and stop Play if it stalls.
- A chat command sent with `SendAsync` straight from `execute_luau` can hang the call for 120 s although the command runs; wrap it: `task.spawn(function() ...:SendAsync("/scrap 1000") end)` returns at once (2026-10-14).
- **Never force-quit Studio** (`kill -9`): on 2026-10-14 the relaunch came up signed out (`Login error: 'Failed to fetch user info'`, then the login dialog) and every Studio job stopped until Ethan signed in. Stop Play, quit normally and answer the save prompt, or leave the old window open.
- **One Studio window at a time** (2026-10-14, the Mac session). Three builds open plus a fourth launch wedged Studio: the log repeated `Failed to acquire deploy lock for plugin deployment` and Play hung. To load a new build: File > Close the old window (Don't Save), then `open build/<file>.rbxl`. `open` on a path that is already open only focuses it, so give a changed build a new file name.
- With real pass ids, Studio treats the experience owner as owning every pass (all Shop pass tiles read "Owned", the storage cap includes the +100 pass). Use `/pass <id> off` for a clean baseline before storage, companion or Shop checks.
- MCP clicks: `user_mouse_input` with `mouseButtonDown`, an 80 ms wait, `mouseButtonUp` on an `instance_path` is reliable; the one-shot `mouseButtonClick` missed small targets. A click that lands on the chat window fails with "hits CoreGUI": hide chat first (`TextChatService.ChatWindowConfiguration.Enabled = false`). The tool resets a Scriptable camera after each call; hold a camera angle from a `RenderStepped` loop instead.
- **Device emulator:** Studio's list has no iPhone SE; **iPhone 7 (667x375)** is the same screen. Use **iPad 9th Generation (1080x810)** for tablets. The device picker is greyed out during Play, so pick the device first, then Play.
- **Two players:** Test > Clients and Servers > 2 players. Each test player is its own Studio process (separate Dock icons). Test players are not Roblox friends, so set the home lock to Anyone before a visiting test.
- **No Rojo Connect over MCP** (2026-10-22): the MCP cannot click the Rojo plugin's Connect, so a place opened without it runs whatever scripts it last saved. The sync that worked: `rojo sourcemap default.project.json -o sm.json`, a manifest of every Folder and script with its source, `python3 -m http.server` on 127.0.0.1, and one Edit-mode `execute_luau` that turns `HttpService.HttpEnabled` on only for the `GetAsync`, creates or updates each instance by path, removes scripts the repo no longer has, and turns it back off. `loadstring` works in that context too (the installer ran that way). A `.model.json` (the SurfaceTemplates) is not in the manifest: build those by hand.
- **The game's Output at Play over MCP:** the Studio log file does not carry the play session's prints; read `LogService:GetLogHistory()` from the Server or Client datamodel instead. The camera is reset every frame by the game's camera script: for a framed screenshot bind a `RenderStepped` step after `Enum.RenderPriority.Last` that sets the CFrame. Frame times measured while Studio is not the focused app read about 70 ms (a background throttle), so they say nothing about the game.
- **Saving:** the MCP cannot save a cloud place (no File menu, keyboard input reaches only the Client). Changes made in Edit mode stay unsaved until someone saves from the window.
- **Logs on a Mac:** the server's Output is also written to `~/Library/Logs/Roblox/*_last.log`; grep the `[AlienGame]` lines there instead of scrolling Output.
- **Stop Play before switching Rojo projects**, reconnect, then Play. Only one person's Rojo connected to a Team Create place at a time.
- **Never force-quit Studio** (`pkill -9`): on 2026-10-14 it dropped the saved sign-in and the next launch opened the login dialog, which only the account's owner can answer. Quit from the menu and answer the save prompt, or leave the window open. The three Rojo projects differ only in the Workspace attribute `WorldId`, so one built place switches worlds with `workspace:SetAttribute("WorldId", 2)` in Edit mode.
- **Never edit scripts in Studio**: Rojo overwrites them. Hand-placed dressing goes in `Workspace.Dressing` (the server builds `Workspace.World` at run time); camera anchors in `Workspace.Dressing.CameraRig`.
- Real saves in Studio need Studio API access on and `Config.UseDataStoreInStudio = true`; without them, profiles live in memory and vanish when the player leaves, so "rejoin keeps progress" steps need real saves.
- `/admin` commands on an unpublished place used to hang (MessagingService); they now time out after 5 s.
- A `ScrollingFrame`'s `CanvasSize` in Scale is measured against its **parent**, not itself; it cut two lists down to one row before the fix ([[UI-Playbook]]).
- Measure UI at the real pixel size: at 667x375 a label that "looks fine" in a big window cuts off. The UI fit pass measured every label against Fredoka One's metrics.

### Memory on the Mac

- **The cause as seen today (2026-10-14):** macOS said "Your system has run out of application memory" and paused every app until Ethan restarted. Open at that moment: four Roblox Studio processes, Blender, Chrome, Obsidian, the Claude desktop app and a Claude Code session. It is the sum, and Studio is usually the heaviest of them (unmeasured until the first diagnosis, below). Each extra Studio process is several GB, and a 2-player test adds one per test client.
- **One Roblox Studio window and process.** Close the old build (File > Close, Don't Save) before opening a new one, as in "One Studio window at a time" above; close the test clients when a multi-client test ends. Never force-quit.
- **Blender:** quit the app after a render or a model session. `blender -b` headless runs exit on their own, so batch work uses those ([[Creature-Generation]]).
- **Claude Code:** one session on the Mac, plus the coordinator in the cloud (which costs the Mac nothing).
- **Chrome:** Memory Saver on (Settings > Performance) and the tab count low; close the research tabs when a task is done.
- **Obsidian** is closed during overnight runs (the vault is plain files, so the sessions do not need it).
- **Check it:** run `tools/mac_memory.sh` before an overnight run, and during one run `caffeinate -dims tools/mac_memory.sh --watch` (every 300 s, `--every N` to change it). It only reads; it never closes anything. It prints physical memory, swap used, the memory-pressure level, the top 12 apps by resident memory (each app's processes summed, with the share of RAM) and the RobloxStudio count.
- **The `WARN:` line** names what tripped: swap used above 2 GB (the Mac is already paging to disk), memory pressure warn or critical (macOS is compressing hard), or more than one RobloxStudio process. `--watch` also posts a notification, the same warning at most once per 30 minutes. Close first, by the top-apps list and in this order if unsure: extra Studio windows (test clients first), then Blender, then Chrome tabs, then Obsidian, then the Claude desktop app. Quit from the menu; do not kill anything.
- **First diagnosis numbers (2026-10-14, Mac session, idle, Studio closed):** the MacBook has **8 GB** of RAM (`hw.memsize` 8589934592), so two Studio processes alone can fill it. Swap 1024 MB total, 142 MB used; pressure normal, 51% free; 106,349 pageouts since boot. Top apps: Claude desktop 989 MB, Claude Code CLI 611 MB (two `claude` processes), Granola 318 MB, Obsidian 161 MB, Spotlight 115 MB, Terminal 81 MB; no Blender, no Chrome, no Studio running. The script's app names and the `RobloxStudio` count match the real process names. One Studio process in Play for an hour (2026-10-14 evening): swap grew to 5.8 GB of 7.2 GB and pressure went to warn, with Studio's RSS only 425 MB because the rest was paged out. On this Mac one Studio in Play is the whole budget: close Blender, Chrome and the Claude desktop app before a Studio session.

### Repo, checks and git

- The four checks before any code commit: `./tools/analyze.sh` (`analyze: clean`), `python3 -I tools/lint_data.py` (`data lint: clean`), `./tools/test.sh` (all 265 pass), `./tools/lint.sh` (strings, remotes, UI, TESTING, run-sheet freshness). CI runs the same on every push.
- When `docs/TESTING.md` or `docs/PRE_PRODUCTION.md` change, regenerate the run sheet: `python3 -I tools/studio_queue.py --write`; otherwise `lint.sh` fails on freshness.
- Every number goes in `src/shared/data`, every string in `src/shared/strings` with a key; the lints catch strays. Dynamic string families (like `SEGMENT_SHORT_<id>`) must be listed in `tools/lint_strings.py`.
- Run the Python tools with `python3 -I`.
- `git pull --rebase origin claude/alien-system-research` before every push. GitHub sometimes answers 500 on push: wait and retry (2, 4, 8, 16 s). Never force-push.
- A merge conflict in `docs/STUDIO-QUEUE.md`: take either side and regenerate it; it is generated.
- Never commit `media/tiktok/out/` audio or frames, `build/`, `.obsidian/` or `.claude/worktrees/` (all ignored).

### Reference videos (TikToks)

- Download on the Mac (the cloud cannot reach TikTok): `yt-dlp --write-info-json -f "mp4/best" -o "media/tiktok/<code>.%(ext)s" "https://www.tiktok.com/t/<code>/"`, commit and push; the cloud session processes it with `tools/watch_video.py` (frames into contact sheets, a Whisper transcript).
- yt-dlp refuses TikTok `/photo/` slideshows; the slides come from the post page's embedded data (`webapp.reflow.video.detail`, with a mobile user agent).
- Every video's lessons go into `media/tiktok/NOTES.md`, the plan into PRE_PRODUCTION, and every tool it names into [[Tools-Status]].

### Blender and models

- Start the MCP server inside Blender each session; with Blender closed the handshake fails. Save the file before a session that runs code in it.
- 1 Blender unit = 1 stud; aliens stand 2 to 3 studs. Models keep their height, pivot (at the feet) and material slot order so they drop into the game unchanged ([[Creature-Generation]], [[Blender-MCP]]).
- The FBX faces -Z (Roblox's front); the GLB faces +Z.
- `blender -b -P tools/blender/alien_base.py -- --only Mossbop` builds one species headless; `assets/models/<Id>/notes.md` records each model.
- Bulk uploads go through Open Cloud (`tools/upload_assets.py`), then `tools/studio/install_models.luau` places and colours them in Studio ([[Map-Dressing]] "Bulk import").

### Codex

- Without `--add-dir <repo>/.git` the sandbox makes `.git` read-only and the first commit fails on `.git/index.lock`; the network option lets it push.
- Cards claim themselves with a one-line commit, so a half-done card is visible; reports land in [[Codex-Reports]], so nobody pastes them.
- Codex cards touch only the files they name; a card that needs another file stops and reports.

### Roblox platform facts we tripped on

- `games.roblox.com` hides the root place of a **private** experience (returns 0); `develop.roblox.com/v1/universes/<id>` gives it.
- A purchase receipt answers `PurchaseGranted` only after the save succeeded (`PlayerData.SaveNow`), or a crash can lose a paid item.
- Paid random items must check `PolicyService:GetPolicyInfoForPlayerAsync` (`ArePaidRandomItemsRestricted`); Studio prints the answer on the first shop open.
- `HapticService` addresses a device through a Gamepad input type; whether a phone answers there is unverified until tested on a real phone.
- Roblox kicks idle players at 20 minutes; resting rejoins the same public server before that (private and home servers fall back to offline income).
- Each world is a place in one universe; the place says which world it is through the `WorldId` attribute each Rojo project file sets.

### How Ethan likes to work

- He is new to Studio and Roblox development: give him click-by-click steps that say where each button is.
- Decisions are asked one line at a time, with a recommendation ("build playtime gifts? yes or no").
- He wants as little manual work as possible: if a session can do it, it should; what only he can do goes on the Board's "Waiting on Ethan" list.
- Keep him updated with short summaries of what changed and what is next, and mind his weekly usage limit.
- Quality bar: the top Roblox games' feel and polish, with our own designs (PRE_PRODUCTION 5a).

## Obsidian connected to Claude (proposal, 2026-10-15)

Proposal for Ethan; nothing here is installed. Decision: [[Decisions]] B33; source: the [report](../../../reports/Roblox%20creature%20UI%20and%20Claude%20workflows.md), section "The vault works when hooks enforce what CLAUDE.md only advises". Why: the filesystem already gives every session the vault (cloud sessions have no Obsidian, and that stays the shared channel); this adds Mac-only conveniences, namely heading-targeted edits, search by frontmatter, backlinks and daily-append. Do it with Studio and Blender closed (8 GB, see [[#Memory on the Mac]]); Obsidian itself must be open for the plugin and the CLI to answer.

1. **Install the plugin.** Obsidian, Settings, Community plugins, turn Restricted mode off, Browse, search "Local REST API" (repo `coddingtonbear/obsidian-local-rest-api`), Install, Enable.
2. **Find the API key.** Open the plugin's settings page: it shows the key and the server address (`https://127.0.0.1:27124`). The key is stored in the plugin's own `data.json` under `docs/vault/.obsidian/plugins/`, inside the vault folder (check the exact folder name on the Mac). That file must never reach git. `.gitignore` already lists `docs/vault/.obsidian/`; prove it before going on:
   `git check-ignore -v docs/vault/.obsidian/plugins/obsidian-local-rest-api/data.json`
   It must print the matching `.gitignore` line. If it prints nothing, add `docs/vault/.obsidian/plugins/*/data.json` to `.gitignore` first. Never paste the key into a note, the log, a chat or a file; it goes into the one command below and nowhere else.
3. **Register the server** (Terminal, from `~/Roblox-Alien-Game`; verify on the Mac):
   `claude mcp add obsidian -e OBSIDIAN_API_KEY=<paste from the plugin settings> -- uvx mcp-obsidian`
   The report names the server (`mcp-obsidian`, by MarkusPfundstein) but gives no `claude mcp add` line for it, so this is the generic form. If it cannot find Obsidian, check the server README for its host and port variables (the plugin listens on 127.0.0.1, port 27124). Use the default local scope or `--scope user`, never `--scope project`: that would write the key into `.mcp.json`, which is committed. The plugin also ships its own MCP endpoint at `https://127.0.0.1:27124/mcp/`; the connection line for it is not in the report, so try `mcp-obsidian` first.
4. **Check it.** Start Claude Code in the repo, `/mcp` should show `obsidian` connected; ask it to search the vault for "Character-Pipeline". If it does not connect: is Obsidian open, is the plugin enabled, is the key current? Put the error text in the log, never the key.
5. **Turn on the Obsidian CLI.** Obsidian, Settings, General, enable the command line interface (Obsidian 1.12 or later; verify the label on the Mac) and follow the app's prompt to make `obsidian` available in Terminal. It talks to the running app over IPC, so Obsidian must be open. It gives `search`, `backlinks`, `daily:append` and `property:set`.
6. **Optional: the skill pack.** `kepano/obsidian-skills` (the Obsidian CEO's pack, with an `obsidian-cli` skill). Type its install line yourself in Claude Code; a session does not install into itself.
7. **Tell the Mac session** "Obsidian is connected". It verifies with reads and searches only, then sets the [[Tools-Status]] rows to in use ([[Board]]).

While connected: the vault stays plain files in git, so commit before a session edits many notes (one author's agent changed 340 files in a vault with no backup). Writes through the MCP still follow the log rule and must leave `python3 -I tools/lint_vault.py` printing `vault: clean`. Close Obsidian for overnight runs as before; the sessions then use the files. Rotate the key (Regenerate in the plugin settings) if it was ever pasted anywhere.

## Hooks proposal (not applied)

Proposal for Ethan. **No session applies this.** Sessions never write their own Claude settings or permission rules, and this edits `.claude/settings.json` (today it holds only `enabledPlugins` and `extraKnownMarketplaces`, so the block below is added beside them). Ethan pastes it, amends it or throws it away. Why: CLAUDE.md is advisory, hooks are deterministic. In one reported test, a session with no repo-side instruction made zero vault calls and implemented a design the vault had recorded as explicitly rejected; that author's answer was these three hooks. Source: the same report section, [[Decisions]] B32.

What it does:
- `SessionStart` on `startup|resume|compact` prints [[Now]] into the session. The `compact` matcher matters: context a hook added earlier is summarised away at compaction, and the hook runs again.
- `PostToolUse` on `Write|Edit` runs `python3 -I tools/lint_vault.py` when the touched path is under `docs/vault`. It checks the raw hook input for the path, so a note that merely mentions the path costs one cheap read-only lint. A broken link exits 2, which hands the message to Claude to fix.
- `Stop` asks once for a log line when `src/` has uncommitted changes and `docs/vault/08-log/` has none (it stands down when the stop hook is already active, so it cannot loop).

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
        "hooks": [
          {
            "type": "command",
            "command": "cat \"$CLAUDE_PROJECT_DIR/docs/vault/00-start-here/Now.md\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "if grep -q '/docs/vault/'; then cd \"$CLAUDE_PROJECT_DIR\" && python3 -I tools/lint_vault.py >&2 || exit 2; fi"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "grep -q '\"stop_hook_active\": *true' && exit 0; cd \"$CLAUDE_PROJECT_DIR\" && if [ -n \"$(git status --porcelain -- src)\" ] && [ -z \"$(git status --porcelain -- docs/vault/08-log)\" ]; then echo 'src/ changed but the log did not: append your heading and bullets to docs/vault/08-log/ (CLAUDE.md, Vault logging).' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

Check before trusting it: run each command by hand once with `CLAUDE_PROJECT_DIR` set to the repo, confirm `/hooks` lists the three, and watch the first session start. Path-scoped rules are a separate proposal that is not written: `.claude/rules/*.md` files with `paths:` frontmatter that load only when Claude touches `src/client/**` (read the [[UI-Playbook]] first), `src/shared/data/**` (every number lives in data) or `assets/models/**` (the [[Character-Pipeline]] rules).
