---
tags: [ui-design, claude-design, workflow]
aliases: [Claude Design brief, Design canvas]
up: "[[UI-Design]]"
---
# Claude Design brief

How the team uses Claude Design: a review surface drawn before code, never a source of shipped assets. Decision: [[Decisions]] B30. Source: the [report](../../../reports/Roblox%20creature%20UI%20and%20Claude%20workflows.md), section "Claude Design draws the review; Blender and Luau ship it". Back to [[UI-Design]].

**The canvas (2026-10-15):** [Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4): the HUD at 844x390 and 1080x810, Aliens, Shop, the reveal in three beats, a species sheet, thumbnail comps, tokens. Ethan picks; nothing on it ships until a worker rebuilds it in Luau.

## What it is for

The in-chat Design canvas is a set of artboards (each a self-contained HTML page) that export as PNG or PDF. That is enough for five review jobs. Sizes are ours: the product default is a portrait 390x844 phone, and this game plays in landscape.

| Job | Claude Design draws | Blender and Luau ship |
|---|---|---|
| UI screens | mockups at 844x390 (phone) and 1080x810 (tablet), two or three options per screen; the picked PNGs go to the refs folder ([[05-ui-design/refs/README]]) | the screen from `Builder` and `Theme`, Scale only |
| Species concept sheet | name, concept, hero feature, the goofy thing, palette hexes, a greyscale silhouette strip (the design doc's legibility check), tier overlay notes, laid over the uploaded Blender turnarounds | the turnaround (`look` angles, `preview.py`), the mesh from the fuse pass ([[Character-Pipeline]]), the data row |
| Icons and 9-slice plates | a review board: a contact sheet beside top-game icons at the same pixel size | the rendered icon from Blender, the id table |
| Thumbnails and game icon | 1920x1080 comps from uploaded renders, with the bottom-band guide ([[Thumbnail-Research]]) | the renders (`store_renders.py`), `store_compose.py` |
| Hatch timing | an interactive prototype with sliders for durations and easing | `TweenService` from the numbers, which go to a table under `src/shared/data` (the day-7 Epic egg first) |

## What it is not for

- **Shipped meshes.** The 3D mode (star ratings, GLB download) lives only in the standalone app. What the creators got from it was a grey, many-part, menacing creature rescued by glow and rings, with no animation in the file; our roster must stay cute, one skin.
- **Shipped UI.** The Luau builder with Scale sizing is the only UI source. Never rebuild from an artboard's HTML.
- **Raster icons, textures, sprites.** Claude draws HTML and SVG, not paintings; the bar is a rendered Blender icon.
- **Animation export.** The GLB carries none; motion is tweens from a data table.
- **The source of truth for tokens.** `Theme.luau` stays the truth; any design-system block for `/design` is a copy regenerated when Theme changes.
- **Anything started in the standalone app.** It closes on 2026-12-14. Design systems migrate, projects do not; chats are deleted, comments are not carried over and public links to standalone projects stop working. Export PNGs into the repo as you go so nothing lives only on claude.ai.

## Workflow

1. **Brief.** Every Design session starts from the same written brief; this note plus [[UI-Playbook]] (with its phone rules) is it. Paste at the top: the game in two lines (crash-land, catch cute aliens with a timing bar, they build a ship, it flies to the next world); one currency, Scrap; Fredoka One from Google Fonts (the only external load a canvas allows), outlined text, gloss bands in CSS, thick outlined buttons, standard rarity colours, no glass, no blur; the sizes above; the Theme hexes from the Playbook; what Ethan rated well so far.
2. **Draw.** In chat, or from Claude Code with `/design [brief]`. Two or three options per screen, the screens Ethan rejected first.
3. **Ethan picks** a board per screen and rates each output.
4. **Rebuild.** A worker rebuilds the chosen screen in Luau from the artboard and the token table, one screen per change, claimed on [[Board]]. Numbers in `src/shared/data`, strings in `src/shared/strings`.
5. **Playbook.** [[UI-Playbook]] is updated in the same change (CLAUDE.md rule); then the four-check device pass.
6. **Log** it in `docs/vault/08-log/` and link the note.

## Prompt patterns

From the creators the report follows (lihfolk, vos_studiostt), under our rules:

- Open: "Before drawing, ask every question you need about the content of the screen."
- Order: the context script, the screen or species request "with the previous details in mind", a reference image with an explicit line about which part to copy, then a second prompt as a numbered list of deltas, then a rating per output. The last two are what the creator credits for "a thousand times better".
- Second pass: "Change only these: 1 ... 2 ... keep everything else exactly as in the current artboard. From the reference image copy only the ear shape, nothing of its colours."
- Species sheets: upload the clay turnarounds from Blender; ask for the greyscale silhouette strip and the hero feature, and keep the goofy eyes and open mouth.
- Long single chats rot (the creators' "handoff document" is that workaround): start a new session per board with the brief pasted.
- Budget: Design shares Claude's usage limits, and full designs cost more than a typical message (lihfolk: ten generated enemies took about 30% of the allowance). Do the HUD, Aliens, Shop and reveal first, not everything.

## Open

- On the Mac: `claude --version` meets v2.1.265 (the commands reference; an older digest says v2.1.234) and `/design` appears while signed in. Then [[Tools-Status]] says so.
- A short design-system block that `/design` reads (Claude Code artifacts treat it as higher precedence than their own choices): a `Design-Tokens.md` pointing at `Theme.luau`, not written yet; CLAUDE.md stays short. `/design-sync` is for React design systems and does not apply to Luau.
- Claude Motion (MP4) is beta on Team and Enterprise only; not used.

Related: [[Sculpt-Pass]] (what the species sheet feeds), [[Decisions]], [[Tools-Status]].
