# Look plan: how the game gets its final look

The mechanics are in and testable with placeholders. This is the plan for the look: what changes, in what order, with which tools, and what each pass costs. It follows the reference-video lessons in `media/tiktok/NOTES.md` (one bold colour per thing, silhouettes that read at thumbnail size, lighting does half the work, chunky outlined UI) and the design's art direction in `docs/GAME_DESIGN.md` section 15 and 16.

## Where the look stands (2026-10-05)

| Layer | Now | Target |
|---|---|---|
| Worlds | flat floor, coloured patches, part scatter; 16 generated props ready to import | lit, dressed, textured ground, hero landmarks, weather with particles |
| Creatures | 32 procedural blockouts (one mesh, flat colours, no rig) | 32 stylised models with idle, walk, work and reveal animations |
| Camp and ship | blocks and ghost modules; hull and station meshes ready to import | modular ship pieces that visibly assemble, lit stations, worker animations |
| UI | code-built from Theme and Builder, Fredoka, outlined; no icons, no image assets | icon pack, 9-slice panels and buttons, rarity frames, animated transitions |
| Store page | nothing | icon, three thumbnails, a 30 s video, a tested name |

## Principles that decide every pass

1. **Readable at thumbnail size.** Every alien, prop and icon passes the greyscale-at-256 px check before colour is discussed (`tools/blender/preview.py`).
2. **Flat colour, strong shape, soft light.** Low-poly meshes with one flat material per colour, no textures on creatures, lighting and post-processing supply the depth (the Pet Simulator and Adopt Me look). Textures only on ground and large surfaces.
3. **Phones first.** Every effect has a budget: Future lighting with at most two shadow-casting lights per world, particles under 200 on screen, meshes under 1,500 triangles per alien and 600 per prop. Check on an iPhone SE in the emulator before calling anything done.
4. **Data, not scenes.** Lighting, colour grades, skyboxes and weather looks live in data tables (`src/shared/data`) and are applied by code, so a world's look is one table and a weather change is one tween.
5. **One pass at a time, reviewed on the Mac.** Each pass is a milestone with a test script, screenshots at iPhone SE and iPad sizes, and a line in the UI Playbook or the art pages when a review corrects something.

## The passes, in order

Core-loop milestones come first (19 group reward and rejoin nudges, 20 global leaderboard). The look passes start after those, cheapest and widest first.

### L1. Lighting and atmosphere per world (one milestone, mostly code) — done as milestone 22 (2026-10-05), verified in Studio on both places

- `data/Lighting.luau`: per world a sky (six skybox ids), Atmosphere (density, haze, colour, glare), ColorCorrection (tint, contrast, saturation), Bloom, SunRays, ambient and outdoor ambient, clock time range, and a per-weather override (Rain darker and bluer, Blizzard white and dense, Shower a warm night with extra bloom).
- `client/World/LightingDirector.luau` applies the table on join and tweens between weather looks over `Config.LightingTweenSeconds`; respects Reduced Motion by snapping.
- Technology Future, shadows on for the sun only, `GlobalShadows` true, no point-light shadows. One free Poly Haven HDRI per world for the sky reference, skyboxes generated as six images.
- Cost: one Sonnet worker and a Mac screenshot review. This pass lifts every screenshot the most for the least spend, so it goes first.

### L2. Ground and water (one milestone)

- Floors become Terrain (grass, snow, sand per biome patch) painted by a build script run once in Studio through MCP, or stay parts with MaterialService custom materials (a PBR set per world) when terrain costs too much on phones. Decide by measuring on the SE: terrain is the goal, materials the fallback.
- A water plane where a world has one (Tidepool later). Patch edges get a soft blend (a second ring part with a gradient texture) so biomes stop looking like discs.

### L3. World dressing and hero landmarks (one milestone per world) — weather particles done as milestone 24 (2026-10-05); five hero set pieces modelled (`tools/blender/heroes_base.py`, renders in `05-ui-design/refs/look-l3/`) and placed from layout data as milestone 29 (2026-10-06); the 16 scenery props get their look pass next; drops and flakes wait on real textures

- Import the 16 props (`Map-Dressing.md`), then paint extra scatter with Brushtool 2, rows with Redupe, curves with Archimedes. Hand dressing lives in the place file.
- Hero pieces modelled in Blender through MCP or generated: the crash site wreck, the shrine, the cave mouth, the geyser field vents, the ship hull per world. Each has a notes line in `Blender-MCP.md`.
- Particles: catch burst and reveal sparkle (exist), weather (rain, snow, ash), shower meteors, geyser steam, heater warmth ring. Budgeted per the SE check.

### L4. Creatures (the big spend, in batches of eight) — first look pass done for all 32 species (batches 1 to 4, 2026-10-05 to 06, renders in `05-ui-design/refs/look-l1/*-v2.png`); the colour re-upload waits on Ethan

- Pipeline in `Creature-Generation.md`: commons first, greyscale check, one accessory, one bold colour. Tools in order of cost: Blender through MCP from the blockout (free, Claude does the shaping), Meshy or 3D AI Studio for a textured rigged model with a target polygon count (paid, fastest), hand touch-ups in Blender.
- Each model keeps its blockout's folder, file names and height, so it drops into the renderers unchanged (`import-model` skill). Four animations each (idle, walk, work-at-station, catch-reveal) as one animation set per body type, retargeted, so 32 species need about six rigs, not 32.
- Review per batch: a sheet of eight silhouettes and eight colour renders from `preview.py`, approved before the next batch.

### L5. UI and GUI (one milestone) — the Star Chart orbit map done (2026-10-05)

- Icon pack: one image model prompt per icon family (currency, materials, gear, menu glyphs, rarity badges), 128 px, flat, two-tone, thick outline; uploaded once and the ids put in `data/Icons.luau`; `Builder` gains `Builder.icon`. Menu glyph letters go.
- 9-slice assets for panels, buttons and chips from one Figma-style sheet, so Builder's chunky button becomes an image with the same API; tier colours stay from Theme.
- Motion: screen open and close scales (exist), list item stagger, number roll-ups, the Star Chart as a drawn orbit with planets instead of a card list, the Ship screen's modules as a side-view of the ship filling in.
- Layout audit at SE and iPad against `UI-Checklist.md`; every change recorded in `UI-Playbook.md`.

### L6. Store presence (one milestone, with the Growth Playbook)

- Icon: one alien close-up, eyes to the lens, one bold colour, no text. Three thumbnails: the catch moment, the ship launch, the roster at camp; big readable title text; tested with Roblox's thumbnail A/B feature.
- Name candidates and the 30 s video from `docs/vault/01-game-design/Growth-Playbook.md`.

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
