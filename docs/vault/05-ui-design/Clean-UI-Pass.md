---
tags: [ui-design, ui, spec, clean-ui]
aliases: [Clean UI pass, Declutter pass]
up: "[[UI-Playbook]]"
---
# Clean UI pass (spec, 2026-10-22)

Ethan, 2026-10-22: "make the ui and ux cleaner as in not everything is so cluttered and it is visually pleasing along with easy to navigate around and pickup on everything in the game quickly. The viewer shouldn't be overstimulated by everything. Refer back to the tik toks I sent you in the past about UI and also do your own research based on popular roblox games and other sources." Earlier the same day: the screen is "so clustered", which became the Menu drop-down ([[Decisions]] B53). This note is the spec three workers build from in parallel. It changes no decision: B44 and B46 (block cells), B51 (shop answers), B52 (the radar column), B53 (Shop, gold Starter Pack beside it, Menu drop-down) all stand. The look rules stay in [[UI-Playbook]]; each package writes its new rules into the Playbook section named in its brief. A Decisions row (B54, "Clean UI pass") is the coordinator's once Ethan approves this note.

Wireframe of the HUD at rest after the pass: `media/studio/2026-10-22/clean_hud_wireframe.png` (16:9; solid boxes always on, dashed boxes contextual).

## What the screenshots show (2026-10-22, before B53)

Read from `store-3-starhollow-night-game.png`, `r4-6-default.png`, `night-starhollow-path-default.png`, `night-lake-default.png`, `fixes-plates-default.png`, `spectacle-cosmic-arrival-default.png`, `fixes-slots-cards-default.png`, `shop-b51-2-chip-ship-default.png`, `second-codex-default.png`, `shop-b51-0-featured-default.png`.

1. **The loudest thing on screen is the tutorial hint.** A gold plate half the screen wide at 0.79 of the height ("Collect 3 wreck plates for the hull. 0/3", `UI/TutorialHint.luau`, `WIDTH` 0.5, `BOTTOM` 0.79) sits on the player's avatar in every world shot. It is the right message in the wrong weight.
2. **The centre column is a stack of four.** Compass strip, compass line ("Cave 113m"), ship bar ("Ship 0%"), luck line ("Luck x2.0") or the event banner ("Haunted Nebula, 8d 0h left, Spectral"), Friend Boost chip ("+0%", now hidden by B53). A week-long event sits in a banner on the eye line for the whole week.
3. **Two banners at once covered the sky** (Mac, `night-lake`, the 2026-10-22 log "Mac session, fourth run"): `Toast.Banner` shares the toast stack (`MAX_VISIBLE` 3), so a Warden sighting banner and a Catch Rush banner drew together, 0.7 of the width each, while the centre event banner and the "Rush in 19s" chip were also up. Four things said "event" at once.
4. **The top-right is three chips** (time and weather, biome, event countdown) over the radar, and after B53 still three chips.
5. **World labels pile up.** Every wild alien within 60 studs wears "Name / Tier", every node its name and condition ("Storm Shard / Only at rain"), plus "!" bubbles; in `r4-6` two "Wispkin Rare" plates, "Wreck Plate" and "Star..." overlap the camp. The Cosmic and Legendary beacons (`data/Spectacle`, 0.35 transparent, 0.6 to 0.9 studs wide, 70 to 110 tall) wash the middle of the screen white when the player stands near them (`fixes-plates`, `spectacle-cosmic-arrival`).
6. **Panels keep the whole HUD around them.** The Ship and Aliens panels open over a screen that still shows the left column, the Scrap pill, the ship bar, three chips and the radar (`shop-b51-2-chip-ship`), so a panel is never the one focal point. Inside, the cream panel face's grout and jitter read as graph paper behind the text; the Ship panel prints "Finish the module above first" four times; the Codex opens with a third of its width an empty white box ("Tap an alien to read about it").
7. **Join-time bursts.** A returning player gets `OFFLINE_TITLE`, `OFFLINE_BODY`, one `OFFLINE_MODULES` per module, `OFFLINE_GREW` and one `TOAST_ALIEN_GREW` per grown alien: up to six or more toasts in the first seconds, each with a ding (`src/client/init.client.luau` lines about 1100 to 1120).
8. **Every catch is a full-screen ceremony.** A repeat Common catch runs beat 2 and the card with "Tap anywhere to continue" (`UI/Reveal.luau`), every 30 seconds in the core loop.

## Principles (each one line, each with its source)

1. **The world and one prompt own the centre; the HUD lives on the edges.** Roblox: put "the most important information where players naturally look" ([Wireframe your layouts](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/wireframe-your-layouts)); pet-sim UI keeps elements "on the edges of the screen" ([pet sim UI notes](https://charismaliu.notion.site/UI-b2857ec703ac4713beb537fe3b963c4b)); Pokemon GO's map is "astonishingly plain and simple" ([Sakurai, Famitsu 515](https://sourcegaming.info/2016/11/24/the-aims-of-ui-sakurais-famitsu-column-vol-515/)).
2. **Show what the player is doing now first.** Roblox's "Hierarchy of Information": what is the player doing, what must they know, what choice is in front of them ([UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
3. **Three to five things always on; the rest appear when they become useful.** Progressive disclosure and contextual display ([Respawn, menus, HUDs and feedback](https://respawn.outlookindia.com/gaming/gaming-guides/ui-and-ux-in-games-building-menus-huds-and-feedback-systems); [Progressive disclosure](https://flyingbisons.com/knowledge-base/progressive-disclosure); the trend is "selectively surfaced, state-dependent" HUDs, [Bonn HUD study](https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207)).
4. **At its default, an element is gone, not dimmed.** B53's zero-lines rule, and Pokemon GO's nearby bar, which shows only silhouettes and opens its list on tap ([Five things UXers could learn from Pokemon Go](https://interactionlab.city.ac.uk/?p=847)).
5. **One goal at a time, always visible.** Roblox onboarding: a persistent hint until the step is done, "teach the essentials, get to the fun quickly" ([Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques)); machv10, "suck the player in within the first five minutes" (TikTok ZPLYSaBcg).
6. **Interrupt in proportion to importance.** A banner for what you can join now, a toast for your own results, nothing for the rest ([NN/g, indicators, validations and notifications](https://nngroup.com/articles/indicators-validations-notifications); matching attention draw to importance lowers annoyance, [Gluck et al., CHI 2007](https://www.interruptions.net/literature/Gluck-CHI07.pdf)).
7. **One banner at a time, never stacked, never over the sky for long.** The dino ranch's single event banner (TikTok ZPL8MtkYu, `refs/dino-event-banner.jpg`); the Mac's two-banner sky (night-lake, 2026-10-22).
8. **A colour means one thing.** Rarity colours only for rarity, a screen's colour for that screen, red for close, alert and "claim me", never colour alone ([UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) conventions; ZPLSQA4aX: colour is the category, the ribbon is the status).
9. **Motion is earned.** Spectacle scales with rarity; on the HUD at most one thing loops; every move has a Reduced Motion form (ZPLSQA4aX: "four small moves ... everything else is still").
10. **Copy the hits' layout, not their noise.** Left column, currency top-left, one prompt bottom-right, Scale only, the one offer in view (ZPLRwXx6J's Steal an Egg HUD; ZPLAB8GM3 "show it"; [Roblox best practices: 44 px targets, ScreenInsets](https://www.creation.dev/blog/roblox-ui-design-best-practices); [ScreenInsets](https://robloxapi.github.io/ref/enum/ScreenInsets.html)).

**What the popular games do (as far as the web says).** Grow a Garden puts its few travel buttons (Seeds, Garden, Sell) along the top and nothing else of weight on screen ([Sportskeeda, merchants](https://www.sportskeeda.com/roblox-news/all-merchants-in-grow-a-garden); [esports.gg, gear shop](https://esports.gg/news/roblox/where-to-find-the-gear-shop-in-grow-a-garden)); Steal a Brainrot keeps Rebirth on the left edge with a confirm at the bottom ([Beebom](https://beebom.com/steal-a-brainrot-rebirth-guide-levels-and-rewards/)); Fisch's catch is one bar with one progress strip along the bottom ([Sportskeeda, Fisch](https://www.sportskeeda.com/roblox-news/roblox-fisch-a-beginner-s-guide)); Pet Simulator 99's look is painted ImageButtons ([DevForum 2914121](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)). No source on the web lays out the HUDs of Adopt Me, Blox Fruits, 99 Nights or Bee Swarm in detail (searched 2026-10-22; Roblox's Creator Hub pages are behind the cloud proxy, so their lines are quoted from search results and `reports/Roblox creature UI and Claude workflows.md`). Our first-hand reads remain the TikTok frames: Steal an Egg's left stack and bottom pet bar (ZPLRwXx6J), the dino ranch's one banner and compass waypoint (ZPL8MtkYu), the shop shelf (ZPLSQA4aX). The common shape is the one the wireframe draws: a few edges used, the middle empty.

## Inventory: everything that can be on screen

"When" is today's rule. Verdict: **keep**, **merge**, **contextual** (shown only while it matters), **hide** (hidden by default, reachable), **remove**. Pkg is the work package below that does it.

### The HUD at rest

| Element | Where (file) | When visible today | Verdict | Reason | Pkg |
|---|---|---|---|---|---|
| Scrap pill and rolling count | top-left (`Hud.luau` `buildScrapPill`) | always | keep | the one currency; stays even over panels (it is what a panel spends) | A |
| "+N/min" rate line | under the Scrap pill | while the camp earns | keep | idle income is the reason to come back | A |
| Shop button | left edge, slot 0 | always | contextual (from the first catch) | B53 keeps it in view; a new player needs it once Scrap means something | A |
| Starter Pack gold button | beside the Shop (`AddSideButton`) | while unbought | keep, appears with the Shop | B53a; flagged below for Ethan (stage timing) | A |
| Menu button and drop-down | left edge, slot 1 | always | contextual (from the first catch) | B53 stands; the rows are empty of meaning before a catch | A |
| Menu badge | Menu button corner | sum of row counts | keep, claimables only | a red count only for something claimable now | A |
| Compass strip | top centre (`Compass.luau`) | always outside panels | keep, fewer marks | the waypoint is the tutorial's and quests' pointer | A |
| Compass line ("Cave 113m") | under the strip | whenever any marker is on the strip | contextual | name only a goal: tutorial waypoint, quest target, Warden, Peddler; landmarks keep their diamond, lose the line | A |
| Landmark diamonds (caves, shrine, vent) | on the strip | always past their min distance | contextual (after the tutorial) | noise before the player can use them | A |
| Ship bar | top centre under the strip | always | merge into the goal plate | the long goal; appears once the Hull Frame is paid | A |
| Tutorial hint | gold plate 0.5 wide at y 0.79 (`TutorialHint.luau`) | tutorial | merge into the goal plate | the short goal; same words, a third of the weight, off the avatar | A |
| Luck line ("Luck x2.0") | under the ship bar | luck not x1.0 | merge into the event chip | one place says "something is boosted" | A |
| Event banner (centre, "Haunted Nebula 8d left") | under the ship bar | any event or server luck | merge into the event chip | a week-long state is a chip, not a banner on the eye line | A |
| Friend Boost chip | centre column | boost above +0% | contextual, moved top-right | under the event chip, so the centre column is only the goal | A |
| Day and weather chip | top-right | always | merge with the biome chip | one place chip, two lines: where and when | A |
| Biome chip (or visit label) | top-right | always | merge (line 1 of the place chip) | as above | A |
| Event countdown chip ("Rush in 19s", shower) | top-right | before a Rush or shower | merge into the event chip | one event slot, priority below | A |
| Radar column | right edge (`RadarColumn.luau`) | with Radar Mk1 or a Scanner Pulse | keep | B52 as built | A |
| Action button (Catch!, Collect, Build) | bottom-right | near a target | keep | the one prompt; its breathing is the HUD's one loop | A |
| "+N" fly to the Scrap pill | from the action button | each Scrap grant | keep | cause and effect in one move | A |
| Power-up bar and "Power-ups" caption | bottom centre (`PowerUpBar.luau`) | while any power-up is held or running | keep the slots, remove the caption | the icons and count badges say it | A |

### Transients (toasts, banners, cards)

| Element | Source | When today | Verdict | Reason | Pkg |
|---|---|---|---|---|---|
| Toast stack | `Toast.luau` (DisplayOrder 40, top 0.29) | up to 3, 2.5 s, a ding each | keep, at most 2, classed | see the budget | B |
| Banner (server-wide) | `Toast.Banner`, shares the stack | up to 3 with the toasts | keep, own slot, one at a time | the two-banner sky | B |
| Others' catch announcement | `init` `ServerAnnouncement`, server `Config.AnnounceMinTier` Rare | every Rare+ catch by anyone | contextual by tier | Rare: chat line only; Epic: quiet toast; Legendary and up: banner | B |
| Catch Rush start, Meteor Shower start | `init` ~1591, ~1618 | at start | keep as banner | an event the player can join now | B |
| Warden awake, Warden sighting | `init` ~986, ~1020 | at start | keep as banner (one kind) | the same "go and see" | B |
| Peddler landed | `PeddlerRenderer.luau` 262 | at landing | keep as banner | join-now | B |
| Server Luck bought by a player | `init` ~1789 | at start | keep as banner | B51 social proof (batch 9, 7a) | B |
| Weekly event start | `init` ~1722 | at start | toast, not banner | it lasts a week; the event chip carries it | B |
| Special weather species ("Rain: Storm Shard...") | `init` ~1962 | at the weather change | toast (with icon) | useful, not urgent | B |
| Blizzard hint | `init` ~1953 | each blizzard | toast | a rule, not an event | B |
| Shower over, Warden retreated, sighting over, friend left, visitor arrived, wave got and sent, habitat income, alien grew | `init` | at the moment | quiet line (no sound) | the player loses nothing by missing them | B |
| Material collected ("+1 Wreck Plate") | `init` 758 | per pickup | toast, merged in place | three pickups read "+3 Wreck Plate", one ding | B |
| Offline summary (title, body, modules, grew, per alien) | `init` ~1100 to 1120 | at join | merge into one welcome toast | one line per kind, three lines at most | B |
| Scrap short + Earn faster chip | `ScrapGap.luau` | on a refused buy | keep | B51 | B |
| Crash lines, fly line | `CameraDirector.luau`, `init` 887 | cinematics | keep | nothing else shows then | B |
| Notify card | `NotifyCard.luau` | never in the first session | keep | already polite | B |
| Gifts pop after T6 | `init`, `data/Tutorial` `GiftPopAfterStep` | once | keep | the first payoff | B |

### Moments (they own the screen)

| Element | Source | When today | Verdict | Reason | Pkg |
|---|---|---|---|---|---|
| Capture bar | `CaptureBar.luau` | a catch | keep | the one focal point already; the HUD extras hide | C (no change) |
| Reveal, three beats | `Reveal.luau`, `data/Reveal` | every catch and egg | contextual by novelty | full ceremony for a new species, Rare and up and eggs; a quick card for a repeat Common or Uncommon | B |
| Cinematic bars, launch fade, resting screen | `CinematicBars`, `LaunchSequence`, `AfkScreen` | their moments | keep | | none |

### The world layer

| Element | Source | When today | Verdict | Reason | Pkg |
|---|---|---|---|---|---|
| Wild nameplate (name + tier) | `World/WildRenderer.luau` | every alien within 60 studs (`Config.NameplateDistance`) | contextual | the nearest 5 and never more (a close crowd does not lift the cap); the tier line within 30 studs | A |
| "!" or heart bubble | `World/Spectacle.luau` | on notice | keep | small, earned by walking up | none |
| Node plate (name, condition) | `World/NodeRenderer.luau` | within its draw distance | contextual | within 30 studs, or the tutorial's target node | A |
| Landmark plates | `World/LandmarkRenderer.luau` | in range | keep | landmarks are places, read rarely | none |
| Presence (pool, glyph orbit, footprints, aura, trail, haze, ambient loop) | `Spectacle.luau`, `data/Spectacle` Caps | nearest 12 (8 on a phone) | contextual, fewer | nearest 6 (4 on a phone); glyph orbit and trail from Rare | B |
| Beacons | `Spectacle.luau` | Epic 20 s, Legendary+ while it stays; 4 (2 phone) | keep, fade near | a beacon is for finding from far; within 25 studs of the camera or the avatar (the nearer) it fades out; each beacon part carries `NearFade`, `CameraStuds`, `AvatarStuds` and `Species` attributes for a Studio check | B |
| Arrival sky dim (Cosmic), edge vignette (Secret) | `Spectacle.luau` | each arrival | keep, spaced | never within 8 s of another dim, never over an open panel | B |
| Shakes (crash, Legendary rumble), Perfect flash, assembly flash | `CameraDirector`, `Vfx` | their moments | keep | already short, already skipped by Reduced Motion | none |
| Weather particles, shower sky | `WeatherFx`, `Vfx.SetShowerSky` | weather and showers | keep | world, not UI | none |

### Sounds

| Sound | Today | Verdict | Pkg |
|---|---|---|---|
| `Sounds.Banner` | each banner, again on a replay after a Hush | once per banner, never on a replay | B |
| `Sounds.ToastDing` | every toast | toast class only; quiet lines and merged updates silent; at most one UI cue per 0.5 s | B |
| Click | every tap | keep (no silent taps) | all |
| Tier stingers, horns, Warden appear, Rush start | their events | keep | none |

## The notification budget

**At most three things announce at once:** one banner, two toasts. Plus at most one world dim (an arrival) and the HUD's one loop (the action button's breath). During a moment (capture, reveal, cinematic, launch, the assembly burst) nothing new draws: the existing quiet rules (`Toast.Quiet`, `Hush`, `QuietFor`) stay as they are.

**Four classes** (rows in a new `src/shared/data/Notify.luau`, rules in a new pure `src/shared/NotifyMath.luau`):

| Class | Where | Sound | Time | Who | Holds and drops |
|---|---|---|---|---|---|
| Banner | its own slot, top centre at 0.19 (0.06 from the bottom while a panel is open, as now) | `Sounds.Banner`, once | `Config.AnnounceSeconds` (4) | something the player can join now: Rush, Shower, Warden or sighting, Peddler, Server Luck, others' Legendary and up, crash and fly lines | one on screen; a queue of at most 3 in priority order (Rush and Shower, then Warden and sighting, then Peddler, then Server Luck, then others' catches), one per kind (the latest wins), 1.5 s between two; one older than 12 s in the queue is dropped (its state is in the event chip by then) |
| Toast | the stack, top centre from 0.27 | `Sounds.ToastDing` | 2.5 s | the player's own results and refusals: material, module done, quest step, Scrap short, purchase, friend joined, mail, weekly start, special weather, blizzard, welcome back, others' Epic | at most 2 on screen; a third waits; a toast with the same merge key as a live one within 3 s updates it in place ("+3 Wreck Plate") and restarts its time, without a ding |
| Quiet line | the stack, under the toasts | none | 2 s | the rest: shower over, Warden retreated, sighting over, friend left, visitor, wave got and sent, habitat income, alien grew (merged: "3 aliens grew") | dropped first when the stack is full; never held through a moment (dropped instead) |
| Nothing | (chat line or chip only) | none | | others' Rare catches (chat system line), the weekly event's continuing state (chip), luck changes (chip) | |

**Rules.**
- A banner never shares the toast stack and two banners are never on screen together.
- When a tutorial ends, the banners it held are not all released: only the highest-priority one still running shows; the rest are already in the event chip.
- A Settings row "Announcements" (All, Big only, Off; default Big only) filters the others'-catch class: All shows others' Rare as a quiet line and Epic as a toast; Off shows none (Rush, Shower, Warden, Peddler and Server Luck always banner).
- A red badge means "claimable now" (a gift, a quest reward, a playtime gift, mail with an attachment), never "something new to read".
- On the HUD only the action button loops; anything newly shown pops once and is still.

## Per-screen changes

What stays everywhere: block cells (B44), the radar column (B52), the Menu with the Shop and the gold Starter Pack (B53), the shop shelf and its answers (B51), Fredoka One, outlined text over the world, the rarity colours, Scale never Offset, 44 px hit areas, every string in `src/shared/strings`, every number in `src/shared/data`.

**HUD** (`src/client/UI/Hud.luau`, package A). Layout at rest, fractions of the screen (all numbers into a new `src/shared/data/Hud.luau`):
- Goal plate, top centre under the compass: the ship bar keeps its slot (0.36 to 0.64 wide, from 0.06 with `CENTER_SHIFT`, tap opens the Ship); under it, joined, the objective line (0.36 to 0.64, 0.118 to 0.168): a dark trough plate (`Theme.Block.Trough`) with gold ink, the hint's text in white outlined Fredoka at the 14 px floor or more and the "1/3" counter chip on its right. The objective line is the tutorial hint moved here (package A owns `TutorialHint.luau`, which keeps its step logic, waypoint and `TUT_DONE` and only changes where and how it draws). Gold face only for 1.2 s when a step changes (a pop), then the trough face. The old 0.5-wide plate at 0.79 is gone. After the tutorial the objective line is hidden and the plate is the ship bar alone.
- Top-right, from 0.985 right: the **place chip** (0.79 to 0.985, 0.025 to 0.105): two lines, the biome (or the visit label from `SetBiomeLabel`) and "Day · Rain"; gold by day, blue by night as the clock chip is now. Under it the **event chip** (0.81 to 0.985, 0.115 to 0.162), shown only while one of these holds, highest first: a running Rush or Shower ("Rush 0:19" with the green luck block), a countdown ("Rush in 0:19": it is only fed inside its warning window and an imminent Rush outranks a standing state, Mac job 65), a server luck, a season or weekly event ("Haunted Nebula 8d"), luck not x1.0 ("Luck x2.0"). A tap on it opens the Quests screen's What's on band (`Screens.Open("Quests")`). Under that, the Friend Boost chip (0.85 to 0.985, 0.17 to 0.215) only above +0%. The radar column keeps its top (0.228).
- The public API keeps every signature (`SetEventBanner`, `SetEventCountdown`, `SetLuck`, `SetFriendBoost`, `SetBiome`, `SetBiomeLabel`, `SetClock`, `SetShip`), so the bootstrap does not change: the functions feed the chips above instead of the old centre column.
- **While a panel is open** (Hud polls `Screens.IsAnyOpen()` from `UI/Screens` every 0.1 s; Screens requires nothing back): everything but the Scrap pill hides (the left column and the drop-down, the goal plate, the chips, the action button). The Shop's own header already shows Scrap. Closing the panel brings them back with no pop.
- `Hud.SetMenuVisible(false)` (a capture or a reveal) hides the goal plate and the event and Friend chips as well as the left column, so the capture bar is alone with the Scrap pill.
- **Staged reveal** (`Hud.SetStage(step)`, called by `TutorialHint` when the server's tutorial step changes; stages in `src/shared/data/Tutorial.luau` `HudStages`, the pure rule in a new `src/shared/HudStages.luau`): see the first five minutes. A finished tutorial shows everything at once, no pops.

**Compass** (`Compass.luau`, `data/Compass.luau`, A): the line under the strip names only a goal kind (waypoint, Warden, Peddler) and hides otherwise; landmark diamonds carry a new `afterTutorial = true` and stay off the strip until the tutorial is done. No other change.

**Power-ups** (`PowerUpBar.luau`, A): remove the "Power-ups" caption; the slots stay where they are.

**World labels** (`World/WildRenderer.luau`, `World/NodeRenderer.luau`, A; numbers in `data/Hud.luau` `Plates`): a wild plate shows for the nearest `MaxShown` 5 aliens in range and never more (the old "plus any within 15 studs" is gone: six aliens 8 studs away drew six, Mac job 65); of aliens standing together only `StackMaxDepth` 3 plates stack up and the later ones are dropped, so none climbs under the compass strip; its tier line only within `TierStuds` 30 (the name alone farther). A node plate shows within `NodeStuds` 30, and the tutorial's target node at any distance. The stacking and screen-share rules of 2026-10-22 stay.

**Toasts and banners** (`Toast.luau`, B): the budget above. The banner gets its own ScreenGui child frame and its own slot (top centre at 0.19, 0.6 wide, aspect 9; bottom slot while a panel is open), the stack keeps 0.42 wide and starts at 0.27, `MAX_VISIBLE` 2, plus the class and merge rules. Public API stays (`Show`, `ShowAction`, `Banner`, `Hush`, `QuietFor`, `SetTop`, `SetPanelProbe`); add `Toast.Quiet(text, color?, iconKey?)` for the quiet class and an optional `mergeKey` as a fifth argument of `Show`.

**Reveal** (`Reveal.luau`, `data/Reveal.luau`, B): a **quick card** for a wild catch whose species is already in the codex and whose tier is Common or Uncommon (`data/Reveal` `QuickTiers`): no dim, no shards, no tier word, no "Tap anywhere"; a small card (0.3 wide) slides up from above the action button with the model, the name and the size chip, stays 1.6 s (`QuickSeconds`), and goes; a tap on it opens Aliens ("Place it"). The Toast quiet moment covers only its 1.6 s. Everything else (a new species, Rare and up, every egg) keeps the three beats as specced.

**Spectacle** (`World/Spectacle.luau`, `data/Spectacle.luau`, B): `MaxPresence` 6, `MaxPresenceMobile` 4; glyph orbit and trail from Rare; a beacon fades to clear between `BeaconNearFadeStuds` 40 and `BeaconHideStuds` 25 of the camera; an arrival's sky dim or vignette is skipped while a panel is open or within `DimGapSeconds` 8 of the last.

**Panels, the shared shell** (`Builder.luau`, `Theme.luau`, C): a `quiet = true` prop on `Builder.blockPlate` (used by every modal panel's body) draws the panel face with the lit top row, the shaded edges and the grout at `Theme.Block.QuietGroutAlpha` 0.95, and no jitter: the face reads as one cream surface in cells, not graph paper. The header tab, the close button and the HUD keep full cells. Every modal passes `quiet = true`.

**Aliens** (`AliensScreen.luau`, C): the station slot names go (the slot shows the model or the species colour; the station header keeps "4/4" and "+258/min"); the Release button leaves the header's left corner for the footer's button row, left of Storage Bay; one primary (green) button in the footer at a time (Storage Bay when buyable, else none); the grid stays two rows.

**Ship** (`ShipScreen.luau`, C): a locked module row shows its number, its name and a small lock (pixel icon `Lock`, 8 by 8, drawn in `data/PixelIcons.luau`) and nothing else; `SHIP_LOCKED` shows once, on the first locked row. The intro line ("Pay Scrap, add the parts...") shows only until the first module is paid. In the active card the one green button is the next step (Pay until paid, then Add while parts are missing).

**Codex** (`CodexScreen.luau`, C): on open the detail card shows the most recently caught species (or the first entry), so it is never empty; the "Event" word on cells goes (an event species keeps a purple corner block, and the detail card names the event); "This week" stays (it is a call to act).

**Quests** (`QuestsScreen.luau`, C): opens on the tab with something claimable, else Field Notes; the What's on band is one line ("2 events on, tap for more") that expands on tap; the event chip on the HUD opens it expanded.

**Gifts** (`GiftsScreen.luau`, C): two columns, the calendar and the wheel; the social column becomes one block button under the wheel, "Group and friends" (a new string), that opens the two asks as a small card. Only a claimable day is green with gold ink; claimed days pale; future days grey with no button.

**Settings** (`SettingsScreen.luau`, C): two section headings in the list, "Sound and motion" (Ambience, Music, Sounds, Reduced Motion, Silhouettes, Announcements) and "Home" (HomeLock), then the code row. The Announcements row itself is data (package B adds it to `data/Settings.luau`; the screen draws rows from data, so it appears with no screen change).

**Playtime** (`PlaytimeScreen.luau`, C): the claimable card the only green one; the rest as the Gifts rule.

**Shop** (`ShopScreen.luau`): no change (B51 stands); the panel shell rule above does not apply to it (it is a full-screen takeover, not a modal plate).

**Capture bar** (`CaptureBar.luau`): no change; the HUD hiding round it is package A's.

## The first five minutes

What a new player sees, step by step (steps are `data/Tutorial.luau`; "stage" is what the HUD shows; everything server-side is unchanged).

1. **Loading, then the crash** (0:00): the loading screen; the crash cinematic with the letterbox and Skip; the two crash lines are the only banners. No HUD.
2. **Stage 1, T1 "Collect 3 wreck plates"** (about 0:10): the Scrap pill (0), the compass strip with one gold diamond and the line "Wreck Plate 40m", the goal plate's objective line with "0/3" (no ship bar yet), nothing else. Near a plate the action button says Collect. Each pickup merges into one toast, "+1 Wreck Plate", "+2...", "+3...". No chips, no Menu, no Shop, no radar, no events.
3. **T2 "A Moop wants to help! Walk up and tap Catch!"** (about 0:45): the objective line pops gold once with the new words; the diamond moves to the trainee Moop. Catch! appears near it; the capture bar takes the screen with the Scrap pill only; the full reveal (a new species).
4. **Stage 2, after the first catch**: the Shop (with the gold Starter Pack beside it) and the Menu drop onto the left edge with one pop each; the Aliens row carries a red dot until it is opened once. The objective line already reads T3.
5. **Stage 3, T3 "Walk to the ship, pay for the Hull Frame..."** (about 1:30): the diamond on the ship; once the hull is paid the ship bar slides into the goal plate above the objective line ("Ship 4%").
6. **Stage 4, T4 and T5 "Catch 3 more aliens while they work"** (about 2:30): the place chip appears top-right ("Meadow / Day · Clear"); repeat Common catches now give the quick card, a new species the full reveal.
7. **T6 "Your crew is building the Hull Frame. Watch the ship bar."** (about 4:00): the module burst (a quiet moment), then the Gifts screen pops for the day-1 gift (as now).
8. **Stage 5, T7 "Thrusters need Glowroot from Starhollow Forest"** (about 5:00): landmark diamonds join the compass; on entering the Forest, `TUT_DONE` shows on the objective line for 2.5 s, the line hides, and held events release under the banner rule (at most one banner). From here the full HUD of the wireframe.

`HudStages` (in `data/Tutorial.luau`): `{ Shop = "T2", Menu = "T2", ShipBar = "T3", PlaceChip = "T4", EventChip = "T7", Landmarks = "T7" }`: each element shows once that step is complete. **For Ethan**: the Shop and the Starter Pack wait about 45 seconds for the first catch; if he wants them from the first frame (B51's "show the offer"), set `Shop` to `"T0"` in the data; nothing else changes.

## Work packages (three, disjoint files)

Every package: Luau strict, `./tools/analyze.sh` prints `analyze: clean`, `./tools/lint.sh` passes, the headless tests pass; Scale only; strings keyed; numbers in data. Each package touches only its own files. Shared files are split by anchor so merges do not touch the same lines:
- `src/shared/strings/en.luau`: append-only, own keys, each package inserting its block directly after its anchor line and nowhere else: **A** after `TUT_PROGRESS = "%d/%d",`; **B** after `OFFLINE_MODULES = ...`; **C** after `SHIP_ADD = "Add %s",`. Never edit or reorder another key, except where a package's own row below says so.
- `src/shared/data/Config.luau`: **B only**. `src/shared/Theme.luau`: **C only**. A and B put new numbers in their own new data files.
- `src/client/init.client.luau` (the bootstrap): **B only**. A and C need no bootstrap change (their modules keep their public functions).
- `docs/vault/05-ui-design/UI-Playbook.md`: each package adds one subsection at its own anchor: **A** a `### Clean pass: the HUD (2026-10-22)` at the end of "Menu drop-down and icons (B52)" (before "## Studio fixes after the block cells"); **B** a `### Clean pass: notifications (2026-10-22)` at the end of "Layers and banners (2026-10-05)" (before "## Input fields and hints"); **C** a `### Clean pass: panels (2026-10-22)` at the end of "Screens after the HUD" (before "## Menu drop-down and icons (B52)"). Outdated lines elsewhere get a one-line "superseded by" pointer in the same subsection's package only if that line sits in the package's own sections.
- `docs/TESTING.md`: each package adds one section directly above its anchor: **A** above `## Radar column (World 1 place)`; **B** above `## Quiet moments: banners and toasts wait for the Reveal and the capture bar (World 1 place)`; **C** above `## Screens in block cells (World 1 place)`.
- The day log (`docs/vault/08-log/`) and the Mac jobs in [[Overnight]]: each worker puts its log bullets and its Mac steps in its report; the coordinator writes both at merge (three appends to one file would conflict).

### Package A: the quiet HUD and the first five minutes

**Goal.** The HUD at rest is the wireframe: the goal plate top centre, at most three small plates top-right, the left column, the radar, the one prompt; it disappears behind panels; it grows in stages for a new player; world labels show only what is near.

**Owns.** `src/client/UI/Hud.luau`, `src/client/UI/TutorialHint.luau`, `src/client/UI/Compass.luau`, `src/client/UI/PowerUpBar.luau`, `src/client/UI/RadarColumn.luau` (read-only unless a slot must move), `src/client/World/WildRenderer.luau`, `src/client/World/NodeRenderer.luau`, `src/shared/data/Hud.luau` (new), `src/shared/HudStages.luau` (new), `src/shared/data/Tutorial.luau`, `src/shared/data/Compass.luau`, `src/shared/data/Menu.luau`, `src/shared/MenuMath.luau`, `tests/HudStages.spec.luau` (new), `tests/MenuMath.spec.luau`, `tests/BlockMath.spec.luau` (its HUD blocks; C does not touch this file), `tests/PlateMath.spec.luau`, `tools/tests/test_menu_hud.py`, its en.luau block, its Playbook and TESTING sections.

1. Goal plate: move the tutorial hint into an objective line joined under the ship bar (numbers above, in `data/Hud.luau`); trough face, gold ink, gold face for `StepPopSeconds` 1.2 on a step change; delete the 0.5-wide plate at 0.79. Keep `TutorialHint`'s steps, waypoint, counter and `TUT_DONE`.
2. Place chip: one two-line plate for the biome (or visit label) and the time and weather; gold by day, blue by night.
3. Event chip: one plate fed by `SetEventBanner`, `SetEventCountdown` and `SetLuck`, by the priority above; tap opens Quests; the centre event banner and luck line are deleted. Friend Boost chip moves under it.
4. Panel hide: poll `Screens.IsAnyOpen()` every `PanelPollSeconds` 0.1; hide all but the Scrap pill while true.
5. `SetMenuVisible(false)` also hides the goal plate and the right-hand chips.
6. Stages: `HudStages` in `data/Tutorial.luau`, `HudStages.Shown(element, stepIndex, done)` in `src/shared/HudStages.luau` (`"T0"` means from the first frame; spec: every element hidden at T1 for a fresh profile, all shown when done, each appears exactly at its step), `Hud.SetStage` called from `TutorialHint` on each step change; a newly shown element pops once (`Theme.Tween.Open`; Reduced Motion: none).
7. Compass: the line only for goal kinds; landmark rows `afterTutorial = true`.
8. Power-up bar: remove the caption (and its string if unused elsewhere).
9. World labels: the nearest-5 and 15, 30 and 30 stud rules in WildRenderer and NodeRenderer, numbers in `data/Hud.luau` `Plates`; a pure helper in `src/shared/PlateMath.luau` is fine (A owns `tests/PlateMath.spec.luau`).
10. Menu badge: in `MenuMath.BadgeTotal` callers, nothing changes; document "claimables only" in the Playbook (the bootstrap's three `SetBadge` calls already count claimables).

**Acceptance (Mac, Studio, default window, World 1).**
1. A finished-tutorial profile at the camp: `screen_capture` to `clean-hud-rest-default.png`. Pass: matches `clean_hud_wireframe.png`: nothing between 0.3 and 0.75 of the height except the world, the Catch button and power-up slots when held; top-right one place chip ("Meadow / Day · Clear") and no other chip at luck x1.0; the ship bar under the compass with no plate under it.
2. `/admin luck`: one purple event chip under the place chip reads the luck; no gold "Luck x2.0" text and no event banner in the centre. `/week next` (a weekly event): the same chip reads its name and days left.
3. `/rush in 20`: the event chip reads "Rush in m:ss", then "Rush m:ss" with the green block when it starts; never a second chip; tap it: Quests opens.
4. Open the Ship from the Menu: only the Scrap pill stays outside the panel; close: the HUD returns, no pop.
5. Start a catch: only the capture bar and the Scrap pill.
6. `/tutorial 1` (back to the first step): step through T1 to T7 (`/tutorial N` jumps; play T1 and T2 by hand) with `screen_capture` at each (`clean-stage-<n>-default.png`); Pass: the elements of "The first five minutes" appear at their steps, each with one pop, and the objective line holds each hint whole at the floor.
7. Two wild aliens and a node in the camp's view: no more than five name plates; a far alien shows its name without the tier line; the Storm Shard plate shows only within about 30 studs.

### Package B: the notification budget and the moments

**Goal.** At most one banner and two toasts; the right class for every message; join-time and pickup bursts merged; a repeat common catch costs 1.6 seconds, not a ceremony; the world's spectacle never whites out the screen.

**Owns.** `src/client/UI/Toast.luau`, `src/client/UI/Reveal.luau`, `src/client/UI/ScrapGap.luau`, `src/client/UI/NotifyCard.luau`, `src/client/init.client.luau`, `src/client/World/Spectacle.luau`, `src/client/World/PeddlerRenderer.luau`, `src/client/World/CameraDirector.luau`, `src/shared/data/Notify.luau` (new), `src/shared/NotifyMath.luau` (new), `src/shared/data/Config.luau`, `src/shared/data/Reveal.luau`, `src/shared/RevealMath.luau`, `src/shared/data/Spectacle.luau`, `src/shared/SpectacleMath.luau`, `src/shared/data/Settings.luau`, `tests/NotifyMath.spec.luau` (new), `tests/RevealMath.spec.luau`, `tests/Spectacle.spec.luau`, `tools/tests/test_lint_reveal.py`, its en.luau block, its Playbook and TESTING sections.

1. `data/Notify.luau`: the four classes, banner kinds and their priority, `BannerQueueMax` 3, `BannerGapSeconds` 1.5, `BannerStaleSeconds` 12, `ToastMax` 2, `QuietSeconds` 2, `MergeSeconds` 3, `CueGapSeconds` 0.5, and the others'-catch tier table (Rare: chat, Epic: toast, Legendary and up: banner) per Announcements level.
2. `NotifyMath`: pure functions for the class of a message, the banner queue order and stale drop, the merge decision; spec every rule in `tests/NotifyMath.spec.luau`.
3. `Toast.luau`: the banner's own slot and single-banner queue; `MAX_VISIBLE` 2 toasts with the quiet lines dropped first; `Toast.Quiet`; `mergeKey` on `Show`; no sound on a replay after `Hush`; the cue gap.
4. Bootstrap: route each call in the inventory to its class (the `init.client.luau` lines listed there); the material toast merges by material; the offline burst becomes one toast (new `OFFLINE_SUMMARY` built from the parts, at most three lines); others' catches by tier and the Announcements setting; weekly start, special weather and blizzard as toasts; on tutorial end release only the top held banner.
5. `data/Settings.luau`: the Announcements level row (levels 0 to 2, `levelKeys` `SETTINGS_Announce_0..2`, default 1) and its strings; confirm `server/ProfileSchema.luau` fills a missing key with the data default for old profiles (it builds defaults from `SettingsData.Order`; if a stored profile lacks the key, read the data default on the client).
6. Reveal quick card: `QuickTiers`, `QuickSeconds` 1.6, `QuickWidth` 0.3 in `data/Reveal.luau`; `RevealMath` decides quick or full from tier, novelty and grant kind (spec it); the quick card is block cells (an edged cream block, the model in `SpeciesThumb`), Reduced Motion: a fade.
7. Spectacle: presence caps 6 and 4; glyph orbit and trail from Rare; the beacon's near fade; the dim spacing and the panel rule; numbers in `data/Spectacle.luau`, the arithmetic in `SpectacleMath` with spec lines.

**Acceptance (Mac, Studio, default window, World 1).**
1. `/rush` then `/sighting` within two seconds (tutorial finished): one banner at a time, Rush first, the sighting 1.5 s after it leaves; never two banners on screen. `screen_capture` while each shows.
2. Collect three wreck plates quickly: one toast that counts up to "+3 Wreck Plate" with one ding.
3. Offline earnings with real saves (TESTING "Milestone" offline step: `Config.UseDataStoreInStudio` true, leave with aliens working, rejoin after more than 60 s): one welcome toast, at most three lines, and no other toast in the first five seconds.
4. Two-client test: player 2 `/spawn`s and catches a Rare (`/spawn Zapfinch`), then an Epic (`/spawn Thunderhog`) and a Legendary (`/spawn Gaiabloom`): on player 1, the Rare is a chat system line only, the Epic one toast, the Legendary one banner.
5. Catch a repeat Moop: the quick card rises over the Catch button for about 1.6 s, no dim, no "Tap anywhere"; the next Catch! works at once. Catch a species not yet in the codex: the full three beats.
6. `/spawn Radish` (World 1's Cosmic) near the camp and walk into its beacon: the screen never goes white; the beam fades as you approach.
7. Settings, Announcements Off: the Epic toast of step 4 does not show; Rush still banners.

### Package C: calm panels

**Goal.** A panel is the one focal point: a quiet face, one primary button, no repeated text, never an empty pane.

**Owns.** `src/client/UI/Builder.luau`, `src/shared/Theme.luau`, `src/client/UI/AliensScreen.luau`, `src/client/UI/ShipScreen.luau`, `src/client/UI/CodexScreen.luau`, `src/client/UI/QuestsScreen.luau`, `src/client/UI/GiftsScreen.luau`, `src/client/UI/PlaytimeScreen.luau`, `src/client/UI/SettingsScreen.luau`, `src/client/UI/MailScreen.luau`, `src/client/UI/LeaderboardScreen.luau`, `src/client/UI/PeddlerScreen.luau`, `src/client/UI/StarChartScreen.luau`, `src/client/UI/VisitScreen.luau`, `src/client/UI/ReleasePanel.luau`, `src/client/UI/BuildScreen.luau`, `src/shared/data/PixelIcons.luau` (the `Lock` icon), `src/shared/data/Panels.luau` (new), `tests/PanelQuiet.spec.luau` (new), `tests/PixelIcons.spec.luau`, `tools/tests/test_block_theme.py`, its en.luau block, its Playbook and TESTING sections. Not `tests/BlockMath.spec.luau` (A's): new panel checks go in `tests/PanelQuiet.spec.luau`.

1. `Builder.blockPlate` `quiet = true`: no jitter, grout at `Theme.Block.QuietGroutAlpha` 0.95; every modal body passes it (the header tab and close keep full cells); frame counts checked in the new spec.
2. Aliens: drop the slot name labels; move Release into the footer row; one green footer button at a time.
3. Ship: locked rows are number, name and lock; `SHIP_LOCKED` once; the intro line only before the first payment; one green button in the active card.
4. Codex: open on the most recent catch (or the first entry); event cells lose the word, keep a purple corner block; "This week" stays.
5. Quests: open on the claimable tab; the What's on band one line, expandable; a public `QuestsScreen.OpenWhatsOn()` that the HUD's event chip can call later (A's chip opens `Screens.Open("Quests")` today; wiring the expanded view is a one-line follow-up after both merge).
6. Gifts: two columns; one "Group and friends" button and its small card; the green-only-when-claimable rule. Playtime: the same rule.
7. Settings: the two section headings (strings `SETTINGS_SECTION_Sound`, `SETTINGS_SECTION_Home`, mapping in `data/Panels.luau`), rows drawn from data so B's Announcements row appears by itself.
8. Mail, Leaderboard, Peddler, Star Chart, Visit, Release, Build: `quiet = true` on the body only; no other change.

**Acceptance (Mac, Studio, default window, World 1).**
1. Open Aliens, Ship, Codex, Quests, Gifts, Settings in turn, `screen_capture` each to `clean-panel-<name>-default.png`. Pass: the cream face reads as one surface (no checkerboard of light and dark cells behind text); the header tab and close still in cells.
2. Ship on a profile with the Hull Frame unpaid: one green "Pay 300" and a blue Add; four locked rows with a lock and a name, "Finish the module above first" once.
3. Codex: the right card shows an alien on open, never the empty "Tap an alien" box.
4. Aliens: no "MoopMoop..." or "Open" words under the slot squares; Release sits in the footer; the two rows of cards as before.
5. Gifts: two columns; "Group and friends" opens the two asks; only today's tile green.
6. Settings: two headings; with package B merged, an "Announcements" row under Silhouettes.

## Sources

- Roblox Creator Hub: [UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design); [Wireframe your layouts](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/wireframe-your-layouts); [Adaptive design guidelines](https://create.roblox.com/docs/production/publishing/adaptive-design); [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques).
- Roblox UI practice: [ScreenInsets enum](https://robloxapi.github.io/ref/enum/ScreenInsets.html); [creation.dev, Roblox UI design best practices](https://www.creation.dev/blog/roblox-ui-design-best-practices); [pet sim UI notes](https://charismaliu.notion.site/UI-b2857ec703ac4713beb537fe3b963c4b); [DevForum 2914121](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121).
- Popular games: [Grow a Garden merchants](https://www.sportskeeda.com/roblox-news/all-merchants-in-grow-a-garden); [Grow a Garden gear shop](https://esports.gg/news/roblox/where-to-find-the-gear-shop-in-grow-a-garden); [Steal a Brainrot rebirth](https://beebom.com/steal-a-brainrot-rebirth-guide-levels-and-rewards/); [Fisch beginner's guide](https://www.sportskeeda.com/roblox-news/roblox-fisch-a-beginner-s-guide).
- Pokemon GO: [Pratt design critique](https://ixd.prattsi.org/2026/09/design-critique-pokemon-go/); [City, University of London interaction lab](https://interactionlab.city.ac.uk/?p=847); [Sakurai, Famitsu 515](https://sourcegaming.info/2016/11/24/the-aims-of-ui-sakurais-famitsu-column-vol-515/).
- Game UX: [Respawn, menus, HUDs and feedback](https://respawn.outlookindia.com/gaming/gaming-guides/ui-and-ux-in-games-building-menus-huds-and-feedback-systems); [Progressive disclosure](https://flyingbisons.com/knowledge-base/progressive-disclosure); [Toward minimalist HUDs (Bonn)](https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207); [NN/g, indicators, validations and notifications](https://nngroup.com/articles/indicators-validations-notifications); [Gluck et al., CHI 2007](https://www.interruptions.net/literature/Gluck-CHI07.pdf).
- Ours: `media/tiktok/NOTES.md` (ZPLRwXx6J, ZPL8MtkYu, ZPLYSaBcg, batch 7 ZPLSQA4aX, the design reference ZPLSHwXqp, batch 9), `reports/Roblox creature UI and Claude workflows.md`, [[UI-Playbook]], [[UI-Checklist]], [[Decisions]] B44, B51, B52, B53.
