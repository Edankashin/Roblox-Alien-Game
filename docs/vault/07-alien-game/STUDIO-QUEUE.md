---
tags: [alien-game, reference, plan, generated]
aliases: [Studio run queue, STUDIO-QUEUE.md]
up: "[[Alien-Game]]"
---
# STUDIO-QUEUE (pointer)

The document itself is [`docs/STUDIO-QUEUE.md`](../../STUDIO-QUEUE.md), outside the vault, so Obsidian cannot open it; this note keeps the `[[STUDIO-QUEUE]]` links in the vault working. It is the run queue of the Studio checks still pending, generated from the milestone statuses in [`docs/PRE_PRODUCTION.md`](../../PRE_PRODUCTION.md) section 5b and the steps in [[TESTING]] (regenerate with `python3 -I tools/studio_queue.py --write`; `tools/lint.sh` checks it is current). It orders the work so the place-only blocks come first, then multiplayer, persistence and published-server checks, and the Mac session does them in that order ([[Board]] lists the rows).
