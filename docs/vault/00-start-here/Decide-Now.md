---
tags: [start-here, decisions, ethan]
aliases: [Decide now, Ethan's decisions]
up: "[[Start-Here]]"
---
# Decide now: every open question, one number each

Ethan, 2026-10-15 night: "I want you to lay everything out for me so it's easier to decide." This is every open decision and every row that carries your name, gathered from [[Asks-Ledger]] (the two owe-lists), [[Board]] ("Waiting on Ethan", "Needs a decision"), [[Decisions]] ("Open"), [[Tools-Status]], [[Setup-and-Tips]], [[Overnight]] (jobs 30 to 33), [[STORE-PAGE]], [[Thumbnail-Research]], [[Hero-Aliens]], [[Model-Toolchain]] and the design doc. Logged in [[2026-10-15]]. Back to [[Start-Here]].

> **Answered 2026-10-17 ([[Decisions]] B43).** Ethan rejected the redesigns: the look becomes blocky, as in popular Roblox games; rarer aliens get more detail, more height and VFX (not a fiercer face); every design goes through Claude Design, Blender and Obsidian. So items **12, 37, 39 and 40 are closed** (the recipe redesigns are not the direction) and **38 is answered yes** (more detail and height with rank). Items 11 (the hero route) and 9 (the hero slate) now wait on the blocky style note. Everything else stands.

**How to answer.** 40 items in six groups (37 to 40 added 2026-10-16). Each has the question, the options (a, b, c), a recommendation in bold with its reason, and what happens right after you answer. Reply with numbers and letters (`1: a, 2: a, 7: d`) or paste the Answer sheet at the bottom. "Use yours" is a valid answer on the picks (7, 8, 12, 13). A recommendation is never an answer: nothing is decided and nothing is spent until you reply. The money items (22 to 28) need their own letter; "all starred" does not cover them. Minutes and dollars come from the notes where they have a source and are estimates where they do not; prices are search snippets, so check the live page before paying. Never paste a key into a reply, a note or a chat.

**Order tonight (about 45 minutes).** Item 1, then 3 and 2 with Studio closed, then reopen one Studio for 4, then 5 and 6 on the phone. Everything after item 6 can wait for tomorrow.

## Tonight on the Mac

**1. Studio windows on the Mac: close the extras?** Four windows wedged Studio's plugin lock on 2026-10-14 and every Studio job waits; the 8 GB Mac holds one Studio at a time.
- Options: a) quit Studio now (File > Quit, Don't Save), do items 3 and 2, then reopen one window; b) close the extras and keep one; c) later.
- Recommend: **a**, because item 3 needs Studio closed and the Studio jobs only need one window afterwards.
- Then: say "Studio is back" to the Mac session (or start a new one with the prompt at the end of [[Overnight]]); it runs jobs 30, 32 and 33 in turn: species effects and surface checks, the Shop shelf and launch camera, the reveal beats.

**2. Blockbench: install it?** Free, no account (version 5.2.2, not on the Mac yet); the desk for hand-painting a species and keyframing its idle, walk and hatch.
- Options: a) the macOS build from `blockbench.net` (about 5 min); b) the browser build at `web.blockbench.net`, no install; c) later.
- Recommend: **a**, because an installed app is the simplest for the Mac session to open and screenshot. Without it nothing in the game breaks, but three Mac probe rows, all texture painting and hero route b wait.
- Then: tell the Mac session; it opens `media/blockbench/Sparkfox.bbmodel` then Mossbop, runs the glTF animation probe and a one-stroke paint test, and flips the Blockbench rows in [[Tools-Status]] to in use.

**3. Obsidian: turn on the CLI and add the Local REST API plugin?** About 10 minutes with Studio and Blender closed and Obsidian open; a Mac-only convenience (backlinks, daily append, edits by heading); cloud sessions keep using the files.
- Options: a) both: Settings > General > turn on the command line interface, then Community plugins > install and enable "Local REST API"; b) the CLI toggle only (1 min); c) later.
- Check first: `git check-ignore -v docs/vault/.obsidian/plugins/obsidian-local-rest-api/data.json` must print a `.gitignore` line; then in Terminal from `~/Roblox-Alien-Game`: `claude mcp add obsidian -e OBSIDIAN_API_KEY=<the key shown in the plugin settings> -- uvx mcp-obsidian` (the key goes in that line only; never `--scope project`).
- Recommend: **a**, because you asked on 2026-10-15 for the vault to be connected directly and it closes two "decided, not installed" rows. Without it nothing breaks.
- Then: tell the Mac session "Obsidian is connected"; it verifies with reads only and sets the rows to in use ([[Setup-and-Tips]] "Obsidian connected to Claude").

**4. The collaborator's access: do both steps tonight?** You promised it on 2026-10-06 and 2026-10-10; their setup, the first cold playtest and `/admin` for them all wait on it. Roblox needs a friend link and an age check on both accounts ([[Handoff]] 13.1 and 13.2).
- Options: a) both: Roblox (friend them, age check, Studio > Collaborate > add with Edit; about 10 min) and GitHub (repo Settings > Collaborators > Add people > Write; 2 min); b) GitHub only; c) later.
- Recommend: **a**, done while the one Studio from item 1 is open, because the Collaborate button lives in Studio.
- Then: Collab-Claude adds their Roblox user id to `src/shared/data/Admin.luau` `DeveloperUserIds` (one line); they run the setup in [[Handoff]] 13.3, then the cold playtest.

**5. Join the private game on your phone?** World 1 v90, World 2 v5, Home v4 carry everything of 2026-10-14 except the evening fixes; about 5 minutes; promised on 2026-10-14. The new bodies are not uploaded, so expect the older ball-shaped aliens.
- Options: a) join tonight and check four things: models load (no grey placeholder shapes), the Shop shows "about $" price lines, one catch works, music plays; b) later.
- Recommend: **a**, because the game has not been seen on a real phone yet (haptics are still listed as unverified in [[STORE-PAGE]] section 6) and only a phone settles touch size and speed.
- Then: tell the coordinator what failed; each failure becomes a [[Board]] row. Do item 6 in the same session.

**6. Music and sound: keep or swap?** Nobody has heard the 12 music picks or the 36 sound picks; the Menus track is still 0 and three sound slots (WardenAppear, Mount, Wiggle) are empty ([[Music-Plan]] has the pick tables).
- Options: a) listen during item 5, then name the rows to swap (one new number per row) and a Menus pick or "none"; b) ship blind and swap in week one, your 2026-10-14 call; c) later.
- Recommend: **a**, because ten minutes now beats a blind launch and each swap is a one-number edit in `src/shared/data/Music.luau`.
- Then: a worker applies your swaps; the Mac or Collab picks one Toolbox candidate for each of the three empty sound slots.

## Picks

**7. Which store icon?** Four are built; the research wants the mascot, no text, readable at 150 and 64 px. The three of 2026-10-14 show the earlier ball-shaped bodies on pale sky (the coordinator's pick was a); the fourth is built from today's bodies.
- Options: a) `media/store/2026-10-14/icon_Mossbop_v2.png` (lime Moop, a purple crown tuft, huge eyes, thin navy outline); b) `icon_Sparkfox_v2.png` (orange Vixa, a gold tuft); c) `icon_Thunderhog_v2.png` (pink Voltus, three cream spikes, a magenta halo), both in the same folder;
- d) `media/store/2026-10-15/icon_v3.png`: Moop's whole body (a lime mound with ears and a gold bulb) on a saturated violet backdrop, a thick navy outline, one gold sparkle.
- Recommend: **d**, built to the research recipe (mascot, dark saturated backdrop, outline 3.2% of the width, checked at 150 px, 64 px and greyscale) where the v2 icons have a pale backdrop and a 1% outline; re-render from the final bodies before launch, because a store image must match the live game.
- Then: [[STORE-PAGE]] 5d points at your pick ("use yours" means d).

**8. Thumbnails: which goes first?** Four directions, in `media/store/2026-10-15/` and on the canvas's Thumbnails board ([Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4)); `thumbs_192_strip.png` shows them at tile size.
- Options: a) the Moment, `thumb_moment_v1.png` ("PERFECT!": a wide-eyed Vixa with the real capture bar, gold zone and ticker); b) the Reward, `thumb_reward_v1.png` ("LEGENDARY": Gaira under gold rays and confetti); c) the Mystery, `thumb_mystery_v1.png` ("WHO'S THAT?": Glim peeking from behind a rock, lamp-lit, a gold "!"); d) the event frame, `thumb_event_nebula_v1.png` (Haunted Nebula, for the Events listing only).
- Recommend: **a, then b, then c** in the first three slots and d on Events only, because the Moment is the only frame that shows the verb and it matches the first minute (the first catch lands at 0:30); hold the set seven days, then read play-through rate and playtime together ([[Thumbnail-Research]] section 9).
- Then: [[STORE-PAGE]] 5d lists your order; all four are re-rendered from the final bodies once the creature direction is settled (the 2026-10-14 titled set is superseded).

**9. Hero slate: yes?** Twenty heroes across Norse, Greek, Egyptian, Japanese, Chinese, Hindu and Roman traditions, the Haku-like dragon among them; eight to build first, one a week: Fenrir, Suiryn (the dragon), Raiju, Qilin, Kerbos, Pegasi, Sphinx, Airava ([[Roster-Redesign]] section 3, [[Decisions]] B37).
- Options: a) yes as written, including Frostbyte's second Legendary (Airava) and first Secret (Suiryn); b) yes with changes (name them); c) no.
- Recommend: **a**, because each hero is an original creature that echoes a being by one attribute and its name, with the goofy-cute eyes kept; nothing ships before you have seen its sheet.
- Then: the Board's "Roster redesign 5" row unblocks: one hero a week in that order, each with a sheet for you first.

**10. "Creatures, not deities" (B37): confirm?** For traditions with living religious communities (Hindu, Shinto, Buddhist) the heroes are creatures from their epics and folklore, never deities; it keeps the Pantheon rule in `docs/GAME_DESIGN.md` section 4.
- Options: a) confirm as written; b) stricter: creatures only for every tradition, no gods anywhere; c) looser: deities allowed.
- Recommend: **a**, because Greek, Norse and Egyptian figures are already allowed by decision 12, and a game that sells random eggs should not put a living religion's deities in them.
- Then: B37 loses its "Ethan to confirm" tag in [[Decisions]], and the slate's Hindu and Japanese rows stay creatures.

**11. Hero hand route: a, b or c?** Two rounds of recipes and the hybrid sculpt hit their ceiling on Fenrir (the snout reads like a trunk, the fur plates read as spikes); only heroes go by hand, the 32 stay on the recipe route ([[Hero-Aliens]] "The coordinator's read after round 2").
- Options: a) the Mac models Fenrir in Blender with Claude looking through the Blender MCP, from the round-2 GLB (free; Studio closed); b) a Blockbench pass on the round-2 project to reshape head and fins (free; needs item 2); c) a Tripo trial (credits; items 23 and 26).
- Recommend: **a** first, because Blender and its MCP are already in use and it costs nothing; add b once Blockbench is verified, and c only as a side-by-side after a.
- Then: [[Board]] "Roster redesign 3" proceeds on that route; nothing under `assets/models/` changes until you say yes to a sheet.

**12. The sheets: is the hybrid fuse the right direction?** Before any model is replaced, look at the hybrid sculpt pass 2 (all 35), Fenrir v2 with Skydrake, and the UV bake (copies in `media/studio/2026-10-15/`; [[Sculpt-Pass]], [[Hero-Aliens]], [[Surface-Pass]]).
- Options: a) yes: one fused skin per creature (B28), rolled across the roster on scratch copies; b) no: keep the 32 recipe bodies as built and say "upload"; c) mixed: name the species to redo first.
- Recommend: **a**, because the recipe bodies are the "shapes mashed together" look you rejected on 2026-10-15 and the fuse was built to fix it; nothing replaces a model until you say yes anyway ("use yours" means a).
- Then: workers continue on scratch copies, the Mac's two Studio probes follow, and the 32 bodies stay un-uploaded until your "upload" (B27).

**13. Claude Design canvas: pick a board per screen?** The HUD, Aliens and the reveal (plus the species sheet) are on [Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4); the HUD rebuild waits on it. The Shop shelf was already rebuilt from the UI reference (ffeae32). [[Claude-Design-Brief]].
- Options: a) pick a board per screen (write it as the canvas labels it, "HUD 2, Aliens 1"); b) "use yours": the coordinator picks and you judge the first built screen on your phone; c) later.
- Recommend: **b**, because the phone rules in [[UI-Playbook]] already fix the layout (the HUD menu sits above the thumbstick zone) and a built screen on your phone is a better judge than a mockup; pick a if you have five minutes with the canvas open.
- Then: the HUD rebuild row starts, one screen per change, with the Playbook updated in the same commit.

## Tools and installs

**14. bun (and the claude-mem trial)?** A JavaScript runtime; claude-mem, the memory plugin enabled since 2026-10-05, needs it and is half working without it. Install: `brew install bun` (or the official bun installer), about 1 min.
- Options: a) install bun and run claude-mem for one week, with ccusage checking its cost; b) drop claude-mem and skip bun; c) later.
- Recommend: **a**, because you said adopt it on 2026-10-07; set its provider deliberately, since it spends calls compressing sessions. Without bun nothing in the game breaks.
- Then: the Mac session finishes the plugin's setup and logs the week's `npx ccusage` numbers; the [[Tools-Status]] row goes to in use or is dropped.

**15. rtk?** A single Rust program that squeezes shell output (Rojo, git, analyzer logs) before a session reads it; its claim is 60 to 90 percent less. Install: `brew install rtk` (about 2 min), then the hook step from its README, which edits Claude settings and so is yours to run (the Mac session reads you the line).
- Options: a) yes, as a one-week trial; b) no; c) later.
- Recommend: **a**, because the usage limit stopped work six times between 2026-10-05 and 2026-10-15 and the ccusage baseline already exists. Without it nothing breaks; sessions just read more text.
- Then: after a week the Mac compares `npx ccusage` with the baseline and keeps or drops it.

**16. ccstatusline?** A status line in Claude Code that shows context used and cost. Install: `npx -y ccstatusline@latest` (about 3 min; it opens a setup menu; the Mac session reads you a pinned version to use instead of `@latest`).
- Options: a) yes; b) no.
- Recommend: **a**, because it makes spend visible while the usage-limit question (item 24) is open. Without it nothing breaks.
- Then: the Mac session notes the pinned version in [[Tools-Status]].

**17. The roblox-dev plugin (ivar-anon)?** A Luau toolkit: exploit-proof remotes, safe DataStores, strict typing, the client and server split. Install, typed by you in Claude Code on the Mac (about 2 min): `/plugin marketplace add ivar-anon/roblox-dev` then `/plugin install roblox-dev@roblox-dev`.
- Options: a) yes, then the dry run; b) no; c) later.
- Recommend: **a**, because it matches our server-authority and strict-mode rules, provided the dry run shows it does not override `CLAUDE.md`. Without it nothing breaks.
- Then: the Mac runs the three-step dry run in [[Claude-Plugins]] and logs it; a failure means uninstall.

**18. The ShiroKSH roblox-studio skill?** Building and placement: maps, arenas, level design. Install, typed by you in Claude Code (about 2 min): `/plugin marketplace add ShiroKSH/skills` then `/plugin install roblox-studio@skills`.
- Options: a) yes, then the dry run; b) no; c) later.
- Recommend: **a**, because the map dressing pass for World 2 is queued and this is the tool for it. Without it nothing breaks; the pass goes by hand through the Studio MCP.
- Then: the same dry run as item 17, before the map pass starts ([[Map-Dressing]]).

**19. Superpowers?** A plugin that plans more before a big feature. Install, typed by you in Claude Code (about 1 min): `/plugin install superpowers@claude-plugins-official`; then say "use Superpowers for this" on a big build.
- Options: a) yes; b) no; c) later.
- Recommend: **c**, because more planning spends more usage and no big build is queued that needs it; install it when the HUD rebuild or World 3 starts. Without it nothing breaks.
- Then: the Tools-Status row stays "decided, not installed" with the trigger written beside it.

**20. kepano/obsidian-skills?** The Obsidian maintainer's skill pack; its `obsidian-cli` skill wraps the CLI (search, backlinks, daily append, properties). Install, typed by you in Claude Code (about 2 min): `/plugin marketplace add kepano/obsidian-skills` then `/plugin install obsidian@obsidian-skills`; the line is from our research note, so check it against the repo README first.
- Options: a) yes, after item 3; b) no; c) later.
- Recommend: **a**, once the CLI is on; it is Mac-only and low stakes. Without it nothing breaks; the vault is plain files.
- Then: the Mac session verifies `backlinks` and `daily:append` and sets the row to in use.

**21. The hooks proposal: apply it?** Three hooks in `.claude/settings.json`: SessionStart prints [[Now]]; PostToolUse runs `python3 -I tools/lint_vault.py` after a vault write; Stop asks for a log line when `src/` changed and the log did not. The block is in [[Setup-and-Tips]] "Hooks proposal (not applied)"; no session applies it; about 3 minutes.
- Options: a) apply all three and write the path-scoped rules next; b) apply the three, decide the rules later; c) amend (name the change); d) no.
- Recommend: **b**, because hooks are deterministic where `CLAUDE.md` is only advice, and they are cheap to remove; judge the rules after a week. Without them sessions can skip the hot note and the log.
- Then: you paste the block (no session edits its own settings), run each command once with `CLAUDE_PROJECT_DIR` set, and check `/hooks` lists three.

## Money and accounts

**22. Substance 3D Painter licence?** Not installed; no Steam and no Creative Cloud on the Mac. The Mac has 8 GB and Painter's published minimum is 16 GB (a snippet), so it may not run at all ([[Model-Toolchain]] section 4).
- Options: a) the 30-day Adobe trial first, buy nothing; b) Steam perpetual, about $200 (no Assets library); c) Adobe Collection, about $60 a month; d) not now, Blockbench for textures. (The free student licence is non-commercial, so a trial only.)
- Recommend: **a**, because the 16 GB minimum means it may not run here and Painter is only for six or seven hero species; check the trial's billing terms on the live page first.
- Then: the Mac runs the trial with Studio closed and logs whether it opens a hero model; the cloud writes the export preset and `tools/painter/export_species.py` blind and the Mac runs it once inside Painter; buy only after that.

**23. Tripo credits?** Tripo's own API (the Blender add-on has Tripo as Premium-only). One low-poly text-to-3D was observed at 40 credits, credits cost $0.01 each, and its paid plan is reported at $19.90 a month (third-party figures, unverified); the Board's figure for the whole trial is about $10 to $15 ([[Character-Pipeline]]).
- Options: a) yes, one Tripo account and a top-up capped at $15; b) no.
- Recommend: **a**, because it is the cheapest way to learn whether a generated hero beats hand work; nothing ships from it without the three ship checks and a read of the current terms.
- Then: a worker runs one species through Tripo's API with the key in the shell only (never a file) and posts a sheet for you; item 11 route c then has its answer.

**24. The usage-limit plan?** The limit stopped work six times between 2026-10-05 and 2026-10-15, twice on the night you asked for it to run uninterrupted. Pooled accounts and model routers are out (terms); the two real options are in [[Claude-Plugins]] "Keeping working when the subscription limit is hit".
- Options: a) an Anthropic API key in the Mac shell for overnight runs only, billed per use, with a monthly cap you set; b) accept the resets and plan the nights around them.
- Recommend: **a**, because a stopped night costs more than a capped spend; keep the daytime on the subscription.
- Then: you create the key and set its cap in the Anthropic console and put it in `~/.zshrc` only; the overnight prompt uses it; the key is never written to a file, a note or a chat.

**25. The group Moop Games (100 Robux)?** Created with your screen linked to the coordinator (Devices in the composer); name and emblem (`media/group/emblem_v1.png`) are ready in [[Group-Page]]; a wrong name costs another 100 Robux and a 90-day wait. Parked while the launch is off (B27).
- Options: a) yes to the spend now; it runs when the date is set and your Mac is linked; b) create it now, date or not (your 2026-10-14 call); c) ask again when the date is set.
- Recommend: **a**, because the group changes nothing for players before launch and the cost is the same later.
- Then: at the date you link your Mac; the coordinator creates the group, fills the Creator Dashboard from the run sheet ([[STORE-PAGE]] 5d) and sets `Social.GroupId` so the join gift shows.

**26. Generator credits: the three-vendor trial?** One species through Tripo, Meshy and Rodin, judged on the three ship checks (silhouette at 64 px, no seam, face at 128 px); about $10 to $15 in all, Tripo's part included. If item 23 is no, this is no.
- Options: a) yes, all three on one species; b) Tripo only (item 23); c) no generators at all, the fused roster only.
- Recommend: **a**, the Board's own recommendation: one species is enough to show whether a hero creature is worth generating; until it runs, the fused roster is the safer choice.
- Then: a worker runs the three through their APIs with keys in the shell only and posts a side-by-side sheet; [[Tools-Status]] rows for Meshy and Rodin are added the same day.

**27. Open Cloud key hygiene (2 minutes)?** In the Creator Dashboard, check the key is scoped to the Assets API (read and write) and `universe-places:write` for this experience only, has an expiry, and lives only in `~/.zshrc`; rotate it if it was ever pasted anywhere.
- Options: a) done; b) later.
- Recommend: **a**, because it is the only credential that can publish your places and upload your assets.
- Then: the Mac session (or the coordinator once your screen is linked) reads the scopes and logs them, never the secret.

**28. Paid Studio plugins?** Stravant GapFill & Extrude, ResizeAlign, Redupe; Brushtool 2; Archimedes v3. Free ones get installed freely; a paid one needs your yes in Robux, and prices wait on the Mac's Studio screenshot ([[Tools-Status]]).
- Options: a) free ones only; b) buy the ones the map pass needs, up to a Robux cap you name; c) decide per plugin when its price is known.
- Recommend: **a**, because the launch is off and the map dressing pass has not shown a gap a paid plugin fills.
- Then: Collab or the Mac installs the free ones (Brushtool 2 and Archimedes only if free) and updates the plugin rows.

## Small game decisions

**29. Rejoin notifications (decision 20)?** Experience Notifications are opt-in and 13+ only; today `Social.NotificationsEnabled` is false and the store page says off. The opt-in card exists and stays hidden until a sender exists.
- Options: a) yes as specced: an opt-in card from session 2, event text only, three a week at most, behind a Config flag; b) never; c) decide after launch, once players return.
- Recommend: **a**, because it is a retention tool that is opt-in, capped and flag-gated, and the flag stays off until the sender exists.
- Then: the sender (Open Cloud key on the Mac, never in the repo) is built at launch; [[STORE-PAGE]] section 3 keeps "off" until then.

**30. A catch at the storage cap: also pay its normal Scrap?** The cap starts at 60 and grows with ship modules and the Storage Bay. At the cap a catch adds no record but counts for the Codex, quests and the board, and pays the tier's release Scrap (5 Common to 1,500 Cosmic).
- Options: a) keep: it also pays its normal catch Scrap, as now; b) release value only.
- Recommend: **a**, because the cap should not feel like a penalty for your most active players, and the cap rises with progress so the extra stays bounded.
- Then: b is one line in `Economy.grantAlien` plus a test; a closes the row in [[Decisions]].

**31. Refuse a Storage Bay purchase past the hard cap?** It cannot happen with Worlds 1 and 2 (the cap reaches at most 640 of the 1,500 hard cap).
- Options: a) refuse a Scrap purchase that would buy nothing; b) allow it.
- Recommend: **a**, as a guard for later worlds: a purchase that buys nothing is a bug.
- Then: one guard line and a test are added when World 3 is built; the row closes in [[Decisions]] now.

**32. The stray place 82258778278086: keep or delete?** "EDankashin's Place: 10072026_2", a leftover of an earlier publish; nothing in the game or the tools uses it (the id appears only in notes).
- Options: a) delete; b) keep.
- Recommend: **a**, because it is unused clutter in the universe's place list.
- Then: you delete it from the experience's Places list in the Creator Dashboard; the Board and [[Handoff]] rows close.

**33. The Mac's 2026-10-15 transcript?** It records a private matter of yours outside the game, so overnight job 31 holds it back; the collaborator will read the vault ([[Transcripts]]).
- Options: a) export it as it is; b) export it with that passage cut (you say which); c) skip the day.
- Recommend: **b**, because the record stays and the private part goes.
- Then: the Mac runs `tools/export_transcript.py --session "Mac session"` after the cut, lints and commits; c ends job 31.

**34. Allow tiktok.com for the coordinator?** Allow `tiktok.com`, `tiktokcdn.com` and `tiktokcdn-us.com` in this cloud environment: the environment menu in the session's title bar, Edit, Network access, Allowed domains, leaving "Allow package managers" ticked (2 minutes). Asked 2026-10-04, suggested 2026-10-07 and 2026-10-14, never applied; today every link waits for the Mac.
- Options: a) allow; b) no.
- Recommend: **a**, because it ends the hours of waiting per batch of links. Without it nothing breaks.
- Then: the next batch is fetched, processed and noted by the coordinator itself; the Mac's yt-dlp stays as the fallback.

**35. The launch date?** B27: no date until the creatures read as seamless, complete characters and the UI meets the top games' bar. The Experience Questionnaire and Public are yours and come with the date.
- Options: a) name a date now; b) no date until both gates pass (the sheets approved and the new bodies in; the HUD, Aliens, Shop and reveal rebuilt and checked on a phone), then you set it.
- Recommend: **b**, because a date set before the gates pass is the one you just withdrew.
- Then: when you name it, item 36 runs and the launch morning (about 20 minutes of yours: phone join, store page, questionnaire, Public) is scheduled from [[STORE-PAGE]] section 5.

**36. Re-date the launch-week tables?** Four tables carry the old plan: `src/shared/data/Overlays.luau` `LaunchWindow` (LaunchGold, 2026-10-16 to 10-26), `Codes.luau` `LAUNCHWEEK` (to 10-31), `Weekly.luau` `Overrides` ["2026-10-16"] (the Sparkfox week) and `Seasons.luau` `HauntedNebula` (2026-10-16 16:00 UTC to 10-30); the store text ("until Oct 31") follows.
- Options: a) one change on the day the date is set: all four move, the event with the launch; b) move the three launch-week tables and leave Haunted Nebula on its Halloween dates; c) re-date now to placeholders.
- Recommend: **a**, because the event is the launch week's draw ([[STORE-PAGE]] 5 lists it on Events) and one edit beats two; until then the windows pass in the private build, where only the team can see them.
- Then: a worker edits the tables with `lint_data.py` and `./tools/analyze.sh` clean; TESTING "Launch week" re-checks by editing data (there is no clock command).

## Added 2026-10-16: the design pass

**37. Design pass batch 2, the rarer bodies: take, fix or redo?** Eight Rare to Legendary species rebuilt fiercer or grander as prototype recipes, one sheet with the old body, three views of the new one and the black shapes (`media/studio/2026-10-15/design_pass_2.jpg`; [[Design-Pass]] "Batch 2"). Nothing under `assets/models/` changed.
- Options: a) the builder's verdicts: take Voltus (`Thunderhog`), Sabrek (`Frostfang`), Boulden (`Rocklobber`), Blinkar (`Reindazzle`) and Gaira (`Gaiabloom`); fix Iridia (`Gloomoth`, the wings) and Skadra (`Skaddle`, the body); redo Aurelyx (`Shimmerlynx`, the pose); b) your own letters per species (take, fix, redo); c) later, after Fenrir by hand (item 11).
- Recommend: **a**, with one change: the three "cool" bodies (Iridia, Aurelyx, Blinkar) are elegant, not fierce, so give them a bite (mandibles, a snarl, a heavier brow) in the fix, per your "the majority of rarer aliens should be fiercer".
- Then: the takes wait on the hand route of item 11 for their final finish (the recipe route reads as parts at close range); three concept lines change in `Species.luau` with a take (Voltus hedgehog to storm boar, Sabrek cub to sabre-tooth cat, Skadra owl to skating hunter).

**38. Triangle band per tier?** The sculpt builds every body at about 2,400 triangles; the ladder in [[Roster-Redesign]] gives Common 1,000 to 1,400, Rare 1,400 to 1,900, Epic 1,700 to 2,200 and Legendary 2,000 to 2,500. A test build at 1,800 kept the shapes and faces and only made the outline slightly more angular ([[Design-Pass]] "Triangle bands per tier").
- Options: a) build to the ladder's bands (a visible step up in detail with rank); b) every species at about 2,400; c) Commons at about 1,600, the rest at 2,400.
- Recommend: **a**, because the ladder is how rank shows in the model itself, and fewer triangles on the many Commons keeps a full server light on phones. The rank-ladder sheet of all 31 redesigns (`media/studio/2026-10-16/rank_ladder.jpg`) shows one more gap: the top tiers are no taller than the Epics (Raddis 3.6 and Syrinx 3.4 studs against Gaira 4.2 and Aurelyx 3.8), while in the reference games the rarest pet is also the biggest on screen. A height step per tier could ride with this answer.
- Then: the recipes get a per-tier `tris` default and the sheets are rebuilt at their band.

**39. Design pass batch 3, the top of the ladder: take, fix or redo?** Raddis (Cosmic) and Syrinx (Secret), the grandest bodies so far, plus Zirrit, Vixa, Floe, Snibble, Pebblet and Eekle (`media/studio/2026-10-16/design_pass_3.jpg`; [[Design-Pass]] "batch 3"). All eight pass the three style checks.
- Options: a) the builder's verdicts: take Syrinx, Vixa, Floe, Snibble, Pebblet and Eekle; fix Raddis (the sun disc hides behind the head, the wings read as palm fronds) and Zirrit (paddle wings, a two-ball body); b) your own letters per species; c) later.
- Recommend: **a**. The two fixes are already being built, with the batch 2 fixes (Iridia, Skadra, Aurelyx, a bite for Blinkar) on one before-and-after sheet ([[Design-Fixes]], `media/studio/2026-10-16/design_fixes.jpg`).
- Then: same as item 37: nothing changes under `assets/models/` until you say yes to a sheet.

**40. Design pass batch 4, the cute end: take, fix or redo?** Buzzik, Lantrin, Twiglo, Soakum, Sizz, Flurra and Digling, all Common or Uncommon (`media/studio/2026-10-16/design_pass_4.jpg`; [[Design-Pass]] "batch 4"). With it, 31 of 35 species have a redesign; only the hero Fenrir and the three event species do not. All seven pass the three style checks.
- Options: a) the builder's verdicts: take six, fix Twiglo (from the front it is a ball on spider legs); b) your own letters per species; c) later.
- Recommend: **a**.
- Then: same as item 37: nothing changes under `assets/models/` until you say yes to a sheet.

## Closed or parked, no answer needed

- **Names v3** is applied (B40, c4ed088): the Board row "Names v3" and item 1 of the owe-list in [[Asks-Ledger]] are out of date.
- **The weekend launch** is off (B27); the dashboard, the group, the clips and the questionnaire wait on items 25 and 35.
- **Screen Recording for Terminal**: the three store clips exist (af32f93, b5267fd), so that Board row can be struck.
- **Slot growth** (decision 16, B10) and **world signatures** (decision 21, proposed yes; Worlds 3 and up are not built): the built defaults stand unless you object.
- **Voxel look** (skill 1 of the design reference): a prototype, no decision until you see it. **Nano Banana, Higgsfield and an image-model account** are candidates for icons v2, no decision until it starts ([[Tools-Status]]).
- Cloud-side rows (the lighting probe, the HUD rebuild, StyLua) have no question for you.

## Answer sheet

Paste this back with your letters (a bare letter is enough; `*` marks the recommendation). Money items 22 to 28 need their own letter.

```
1: a* quit Studio now | b keep one window | c later
2: a* macOS app | b browser build | c later
3: a* CLI and plugin | b CLI only | c later
4: a* Roblox and GitHub | b GitHub only | c later
5: a* join tonight | b later
6: a* listen and swap | b ship blind | c later
7: a Mossbop v2 | b Sparkfox v2 | c Thunderhog v2 | d* icon_v3 | use yours
8: order of a Moment, b Reward, c Mystery (* a b c), d event on Events only | use yours
9: a* yes | b yes with changes | c no
10: a* confirm | b stricter | c looser
11: a* Blender by hand | b Blockbench | c Tripo trial
12: a* hybrid fuse | b keep recipe bodies | c mixed | use yours
13: a pick per screen | b* use yours | c later
14: a* bun and claude-mem trial | b drop claude-mem | c later
15: a* yes, trial | b no | c later
16: a* yes | b no
17: a* yes | b no | c later
18: a* yes | b no | c later
19: a yes | b no | c* later
20: a* yes, after 3 | b no | c later
21: a all three and path rules | b* all three | c amend | d no
22: a* trial first | b Steam | c Adobe | d not now
23: a* yes, cap $15 | b no
24: a* API key for overnight, capped | b accept the resets
25: a* yes to the spend, run at the date | b create now | c ask at the date
26: a* all three vendors, one species | b Tripo only | c none
27: a* done | b later
28: a* free only | b buy up to a cap | c per plugin
29: a* yes, flag off | b never | c after launch
30: a* pay both | b release value only
31: a* refuse | b allow
32: a* delete | b keep
33: a as is | b* cut the passage | c skip
34: a* allow | b no
35: a name a date | b* none until both gates pass
36: a* all four tables | b three only | c placeholders now
37: a* builder's verdicts plus a bite for the cool three | b per species | c later
38: a* ladder bands | b all 2,400 | c Commons 1,600
39: a* builder's verdicts, fixes already running | b per species | c later
40: a* take six, fix Twiglo | b per species | c later
```
