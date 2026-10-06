# Map dressing

How a world gets its scenery: 16 generated props that stand in for the part-built placeholders, plus hand dressing with the Studio plugins the pros use. Tools and plugin order come from `media/tiktok/NOTES.md` (batch 4). Read this before importing a prop or placing scenery by hand.

## What the code does

- `src/shared/Props.luau` is the one lookup. It reads `ReplicatedStorage.Models.Props.<Name>` (`Config.ModelFolderName`, `Config.PropsFolderName`) with `FindFirstChild`, clones the Model, anchors every part and stands it on a ground point. Nothing yields and nothing errors when a name is missing.
- The server world builder (`src/server/Services/Meadow.luau`) takes names from the layout's `Props` table: `src/shared/data/Meadow.luau` (`MeadowTree`, `MeadowTreeB`, `MeadowRock`, `MeadowRockB`) and `src/shared/data/Frostbyte.luau` (`SnowPine`, `IceSpire`, `IceRock`, `IceRockB`, `GeyserCone`). Both layouts also name `ShrineStone` and `Pedestal`. Scattered kinds pick one name at random and scale it by `Config.PropScaleJitter` (plus or minus 10%).
- The client camp renderer (`src/client/World/CampRenderer.luau`) reads `Camp.Props` in `src/shared/data/Camp.luau`: `ShipHull` for the ship, `GatherStation`, `BuildStation`, `SparkStation` for the three stations. The Heaters service stands `Config.HeaterPropName` (`HeaterLamp`) on its disc.
- A missing name means the part-built placeholder, so props can be imported one at a time and the game never breaks half way. The placeholder sizes are the footprints below; the scatter spacing in the layouts assumes them.

## Generate

```
python3 tools/blender/props_base.py --all                      # all 16 into assets/models/props/
python3 tools/blender/props_base.py --props MeadowTree,IceRock # only these
python3 tools/blender/preview.py --models assets/models/props  # 256 px thumbnails next to each GLB
```

Needs the `bpy` module (Blender 5.0) or a Blender binary (`blender -b -P tools/blender/props_base.py -- --all`). Output per prop: `assets/models/props/<Name>/<Name>.glb`, `<Name>.fbx`, `notes.md` (date, tool, footprint, triangles, colours). Budget 40 to 600 triangles; the script exits non-zero when one is over 600 or a footprint misses its placeholder size. Output is deterministic, so a re-run does not change files.

| Name | What it is | W x D x H (studs) | Materials |
|---|---|---|---|
| MeadowTree | round oak, one squashed crown | 8 x 8 x 14 | Trunk, Leaves |
| MeadowTreeB | taller oak, two-lobed crown | 9.2 x 7 x 16.1 | Trunk, Leaves |
| SnowPine | grey trunk, three snow cones | 9 x 9 x 15 | Trunk, Snow |
| IceSpire | crystal cluster, main shard 10 tall | 6.6 x 3.6 x 10 | Ice, IceTip |
| MeadowRock / MeadowRockB | lumpy boulder / wide flat one with moss | 4 x 4 x 2.8 / 5 x 4 x 2 | Rock, Moss |
| IceRock / IceRockB | angular ice boulder / upright shard | 4 x 4 x 3 / 3 x 3 x 4 | IceRock |
| GeyserCone | vent cone with a crater dish | 6 x 6 x 7 | Cone, Rim, Crater |
| ShrineStone / Pedestal | standing stone / two stacked discs | 2 x 1.25 x 5 / 5 x 5 x 1.5 | Stone (the game tints it) |
| ShipHull | landing pad: top at z 0.5, lip to 0.75, feet to -0.4 | 12 x 20 (long side is Y) | Plate, Lip, Feet |
| GatherStation | picnic table | 6 x 3 x 1.5 | Top, Legs |
| BuildStation | workbench, plank stack, anvil | 5 x 3 x 2.5 | Wood, Plank, Metal |
| SparkStation | glow flower | 2 x 1.8 x 4 | Stem, Petal, Glow |
| HeaterLamp | brazier with three flames | 3 x 3 x 2.6 | Metal, Glow |

Each prop is one mesh, flat shaded, one flat material per colour, no textures, standing on z = 0 with its pivot at the bottom centre (trees: the trunk axis). `Glow` has emission 2.0 in the file, but Roblox ignores that on import, so set the Glow MeshPart's Material to Neon in Studio (`Props.Tint` leaves Neon parts alone when it recolours a prop).

## Import into Studio by hand

1. File -> Import 3D, pick `assets/models/props/<Name>/<Name>.glb`, keep scale 1. One MeshPart per material comes in, grouped in a Model.
2. Rename the Model to exactly `<Name>`. The name is the lookup key: name = file name = instance name.
3. Create `ReplicatedStorage.Models` and `ReplicatedStorage.Models.Props` (Folders) if they are missing, then drop the Model into `Props`.
4. Select every part: Anchored on. Glow parts: Material Neon. Check the Model's size against `notes.md`.
5. Test: press Play. The scattered trees (or the ship, stations, heater) show meshes where the placeholders were. Stop and check Output for nothing red.
6. Record the import in `assets/models/props/<Name>/notes.md`. Never commit a `.rbxl`, `.rbxm` or `.rbxlx`.

## Bulk import through Open Cloud

Skips File -> Import 3D for all 48 models (32 aliens, 16 props). `tools/upload_assets.py` uploads each `.glb` (default; `--format fbx` for the `.fbx`) as a Model through the Open Cloud Assets API (checked 2026-10-05 against `cloud/guides/usage-assets.md` in Roblox's creator-docs: assetType `Model` accepts `.fbx` and `.glb`, one file per call, 20 MB max), then `tools/studio/install_models.luau` places them in Studio and colours them.

**Why GLB plus `materials.json` (found in Studio, 2026-10-05).** An FBX upload arrives as ONE grey MeshPart: the materials are merged. A GLB upload arrives as one MeshPart per material slot, named `<Name>`, `<Name>2`, `<Name>3`... in slot order, but every part is grey (163,162,165) with no TextureID, so the colours are lost. Each model folder therefore holds `materials.json` (slot order: `slot`, `name`, `hex`, `roughness`, `metallic`, `emission`); `--emit-luau` turns them into a `MATERIALS` table and the installer restores the colours (below).

**Make the API key, once.** Creator Dashboard (create.roblox.com) -> Open Cloud -> API Keys -> Create API Key.
1. Name it (`alien-game-assets`). Under Access Permissions pick the **Assets** API and add the operations **Read** and **Write** (scopes `asset:read`, `asset:write`).
2. Creator: the key acts as its owner. For assets owned by you, use your own account (your user id is the number in your profile URL). For a group-owned set, make the key as an account that may create assets for that group (a dedicated account limited to the group is the safer choice) and use the group id from the group URL.
3. Security: leave the IP allowlist off or enter `0.0.0.0/0` to allow any IP, or enter the Mac's public IP as `x.x.x.x/32`. Set an expiry date (a key unused for 60 days expires on its own).
4. Save & Generate Key and copy the string at once; it is shown once.

**Keep the key out of the repo.** Put it in the Mac shell only (add the `export` to `~/.zshrc` to keep it), never in a file under the repo, a commit or a chat:
```
export ROBLOX_OPEN_CLOUD_KEY=...            # the key string
export ROBLOX_CREATOR_USER_ID=1234567       # or ROBLOX_CREATOR_GROUP_ID=7654321
python3 tools/upload_assets.py --dry-run    # list the .glb files that would upload (needs no key)
python3 tools/upload_assets.py              # upload GLBs; add --props, --species or --only Mossbop,MeadowTree
python3 tools/upload_assets.py --redo       # rerun over names already in the JSON (e.g. replace the FBX ids)
python3 tools/upload_assets.py --emit-luau | pbcopy   # ASSET_IDS, PROP_NAMES and MATERIALS
```
The upload writes each asset id to `assets/models/asset_ids.json` as it succeeds, with its `"format"` (commit that file; ids are not secrets), skips names already in it, and exits non-zero if any model failed; re-run to retry only those. `--redo` ignores those names and overwrites their entries; the old FBX assets stay on the account, harmless. `--format fbx` picks the `.fbx` files instead.

**Place them in Studio.** Open `tools/studio/install_models.luau`, paste the clipboard over the three tables between the PASTE markers, and run it in the command bar (or the Studio MCP `execute_luau`). Studio must be signed in as the owning user or a group member. It loads each id with `InsertService:LoadAsset`, names the Model exactly the key, puts aliens in `ReplicatedStorage.Models` and props in `ReplicatedStorage.Models.Props` (folders created, same-name children replaced), colours the parts from `MATERIALS`, anchors every part (creatures also CanCollide and CanQuery off), then prints a line per model and a count.

**How the colours come back.** The installer sorts the Model's MeshParts by the numeric suffix of their name (no suffix = 1, `Name2` = 2, ...) and gives part i the material row i: `Color` from the hex; `Neon` when emission > 0, `Metal` when metallic >= 0.5, else `SmoothPlastic`. It renames the part to the material name (Body, EyeWhite, Glow...) so the name-based rules still work (a part named Glow, `Props.Tint` skipping Neon). Roughness is carried in the table but not applied (Roblox has no per-part roughness). When the part count and row count differ, the parts that exist are coloured and a warn names the model and both counts. A model with no `MATERIALS` entry keeps the old rule (a prop MeshPart named Glow becomes Neon).

**Moderation.** Uploads are moderated by Roblox "generally within a few hours"; an asset still in review cannot load in games, and the installer prints FAIL for it until it is approved. Run the installer again later; it is safe to repeat.

**Still by hand.** The API imports with default settings and no preview (Roblox points to the Studio Importer for that) and stores Models as packages. After the first install check one alien and one prop: height against `notes.md`, facing -Z, the colours and Glow Neon, and that `LoadAsset` returns the Model. Not run against Roblox yet (see Record).

## Dress by hand with the pro plugins

Install GapFill, ResizeAlign, Brushtool 2, Redupe and Archimedes from the Creator Store before dressing a biome. Hand-placed dressing lives in the place file, not in Rojo: it is saved by publishing the place (File -> Publish to Roblox), and a teammate sees it only after that. Keep it in a top-level `Workspace.Dressing` folder (one subfolder per world). Do not create `Workspace.World` by hand: `Meadow.Init` returns at once when a folder of that name already exists, so the generated floor, camp and scatter would not be built. The generated world exists only while the game runs; to paint in Edit mode, add a temporary 400 x 1 x 400 Part at the origin (the runtime floor, top at y 0.5), dress on it, and delete it before publishing.

**Brushtool 2: scatter extra trees and rocks**
1. Plugins -> Brushtool. In Explorer select the Models in `ReplicatedStorage.Models.Props` you want, and add them to the brush palette.
2. Set size, density, random rotation and a little random scale (about 10%, like `PropScaleJitter`); set the surface to the temporary floor.
3. Drag across the biome; Ctrl+Z undoes a stroke.
4. Select everything painted: Anchored on, CanQuery off, then group it into `Workspace.Dressing.<World>`.

**Redupe: rows (fence lines, lamp posts, codex pedestals)**
1. Place one prop and select it, then open Redupe.
2. Pick Stamp and Repeat. Set Count (or Alignment) and the copy spacing, extra padding and rotation between copies.
3. Drag the handle along the line; the array builds as you drag. Tick Automatic ResizeAlign when the copies must touch.
4. Anchored on, CanQuery off, then move the row into `Workspace.Dressing`.

**Archimedes: round camp pads and curved paths**
1. Open Archimedes and choose the curved shape (arc, ring or path).
2. Enter the exact angle and segment count; a camp pad ring uses the layout's `CampPadRadius` (12).
3. Press Render All, then set Anchored, colour and Material on the result.
4. Move it into `Workspace.Dressing`.

**GapFill and ResizeAlign: seams between ship pieces**
1. Select the two parts with the hole between them and press GapFill to close it in one click.
2. For parts that should meet exactly, select them, open ResizeAlign and pick the method (Outer Touch, Inner Touch, Wedge, Rounded, Butt Joint or Extend).
3. Check the seam from three angles; modules stack on the `ShipHull` plane at z 0.5.

## Rules

- 1 unit = 1 stud. Feet at the origin. Flat colours, one material per colour, no textures.
- Budget 40 to 600 triangles per prop; trees are placed about 30 times per world.
- Name = file name = instance name, exactly as in the layout's `Props` table.
- Never commit a `.rbxl`. Replace a generated prop with a hand-made mesh by keeping the folder, name, footprint and pivot.

## Record

- 2026-10-05: first generation, `python3 tools/blender/props_base.py --all`, 16 props, all inside budget. Triangles: MeadowTree 336, MeadowTreeB 416, SnowPine 82, IceSpire 66, MeadowRock 80, MeadowRockB 80, IceRock 60, IceRockB 40, GeyserCone 106, ShrineStone 54, Pedestal 238, ShipHull 276, GatherStation 124, BuildStation 168, SparkStation 240, HeaterLamp 212. Not yet imported into Studio.
- 2026-10-05: `tools/upload_assets.py` and `tools/studio/install_models.luau` written from the Open Cloud docs and tested against a local mock of the API only; the first real upload and install are still to do.

### Icons and particle sprites (2026-10-06)

`tools/upload_assets.py --images` uploads every PNG under `assets/icons` and `assets/particles` (rendered by `tools/blender/icons.py`) as a Decal asset, keeps the ids in `assets/icons/asset_ids.json`, and `--images --emit-icons-luau` prints the Icons and Particles tables for `src/shared/data/Icons.luau`. An ImageLabel or a ParticleEmitter takes a decal id as `rbxassetid://<id>`. Until an id is in, the UI shows its glyph letters and the default particles.
