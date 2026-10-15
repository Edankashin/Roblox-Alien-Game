---
tags: [start-here, hot]
aliases: [Now, Hot note]
up: "[[Start-Here]]"
---
# Now

The hot note: read this first on every start, then the notes it points to. Keep it under 500 words and rewrite it when the state changes (newest truth only; history belongs in the log). Last updated 2026-10-15.

**The game.** Catch an Alien (working title AlienGame in code): crash-land on a planet, catch cute aliens with a timing-bar minigame, they work at camp and build a ship, the ship flies to the next themed world. One currency, Scrap, never sold for Robux. Luau strict, Rojo, server authority; Ethan, a collaborator and Claude sessions.

**State today (2026-10-15).** The weekend launch is off. Ethan: "I'm not satisfied with launching the game right now given the designs and UI of the game." No new date. The 32 surfaced bodies stay un-uploaded, the private build stays (v90, v5, v4), and the dashboard, group page and clips wait. The LaunchGold window in [[Decisions]] B21 is dated to the old plan.

**The bar.** Creatures: "seamless, fluid, complete, not shapes mashed together", with the goofy eyes and open mouth kept. UI: one token system (thick outlines, Fredoka One, gloss, standard rarity colours) that passes the phone rules. The seven decisions of this turn are [[Decisions]] B27 to B33.

**Three open threads.**
1. **Creatures.** One connected skin per species by the hybrid fuse: a fused core plus crisp features. Next prototype: Moop, Sparkfox, Mitt. Nothing replaces a model until Ethan says yes. [[Character-Pipeline]], [[Sculpt-Pass]].
2. **UI.** The Claude Design canvas holds the HUD, Aliens, Shop and the reveal in three beats. Ethan picks a board, a worker rebuilds it in Luau, the Playbook changes in the same commit. [[UI-Playbook]] ("Phone rules from the design research"), [[Claude-Design-Brief]].
3. **Vault connection.** Hooks and the Obsidian Local REST API plugin with the CLI are proposals for Ethan to apply on the Mac; the Mac then verifies. [[Setup-and-Tips]], [[Tools-Status]].

**Roles.** The Mac session owns Studio, Blender and Obsidian on Ethan's 8 GB MacBook (one Studio at a time; Obsidian closed on overnight runs). Cloud sessions (the coordinator and the build workers) own the repo work: code, data, the vault, headless `bpy`, research. They have no Studio and no Obsidian. Git is the sync channel: claim a row on [[Board]] before you work, log under your own heading in `docs/vault/08-log/`.

**Rules that bite.**
- Sessions never write their own Claude settings or permission rules. A change to `.claude/settings.json` is a proposal for Ethan.
- The Open Cloud key lives only in the Mac shell. No key, token or secret in the vault, the log or a chat.
- Git is the only memory the team shares. A session's auto memory is personal scratch; a decision counts when it is in [[Decisions]].
- One system per change; numbers in `src/shared/data`, strings in `src/shared/strings`, Scale never Offset.

**Read next.** [[Handoff]] (the whole project), [[Board]] (who does what), [[Launch-Dashboard]] (the state on one screen), [[UI-Playbook]], [[Character-Pipeline]], [[Transcripts]] (the coordinator's chat with Ethan, one note per day).
