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
- Every icon PNG carries a thick black stroke (about 6% of its width); a thin stroke next to a thick one reads as broken.
- Make icon sets with one image model from a screenshot of a reference shop, one style per game; never mix packs.
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
- Centre column under the strip: the ship bar, the luck line or event banner and the Friend Boost chip sit 0.046 of the screen height lower than before (ship bar top 0.071, banner top 0.151, Friend Boost chip top 0.226; `CENTER_SHIFT` in `Hud.luau`), the strip's height plus a gap. The Scrap pill, the clock chip, the round top buttons, the biome and shower chips and the menu stack did not move. Toasts stacking under the event banner start at 0.235, and the plain toast slot starts at 0.155, under the shifted ship bar. A radar-marked alien is one diamond, not two: the target marker yields to the waypoint when both point at the same spot.
- Verb markers: floating "✦ Collect" labels over nodes, white outlined text with a small glyph, visible from far away; the noun appears within nameplate distance.

## Radar minimap (Radar Mk1 and up; `src/client/UI/Radar.luau`)
- Where: right edge under the Meteor Shower chip, in the slot the free Nearby column otherwise starts in (right edge 0.985, top 0.225). A square holder 14% of the screen width, kept square by an aspect constraint, so its height follows the viewport. The free Nearby column hides while a radar is held (the blips carry the same caught/uncaught reading, placed; the column's remaining 0.14 of height would not fit its rows) and comes back if the tier ever reads 0. Hidden with the other HUD extras during a capture, a reveal or an open panel, and absent altogether until the server says a radar tier is held.
- Disc: a navy (`#1B1F3B`) circle with the 3 px outline stroke and the usual vertical gradient. The cardinal "N" sits at the top in white outlined Fredoka One (label size). The map is north-up and never rotates: world -Z is up, +X is right, and the tier's range is the disc radius.
- Range ring: a faint blue (`#68C9FE`, 60% transparent, text-stroke thickness) circle at half the radius with a small "60m" label on its top edge (half the range), so distances read at a glance.
- Player: a gold (`#FFC83D`) diamond at the centre with a small white dot on its tip; the whole marker turns to the camera's look yaw, so the dot shows which way the player faces while the map stays put.
- Alien blips: one round dot per wild alien within range, 10% of the disc, with an invisible tap area twice that. Caught species: filled in the tier colour with the navy outline. Uncaught species: the silhouette rule, a dark fill with the ring in the tier colour (white for a Secret, whose tier colour is near black). An alien the server reserved for this player (a trainee, the summoned Warden) gets a gold ring; one reserved for someone else is not drawn at all. Blips at the edge of the range are kept fully inside the disc.
- Camp and Peddler: a small cream (`#FFF4DC`) square for the ship and a gold diamond for the Peddler while it visits, both pinned to the rim when out of range so they point the way. Nothing else on Mk1; nodes and hidden spots come with Mk2.
- Tap to mark: tapping a blip clicks and hands the alien to the bootstrap, which sets the world waypoint on it ("Marked: Mossbop") and clears it on arrival. The client only draws: which radar is held, which aliens stand where and who may see them are the server's.

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
