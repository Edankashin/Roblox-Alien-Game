---
tags: [start-here, playtest, how-to]
aliases: [Playtest brief, Tester brief]
up: "[[Start-Here]]"
---
# Playtest brief: what testers see, what to send them, what to ask

Written 2026-11-04 on the Mac for Ethan ("set up the game so that I can have people play test it"). The release for playtesting is [[Decisions]] B58. `tools/release.py` is written and tested, but the Open Cloud key on the Mac has no `universe:write` or `universe.place:write` scope (every write answered 403 on 2026-11-04), and a session's auto-mode guard refuses to open a public surface itself anyway. Ethan added the two write scopes to the key the same evening ([[Launch-Steps]] step 2, 3b) and `--prepare` set the store name, the description, 8 players a server and VR off; the public switch through Open Cloud did not take (2026-11-04: Roblox answered 200 to `visibility: PUBLIC` and the universe stayed PRIVATE on three reads), so the switch is the dashboard's Public tab (Creator Hub > the experience > Publish settings > Manage access). The icon and thumbnails are still Ethan's uploads on the dashboard ([[Launch-Steps]] step 6), so until then the page shows Roblox's grey placeholder.

## What a tester sees on Roblox

- **Name:** Catch an Alien. **Link:** https://www.roblox.com/games/93842567264184
- **Description** (the store blurb, one home: `docs/STORE-PAGE.md` section 2): "You crash-landed on a strange planet built of little blocks. Cute aliens are everywhere! Catch them with a quick timing bar, put them to work at your camp, and watch your ship come together piece by piece. Fill the ship bar, launch, and land on World 2, Frostbyte." Then the seven bullets (35 aliens Common to Secret, rarer means more special eyes and effects, the Starhollow Forest, offline earnings, Meteor Showers and the Peddler, fusion and companions, the home planet) and the line "One thumb, no stress, nothing you did is ever wasted."
- **Rating 13+** (the questionnaire's answer as it stands). An account under 13, or one whose content-maturity setting excludes 13+ experiences, is bounced to the Roblox home screen with no message (the 2026-11-01 phone bounce, [[2026-11-01]] job 79). Devices: computer, phone, tablet. 8 players per server (`Config.MaxPlayers`).
- **Shop prices are real Robux.** Fifteen items are for sale; nothing hands out Scrap for Robux. The LAUNCHWEEK code expired 2026-10-31.

## The message to send a tester (copy as is)

> I'm playtesting my Roblox game, **Catch an Alien**. You crash-land on a planet made of little blocks, catch cute aliens with a timing bar, and they build your ship so you can fly to the next world.
>
> Link: https://www.roblox.com/games/93842567264184 (phone, tablet or computer; your Roblox account needs to be 13+).
>
> Play for 10 to 15 minutes without asking me anything. Catch a few aliens, open the Aliens and Shop screens, walk into the forest, and try to fill the ship bar.
>
> Then tell me in plain words: where you were confused in the first five minutes, where you waited, what you wanted to tap, what felt slow or ugly, and whether you would come back tomorrow. A screenshot of anything wrong helps.

## What we are trying to learn

1. **The first five minutes.** Do the staged tutorial hints get them to the first catch with no help? Where do they stall?
2. **The catch.** Is the timing bar readable on a phone, and does a Rare feel harder than a Common without feeling unfair?
3. **The reveal and the tiers.** Does each tier read as rarer than the one below (eyes, glow, the card)?
4. **The HUD on a phone.** Every button tappable, nothing under the notch, the radar scroll understood?
5. **The loop.** Do they understand the ship bar, the camp earning while away, and what to do next?
6. **Money.** Never ask. Note whether they open the Shop on their own and what they look at.
7. **The join.** Any bounce to the home screen on a phone: which account, which device.

## Where the notes go

One note per tester in `docs/playtests/<date>-<name>.md`: device, minutes played, what they said as they said it, what we saw, then the three things to fix first. Link it from the day's log in `docs/vault/08-log/`. The first cold playtest row is on [[Board]] ("Cold playtest of World 1 from a fresh profile").

## Known rough edges (say nothing; watch whether a tester notices)

- World cards on the Star Chart keep their diorama instead of the picture (the transparent-label bug, [[2026-11-01]] job 78).
- A bright plate on the ground under Cosmic and Legendary aliens (the Feet and Aura sizes in the Effects data, job 78).
- Syrinx's eclipse is lost against its body (deferred to the Rare second pass).
- Five shop items are hidden on purpose (their features do not exist yet).

## Opening it and closing it

Dashboard: Creator Hub > the experience > Publish settings > Manage access > the Public tab (on opens it to everyone on Roblox, or to friends with the Friends switch; off closes it, and Roblox removes every player at once). `tools/release.py --public` and `--private` send the same change through Open Cloud, but on 2026-11-04 Roblox accepted the request and left the switch where it was, so until a run shows otherwise the dashboard is the switch; the tool still sets the name, description, server size and VR, and prints Roblox's answer. To let only friends in, the dashboard's Friends switch (Creator Hub > the experience > Publish settings > Manage access > Public > Friends) narrows a public experience without touching the API.
