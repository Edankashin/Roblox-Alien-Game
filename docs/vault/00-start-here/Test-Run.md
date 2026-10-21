---
tags: [start-here, how-to, testing]
aliases: [Test run, Test-run the game]
up: "[[Start-Here]]"
---
# Test-run the finished game on your Mac

For Ethan, after [[Overnight]] job 40 has uploaded the new aliens and their art ([[Decisions]] B47) and pushed the ids. About ten minutes.

## Start it

1. Terminal: `cd ~/Roblox-Alien-Game && git pull --rebase origin claude/alien-system-research`
2. `rojo serve default.project.json` (World 1; leave it running).
3. Open Studio and your World 1 place (or a new Baseplate, which shows the loader best). Plugins tab > Rojo > Connect, accept the prompt.
4. Press Play. In Output, look for the line `Models: N loaded, 0 present, 0 failed`. A failure count means some uploads are still in moderation (see "Still old blockouts" below).

## What you should see

- **The new aliens**: block-cell models 2 to 3.5 studs tall next to your 5-stud avatar, each with its own eyes that blink. Rarer ones have more detail, moving parts (wings, ears, tails) and their own glow, never more height.
- **The HUD in block cells**: square stepped plates, chunky block buttons, pixel icons (Scrap cube, eggs, power-ups). Nothing rounded, no gloss.
- **Catch one**: walk up to an alien and tap Catch. The capture bar is a cell trough with a pixel arrow; tap to stop it in the zone. The reveal plays: a pixel egg cracks, then the card lands in the tier's colour.

**Per tier, what to look for in the reveal and in the world:**
- Common (Moop `Mossbop`, Glim `Glimmo`): a pop and one sparkle burst; a blink and one simple idle.
- Rare (Zirrit `Zapfinch`, Vixa `Sparkfox`): a pixel starburst, short cell rays, and the alien hops and turns in the card (its flourish).
- Epic (Voltus `Thunderhog`, Iridia `Gloomoth`): a fuller ray fan and a colour wash.
- Legendary (Gaira `Gaiabloom`): a gold cell frame runs round the card; slower and grander.
- Cosmic (Raddis `Radish`) and Secret (Syrinx `Panpipe`): a pixel sky and the name spelled in.
- Everywhere: does each tier feel clearly rarer than the one below, and does nothing look fierce?

## Spawn a rare one quickly

The developer chat commands work in Studio only. Type in the chat box:
- `/spawn Radish` (a Cosmic), `/spawn Gaiabloom` (Legendary), `/spawn Thunderhog` (Epic). Add a size if you like: `/spawn Radish big`. The id is the code name (`Mossbop`), not the display name (Moop).
- `/scrap 1000` for Scrap; `/models` prints the loader's counts and the names that failed; `/models retry` loads the failed ones again.
- World 2: stop Play, `rojo serve world2.project.json`, Play, `/spawn Fenripup` (Fenrir, Cosmic).

## Phone and tablet sizes

Test tab > Device, pick **iPhone SE** (landscape), Play, look at the HUD, a catch and a reveal; then **iPad**. Every label whole, buttons easy to hit, nothing under the notch.

## Still old blockouts?

- **Moderation.** New uploads can sit in Roblox moderation for a few hours. Output shows `Models: ... N failed`, and the old models or placeholders stay. Wait, then type `/models retry` in Play, or stop and press Play again.
- **Old models saved in the place.** The loader skips any model already in `ReplicatedStorage.Models`. If your place file still holds the old ones, delete `ReplicatedStorage.Models` in Edit mode (or use a new Baseplate), then Play.
- **The full pixel look (sharp cells).** A model loaded at Play gets its colours, and its eyes come from the face sheet. For the pixel-sharp cell texture, run the installer once: in Edit mode, open `tools/studio/install_models.luau`, paste it all into the command bar and press Enter, then save the place. It installs every uploaded alien with its atlas set to Pixelated.
- **Nothing uploaded yet, or you want to try one now.** File > Import 3D, pick `assets/models/<Id>/<Id>.fbx` (scale 1), select the Model it makes, then run `tools/studio/install_models.luau` in the command bar. It fixes that alien by name.

## For the team

The upload is one command on the Mac: `tools/finalize_upload.sh`. It runs `python3 -I tools/upload_assets.py --blocky`. That finds every block-cell model folder (species and props, by a `materials.json` entry with `pixelated` true), every sprite in `assets/sprites/blocky` and every tile in `assets/textures/blocky_tiles`. It fills the ids into the data through the generators. **The tile convention:** a tile's Image id is written into the one row of any `src/shared/data/*.luau` that is keyed by the tile's file name and has an `id` field on the same line, `MeadowGrass = { id = 0, ... }`. If two rows match, neither is filled, and the plan says so. Log in [[2026-10-21]] under "Upload worker".
