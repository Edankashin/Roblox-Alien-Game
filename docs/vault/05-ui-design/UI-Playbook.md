# UI Playbook

The look, written to the level Claude can build from. Hex values here are the starting palette; the team's choices in PRE_PRODUCTION section 2 replace them. When a review corrects a panel, update this file in the same change.

## Font and text
- Fredoka One for all UI text; Builder Sans only for long settings text.
- Sizes: 14 minimum on mobile, 18 body, 24 labels, 36 titles, 48 reveal text.
- Any text over the world gets a UIStroke of 2 to 3 px, colour `#1B1F3B`.

## Palette (starting values)
| Role | Hex |
|---|---|
| Panel background (cream) | `#FFF4DC` |
| Outline and trough (navy) | `#1B1F3B` |
| Confirm / buy (green) | `#51DF51` |
| Close / alert (red) | `#FF4D4D` |
| Select / info (blue) | `#68C9FE` |
| Featured / premium (gold) | `#FFC83D` |
| Section heading text (yellow) | `#FFEF4A` with black stroke |
| Codex / rarity accent (purple) | `#A855F7` |

## Rarity colours (platform convention, each paired with a shape icon)
| Tier | Hex |
|---|---|
| Common | `#B0B0B0` |
| Uncommon | `#57F96C` |
| Rare | `#3B82F6` |
| Epic | `#C026D3` |
| Legendary | `#F59E0B` |
| Cosmic | animated rainbow gradient |
| Secret | `#111111` with rainbow stroke |

## Buttons
- Rounded rectangle, UICorner 12 px, vertical gradient lighter at the top, 3 px darker stroke, 4 to 6 px darker "lip" at the bottom.
- White text with dark stroke. Press scales to 0.92, hover on PC 1.05.
- Green = buy or confirm, red = close, blue = select, gold = featured.

## Panels
- Solid cream body, thick coloured border, UICorner 16 px.
- Header tab with the title in white outlined text.
- Close: red, square-ish, white X with black stroke, about 80% of the header height, top right, same place on every panel.
- At least 2% inner margin all round; nothing touches the frame. Body scrolls with a thin dark scrollbar on the right.
- Tabs down the left; the active tab is raised and brighter.

## Section headings
- "— FEATURED —", "— PASSES —": yellow text with black stroke, centred, about 7% of panel height; the dashes are part of the text.

## Icons (batch 4)
- The set: 128 px flat two-tone icons with a thick dark outline (about 6% of the width), modelled in Blender and rendered into `assets/icons` (the three weather particle sprites into `assets/particles`). One style for the whole game; never mix packs, and a thin outline next to a thick one reads as broken.
- Ids: each file name is its key in `src/shared/data/Icons.luau` (`Icons[key] = assetId`, 0 meaning not uploaded yet). `Aliases` map a data id whose icon has another key (Gear "Boots" uses `SpeedBoots`). `Particles` holds the weather sprites (Raindrop, Flake, Wisp).
- Use: `Builder.icon({ key = ..., parent = ..., position/size/anchor in Scale })` returns an ImageLabel (transparent background, `ScaleType` Fit), or nil with nothing created while the id is 0 or the key is unknown. `Builder.button` takes `icon = key`: once the id is uploaded the face shows the icon centred at 0.7 of its size (`BUTTON_ICON_SCALE`) and no text, and the icon presses with the face.
- Fallback: with an id of 0 every spot shows what it showed before the pack: the `MENU_GLYPH_<id>` letter on a button face, the gold square on the Scrap pill, the purple square on the event banner, Roblox's default particle in the weather. The game must always run with any id at 0, so never build a layout that needs the image.
- Where they show: the left menu stack (Shop, Aliens, Codex, Ship, Quests, Gifts) and the round top buttons (Settings, Ranks), both keyed by the menu id; the Scrap pill's square (`Scrap`); the event banner's square (`Hud.SetEventBanner`'s fourth argument, e.g. `Shower`; the server luck banner has none yet); the weather sprites (`texture` in `data/Weather.luau`, read by `WeatherFx`). Where an icon fills a backing square, the square and its outline go transparent while the image shows, since the icon carries its own outline.
- Shop layout: large tiles for bundles and the biggest purchases, small tiles for singles.

## Cards
- Square, rarity-coloured gradient background, item rendered large, name underneath, small stat chips, diagonal "NEW!" ribbon, "x3" count badge bottom right.
- Uncaught: dark silhouette plus a small lock.

## Bars and counters
- Pill-shaped bars, dark trough, gradient fill, highlight sweep every 2 s, white outlined text centred, tick marks at milestones.
- Counters roll digits; gains fly from the source as "+25".

## Toasts and reveals
- Toasts top centre, slide down with a small bounce, icon left, gone in 2.5 s, at most three stacked.
- Reveal: backdrop dims 60%, scale in with Back ease, radial burst behind, tier name in its colour, confetti for Epic and above, "Tap anywhere".

## Event banner and compass (reference: `refs/dino-event-banner.jpg`)
- Event banner: top centre under the compass strip, a dark navy pill with the outline colour, aspect about 5:1. Event icon in a rounded square on the left, event name in bold white outlined text with the time left ("3:39 left") in smaller text beneath it, and a green (`#51DF51`) pill chip on the right reading "1.5x LUCK" whenever the event changes luck. Same slot for the Meteor Shower countdown and weather events; never more than one banner.
- Compass strip (`src/client/UI/Compass.luau`, numbers in `src/shared/data/Compass.luau`): its own ScreenGui at the HUD's layer (10). A thin navy (`Trough`) pill with the outline stroke and the usual gradient, top centre: 38% of the screen width (clear of the round top buttons at 4:3), 4% of its height (about 15 px on a phone in landscape, so the 14 px minimum text fits), its top at 0.006 (so it ends at 0.046). The cardinal letters N, E, S, W (white outlined, minimum text size) and tick marks every 15 degrees (short white frames, taller every 45) slide along it as the camera turns; north is world -Z, east +X, clockwise, the same as the Radar's player marker, taken from the camera's look yaw. A thing `delta` degrees from the heading sits at `0.5 + delta / 180` across the band and is hidden beyond 90 degrees either side; within 15% of either end it fades up to 60% transparent. A small dark pill at the centre (the Trough darkened, outline stroke) reads the heading in whole degrees ("270°", 0 to 359); it covers the letters and ticks behind it, but diamonds draw over it so a marker dead ahead is never hidden. Refreshed 20 times a second, and only while shown (it hides with the tutorial hint: capture, reveal, an open panel or the opening cinematic).
- Compass diamonds: a square turned 45 degrees with the outline stroke, 55% of the band's height, one per data marker, coloured by kind: the waypoint (tutorial or Field Notes marker, or an alien marked from the radar by name) and the Peddler gold (`Featured`), the radar target blue (`Select`), the camp green (`Confirm`), the shrine orange (`Legendary`), the cave mouths purple (`Codex`), the Great Vent red (`Close`). A marker shows only while the player is at least its minimum distance away (so it is not in your face), and the lowest priority number draws on top where two overlap (the waypoint over the radar target on the same alien).
- Compass line: under the band, one line in white outlined minimum-size text, "Camp 42m": the name and the flat distance in studs, floored. It names the marker on the strip with the lowest priority number (waypoint, then target, Peddler, camp, shrine, caves, vent), the nearest of equals, using the waypoint's own label when that is the marker. It keeps its marker half a second before switching, so two at similar distance do not flicker, and switches at once when its marker leaves the strip; with nothing on the strip the line is hidden.
- Centre column under the strip: the ship bar, the luck line or event banner and the Friend Boost chip sit 0.046 of the screen height lower than before (ship bar top 0.071, banner top 0.151, Friend Boost chip top 0.226; `CENTER_SHIFT` in `Hud.luau`), the strip's height plus a gap. The Scrap pill, the clock chip, the round top buttons, the biome and shower chips and the menu stack did not move. Toasts start at 0.29 in both states, under the whole centre column (the Friend Boost chip is always shown and ends at 0.281); a toast higher than that covered the chip. A radar-marked alien is one diamond, not two: the target marker yields to the waypoint when both point at the same spot.
- Verb markers: floating "✦ Collect" labels over nodes, white outlined text with a small glyph, visible from far away; the noun appears within nameplate distance.

## Radar minimap (Radar Mk1 and up; `src/client/UI/Radar.luau`)
- Where: right edge under the Meteor Shower chip, in the slot the free Nearby column otherwise starts in (right edge 0.985, top 0.225). A square holder 14% of the screen width, kept square by an aspect constraint, so its height follows the viewport. The free Nearby column hides while a radar is held (the blips carry the same caught/uncaught reading, placed; the column's remaining 0.14 of height would not fit its rows) and comes back if the tier ever reads 0. Hidden with the other HUD extras during a capture, a reveal or an open panel, and absent altogether until the server says a radar tier is held.
- Disc: a navy (`#1B1F3B`) circle with the 3 px outline stroke and the usual vertical gradient. The cardinal "N" sits at the top in white outlined Fredoka One (label size). The map is north-up and never rotates: world -Z is up, +X is right, and the tier's range is the disc radius.
- Range ring: a faint blue (`#68C9FE`, 60% transparent, text-stroke thickness) circle at half the radius with a small "60m" label on its top edge (half the range), so distances read at a glance.
- Player: a gold (`#FFC83D`) diamond at the centre with a small white dot on its tip; the whole marker turns to the camera's look yaw, so the dot shows which way the player faces while the map stays put.
- Alien blips: one round dot per wild alien within range, 10% of the disc, with an invisible tap area twice that. Caught species: filled in the tier colour with the navy outline. Uncaught species: the silhouette rule, a dark fill with the ring in the tier colour. A Secret-tier alien is never a blip (see Radar Mk2 below): Mk1 draws nothing for it. An alien the server reserved for this player (a trainee, the summoned Warden) gets a gold ring; one reserved for someone else is not drawn at all. Blips at the edge of the range are kept fully inside the disc.
- Camp and Peddler: a small cream (`#FFF4DC`) square for the ship and a gold diamond for the Peddler while it visits, both pinned to the rim when out of range so they point the way. Nothing else on Mk1; nodes and hidden spots come with Mk2.
- Tap to mark: tapping a blip clicks and hands the alien to the bootstrap, which sets the world waypoint on it ("Marked: Mossbop") and clears it on arrival. The client only draws: which radar is held, which aliens stand where and who may see them are the server's.
- Radar Mk2 (`Radar.Mk2` in `data/Radar`, held when `gear.radar >= Mk2.Tier`): a Secret-tier alien in range is a "???" ping, not a blip: a dark disc 32% of the radar disc with a white ring (gold if reserved for you) and white outlined "???" at the minimum size, tappable like a blip. Mk1 draws nothing for a secret. While a ping is on the disc a heartbeat plays and every ping swells to `SecretPulseScale` and back within the beat, every `SecretPingFarSeconds` at the full range down to `SecretPingNearSeconds` at `SecretNearStuds` or closer (linear in the nearest secret's distance); no secret in range, no sound. From Mk2 the Nearby column comes back under the disc (its top follows the disc's bottom edge, its bottom stays put) as a compact "not now" list, shown only while the disc shows: for this biome's species of tier `AbsentMinTier` and up listed under a condition not active now (uncaught first, then higher tier), up to `AbsentRows`, each row two lines of minimum-size text with no icon, left-aligned and outlined, the name and under it the condition in the Select blue ("in the rain"). A row needs two 14 px lines (1.25 line height) in pixels, so the list shows as many as fit, one at iPhone SE size and three on an iPad, and with nothing absent or no room the whole column hides. (Where the column sits at its default top at Mk2 it lists the species that are out, then dimmed rows with a small icon, but the bootstrap does not show it there.) The Shop's Gear tab gets a Radar Mk2 row after Mk1 (grey, "Unlocks with World 2", until a second world is unlocked and Mk1 held); five rows no longer fit, so that tab scrolls with the thin dark bar like the Robux page.

## Featured banner
- Full width, aspect about 2.6:1, illustrated background themed to the item, darkened, timer and odds visible.

## What to avoid
- Default grey Roblox buttons, Source Sans, Inter or Montserrat, glass or blur panels, outline-free card grids, emoji icons, gradient text, silence on tap.

## Layers and banners (2026-10-05)

Display orders: HUD 10, tutorial hint 15, modal panels 20, the notifications ask card 45, toasts and server-wide banners 40, the launch fade 50. Toasts stay above panels because refusals from inside a panel must show. A wide banner (rare catch, Peddler landing) would cover a panel's header, so while any panel is open a banner slides up from the bottom edge instead of the top stack; with no panel open it stacks at the top as before. The toast stack itself starts lower while a panel is open.

## Input fields and hints (2026-10-05)

A text box is navy Fredoka on the cream panel colour with the outline border stroke only, no text stroke, placeholder in the Common grey. A hint line under a panel's rows is Fredoka too, navy, no stroke: the outlined white style is for titles and anything drawn over the world, never for fields or helper text.

## Grids inside scrolling frames (2026-10-05)

A UIGridLayout cell with a Scale height inside a ScrollingFrame resolves against the canvas, and the canvas grows to hold the grid's content, so the two feed back until the canvas is three pages tall and one card sits 150 px down. Inside a ScrollingFrame the cell height is therefore derived in pixels from the frame's width on every resize (the one place a pixel value is set), width and padding stay Scale, and the canvas is set to the page count from the row count. The Scale-only rule still holds for positions and sizes everywhere else.

## Capture bar variants (2026-10-05)

A variant (data/CatchVariants) changes how the one timing bar behaves, never how it is built. The drifting zone moves its centre along the bar with the shared sine from the server's phase while its widths stay put, and it freezes where the tap was scored while the verdict shows, so the player sees exactly what they hit.
The reel is hold and release: pressing starts the hold, the hint swaps to the held line ("Reeling... let go!") and the ticker pops; letting go is the tap.
The chase adds a countdown chip above the bar's right end, mirroring the lure chip on the left: Trough pill, white outlined text, turning red and popping once a second for the last three seconds.
Zone and ticker colours come from the variant row's Theme keys (Select and Featured for the reel, Confirm and Featured for the chase), so no new colours were added; the Standard bar looks as it always did.

## Alien card chips (2026-10-06)

A chip on the alien card is 0.38 of the card wide, with its text at 0.9 of that: the minimum text size is 14 px and an iPhone SE card is about 115 px, so anything narrower clips a five-letter word ("Elder" became "Elde" at 0.26). The chips sit in a row on the shape square's lower edge (shape at y 0.38, 0.36 wide; chips at y 0.59), below the shape's label, so neither covers it. A chip never holds more than five characters: the growth countdown shows whole hours or whole minutes ("2h", "59m"), never both.
Every text row on a square card is one line at the minimum size: a 0.17-tall slot is about 22 px, which holds one 14 px line, not two, so "gathering at the Picnic Table" clipped to its first line. The status is therefore the station's name alone ("Picnic Table"), and the countdown lives in the chip, never a third row.
A panel that opens by itself is its own message: a toast before it covered the header and a banner after it covered the bottom row, so the gift pop opens the Gifts screen with nothing over it.

## Visual quality bar (2026-10-06)

The target look is the top Roblox sims (Pet Simulator 99, Adopt Me):
- Rendered glossy icons, each with an outline and a soft shadow, never flat glyphs.
- Bevelled 9-slice plates for panels, buttons and pills (to come, with the art pass).
- A gloss band on every button and chip: a white highlight across the top half of the face that fades out downward.
- An inner shadow at the bottom of every panel, so the plate reads as having thickness.
- A shine sweep on the one featured button per screen, never on two at once.
- Saturated two-tone colours (the lighter top of the gradient over the base colour), outlined Fredoka text, no blur and no glass.

What this change added, in code only (`src/shared/Theme.luau` `Theme.Gloss` holds every number, `src/client/UI/Builder.luau` the helpers):
- `Builder.gloss(target, corner?)` adds the "Gloss" highlight band (top `Theme.Gloss.Top` of the target, corners matching the target's). It is non-interactive and a child of the target, so it presses and scales with it. `Builder.button` calls it on every face automatically; `Builder.frame` and `Builder.pill` do it only when `gloss = true` is passed, because they are also plain containers. Children of a glossed frame need a ZIndex of the frame's plus 2 or more, or the highlight washes over them (a button's icon already is).
- `Builder.innerShadow(target)` adds the "InnerShadow" band across the bottom `Theme.Gloss.Shadow` of the target. Nothing uses it yet: each panel adopts it in its own change.
- `Builder.shine(target)` sweeps a diagonal white band across the target every few seconds inside a "ShineClip" frame, and returns a function that stops it. It does nothing under Reduced Motion. Nothing uses it yet: give it to the Face of the featured button when a screen adopts it.
- The gradient carries the transparency of all three bands (their frames stay opaque white or black underneath), because a UIGradient combines with the frame's own transparency and setting both would count it twice. Tune the look in `Theme.Gloss`, not in the helpers.

Still waiting on assets: the rendered icon pack (the Icons table keeps text glyphs until ids are uploaded), the 9-slice plate images that replace the flat rounded rectangles, and the bevel and rim-light baked into them. The gloss and inner shadow stay as code overlays on top of the plates; the shine stays code.

## Aliens screen footer and level chip (2026-10-06)

The footer holds two buttons, Fuse (Featured) left of Optimize (Select), each 0.24 of the panel wide and 0.075 tall, with a one-line grey hint under them in the minimum size ("4 spare copies of a species fuse into +1 level (up to Lv 3)"); the card grid ends above them. A fused copy shows a gold "Lv N" chip top-left of its card, the speed chip's size; when an overlay badge already sits there the level chip goes directly under the badge.
Companions (milestone 36). The count row now has two halves: "N aliens" at the left and "Companions 2/3" (followers over slots) right-aligned at the right. Under it, at y 0.50, a one-line perks line in the minimum size, left-aligned: green outlined text ("Perks: +10% catch Scrap, +15% zone") while any perk is active, grey "Perks: none yet" otherwise. It lists catch Scrap, zone, luck, radar in that order and skips zero kinds. Measured in Fredoka at 14 px, three perks are about 310 px and fit the line (the panel's 0.96 width is about 520 px at the reference SE size and 380 px on a 667x375 screen); all four are about 390 px and only fit the wider one. The grid moved down to y 0.545 and still ends at 0.845, so a row of square cards fits above the button row.
A card's status line has three states: the station's name in white for a seated alien, "Following" in green for a follower, "Tap to follow" in grey for a resting one; followers sort to the front. Every status is one line at the minimum size, so check a new string against the card's label (about 107 px at the reference SE size: "Following" is 93 px, "Tap to follow" is 147 px and wraps). Tapping a card asks the server to follow or stop and plays the click; a seated alien or a full set of slots only shows a grey toast and sends nothing. The card never changes from the tap: it redraws when the server's companion push arrives.
The Companion Token button is Select blue, Fuse's height and 0.30 of the panel wide, directly left of Fuse in the footer row, and is only there while a token is held; its label carries the count ("Use Companion Token (2)") and wraps to two lines at that width on a phone, so widen it before adding words. Toasts: green when an alien starts following and when a slot unlocks, grey for an alien staying at camp, a seated alien and full slots.
Ride button (milestone 37). A following alien whose species can be ridden (`ride` on its Species row) shows a chunky button in the status slot, replacing the status label (same place, 0.94 of the card wide, y 0.80, 0.14 tall): gold "Ride", or Select blue "Hop off" on the ridden card, whose "Riding" status is implied by "Hop off". It is a sibling above the invisible Tap overlay (ZIndex 9 over 8), so its tap never reaches the card; a resting mount shows none until it follows. The other cards keep three statuses: the station's name in white (seated), "Following" in green, "Tap to follow" in grey. The ridden card sorts first, then followers. A tap on the ridden card hops off (grey toast "You hop off ..."); the next tap, on a plain follower, unfollows. The slot is the full card width, so "Hop off" (49.5 px at 14 px, Fredoka metrics) fits one line on the 115 px reference card (108 px of button) and on a 78 px card (73 px). An earlier version put the button under the speed chip (0.48 wide): there "Hop off" wrapped at 78 px and the button covered the shape, so keep it in the status slot.

## Weekly drop (milestone 38)

The Alien of the Week takes the event banner's slot with the lowest priority: a shower, then a Catch Rush, then a bought server luck all win it, and the tutorial hold keeps it off like the rest. The name is the title ("Alien of the Week: Panpipe"), the subtitle the time left in days and hours ("5d 3h left", refreshed every second by the banner poll and on each clock push), and the green chip names the week's weather ("Aurora week"), hidden for a week with the usual sky. A Codex-purple banner toast says it once at join, after the server's answer gives the week, and again on every flip it pushes. In the Codex each card carries a stamp in its top-left corner: "This week" in `Featured` for the current species, "Vaulted" in the grey `Common` for a limited species out of its week, nothing otherwise. It is an outlined label at the minimum size, 0.84 of the card wide and 0.2 tall at x 0.06, y 0.03, ZIndex 7 (over the square and its mark, under the tap button), and it never meets the count badge, which sits 0.48 to 0.64 down the right side. The detail card's first line follows suit for an uncaught alien: "Alien of the Week: 5d 3h left", or "Vaulted: back in a later week"; a caught one keeps its found line. "This week" is the longest stamp text and is close to the narrowest card's width (about 74 px), so check it at iPhone SE size and widen the stamp before adding words.

## Star Chart (milestone 42a)

The Home planet is one more planet at the map's centre (0.11 of the map square, a touch under a ring planet), over the star and inside the innermost ring, with no ring and no number; it takes the ring planets' looks (green and pulsing when you are there, blue when unlocked, faint grey when locked, never the next stop) and never shows an outpost chip or dot. Its card has two states: locked it reads "Home" with "Launch once to unlock your home" and no buttons, unlocked it reads "Home Planet" with "Your own planet. The ship and the stations work here too." and the Fly button, and never Collect or Upgrade; its line takes the room the outpost rows use on a world's card because the text is long.

## Build tray (milestone 42b)

The house grid's Build screen (`src/client/UI/BuildScreen.luau`, registered as "Build", opened by the "Decorate" action beside the plot) is a tray along the bottom edge, not a centre panel, because the player has to see the plot to place on it: 0.9 of the screen wide, 0.32 tall, anchored bottom centre with the usual 2% gap under it, at the modal layer (20), with no backdrop dimming the world. The tray plate sinks input (`Active`), so a tap on it never reaches the world. Inside it (fractions of the tray): a blue title tab ("Decorate") straddling the top edge, 0.2 wide and 0.2 tall; two rows of cards at y 0.11 and 0.40, each 0.27 tall (about 32 px at iPhone SE height: a card holds two 14 px lines, the name over the price, so do not add a third); a cap line at each row's left, 0.18 wide, in navy with no outline ("Rooms: 1/4", turning red when full; "Things: 12/12" wraps to two lines there, which still fits); the cards in the 0.22 to 0.98 span on a five-slot grid shared by both rows (the Rooms row fills three, its right side stays empty), 0.012 apart; and a footer at y 0.70, 0.26 tall: the hint line left (0.45 wide, navy, no outline, wraps to two lines), then Turn (Select blue, grey until an item is picked), Take away (gold, red while remove mode is on) and Done (green) at x 0.50, 0.65 and 0.85, 0.14, 0.19 and 0.13 wide.
A card is tinted with its item's placeholder colour with the usual gradient and white outlined text; it goes the Common grey while the Scrap is short (still tappable: the server answers with the toast), and the picked card wears a thick gold border. The cards, the rows and the footer all stay inside the 2% margin; check the tray at iPhone SE and iPad sizes before changing a number, since the SE row is the tightest thing in it.
The world half: the first tap on a cell only moves the ghost there (the item's placeholder at half transparency, so the player sees it before paying); a tap on the ghost places it, and the ghost goes once the item stands. A touch counts as a tap only through the engine's `TouchTapInWorld`, so dragging the camera round the plot never previews or places; a click counts on press. The tap is a ray against the plot and the ghost, or with Take away on the plot and the placed items, so a tap on the body of a tall item finds that item.
