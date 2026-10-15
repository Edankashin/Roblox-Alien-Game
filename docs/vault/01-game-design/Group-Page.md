---
tags: [game-design, research, launch]
aliases: [Moop Games, Roblox group]
up: "[[Game-Design]]"
---
# Group page: name, emblem, description, ranks, and who owns the game

Researched and drafted 2026-10-14 for Ethan, who creates the Roblox group this week (decision 16, [[Decisions]]; the Board row "A Roblox group co-owned by both" in [[Board]]). The game already pays a group-join gift once `Social.GroupId` is set (`src/shared/data/Social.luau`), so the group is the one thing standing between the gift and the players.

**Evidence tiers** (as in [[Growth-Playbook]]): **doc** = Roblox's own Creator Docs or Help Center, read directly or quoted by a search result; **forum** = DevForum threads and staff replies; **wiki** = Fandom or the games' own wikis; **unverified** = one low-quality source, or not retrievable. roblox.com and create.roblox.com are blocked from the research environment, so no group page could be opened: every group description, rank list and emblem below that says "not retrievable" is a gap, not a finding. Member counts come from wiki snapshots and are stale by months.

## 1. What the top games' groups do

| Game | Group name | Owns the game? | Join perk | Emblem, description, ranks |
|---|---|---|---|---|
| Adopt Me! | **Uplift Games** (renamed from DreamCraft in 2021; founders NewFissy and Bethink; about 14.2M members, verified) [wiki] | Yes: Uplift Games "develops and publishes" it [wiki] | None found (rewards come through codes and events) | Not retrievable. Only the "UGC" role of the official UGC account is mentioned |
| Pet Simulator 99 | **BIG Games** (about 11.3M) and **BIG Games Pets** (about 27.7M, the PS99 line); plus **BIG Games Experimental** (about 2.8M, test builds) [wiki] | The Pets group publishes it [wiki] | Like the game and join both groups, stand in the Group Rewards area of the plaza, claim every 24 h [forum/guide, 2023]; 2026 guides say Auto-Hatch, hatch-speed boosts and a Group Reward Chest [unverified] | Not retrievable. Studio plus product-line plus test groups: three groups for one studio |
| Grow a Garden | Developer credits: BMWLux, Jandel, Jhailatte; publishers Splitting Point Studios and Do Big Studios [wiki]; the group page was not found | Publisher groups | None found; guides call the group a place for update and code news. (The "Green Bean team" event was an in-game NPC, not a group join) | Not retrievable |
| Steal a Brainrot | **Brazilian Spyder** (SpyderSammy's group) [wiki/tracker]; Do Big Studios listed as owner on Wikipedia | Group-published | One source says "$10M for joining the group" but it describes a modded copy [unverified] | Not retrievable |
| Fisch | **Fisching** (formerly "The Fisch Studio", created Aug 2020 by WoozyNate; about 5.9M) [wiki] | Yes, since 2024-11-04 (Do Big Studios era), handed back 2025-08-21 [wiki] | **A free chest**: a "Join the group to claim your chest" button below the code box in the menu; later round-ups say "Like and Join the Group to Claim" [guides; amounts unverified] | Not retrievable |
| Small cute-collection games under 10k members | **Not found.** Neither Steal An Egg (group "And Collect Rare Pets", the UI reference of decision 14) nor Pet Catchers (Rumble Studios) could be sized from here, and both are probably above 10k | | | Left open: Ethan can open three or four small cute collectors in the app and screenshot their group pages (emblem, first line, ranks) in five minutes |

**What the table says, plainly:**

- **Adopt Me, Pet Simulator 99 and Steal a Brainrot sit under studio-named groups**, and Grow a Garden's credits are studios too (its own group page was not found); Fisching is the exception, the old studio name with the game's word in it. Studios then add games under one name (BIG runs three groups for one studio).
- **The join perk is a chest or a boost, claimed in the game's own UI**, which is what `Social.GroupReward` does on the Gifts screen. None of them ties the perk to a like (rewarding ratings is treated as prohibited; [[Growth-Playbook]] section 3).
- **Rank names, emblem styles and description shapes of the big groups could not be read.** The design below is therefore the game's own voice plus Roblox's documented limits, not a copy of anyone's page.

## 2. Roblox's current facts (checked 2026-10-14)

| Question | Answer | Tier |
|---|---|---|
| Cost to create | **100 Robux**, one time. The Help Center now says "Community" (renamed late 2024; the URL is `roblox.com/communities/<id>/<name>`); Creator Hub still says Groups | doc |
| Rename later | 100 Robux; owner needs a verified email; not within 90 days of the last name change or of an ownership change; the old name is recycled after 90 days; members get a message. So the name is not a one-way door, but it can only change once per quarter | doc |
| Emblem size and format | The group docs only say "upload an image for the group logo": no size or format is stated. The experience-icon page recommends a **512x512 square** (at least 512) and warns icons are shown down to about 150x150; images pass moderation first. DevForum answers say 256x256 minimum for a group icon, larger is rescaled. So **512x512 PNG** is safe | doc, forum |
| Description limit | The Help Center gives no number. DevForum threads give **1,000 characters** (some users hit errors near 980); the shout is **255**. We stay under 700 and 255 | forum |
| Social links | Up to **three**, added on the group profile page after creation | doc |
| Owners | A group has **one Owner**. "Co-owned" (decision 16) is one Owner plus a second member whose role has every permission | doc |
| Move an experience from a user to a group | Yes: Creator Hub, Creations, the experience, Configure, Settings, **Initiate ownership transfer**; the group accepts. Needs a verified email and publish rights in the group. Once accepted, **the experience goes private and all its servers close**; make it public again afterwards. It usually takes minutes, and discovery can be affected for up to 24 hours after it is public again. Existing Open Cloud keys are not affected when moving from a user to a group you own. Group-to-user is not offered | doc, staff reply |
| What the transfer needs from you | **Private assets used through InsertService must be owned by the group**, private ModuleScripts uploaded to it, user-owned packages recreated, animations published to the group | doc |
| What it does to stats, passes, badges | Staff say visits and statistics are not affected and discovery should hold if the title is unchanged. Whether passes and badges move is **disputed**: some replies say they persist, a 2024 reply says only the passes that go with the experience move, others say recreate them. Nothing official found | forum, disputed |
| Selling passes from a group experience | No extra gate beyond owning the experience and having a role that manages monetization (the Universe Monetization Manager permission). The Robux lands in **group funds**, not in a person's balance | doc |
| Getting funds to a person | Finances, Payouts: a one-time payout or a recurring **percentage split** (the Revenue Manager permission), plus a per-experience split in Creator Hub (2024). Paid-access games in local currency cannot be split. Reported limits: a new member waits **14 days** before a payout (3 days for verified groups until August 2025, back to 14 since), the group itself must be a few weeks old (reports say 3 to 4), and a flagged payout can sit pending up to 10 days | doc and forum |

## 3. The design

### 3.1 Name

| | Group name | Fits | Notes |
|---|---|---|---|
| A | **Crash Planet** | The leading game name, "Crash Planet: Catch Aliens" | Short, searchable, reads as the game's home; dies with the name if decision 19 flips |
| B | **Alien Pals** | The alternate "Alien Pals: Build a Rocket" | Generic words; most likely to collide with an existing group |
| C | **Planet Hoppers** | The alternate "Planet Hoppers: Alien Collector" | Distinct, but the ship-hopping promise is the second half of the game |
| S | **Moop Games** | Any game name (a studio-style name that can hold later games) | Moop (species id Mossbop, renamed in the second naming pass) is the first alien, the icon and the loading screen; backups if it is taken: Wreckplate Games, Scrap Orbit Games |

**Recommendation: S, Moop Games (Ethan's choice, 2026-10-14).** Reasons: decision 19 is still open and a studio name survives any answer; three of the five big games publish under a studio name and a fourth is a studio-plus-game hybrid; when the experience moves into the group the group's name becomes the byline on the game page, and "Crash Planet: Catch Aliens by Moop Games" reads like "Adopt Me! by Uplift Games"; and players reach the group from the in-game button, so nobody has to search for it. Cost of being wrong: 100 Robux and a 90-day wait. If Ethan prefers one name for everything, A is the second choice; the emblem tool takes the banner text as an argument (`python3 -I tools/group_emblem.py "CRASH PLANET"`). Group names are unique, so check availability on the create page; Roblox may reject names it dislikes.

### 3.2 Description (paste as is; 619 characters)

```
Moop Games makes Crash Planet: Catch Aliens, a cozy alien-collecting game for Roblox.

Crash-land on a strange planet, catch cute aliens with a quick timing bar, and let them build your ship to the next world.

JOIN PERK: join us, then open Gifts in the game and tap Group gift for 500 Scrap, 3 x Twig Lure and 2 free spins.
LAUNCH CODE: type LAUNCHWEEK under Promo code for 300 Scrap and a Lucky Charm (Oct 16 to Oct 31).

Rules
1. Be kind. Everyone here is welcome.
2. No begging, scams or trading offers. We never ask for your password.
3. Keep the wall on topic: aliens, ideas, screenshots.

Discord: [DISCORD LINK]
```

- The perk line is the in-game text: the Gifts screen shows "Group members get 500 Scrap, 3 x Twig Lure, 2 free spins" (`SOCIAL_GROUP_LINE`, `REWARD_scrap`, `REWARD_lure`, `REWARD_spin`) from `Social.GroupReward`. If the reward in `Social.luau` changes, change this line in the same commit.
- The code line mirrors `Codes.luau` `LAUNCHWEEK` (300 Scrap and a Lucky Charm, 2026-10-16 00:00 to 2026-10-31 23:59:59 UTC). Delete the line on 1 November.
- If the group takes the game's name (A), the first line becomes: `The official home of Crash Planet: Catch Aliens, a cozy alien-collecting game for Roblox.`
- No line rewards a like or a favorite, and none asks for one.
- Put the Discord invite in the first of the three social links as well; drop the `Discord:` line while there is no server (the Board recommends the server later).

### 3.3 Ranks (the game's voice: short, a little dramatic, "Mayday! We're going down!")

| Rank number | Name | Who | Notes |
|---|---|---|---|
| 0 | Guest | Roblox's default | Cannot be renamed |
| 1 | **Stowaway** | Everyone who joins from 1 November | Create it then, not before (see Crash Crew). Every role counts for the gift: `IsInGroupAsync` only asks "is the player in the group" |
| 10 | **Crash Crew** | Early players: everyone who joined during launch week (2026-10-16 to 10-31, the LAUNCHWEEK code's window) | Roblox puts a new member in the lowest role, so at launch create Crash Crew first and no Stowaway; on 1 November add Stowaway below it and new joiners land there (check that on the day; it is one settings page). A permanent "I was here first" badge |
| 50 | **Alien Wrangler** | Helpers, bug finders, creators and friends we want to thank | Optional; no permissions |
| 100 | **Ship Mechanic** | Moderators | Delete wall posts and forum threads, kick; no funds, no role changes |
| 250 | **Co-Captain** | The second owner (the collaborator) | Every permission, so decision 16's "co-owned" holds |
| 255 | **Captain** | Ethan, the one Roblox Owner | Turn on two-step verification first: a lost Owner account is a lost group |

### 3.4 Emblem

**Spec:** 512x512 PNG, square, under 1 MB, nothing important within 20 px of the edge (Roblox may round the corners). Navy `1B1F3B` (`Theme.Colors.Outline`) ground, cream `FFF4DC` (`Panel`) ring about 22 px thick, gold `FFC83D` (`Featured`) banner with a navy outline, name in Fredoka One, cream with a navy outline about 8 px thick. The name must be readable in a 150x150 preview: at that size the banner text is about 20 px tall and held.

**Built:** `media/group/emblem_v1.png` from `tools/group_emblem.py` (cropped from `media/store/2026-10-14/icon_Mossbop_v2.png`, the same face as the store icon, so the group and the tile look related). Banner, not arc text: arc text fell apart at 150x150. Redrawn on 2026-10-14 with the banner MOOP (`python3 -I tools/group_emblem.py "MOOP"`, now the tool's default); it still reads at 150x150.

Three concepts:

1. **Face and banner (v1, built):** the Moop in a cream ring over a gold banner reading MOOP, on navy. Closest to the icon, strongest at small size.
2. **Wordmark (if the group takes the game's name):** CRASH PLANET stacked on two lines in cream with a navy outline, a tiny Moop riding the A, a meteor streak behind; text first, for the day the face is not enough.
3. **Crew line-up:** Moop, Sparkfox and Thunderhog heads in a row over the ship wreck's silhouette, no text (Roblox prints the group name beside the emblem). More "studio", busier at 150x150, needs a new render.

### 3.5 First shout (205 characters; the launch post, pinned on the group page)

```
Crash Planet: Catch Aliens is open! Code LAUNCHWEEK = 300 Scrap + a Lucky Charm until Oct 31. Join us, then claim your Group gift in game: 500 Scrap, 3 Twig Lures, 2 free spins. Catch a Moop and say hi!
```

## 4. Decide before launch

1. **Who owns the experience.** The Board says user ownership for launch. The facts above agree:
   - **The transfer closes every server and sets the game private**, then discovery can wobble for up to 24 hours. The launch week and Haunted Nebula run 2026-10-16 to 10-30; do not transfer inside them. A planned window after 2026-10-30 16:00 UTC, with a Discord or wall notice, is the earliest sensible time.
   - **The 53 model assets belong to Ethan's account** and load at runtime through InsertService. A group-owned experience cannot load them until they are re-uploaded under the group (`tools/upload_assets.py` with `ROBLOX_CREATOR_GROUP_ID`, then the new ids in `ModelAssets`). Skipping this blanks every alien for everyone ([[Handoff]] 13.1).
   - **Passes and badges are the disputed part.** Test first: make a throwaway experience with one pass and one badge, transfer it to the new group, and look. Then check the six live shop ids after the real transfer.
   - **Revenue lands in group funds** and reaches a person only through a payout or a recurring split (14-day new-member wait, group-age limit). While the game is user-owned, passes pay Ethan directly. Set the recurring split on day one of the move.
   - **Collaboration gets easier, not required:** a group role replaces "Roblox friends only" Edit access, and a group member can mint an experience-scoped Open Cloud key. Today's Collaborate setup works, so there is no pressure.
2. **Create the group now, leave the game where it is.** `Social.GroupId` only needs the group to exist: `Player:IsInGroupAsync` works for a user-owned game. The one cost is that the group's Experiences tab is empty until the move; the description and the shout carry the link.
3. **The name** (3.1): Moop Games (Ethan's choice, 2026-10-14), check it is free, 100 Robux. Moop is also on the trademark-search list in [[Species-Names]].
4. **Discord:** later, as the Board says; the description has a placeholder and one social-link slot ready.
5. **Ethan sends back the group id** (the number in `roblox.com/communities/<id>/<name>`) so a worker sets `Social.GroupId` and runs `./tools/analyze.sh`, `./tools/test.sh` and `./tools/lint.sh`.

## Sources

- Creator Docs, Groups: `create.roblox.com/docs/projects/groups` (100 Robux, up to three social links, roles, payouts, group funds; read through the docs mirror). Experience ownership transfer: `create.roblox.com/docs/projects/experience-ownership-transfer` (as quoted by a search result; the mirror file was not found). Icons: `create.roblox.com/docs/production/publishing/experience-icons` (512x512, about 150x150).
- Help Center: "Group Name Change" (100 Robux, 90 days) and "How to Create a Community".
- DevForum: "Does experience ownership transfer, transfer other things?" (3858493), "Transfer Experiences to Groups and Track Group Activity" (3299360), "Manage Group revenue in Creator Hub and split profit per experience" (3059259), "Verified group no longer eligible for 3-day payout wait time" (4065307), group description and shout limits (702254, 486363), "Introducing Roblox Communities" (3268307).
- Wikis and guides: Fandom pages for Uplift Games, BIG Games, BIG Games Pets, BIG Games Experimental; the official Fisch wiki (fischipedia.org, Fisching); Wikipedia for Adopt Me!, Grow a Garden and Steal a Brainrot; PCGamesN's Pet Simulator 99 group-reward steps.
