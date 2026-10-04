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

## Featured banner
- Full width, aspect about 2.6:1, illustrated background themed to the item, darkened, timer and odds visible.

## What to avoid
- Default grey Roblox buttons, Source Sans, Inter or Montserrat, glass or blur panels, outline-free card grids, emoji icons, gradient text, silence on tap.
