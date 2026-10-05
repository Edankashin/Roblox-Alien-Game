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
- Compass strip: a thin band along the top edge with cardinal letters in white outlined text, tick marks between them, the heading number in a small dark pill at the centre, and coloured diamond markers for the camp, the quest target, the Peddler and any live event. Under it, the nearest waypoint as "Camp 42m".
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
