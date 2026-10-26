---
tags: [ui-design, ui, plan]
aliases: [UI richness pass, Richness pass]
up: "[[UI-Playbook]]"
---
# UI richness pass (spec, 2026-10-26)

Ethan, 2026-10-24, on the UI in TikTok ZPLAVdpnX: "examine this ui. See how everything seems complete and less basic. There is more going on while also looking clean and easy to navigate around. I want that replicated." The reference and its lessons are in `media/tiktok/NOTES.md` (Batch 10, ZPLAVdpnX). This note is the spec three workers build from in parallel. It sits on top of [[Clean-UI-Pass]] and changes none of it: the notification budget (one banner, two toasts), the quiet HUD, the staged reveal, one primary button per card and "say it once" all stand. It also keeps [[UI-Playbook]] block cells (B44 in [[Decisions]]: frames only, no gradient, no glass, nothing waits on an upload) and the radar column and Menu (B52, B53). Each package writes its rules into the Playbook subsection named in its brief. A Decisions row is the coordinator's once Ethan approves.

**The one idea.** Clean made the screen calm by taking things away. Richness puts them back in the right place: the HUD stays at its calm count, and every panel and every moment gets a fixed, recognisable shape (a header with icon, title and counts; a body with sections; cards with a picture, a state and one button). "Complete" in the reference is counts, pictures and states on everything, not more items.

## What the reference has and we lack (frames in `zpl-avd/`, never committed)

| Frame | The reference | Ours today (Studio, 2026-10-22) |
|---|---|---|
| `mines.jpg`, `pick2.jpg` header | a full-width saturated band: icon, title, one or two pills ("MINES OPEN 10/10", "COLLECTION 38/38"), red X | a small tab straddling the top edge, the title alone (`cleanC-aliens`, `cleanC-codex`, `cleanC-ship`) |
| `mines.jpg` cards | each mine a picture card: number badge, name, found-icons with "?", colour border, HERE or TRAVEL | an orbit map of discs plus one white card of text (`cleanC-starchart`: "Verdant Crash Site / You are here" and an empty column) |
| `pick2.jpg` | the selected skin big (model on a plinth, tag, name, two lines, EQUIP) beside a tile grid with OWNED and gold frames, under section strips with counts ("7/7 owned") | the Codex's detail card is a model and four short lines; the Aliens screen has no featured card |
| `pick.jpg`, `hud.jpg` | a goal card: title tab, one line, a bar with "50 / 200", the reward in green | a gold hint plate with a "1/3" chip; no bar, no reward (`cleanA-hud-rest`) |
| `arrive.jpg` | "VOID ABYSS / NOW ARRIVING" screen-wide, outlined, speed lines | a black fade with "Next stop: Frostbyte" (`LaunchSequence`) and, on the first visit only, an arrival fly-through with no name |

## 1. Principles

1. **The HUD stays calm; richness lives in panels and moments.** The HUD at rest keeps the [[Clean-UI-Pass]] count (`hud.jpg` is one goal card and a few chips). The only HUD change is the goal card (section 5), inside its present height.
2. **Every panel has the same anatomy** (`mines.jpg`, `pick2.jpg`): band, pills, tinted body, sections. A player who has learned one panel has learned them all.
3. **Counts and states on everything** (Collection 38/38, HERE, OWNED): a header never hides what you have, a tile never hides its state. A count is data from State, never a literal.
4. **A place is a picture, a selection is big** (`mines.jpg`, `pick2.jpg`): worlds are cards with their own render, not discs on a map; a grid tile selects and a featured card shows the full alien and its one action. One picture and one button per card (Clean: one primary); never an empty pane (Clean).
5. **Travel is a moment** (`arrive.jpg`): a screen-wide title card with speed lines, spaced by the notification budget and replaced by a fade under Reduced Motion.
6. **A colour means one thing** (Clean rule 8): accent green is the main action, orange only Robux, grey the current or unavailable, red close, blue select, gold featured, a world's border its own colour; rarity colours stay on rarity, and no state is colour alone (every state also has a word or an icon).
7. **Richness is cells and few frames** (B44, Playbook "Frames"): repeated things are edged or flat blocks, no gradient, no gloss, no glass; a picture is an `ImageLabel` that falls back to cells at an id of 0, so nothing waits on an upload.
8. **Not everything wears the game chrome** (Ethan, 2026-10-26, on the radar: "one long rectangle ... silhouette and shadow of the aliens on a white or something similar background ... like if you opened up a scroll vertically. Not everything has to be that gaming design"). Quiet instruments, things read rather than pressed, may be plain flat shapes on a calm paper or cream surface, with no lit rows, grout, jitter or stepped corners (a square or softly rounded plain rectangle, one thin navy edge): **the radar scroll** (a separate worker rebuilds it; this pass does not touch it), **the goal card**, **the status pills** and **the section strips**. The game chrome (block cells, sinking buttons) stays on what is pressed or collected: the header band, buttons, tiles, world cards, the featured card and the HUD's Scrap and Menu. Where a plain instrument sits on a block panel it stays flat so it reads as a label, not a second panel.

## 2. The panel anatomy

**The shell** (`data/Panels.Shell`; every modal reads it, so the numbers live once). The panel keeps each screen's width; height `0.84` of the screen, top at `0.10` (it was 0.78 centred; the HUD hides everything but the Scrap pill while a panel is open, and the pill ends at 0.10, so the band clears it). The old straddling tab goes. Layers from the top of the panel:

1. **Header band**: a block plate the panel's full width inside its ink, `0.13` of the panel's height (3 rows, cells square from the panel's aspect as `Builder.blockHeader` does), in the screen's colour. Left to right: the **icon** (the pixel icon of the screen's Menu row, from `data/PixelIcons`, on a flat block `0.7` of the band tall), the **title** (white outlined Label text, 24, never under the 14 px floor), then at the right the **status pills**, then the **X**.
2. **Status pills**: one or two **plain flat plates** (principle 8), `0.56` of the band tall, text at least 14 px outlined, fitted to their text, `0.012` apart, right-aligned left of the X. **Pill 1 is plain** (face `Theme.Block.Trough`, white text); **pill 2 is the accent** (face in the screen's contrasting colour: Featured gold on blue and purple bands, Select blue on gold bands). If title and pills do not fit (iPhone SE), pills drop from the last; the title never wraps. A pill says "Label value" ("Aliens 34 / 160") from one template string, so it translates. A pill tap does nothing (it is a count), except the Quests pill, which opens its tab.
3. **The X**: `Builder.blockClose`, red, `0.8` of the band's height, overlapping the band's right end by a quarter of its width, 44 px hit area, the same place on every panel.
4. **Body**: the cream face tinted `0.12` toward the band's colour (`Builder.tint(Theme.Colors.Panel, color, 0.12)`), quiet (Clean package C: lit top row, shaded edges, grout at `QuietGroutAlpha`, no jitter). Cards on it stay white or tier-coloured edged blocks. Inner margin 2% as now.
5. **Section strips** (`Builder.sectionStrip(body, text, count?)`): a **plain flat plate** (principle 8) `0.05` of the body tall, full width, in the band's colour a step darker (`Theme.Darken` 0.2), the label in outlined caps on the left (Label, 18), an optional count pill on the right ("7 / 7 owned", "Rare 3 / 4"). It replaces the centred "- FEATURED -" headings and the Settings' small gold headings. A strip only where a list has two or more groups.

**Button colour roles** (`data/Panels.Roles`, `Builder.roleColor(role)`; no screen picks a colour of its own):

| Role | Colour | Used for |
|---|---|---|
| main | `Confirm` green | the one main action of a card or footer (Follow, Pay, Claim, Travel, Equip) |
| robux | new `Theme.Colors.Robux` (`#FF7A1A`, clear of Legendary `#F59E0B`) | any button whose price is Robux, always with the pixel `Robux` icon; the Shop's Robux prices were green and become this |
| current | `Trough` grey with the pixel `Check` | the thing that is already so: HERE, Following (tap again stops), Owned, On display, disabled |
| select | `Select` blue | a secondary action beside the main one (Ride, See in Aliens, Optimize) |
| close | `Close` red | the X and a destructive confirm only |
| featured | `Featured` gold | tags and pills, never a button (the Starter Pack's gold tile stays, B53) |

**Per-panel header** (`data/Panels.Headers`, one row per panel; `title` is the existing string, templates are new `PILL_*` strings; every value is read where the screen already reads it):

| Panel (screen) | Colour | Icon | Pill 1 (plain) | Pill 2 (accent) |
|---|---|---|---|---|
| Your Aliens (Aliens) | gold | Aliens | "Aliens 34 / 160": count of `profile.aliens` over `State.GetStorageCap()`; pill turns red-faced at `Storage.WarnFraction` | "Companions 2 / 4": `#profile.companions` over `State.GetCompanionSlots()` |
| Codex | purple | Codex | "Found 12 / 35": `profile.codex` keys over species of built worlds (`Worlds[].built`) | "Verdant 3 / 19": this page's world, short name, found over total |
| Your Ship | gold | Ship | "Modules 3 / 5": entries of `profile.modules[world]` with `completedAt` over `#Modules[world]` | "Crew x1.6": `State.GetRate().assemblySpeed.Build`, hidden when nil |
| Star Chart | blue | StarChart (new) | "Worlds 2 / 3": `profile.world.unlocked` over built worlds | "Ready 90 Scrap": sum of `OutpostMath.Pending` over `profile.world.outposts`, hidden at 0 |
| Quests | blue | Quests | "To claim 2": the Menu badge's count (claimable steps and rewards) | "Field Notes 3 / 5": `State.GetQuests().fieldNotes[world]` step over `#FieldNotes[world]` |
| Gifts | gold | Gifts | "Day 3": `State.GetGifts().daysPlayed` | "Spins 2": `freeSpins + bankedSpins` |
| Playtime | gold | Playtime | "Today 12 min": `profile.playtime.seconds // 60` | "Gifts 2 / 6": claimed over `#Playtime` rows |
| Shop | violet takeover, band `ShopBackdrop` | Shop | "Scrap 99,936": `profile.scrap` (the Shop's own Scrap pill moves into the band) | none |
| Mail | blue | Mail | "Letters 3": `#profile.mail` | "To claim 1": letters with rewards |
| Visit | blue | Friends | "Online 4": the list's online flag count | none |
| Ranks | gold | Ranks | "You #12": the pinned row's rank | none |
| Peddler | gold | Shop | "Leaves in 2:30": `State.GetPeddler().endsAt` less `State.Now()` | none |
| Settings | blue | Settings | none | none |

The Build tray, Release card, notify card and resting screen keep their own shells (they are not browsing panels). The Quests screen's tabs (Field Notes, Daily and Weekly, Event) become a row of tab buttons directly under the band, in the screen's colours, the active one raised.

**Tile states** (`Builder.stamp(card, kind)`: a flat block chip across the tile's bottom edge, `0.18` of its height, 14 px caps, one at a time; the tile's ink stays its tier colour):

| State | Where | Stamp | Fed by |
|---|---|---|---|
| Found | Codex tile, world card chip | none; tier ink, the model, an "x3" count badge; uncaught is a "?" silhouette in grey ink | `profile.codex[species]` |
| Owned | Shop one-off items and passes, Gifts and Playtime claimed tiles | grey, Check, "OWNED" (a claimed gift keeps its pale face) | `State.GetPurchases()`, `profile.gifts`, `profile.playtime` |
| Equipped | the Radar column tier in use, gear on | green, Check, "EQUIPPED" | `profile.gear` |
| Companion | Aliens tile of an alien following you | green, "COMPANION" | `profile.companions` holds its uid |
| Riding | Aliens tile of the mount you ride | gold, "RIDING" | `State.GetRiding() == uid` |
| Here | world card | the grey HERE button (not a stamp) | `profile.world.current` |

**Tier frames** (`data/Panels.TierFrames`, `Builder.tierFrame(card, tier)`). The ink is the tier colour already (Clean). The ladder adds studs, flat one-cell blocks in the tier colour a step lighter at the card's corners, and a face tint: Common and Uncommon 0 studs; Rare 1 (top left); Epic 2 (top corners); Legendary 4 and a `0.12` tint; Cosmic and Secret 4, the tint `0.18`. At most four more frames a card; rarer is never bigger (B45) and never fiercer (B46). Rarity colours stay on rarity only.

**The API the packages share** (A writes it; B and C call it, so the signatures are fixed here):
- `Builder.panelHeader(panel: Frame, spec: { panelId: string, panelAspect: number, panelHeight: number }, onClose: () -> ()): { band: Frame, title: TextLabel, setPills: ({ { any } }) -> (), close: Frame }`. Colour, icon, title key and pill templates come from `Panels.Headers[panelId]`; `setPills({ { 34, 160 }, { 2, 4 } })` passes each pill's values, formatted by the row's template.
- `Builder.sectionStrip`, `Builder.stamp`, `Builder.tierFrame`, `Builder.tint`, `Builder.roleColor` as above; pure `Shared/PanelHeaderMath.luau` (`Fit(widthPx, titlePx, pills)`, `Format(template, values)`) with `tests/PanelHeaderMath.spec.luau`.

## 3. World cards (Star Chart and the Ship's next stop)

The Star Chart's body becomes a scrolling grid of world cards, two columns, the Home planet first, then worlds 1 to 7 in order; it opens scrolled to the current world. The orbit map is retired (its planets are the number badges; open question 2). The Ship panel has no destination list of its own today (only a "Star Chart" button), so it gets a **next stop strip**: one compact card (full width of the body, `0.2` tall) of the first locked or unlocked-but-not-here world above the footer, tap opens the Star Chart with that world selected (`Screens.Open("StarChart")`; no new server path).

**Card** (`UI/WorldCard.luau`, `WorldCard.Build(parent, worldId, compact: boolean)`; a fitted edged block, aspect 2.2, ink in the world's colour, `data/WorldCards`):
- **Background**: the world's render filling the card face (`ImageLabel`, `image` an asset id, 0 until uploaded). At id 0, or while it loads, the **cell diorama** draws instead: five flat bands from the world's `palette` (`sky`, `skyLow`, `far`, `ground`, `accent`): sky 25% and sky-low 20% of the height, a skyline of 1 to 3 cell towers in `far` (heights from `BlockMath.Level`, so it is the same every build), ground 30%, one accent block for the sun, moon or planet. About 20 frames. A stepped dark scrim (flat black block, 0.55 transparent, the lower 45% and the left 40%) keeps the text readable; no gradient.
- **Pictures**: World 1 and World 2 are crops of the existing hero renders (`media/studio/2026-10-21/world1_hero_b46.jpg`, `world2_hero_b46.jpg`, 1920x1080, cropped to 2.2:1 and scaled to 640x291, saved as `assets/sprites/worlds/World1.png` and `World2.png`). The Home card wants a new render of the camp pad (art worker, same size, `World0.png`; cell diorama until then). Worlds 3 to 7 are designed, not built (`Worlds[].built`), so they stay on the cell diorama in their designed palette until their dioramas exist; no render is blocked on them. Ids are 0 in data; the uploader fills them.
- **Number badge**: top left, a pixel octagon in the world's colour with the world number (Home: the pixel `Home` icon), `0.16` of the card's height.
- **Name**: bottom left over the scrim, Label text, white outlined, the string `WORLD_<id>`.
- **Species row**: under the name, up to 5 flat chips (square, `0.14` of the card's height) and a count "3 / 19" right of them. A caught species is a chip filled with its `placeholder.color` in its tier's ink; an uncaught one is a dark chip with "?" (a Secret is always "?"). Which five: `WorldCardMath.Roster(worldId, species)`, pure and specced: the world's Warden first, the special-weather species second, then the rest by tier descending, then by name. Caught means `profile.codex[id] ~= nil`.
- **Border**: the ink in `WorldCards[id].color` (World 1 `Confirm`-green family, World 2 ice blue, 3 magenta, 4 orange, 5 teal, 6 pink, 7 violet; numbers in data). A world colour is a place colour: it never reuses a rarity colour as a signal, and the state is always in the button or the badge as well.
- **Button**, bottom right, one: **HERE** (current: grey, Check, inert, no tap sound change: it clicks and a toast says "You are here"), **TRAVEL** (unlocked, not here: the main green; the same `FlyTo` request as the old Fly button, same refusals and toasts), nothing on a locked or unbuilt card. A guest (`State.IsGuest()`: visiting, or the ship is elsewhere) sees TRAVEL on the world the ship waits on, labelled "Return" (`STARCHART_RETURN_LINE` text kept as its line).
- **Locked**: the face fades `0.45` (`setBlockFade`), the picture greys, a pixel `Lock` replaces the button, the line says what opens it: "Finish the ship on World 2 to unlock" (`WORLDCARD_UNLOCK`; the next stop takes gold ink and a "NEXT" ribbon instead of the grey one), the species row is all "?" and the count reads "0 / 16". An unbuilt world reads "Opens soon" (`WORLDCARD_SOON`) with no species row.
- **Outposts**: an unlocked world with an outpost wears "Lv 2" top right and a green ready dot (as the planets did). Tapping a card (not its button) selects it (gold ink, the old "selection is an ink colour" rule); the selected unlocked world with an outpost opens an **outpost tray** along the body's bottom (`0.16` tall): "Outpost Lv 2, 120 Scrap/h, ready 90 Scrap" and the two buttons Collect (main green when something is ready, else grey) and Upgrade (select blue, or grey when unaffordable or maxed), exactly the old requests, one in flight, refreshed every `Config.StarChartTickSeconds`. The Home card's Visit button (milestone 42e) is the tray's too, shown when Home is selected.
- **Budget**: 8 cards, each about 8 frames of card + 20 of cell diorama or one image + 6 to 10 chips and strings; the grid is `ScrollingFrame` only; under 400 frames total; a picture loads only when its card is within one screen of the viewport.
- **iPhone SE (667x375)**: the body is about 254 px tall and 500 wide; two columns of 240 px cards are 109 px tall, so about two rows show and the rest scroll; the species row drops to 4 chips under 520 px of panel width, the count stays; the compact (Ship) strip shows only badge, name, count and the button.

## 4. Featured plus grid (Aliens and Codex)

**Shape** (`UI/FeaturedCard.luau`, built once, refilled on selection; `Shared/FeaturedMath.luau` pure and specced). At a panel at least `Featured.MinPanelPx` 620 x 330 px (the default Studio window and the iPad) the **side mode** shows: the featured card on the left `0.30` of the body's width, the grid on the right `0.68`. Under that (iPhone SE) the **strip mode** shows: the featured card as one strip across the top of the body, `0.2` of its height (a `0.2` square picture, name and tier chip, the flavour line, the main button on the right), the grid full width under it. The card never needs a second tap in strip mode: it is always in view.

**The featured card** (top to bottom): the model (`SpeciesThumb`, still, on a flat plinth block in the tier colour's lighter tone; the Codex keeps its slow turn, Reduced Motion still), a **tier tag** (a flat chip in the tier colour with the tier word and its pixel shape icon: never colour alone), the **name** (Label, outlined), **one flavour line** (muted Body text, one line, up to 48 characters, from the string `FLAVOUR_<speciesId>` with `FLAVOUR_TIER_<tier>` as the fallback so a new species never prints a blank; cute, never fierce, B46; written for the 35 current species, 19 in World 1 and 16 in World 2), then **one main button by context**:

| Screen and context | Main button | Beside it (optional) |
|---|---|---|
| Aliens, free companion slot | FOLLOW, green | Ride, blue, if the species has `ride` and it is following |
| Aliens, following | Stop following, grey (current) | Ride, blue |
| Aliens, riding | Hop off, blue | none |
| Aliens, slots full | FOLLOW, grey; the server's refusal toasts as now | none |
| Aliens, home, a habitat is free / on display | Display, green / Bring back, grey | none |
| Aliens, visiting another home | none (a guest never changes it) | none |
| Codex, caught | See in Aliens, green: `Screens.Open("Aliens")` with its first record selected | none |
| Codex, not caught | none; the hint line ("Appears in the Meadow at night") takes the room, with the weekly, vaulted and event lines as now | none |

Every tap asks the server exactly as today (SetCompanion, SetMount, SetDisplay); nothing here decides an outcome.

**Selection.** Aliens: a tap on a card **selects** it (purple-free: the selected card takes the gold ink, the rule "a selection is an ink colour") and fills the featured card; the follow action moves to the featured button. This is one more tap than today's tap-to-follow; the stamp (Companion, Riding) shows the result on the tile, and a hold still opens Release (Storage). The default selection on open: the mount you ride, else the first companion, else the newest alien (`FeaturedMath.AliensDefault`, spec). The Codex keeps `PanelQuiet.CodexDefault`. The grid shows three columns in side mode (about 6 cards visible), five in strip mode, with the station strip across the top of Aliens unchanged (it stays full width above both). Aliens at iPhone SE shows one grid row and a peek of the second (the strip takes the second row's room): the trade for the featured card, flagged for the Mac to judge; the fallback is a drawer (the featured card slides over the grid's left half on a tap and a tap outside closes it).

**Grid sections.** The Codex grid is cut into one section per tier present on the page (`Builder.sectionStrip`, "Rare 3 / 4"); each section is its own grid, so a section's count and the "Found 12 / 35" pill always agree. The Aliens grid is one list sorted companions first, then by tier, with no strips.

## 5. The goal card

The goal plate keeps its slot and its height ([[Clean-UI-Pass]] Goal: the ship bar `0.07` to `0.12`, the objective line under it `0.126` to `0.176`, 0.36 to 0.64 wide, growing only in width to `MaxWidth` 0.44 as now). It does not get a second row (at iPhone SE the line is already at the 22 px floor, and a bar under it would add about 12 px). The **objective plate becomes its own bar**, as the ship bar already is, and stays a plain flat card (principle 8; the dark trough colour and the blue fill, a thin navy edge, no cells beyond the fill's): the dark trough face fills left to right in Select blue under the grout (`Builder.blockBar`), the hint stays white outlined text over it, and the right end gains the **reward chip** beside the "1/3" counter chip:

- **Bar**: fill = counted progress over its count (a counted tutorial step: `State.GetTutorial()` counter over the step's `trigger.count`; a Field Notes step: the sum of `min(progress, count)` over the step's objectives divided by the sum of counts, from `State.GetQuests()`). An uncounted step is a full-height trough with no fill (no fake progress). A step change pops the plate and turns its face gold for `StepPopSeconds` 1.2 as now; the fill tweens (`Theme.Tween.Open`), none under Reduced Motion.
- **Reward chip**: a flat block, right of the counter, `0.2` of the plate's width: the reward's pixel icon (`RewardIcon.Key`) and "+300" in green outlined text, from the Field Notes step's first reward (`data/Quests`). The tutorial's steps pay nothing, so the chip is absent there (no invented reward). Width shares move in `data/Hud.Goal`: `TextShareCounter` 0.72 becomes `TextShareReward` 0.5 with a reward, `RewardShare` 0.2, `CounterShare` 0.17.
- **After the tutorial** the plate shows the current Field Notes step instead of vanishing (open question 1; Clean principle 5, "one goal at a time, always visible"): title string `FN_<stepId>_TITLE`, the bar and reward above. A finished step turns the face gold with "Claim" and a tap opens Quests (the red Menu badge already says so); a finished chain hides the plate for good. A tap on the plate otherwise opens Quests on Field Notes.
- Unchanged: the staged reveal, the plate hiding behind panels and captures, no sound, only the action button loops.

## 6. The arrival title card

**What shows** (`UI/ArrivalTitle.luau`, a `ScreenGui` at DisplayOrder 55, over the launch fade at 50, built once): the world's name screen-wide in Reveal size (48), white, outlined (`Builder.stroke`), `0.8` of the width at most (the size shrinks to fit, never wraps); under it a flat bar in the world's colour, `0.3` of the width, 3 cells thick; under that "NOW ARRIVING" (`ARRIVAL_NOW`, Label 24, `Heading` yellow, outlined). Behind them **speed lines**: 12 thin flat white blocks (1 cell tall, 8 to 18 cells long, heights and lengths from `BlockMath.Level` so they are the same each time, two thirds in the outer thirds of the screen) that streak inward from the left and right edges, each over `0.5` to `0.8` s staggered across the first `1.2` s, transparency 0.2 to 1. Axis-aligned, no rotation: the block look. Numbers in `data/Cinematics.Title`.

**Timeline**: in 0.25 s (the name grows from 1.15 to 1.0 and fades in, `Theme.Tween.Open`), hold 1.6 s, out 0.35 s (`Title.TotalSeconds` 2.4). During it `Toast.QuietFor(2.4)`, no new banner starts, and the world's own sky dim is skipped (Clean: one world dim at a time).

**Reduced Motion** (`Prefs.ReducedMotion()`): no speed lines, no scale; the card fades in over 0.2 s, holds 1.2 s (`Title.ReducedHoldSeconds`), fades out over 0.2 s.

**How it fits the flight.** Departure is unchanged: `LaunchSequence` and the `Flew` handler fade to black with "Next stop: <world>" and teleport. The card belongs to the destination place:
- **First visit** (the profile's `seen.Arrival_<n>` is unset, so `init.client` plays the `Arrival_<n>` moment): the card starts `Title.AtSeconds` 0.8 into the moment, the end of the open shot, so the speed lines run over the low, fast, blurred "Fly" shot (3 s, FOV 82, blur 0.85), and it is gone at 3.2 s, before the rise. The stinger `Arrival` already plays; the card adds none. The letterbox bars stay; the card sits between them. The crash landing in World 1's first visit has its own two crash lines and shows no title card.
- **Later arrivals** (no cinematic): the card plays once the loading screen hands over, only when the join came from another place of this game (`Players.LocalPlayer:GetJoinData().SourcePlaceId ~= nil`: a flight, not a website join or a rejoin), so a rejoin never says "now arriving". The HUD waits for it (`Hud.SetVisible(false)` as the cinematics do) and returns with no pop.
- The Home planet shows "Home Planet / Now arriving" the same way.

## 7. Work packages (three, disjoint files)

Every package: Luau strict, `./tools/analyze.sh` prints `analyze: clean`, `./tools/lint.sh` ends `vault: clean`, `./tools/test.sh` passes, Scale only, strings keyed, numbers in data, no key or secret anywhere. Shared files by anchor so merges do not touch the same lines: `src/shared/strings/en.luau` is append-only, own keys, each package directly after its anchor line (**A** after `TUT_PROGRESS = "%d/%d",`; **B** after `FLY_LINE = "Flying to %s...",`; **C** after `SHIP_ADD = "Add %s",`). `src/shared/data/Panels.luau`: A edits above the `-- Aliens footer` comment and C appends its own block directly above `return Panels`. `src/shared/data/PixelIcons.luau`: A adds `StarChart`, `Robux`, `Check` after `Lock`; B adds `Home` at the end of the `Icons` table. Playbook subsections, one each at its own anchor: **A** `### Richness pass: panels and the goal card (2026-10-26)` at the end of "Clean pass: panels (2026-10-22)"; **B** `### Richness pass: world cards and the arrival` at the end of "Star Chart (milestone 42a)"; **C** `### Richness pass: featured and grid` at the end of "Aliens screen footer and level chip (2026-10-06)". The day log and the Mac jobs in [[Overnight]] and `docs/TESTING.md` are the coordinator's at merge (as in Clean). **Merge order: A first** (B and C call its header API, fixed in section 2); B and C start in parallel from the contract and make the header call their last numbered change, after rebasing on A.

### Package A: panel anatomy and the goal card

**Owns.** `src/client/UI/Builder.luau`, `src/shared/Theme.luau`, `src/shared/data/Panels.luau` (above the footer block), `src/shared/PanelHeaderMath.luau` (new), `tests/PanelHeaderMath.spec.luau` (new), `src/shared/data/PixelIcons.luau` (its three icons), `tests/PixelIcons.spec.luau`, `src/client/UI/{QuestsScreen,GiftsScreen,PlaytimeScreen,SettingsScreen,MailScreen,VisitScreen,LeaderboardScreen,PeddlerScreen,ShopScreen}.luau` (header and body tint only), `src/client/UI/Hud.luau`, `src/client/UI/TutorialHint.luau`, `src/shared/data/Hud.luau`, `src/shared/HudStages.luau`, `tests/HudStages.spec.luau`, `tools/tests/test_block_theme.py`, its strings block and Playbook subsection.

1. `Theme`: `Colors.Robux`; `Block.Band` (the band's numbers). `data/Panels`: `Shell`, `Headers` (the 13 rows of section 2), `Roles`, `TierFrames`, `Strip`. Keep every existing key.
2. `Builder.panelHeader`, `sectionStrip`, `stamp`, `tierFrame`, `tint`, `roleColor` to the signatures above, frame counts per panel kept under the Playbook budget (`PanelQuiet.Frames` style test).
3. `PanelHeaderMath` (`Fit`, `Format`) with a spec: pills drop from the last, the title never wraps, SE and iPad widths.
4. Convert the nine screens above to `panelHeader` and the shell numbers; Quests tabs under the band; Settings headings become section strips; the Shop's Robux price buttons the `robux` role with the `Robux` icon.
5. Goal card: the objective plate as a bar, the reward chip, the Field Notes goal after the tutorial (section 5), `data/Hud.Goal` shares, the pure objective-fraction rule in `HudStages` with spec lines.
6. Playbook subsection, strings (`PILL_*`, `ROLE_*` words, `GOAL_CLAIM`), test list updates.

**Acceptance (Mac, Studio, default window, World 1).**
1. Open Quests, Gifts, Playtime, Settings, Mail, Ranks, Shop in turn (`screen_capture` to `rich-panel-<name>-default.png`). Pass: each has the full-width band with icon, title, its pills from the table and the X overlapping the right end; the body is faintly tinted toward the band colour; the Scrap pill stays clear above the band; nothing under 14 px.
2. Quests with a claimable step: "To claim 1" and "Field Notes n / 5" read the same numbers as the Menu badge and the tab; tabs sit under the band. Settings has no pills.
3. Shop: a Robux price is orange with the Robux mark, a Scrap price stays green; "Scrap" shows once, in the band.
4. A finished-tutorial profile at the camp, then `/tutorial 1`: the goal plate fills as `1/3` becomes `2/3` (`rich-goal-1-default.png`, `rich-goal-2-default.png`), no taller than `cleanA-hud-rest-default.png`'s; a Field Notes step shows its bar and "+800" reward after the tutorial; a finished step turns gold with "Claim" and opens Quests.
5. Reduced Motion on: the fill jumps, no pop. iPhone SE emulator: the pills drop from the last before the title wraps.

### Package B: world cards and the arrival title

**Owns.** `src/client/UI/StarChartScreen.luau`, `src/client/UI/ShipScreen.luau`, `src/client/UI/WorldCard.luau` (new), `src/client/UI/ArrivalTitle.luau` (new), `src/shared/data/WorldCards.luau` (new), `src/shared/WorldCardMath.luau` (new), `tests/WorldCardMath.spec.luau` (new), `src/shared/data/Cinematics.luau` (a `Title` block), `src/shared/data/Worlds.luau` (only if a field is needed; the card data is its own table), `src/client/init.client.luau` (the two `ArrivalTitle.Play` hooks only), `assets/sprites/worlds/World1.png` and `World2.png`, `src/shared/data/PixelIcons.luau` (`Home`), its strings block and Playbook subsection.

1. `data/WorldCards`: per world `{ color, palette = { sky, skyLow, far, ground, accent }, image = 0, unlockLineKey }`, `Row` 5, card aspect 2.2, scrim, the species-row size; `WorldCardMath.Roster` with a spec (Warden, weather species, tier order, ties, a world with none).
2. `WorldCard.Build`: the cell diorama, the image over it, scrim, badge, name, species row, border, HERE, TRAVEL, locked, soon, outpost chip and dot, compact form.
3. Star Chart: the card grid, selection, the outpost tray, the Home Visit button, the guest case, scroll to the current world, every old request and refresh kept; drop the orbit map code and its pulse.
4. Ship: the next stop strip above the footer.
5. Crop the two hero renders to `assets/sprites/worlds/` with PIL (ids stay 0; the upload is the uploader worker's).
6. `ArrivalTitle` and `data/Cinematics.Title` (name, bar, speed lines, timeline, Reduced Motion); the hooks in `init.client.luau`: first-visit offset into `playCinematic`, later arrivals by `SourcePlaceId`.
7. Header call (`panelHeader`, panels `StarChart` and `Ship`) last, after rebasing on A.

**Acceptance (Mac, Studio, default window, World 1 profile with World 2 unlocked, then a fresh profile).**
1. Open the Star Chart (`rich-starchart-default.png`). Pass: two columns of picture cards; Home first; World 1 "HERE" in grey with Check, World 2 a green TRAVEL, World 3 the next stop with a gold ink and NEXT, Worlds 4 to 7 "Opens soon"; names, number badges, the species rows (caught ones coloured, the rest "?"), counts and the header pills "Worlds 2 / 3" read right.
2. Tap TRAVEL on World 2: the same fade and "Flying to Frostbyte..." banner as before; tap a card with an outpost: the tray shows Lv, rate, ready Scrap and Collect and Upgrade, which behave as before.
3. A card with image id 0 shows the cell diorama in its palette, not an empty box.
4. Ship with all five modules done: the next stop strip shows World 2's card; a tap opens the Star Chart on it.
5. Fly to World 2 on a fresh profile (`/cinematic Arrival_2`, then a real teleport if the place is live): the title card with speed lines starts 0.8 s in and ends before the rise; capture `rich-arrival-default.png` at 1.5 s. A second flight (no cinematic) shows it after loading; a rejoin shows none.
6. Reduced Motion on: no speed lines, a 1.6 s fade. iPhone SE and iPad: the name fits one line at the width limit.

### Package C: featured plus grid

**Owns.** `src/client/UI/AliensScreen.luau`, `src/client/UI/CodexScreen.luau`, `src/client/UI/SpeciesThumb.luau`, `src/client/UI/FeaturedCard.luau` (new), `src/shared/FeaturedMath.luau` (new), `tests/FeaturedMath.spec.luau` (new), `src/shared/PanelQuiet.luau` and `tests/PanelQuiet.spec.luau`, `src/shared/data/Panels.luau` (its `Featured` block above `return Panels`), its strings block (the 35 `FLAVOUR_*` lines, `FLAVOUR_TIER_*`, button words) and Playbook subsection.

1. `FeaturedMath`: `Mode(panelPxW, panelPxH)`, `AliensDefault`, `Button(context)` (the table in section 4), `FlavourKey` with the tier fallback; spec every row.
2. `FeaturedCard`: the model view and plinth, tier tag, name, flavour, main and secondary button, refill on selection without rebuilding the view.
3. Aliens: the selected card, the featured card, the buttons moved off the tile tap, the three-column and five-column grids, the station strip kept, the footer row kept (`PanelQuiet.AliensFooter` re-fit), stamps (Companion, Riding) and tier frames from A.
4. Codex: the featured card replacing the detail card (turn kept), tier sections with strips and counts, "See in Aliens" (a public `AliensScreen.Select(speciesId)`), stamps and tier frames.
5. Strip mode at iPhone SE for both; the drawer fallback only if the Mac reports one grid row is too cramped.
6. Write the 35 flavour lines (one line each, cute, no fangs or threats).
7. Header call (`panelHeader`, panels `Aliens` and `Codex`) last, after rebasing on A.

**Acceptance (Mac, Studio, default window, World 1 profile with about 12 aliens).**
1. Aliens (`rich-aliens-default.png`). Pass: band with "Aliens 12 / 160" and "Companions 0 / 4"; the featured card left with a model, tier tag, name, one flavour line and a green FOLLOW; three columns of tiles with tier frames (a Rare shows its stud); the station strip on top.
2. Tap another tile: the featured card changes with no rebuild flash; FOLLOW makes the tile wear a green COMPANION stamp and the button turn grey "Stop following"; Ride shows only for a rideable species; a hold still opens Release.
3. Codex (`rich-codex-default.png`): "Found n / 35" and the page pill agree with the section counts; the featured card shows a caught species with "See in Aliens" (opens Aliens on it), an uncaught one with its hint and no button; no empty pane on open.
4. iPhone SE emulator: both screens switch to the strip, the strip's button is reachable (44 px), the Aliens grid shows one row and a peek.
5. Reduced Motion on: the Codex model stops turning; nothing else changes.

## Open questions for Ethan (defaults as written)

1. The goal plate keeps showing the next Field Notes step after the tutorial (Clean hid it for good). Default: yes.
2. The Star Chart's orbit map goes; world cards replace it. Default: yes; the planets' colours live on as the badges.
3. Aliens tiles select first and the featured button follows (one more tap than today). Default: yes.
4. Robux buttons turn orange (they were green in the Shop). Default: yes, with the Robux mark so it is never colour alone.

## Sources

[[Clean-UI-Pass]], [[UI-Playbook]] ("Block cells", "Clean pass: panels", "Clean pass: the HUD"), [[Decisions]] (B44, B45, B46, B52, B53), `media/tiktok/NOTES.md` Batch 10, `media/studio/2026-10-22/cleanC-*.png` and `cleanA-hud-rest-default.png`, `media/studio/2026-10-21/world1_hero_b46.jpg`.
