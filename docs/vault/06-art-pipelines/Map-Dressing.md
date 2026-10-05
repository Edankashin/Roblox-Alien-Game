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
