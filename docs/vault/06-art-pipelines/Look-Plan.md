---
tags: [art-pipelines, plan, pipeline]
aliases: [Look plan]
up: "[[Art-Pipelines]]"
---
# Look plan: how the game gets its final look

The mechanics are in and testable with placeholders. This is the plan for the look: what changes, in what order, with which tools, and what each pass costs. It follows the reference-video lessons in `media/tiktok/NOTES.md` (one bold colour per thing, silhouettes that read at thumbnail size, lighting does half the work, chunky outlined UI) and the design's art direction in `docs/GAME_DESIGN.md` section 15 and 16.

## Where the look stands (2026-10-05)

**Order change (2026-10-06, Ethan):** the replication of the top games' look (icons v2, soft sprites, 9-slice plates, texture passes, world dressing) is the last pass, after every mechanism is in, polished and Studio-tested, and it is done together with Ethan's collaborator in Studio (Team Create) so the designs stay unique. Until then the visual work is limited to what the code already supports with fallbacks (gloss, auras, sprite slots at id 0). The sections below keep their content; their order of execution is: mechanics polish first.

| Layer | Now | Target |
|---|---|---|
| Worlds | flat floor, coloured patches, part scatter; 16 generated props ready to import | lit, dressed, textured ground, hero landmarks, weather with particles |
| Creatures | 32 procedural blockouts (one mesh, flat colours, no rig) | 32 stylised models with idle, walk, work and reveal animations |
| Camp and ship | blocks and ghost modules; hull and station meshes ready to import | modular ship pieces that visibly assemble, lit stations, worker animations |
| UI | code-built from Theme and Builder, Fredoka, outlined; no icons, no image assets | icon pack, 9-slice panels and buttons, rarity frames, animated transitions |
| Store page | nothing | icon, three thumbnails, a 30 s video, a tested name |

## Principles that decide every pass

1. **Readable at thumbnail size.** Every alien, prop and icon passes the greyscale-at-256 px check before colour is discussed (`tools/blender/preview.py`).
2. **Flat colour, strong shape, soft light.** Low-poly meshes with one flat material per colour, no textures on creatures, lighting and post-processing supply the depth (the Pet Simulator and Adopt Me look). Textures only on ground and large surfaces. (Revised 2026-10-14 after Ethan's review of the World 1 bodies, "They don't have any texture to them": creatures get a surface pass, [[Surface-Pass]]: a Roblox material per slot, smooth bevelled bodies with a vertex gradient, glossy eyes and, once uploaded, shared texture sets. Flat colour and soft light stay the base.)
3. **Phones first.** Every effect has a budget: Realistic lighting with at most two shadow-casting lights per world, particles under 200 on screen, meshes under 1,500 triangles per alien and 600 per prop. Check on an iPhone SE in the emulator before calling anything done.
4. **Data, not scenes.** Lighting, colour grades, skyboxes and weather looks live in data tables (`src/shared/data`) and are applied by code, so a world's look is one table and a weather change is one tween.
5. **One pass at a time, reviewed on the Mac.** Each pass is a milestone with a test script, screenshots at iPhone SE and iPad sizes, and a line in the UI Playbook or the art pages when a review corrects something.

## The passes, in order

Core-loop milestones come first (19 group reward and rejoin nudges, 20 global leaderboard). The look passes start after those, cheapest and widest first.

### L1. Lighting and atmosphere per world (one milestone, mostly code) — done as milestone 22 (2026-10-05), verified in Studio on both places

- `data/Lighting.luau`: per world a sky (six skybox ids), Atmosphere (density, haze, colour, glare), ColorCorrection (tint, contrast, saturation), Bloom, SunRays, ambient and outdoor ambient, clock time range, and a per-weather override (Rain darker and bluer, Blizzard white and dense, Shower a warm night with extra bloom).
- `client/World/LightingDirector.luau` applies the table on join and tweens between weather looks over `Config.LightingTweenSeconds`; respects Reduced Motion by snapping.
- `LightingStyle` Realistic plus `PrioritizeLightingQuality` true (the deprecated `Technology` Future stays as the fallback for older clients; see [[Lighting-Style]]), shadows on for the sun only, `GlobalShadows` true, no point-light shadows. One free Poly Haven HDRI per world for the sky reference, skyboxes generated as six images.
- Cost: one Sonnet worker and a Mac screenshot review. This pass lifts every screenshot the most for the least spend, so it goes first.

### L2. Ground and water (one milestone)

- Floors become Terrain (grass, snow, sand per biome patch) painted by a build script run once in Studio through MCP, or stay parts with MaterialService custom materials (a PBR set per world) when terrain costs too much on phones. Decide by measuring on the SE: terrain is the goal, materials the fallback.
- A water plane where a world has one (Tidepool later). Patch edges get a soft blend (a second ring part with a gradient texture) so biomes stop looking like discs.

### L3. World dressing and hero landmarks (one milestone per world) — weather particles done as milestone 24 (2026-10-05); five hero set pieces modelled (`tools/blender/heroes_base.py`, renders in `05-ui-design/refs/look-l3/`) and placed from layout data as milestone 29 (2026-10-06); the 16 scenery props had their look pass (88ce665, 4d53289: 300 to 900 triangles, renders in `refs/look-l3/props/`); drops and flakes wait on the L5 textures

- Import the 16 props (`Map-Dressing.md`), then paint extra scatter with Brushtool 2, rows with Redupe, curves with Archimedes. Hand dressing lives in the place file.
- Hero pieces modelled in Blender through MCP or generated: the crash site wreck, the shrine, the cave mouth, the geyser field vents, the ship hull per world. Each has a notes line in `Blender-MCP.md`.
- Particles: catch burst and reveal sparkle (exist), weather (rain, snow, ash), shower meteors, geyser steam, heater warmth ring. Budgeted per the SE check.

### L4. Creatures (the big spend, in batches of eight) — first look pass done for all 32 species (batches 1 to 4, 2026-10-05 to 06, renders in `05-ui-design/refs/look-l1/*-v2.png`); the colour re-upload waits on Ethan

- Pipeline in `Creature-Generation.md`: commons first, greyscale check, one accessory, one bold colour. Tools in order of cost: Blender through MCP from the blockout (free, Claude does the shaping), Meshy or 3D AI Studio for a textured rigged model with a target polygon count (paid, fastest), hand touch-ups in Blender.
- Each model keeps its blockout's folder, file names and height, so it drops into the renderers unchanged (`import-model` skill). Four animations each (idle, walk, work-at-station, catch-reveal) as one animation set per body type, retargeted, so 32 species need about six rigs, not 32.
- Review per batch: a sheet of eight silhouettes and eight colour renders from `preview.py`, approved before the next batch.
- Since 2026-10-14 the creature passes have their own notes: [[Silhouette-Pass]] (a recipe and a body plan per species, all 32 built), [[Surface-Pass]] (a material per slot, smooth bevelled bodies, texture sets once uploaded), [[Character-Pipeline]] (2026-10-15: fuse the recipe volumes into one skin, three ship checks) and the display names in [[Species-Names]].

### L5. UI and GUI (one milestone) — the Star Chart orbit map done (2026-10-05); the compass strip built as milestone 30 (2026-10-06); the flat icon set and sprites rendered (`tools/blender/icons.py`); v2 (2026-10-06, Ethan's bar: the top sims' look) renders them shaded and glossy in Eevee with bevels, rim light, outline and a drop shadow, adds the soft sprite set (Glow, Sparkle, Star, Ring, Shine, Confetti, Ember) and 9-slice plates (`tools/blender/ui_plates.py`, `assets/ui/`); Builder gains gloss, inner shadow and shine; the VFX pass uses the sprites; uploads with the models

- Icon pack: one image model prompt per icon family (currency, materials, gear, menu glyphs, rarity badges), 128 px, flat, two-tone, thick outline; uploaded once and the ids put in `data/Icons.luau`; `Builder` gains `Builder.icon`. Menu glyph letters go.
- 9-slice assets for panels, buttons and chips from one Figma-style sheet, so Builder's chunky button becomes an image with the same API; tier colours stay from Theme.
- Motion: screen open and close scales (exist), list item stagger, number roll-ups, the Star Chart as a drawn orbit with planets instead of a card list, the Ship screen's modules as a side-view of the ship filling in.
- Layout audit at SE and iPad against `UI-Checklist.md`; every change recorded in `UI-Playbook.md`.

### L5b. Icons v2: the plan (written 2026-10-12, for the collaborator's lead)

Ethan's standing direction (PRE_PRODUCTION 5a): the current flat icon pack is below the top games' level. This is the replacement plan; it starts when the collaborator opens the visual pass.

1. **The bar.** A top sim's icon (Grow a Garden, Pet Simulator 99, Adopt Me, Steal an Egg) beside ours at the same pixel size on a phone screenshot: ours must read as the same family. The look: a rendered 3D object, saturated two-tone colour, a thick dark outline (about 6% of the icon's width), a soft drop shadow down-right, a rim light top-left, a small specular hot spot, no flat vector fills. Readable at 44 px (the HUD's round buttons at iPhone SE size).
2. **References first.** A board in `05-ui-design/refs/icons-v2/README.md`: 12 icons from the top games (screenshots, not downloads; we never ship their art), each with one line on what makes it read (silhouette, colour pair, outline weight). The collaborator builds the board; Ethan says yes to the direction before any render.
3. **The set.** Every key in `src/shared/data/Icons.luau` (48 today) plus the ones added since without art: the Playtime gift and button icons, the Storage Bay, the Music setting, the Release and Visit buttons, the StorageBoost pass tile. One list in the board's README with the 44 px and 128 px uses of each.
4. **The pipeline.** Blender through MCP, `tools/blender/icons.py` v2 (the v2 route already in L5 above): one scene per icon from a shared template (camera at 35 degrees, three-point light, Eevee, bevel modifier on every edge, a Solidify-based outline, a transparent background), rendered at 1024 px and downsampled to 256 (Roblox's decal size for buttons) and 512 (shop and featured tiles). The same template renders the species' Codex and Reveal portraits from their models so the whole UI shares one light. An image model (Nano Banana or Gemini, Ethan's account) is allowed for concept sheets only; the shipped icon is always the Blender render, so every icon matches.
5. **Batches and review.** Twelve icons per batch, a contact sheet per batch in `05-ui-design/refs/icons-v2/batch-N.png` beside the top-game board, Ethan's yes per batch, then `python3 tools/upload_assets.py --images` on the Mac and the ids into `Icons.luau` (ids of 0 keep the letter fallbacks, so a half-done set never breaks a screen).
6. **Who.** The collaborator leads (board, direction, review), the Mac session renders and uploads, the coordinator wires the ids and the Builder gloss, inner shadow and shine that L5 lists.
7. **Done when** every key has an id, the HUD, Shop, Gifts, Aliens and Codex screens show no letter fallbacks at iPhone SE and iPad sizes, and the side-by-side in step 1 passes for the three hero icons (Scrap, the Shop button, the Ship bar).

### L6. Store presence (one milestone, with the Growth Playbook)

- Icon: one alien close-up, eyes to the lens, one bold colour, no text. Three thumbnails: the catch moment, the ship launch, the roster at camp; big readable title text; tested with Roblox's thumbnail A/B feature.
- Name candidates and the 30 s video from `docs/vault/01-game-design/Growth-Playbook.md`.
- Since 2026-10-14: [[Thumbnail-Research]] (what earns the first click, and the four candidates rendered on 2026-10-15), [[Group-Page]] (Moop Games and its emblem) and [[Launch-Dashboard]] (where the launch stands). Mac memory limits that shape the render runs: [[Setup-and-Tips#Memory on the Mac|Memory on the Mac]].

## Tools per pass

| Pass | Claude side | Mac side (Ethan) |
|---|---|---|
| L1, L2 | data tables and directors by Sonnet workers; Studio MCP applies and screenshots | approve the grade per world from screenshots |
| L3 | props generator, Blender MCP for hero pieces | import props, paint with the plugins, publish the place |
| L4 | Blender MCP shaping, review sheets, wiring | run the paid generator with the prompt, Import 3D, approve batches |
| L5 | Icons data, Builder changes, screens | upload the image assets, paste the ids |
| L6 | briefs and copy | icon and thumbnail uploads, the A/B test |

## Review loop

Every pass ends with: the test script line in `docs/TESTING.md`, screenshots at iPhone SE and iPad from the Mac session, the greyscale check for anything new, and a dated line in the matching art page recording the tool, the prompt and what was kept. Corrections go into the UI Playbook in the same change.
