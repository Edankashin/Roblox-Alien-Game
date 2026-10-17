# Blocky Roblox pets and creatures: the build pipeline, from model to in-game VFX

Research worker, 2026-10-17. Scope: how creators build blocky pets for Roblox (modelling, textures, export and import, budgets, animation, VFX), with numbers a headless Blender (bpy 5.0) pipeline can follow.

**How the sources were read.** Tags on every finding:
- **(read)**: I read the primary text. Roblox's `creator-docs` repository on GitHub, cloned at commit `58f787e` (2026-10-16), which is the source of create.roblox.com/docs. The Blockbench source on GitHub at `7c92e27` (2026-10-09). A third-party GitHub README.
- **(measured)**: I ran it myself in Blender 5.0.1 (`bpy`) in this container, with the RNA defaults read from the running build.
- **(snippet)**: a search-engine summary of a page I could not open. `devforum.roblox.com`, `note.com`, `blockbench.net` and `docs.blender.org` all refuse a connection from here (proxy 403 or DNS failure), so every DevForum claim below is a snippet. DevForum years are estimated from thread id numbers and marked "~".
- **(project)**: the repository's own notes.
- **(inferred)**: my conclusion, not a source.

Already in the project, so not repeated here: the Blockbench file format, the glTF rig and animation route and its gotchas, and the Substance prices (`docs/vault/06-art-pipelines/Model-Toolchain.md`). Also the 100 particles per second mobile cap, the 255 Highlight limit, the procedural idle decision B39 and the per-species Beams (`Roster-Redesign.md`, `Decisions.md`, `Species-Effects.md`). Each section's Inferences says what is new.

---

## 1. Modelling: how blocky pets are built (Blender, Blockbench), the Blockbench-to-Roblox route, and which tool dominates

### Takeaway
The documented route for Roblox simulator pets is Blender box modelling. Start from a cube, add loop cuts, push the shape with proportional editing, then bevel the outer edges, keeping any part that will move as a separate object. Blockbench can export OBJ, FBX or glTF to the Roblox Importer, but no Roblox plugin exists, users report problems with scale, textures and animation, and nobody has measured which tool pet modellers use most. For a script, a bevelled 9-box pet costs 396, 972 or 1,692 triangles at 1, 2 or 3 bevel segments (measured).

### Cited Findings
**Blender pet tutorials (DevForum and YouTube)**
- The DevForum community tutorial "Creating Simulator-Styled Pets in Blender" (~2020) works like this. Loop-cut the body cube and pull the edges into shape with proportional editing (O). Then select the cube's side edges, leaving out the loop-cut edges, and bevel with Ctrl+B, dragging to set the amount. Skipping the loop cuts gives "a more rounded-square look". "Keep them separate if you plan on animating them". The parts are imported into Studio as meshes. — [DevForum 517174](https://devforum.roblox.com/t/creating-simulator-styled-pets-in-blender/517174) (snippet; no numeric bevel width is quoted in any snippet).
- A forum answer recommends a cube as the pet's base "because it is simple and most tutorials use it". — [DevForum 3048637, "How do you make pets for simulator game"](https://devforum.roblox.com/t/how-do-you-make-pets-for-simulator-game/3048637) (snippet, ~2024).
- Modern simulator pets are "often built in Maya or Blender and textured in Photoshop or Substance Painter". Another reply suggests pulling existing pets from the Creator Store as `.obj` files for reference. — [DevForum 2882620, "How are modern simulator pets made?"](https://devforum.roblox.com/t/how-are-modern-simulator-pets-made/2882620) (snippet, ~2024).
- A second community tutorial lists the hotkeys used for pet modelling. — [DevForum 1468850, "How to make Pets in Blender"](https://devforum.roblox.com/t/how-to-make-pets-in-blender/1468850) (snippet, ~2021).
- A Japanese guide exists on modelling the common square pets in Blender and Roblox Studio. — [note.com/robloxken, "3D Modeling of Common Square Pets in Roblox"](https://note.com/robloxken/n/n9e2195f7fea7?hl=en) (title only; the page is blocked here).
- Three YouTube tutorials exist; I did not watch them: ["How to Make a Simulator Pet in Blender! (Pet Sim 99/Pet Sim X)"](https://www.youtube.com/watch?v=Mck-ndoI_yA), ["Making Roblox Simulator Pets in Blender!"](https://www.youtube.com/watch?v=3MNMq2J72UE) and ["HOW TO MAKE PETS IN BLENDER FOR YOUR ROBLOX SIMULATOR GAME!"](https://www.youtube.com/watch?v=Ied8ktbjmlQ) (titles only).

**Blender's Bevel and Remesh defaults, and measured triangle counts**
- Blender 5.0.1 Bevel modifier defaults (measured, from the RNA):
  - `width` 0.1, `segments` 1, `offset_type` OFFSET
  - `limit_method` ANGLE with `angle_limit` 30° (0.5236 rad)
  - `profile` 0.5 ("0.5 = round"), `affect` EDGES
  - `harden_normals` False ("Match normals of new faces to adjacent faces"), `miter_outer` MITER_SHARP, `use_clamp_overlap` True, `loop_slide` True
- Remesh modifier defaults (measured): `mode` VOXEL; Blocks mode uses `octree_depth` 4 and `scale` 0.9 ("ratio of the largest dimension of the model over the size of the grid").
- Triangle counts (measured, Bevel width 0.08 on a 1-unit cube, angle limit 30°):

| Shape | Triangles |
|---|---|
| plain cube | 12 |
| cube, bevel 1 segment (a chamfer) | 44 |
| cube, bevel 2 segments | 108 (same with harden normals on) |
| cube, bevel 3 segments | 188 |
| cube, bevel 4 segments | 300 |
| cube with one loop cut each way, bevel 3 segments | 296 |
| icosphere, subdivisions 1 ("ball" hands and feet) | 20 |
| icosphere, subdivisions 2 | 80 |
| cone, 6 sides (spike) | 10 |
| cone, 8 sides | 14 |

- A 9-box pet (body, head, four legs, two ears, tail; bevel at 8% of each box's side) comes to 396 triangles at 1 segment, 972 at 2 and 1,692 at 3 (measured).
- The voxel route, Remesh Blocks on a radius-1 UV sphere (measured):

| Octree depth | Remesh alone | Remesh, then Decimate Planar at 1° |
|---|---|---|
| 3 | 444 | 146 |
| 4 | 1,932 | 886 |
| 5 | 7,884 | 4,472 |

**Blockbench**
- Blockbench's Add Mesh dialog has a "Beveled Cuboid" primitive. Its defaults are diameter 16, height 8 and `edge_size` 2 (Blockbench units, 16 to a block), so the chamfer is 12.5% of the width. Its vertices are four per side on six sides, a single chamfer with no segment count. — [Blockbench `js/modeling/mesh/add_mesh.ts`](https://github.com/JannisX11/blockbench/blob/master/js/modeling/mesh/add_mesh.ts) (read).
- The English action list has Create Face or Edge, Extrude Selection, Inset Selection, Loop Cut, Split Mesh and Merge Vertices, and no Bevel action. — [Blockbench `lang/en.json`](https://github.com/JannisX11/blockbench/blob/master/lang/en.json) (read).
- Blockbench's style guide treats a block as 16×16×16 pixels, which represents 1 m³, so "a single pixel is 6.25 cm long". The ratio of pixels must be kept on the model, with no squashing or stretching. Textures are resized with Nearest Neighbor. — [Blockbench Wiki, Minecraft Style Guide](https://blockbench.net/wiki/guides/minecraft-style-guide/) (snippet).
- In Per-face UV mode, the project's Texture Size sets the pixel grid without changing UVs. In Box UV mode, every texture must share the project size. — [normalmap.ai guide](https://normalmap.ai/learn/resize-textures-blockbench-guide/) (snippet, third party).

**Blockbench to Roblox**
- "You're able to export it as a .fbx and import it to Roblox Studio normally", but the model may come in bigger than in Blockbench and need scaling down. Another user hit a texture error with FBX and was pointed to OBJ. — [DevForum 2462295](https://devforum.roblox.com/t/how-do-i-import-models-from-blockbench-into-roblox/2462295) (snippet, ~2023).
- Studio can reject a Blockbench texture with an unsupported-format error. — [DevForum 2943404, "Exporting from Blockbench?"](https://devforum.roblox.com/t/exporting-from-blockbench/2943404) (snippet, ~2024).
- "Import with Animation" often brings in only the model, and GeckoLib animations do not carry over. Users recreate the animations in the Animation Editor or script them. — [DevForum 3639381](https://devforum.roblox.com/t/how-to-import-model-with-animations-that-are-made-in-blockbench-into-studio/3639381) (snippet, 2025).
- The Importer takes `.fbx`, `.obj` or `.gltf`. — [creator-docs `studio/importer.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/importer.md) (read).
- OBJ carries no rig, animation, units or embedded textures, so the `.mtl` and texture files must travel with the mesh. — [nilo.io, export OBJ](https://nilo.io/articles/export-obj-files-roblox-studio) (snippet, third-party vendor).

**Roblox geometry rules**
- "Individual meshes can not exceed 20,000 triangles". Geometry must be "watertight without exposed holes or backfaces", with "No N-gons (quads where possible)" and some volume (no zero thickness). — [creator-docs `art/modeling/specifications.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) (read).

**Which tool creators use**
- No survey exists. One blog suggests starting in Blockbench and refining, rigging and animating in Blender. — [Medium, "The New Era of Low-Poly Creation"](https://medium.com/@neonmaxima/the-new-era-of-low-poly-creation-blockbench-blender-rigging-and-the-quiet-rise-of-ai-animation-70d0ece654fd) (snippet, low quality).
- Blockbench's appeal is its browser version and no need to UV-unwrap blocky models. — [Hacker News 33845291](https://news.ycombinator.com/item?id=33845291) (snippet).
- In the owner's references, the creators show only Blender, never Blockbench or Substance (TikToks ZPLSQ1o7Q, ZPLSQAq5q and ZPLSQAhnb). — `media/tiktok/NOTES.md`, `Model-Toolchain.md` section 5 (project).

**A ready-made library in this exact style (provenance unknown)**
- A public GitHub asset library is built in Blender for Roblox in this style. — [7llamaking-collab/Roblox README](https://github.com/7llamaking-collab/Roblox) (read; author, date and quality unverified).
  - The look: "blocky chamfered shapes, square pixel eyes (black square with a white highlight), boxy muzzles and ears, square-section tails and limbs, and flat shading". "Curved things use few sides (8 or fewer)". "Most assets are under 4,000 triangles".
  - The scale: "1 Blender unit = 1 stud", with "pets 2–5 studs long".

### Inferences
- Blockbench's Beveled Cuboid is a single 44-triangle chamfer, the same count as Blender's 1-segment bevel. I worked that out from its 24 vertices (6 quad faces, 12 edge quads and 8 corner triangles); it was not counted in the app. For a rounded "simulator" bevel, Blender with 2 or 3 segments is the tool. Blockbench has no segment control.
- No source names a bevel width. The values to start from are Blockbench's own 12.5% of the side and the 8% I measured with. Start from 6 to 10% of the smallest side of each box, which reads as a soft chamfer at 2 to 5 studs (inferred).
- The voxel route (Remesh Blocks, then a planar dissolve) gives an organic sculpt a stepped Minecraft look in budget at depth 4 (886 triangles for a sphere). Its UVs need regenerating after the remesh (inferred).
- Blockbench-to-Roblox is a static-mesh route at best. The scale, texture and animation reports above match the gotchas the toolchain note listed, so Blender stays the builder (inferred). These are new to the project: Blockbench's Beveled Cuboid primitive, the missing Bevel action, and the DevForum reports of failed Blockbench imports.

#### Numbers for the scripted pipeline (the writer's summary)

| Step | Setting | Basis |
|---|---|---|
| Scale | 1 Blender unit = 1 stud; pet 2 to 5 studs long | palette library README (read); the project's GLBs already do this |
| Base | cube primitives per part (body, head, limbs, ears, tail); a mirror on X for paired parts; apply scale before export | DevForum tutorial (snippet); the TikTok "non-uniform scale" warning (project) |
| Bevel | `width` = 0.06 to 0.10 × the part's smallest side; `segments` 1 (chamfered look) or 2 (soft simulator look; 3 only for hero heads); `limit_method` ANGLE at 30°; `harden_normals` True if smooth-shaded; `use_clamp_overlap` True | measured counts; Blockbench's 12.5% default (read); widths are inferred |
| Round bits | icosphere at subdivisions 1 (20 triangles) or 2 (80) for paws; 6 to 8-sided cones for spikes; 8 sides or fewer for any curve | measured; palette README (read) |
| Triangle target | 9-box pet, 400 to 1,700 triangles; hero 2,500 at most (the project cap); hard cap 20,000 | measured; specifications.md (read) |
| Mesh hygiene | watertight, quads, no zero-thickness faces, one UV set inside 0:1 | specifications.md and texture-specifications.md (read) |
| Parts | wings, tails and ears that move are separate objects, exported as separate MeshParts or bones | DevForum (snippet); section 4 |

### Gaps
- No numeric bevel width or segment count from a named pet creator: the DevForum and note.com pages are blocked here and the YouTube tutorials were not watched.
- No data on which tool Roblox pet modellers use in 2025 or 2026: no survey or job-post count was found.
- BIG Games (Pet Simulator 99) has not described its pet pipeline publicly in anything I found.

---

## 2. Textures: pixel-art faces, palette atlases, vertex colour, SurfaceAppearance versus MeshPart texture, and what looks premium

### Takeaway
Three texture styles are in use:
- a single shared palette atlas (flat colours, one upload for every pet);
- a painted texture per pet with baked gradient lighting (the "modern simulator" look, done in Photoshop or Substance);
- a small pixel-art face on a cube head.

The pixel style has a new enabler. A plain `MeshPart.TextureID` is always bilinear-filtered (blurry pixel art), but `SurfaceAppearance.ResampleMode = Pixelated` (nearest-neighbour) entered the official docs on 2026-05-05. The Creator Docs size guide gives 256×256 for a 5-stud object, and 64 to 256 px for a pet-sized PBR budget.

### Cited Findings
**Roblox texture rules**
- Textures can be "up to 4096×4096". The docs give "256×256 for smaller 5×5 stud objects", 512 for 10×10 and 1024 for 20×20. "Mesh objects can only have one material assigned". "Parts display a 1024×1024 on an 8×8 stud face" (128 px per stud); "Terrain displays 512×512 across 8×8 studs" (64 px per stud). "When rendering many textures at the same time, Roblox may downsample textures". — [creator-docs `art/modeling/texture-specifications.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md) (read).
- The PBR budget on the same page is "256×256 for every 2×2×2 unit space":

| Map size | Object size | Note |
|---|---|---|
| 64 to 128 px | 1×1×1 | |
| 256 px | 2×2×2 | also the maximum for non-albedo maps on rigid accessories |
| 512 px | 4×4×4 | |
| 1024 px | 8×8×8 | the maximum |

  The same page also requires a single UV set, coordinates inside 0:1, and allows overlapping UVs. Its UV section says "up to 1024×1024 pixel spaces for texture maps", which conflicts with the 4096 line above it. — same file (read).

**SurfaceAppearance**
- `AlphaMode` has four values. **Overlay** (the default) shows `MeshPart.Color` where the map is transparent. **Opaque** ignores alpha. **Transparency** cuts the mesh away. **TintMask** applies `SurfaceAppearance.Color` only where alpha is opaque. `Color` "applies a tint to your existing colormap". — [creator-docs `art/modeling/surface-appearance.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/surface-appearance.md) and [`SurfaceAppearance.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/SurfaceAppearance.yaml) (read).
- "When set to `Pixelated`, the textures preserve the sharp edges of pixels using nearest-neighbor filtering. Defaults to `Enum.ResamplerMode.Default`." — `SurfaceAppearance.ResampleMode` in [`SurfaceAppearance.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/SurfaceAppearance.yaml) (read). The property was added to the docs in commit `380251a` on 2026-05-05 (read from the git history). `MeshPart` has no `ResampleMode` in its reference (read).

**MeshPart texture**
- `MeshPart.TextureID` can change at runtime; `MeshId` cannot. — [`MeshPart.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MeshPart.yaml) (read).

**Blurry pixel art (DevForum)**
- A pixel texture is sharp in Blender and blurry in Studio. — [DevForum 2728420](https://devforum.roblox.com/t/pixel-texture-being-blurry-in-roblox-studio-while-in-blender-not/2728420) (snippet, ~2023).
- Upscaling "reduces the blurriness to some small degree" but "eats up much more memory". Pre-upscaling 64×32 to 1024×512 with nearest neighbour worked for one developer, "still a bit blurry". — [DevForum 2303754, "Mesh Texture Pixel Art"](https://devforum.roblox.com/t/mesh-texture-pixel-art/2303754) (snippet, ~2023).
- A feature request from 2025 says "Textures on models are always blurred by forced bilinear filtering". — [DevForum 4028314, "Pixelated ResampleMode for SurfaceAppearances"](https://devforum.roblox.com/t/pixelated-resamplemode-for-surfaceappearances-pixel-art-meshes/4028314) (snippet). It conflicts with the docs entry above, which came later.
- Workaround for flat faces: a SurfaceGui with an ImageLabel set to `ResampleMode` Pixelated. This limits you to blocks or blocky meshes. — [DevForum 3479864](https://devforum.roblox.com/t/cool-pixel-perfectnearest-neighborpixel-perfect-3d-objects/3479864) (snippet, ~2025).
- ResampleMode on GUI images: Default is bilinear, Pixelated is nearest-neighbour. — [DevForum 1418681, ResampleMode announcement](https://devforum.roblox.com/t/resamplemode-new-property-for-image-gui-objects/1418681) (snippet, ~2021).

**Palette atlases**
- The palette library uses "one 512×512 atlas (`textures/StudPalette.png`, 298 named colours)" for every asset, with matching metalness and roughness atlases for metals and gems in a SurfaceAppearance. Recolouring means moving a face's UVs to another palette cell. The "AnimalBundle" animals it copies carry "6 `Texture` objects (one per face, `rbxassetid://9527811247`, 9 studs per tile, Transparency 0.4)" as a stud overlay. — [7llamaking-collab/Roblox README](https://github.com/7llamaking-collab/Roblox) (read; provenance unknown).
- Shrinking palette UVs all the way down to a point "can cause flickering in game engines"; keep each UV position distinct. — [YouTube, "This Blender Scene uses ONLY ONE TEXTURE"](https://www.youtube.com/watch?v=4tt3tW1Pz5U) (snippet, a comment).

**Painted textures and vertex colour**
- "The original texture of the dog uses a bit of gradient-based lighting". The suggested route is to mark seams, export the UV layout, and paint colours and gradients in an image editor. — [DevForum 2882620](https://devforum.roblox.com/t/how-are-modern-simulator-pets-made/2882620) (snippet).
- OBJ does not save vertex colours; FBX does. A vertex-colour gradient needs `MeshPart.Transparency` above 0 to show its alpha. — [DevForum 3941014](https://devforum.roblox.com/t/how-do-i-make-a-transparency-gradient-in-blender/3941014) (snippet, ~2025); [DevForum 2412540](https://devforum.roblox.com/t/neon-gradient-transparency-on-mesh-vertex-painting/2412540) (snippet, ~2023).

**Draw calls**
- Identical meshes share one draw call when the `MeshContent` is the same and the SurfaceAppearances, or else the `TextureContent`s, are identical. "Objects like decals, textures, and particles don't batch well and introduce additional draw calls". — [creator-docs `performance-optimization/improve.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md) (read).

**What reviewers notice**
- Reviewers flag uneven eyes most often. Smooth shading divides opinion: "you shouldn't shade smooth as it ruins the shading", against "making it smooth like that is a part of the simulator pet style". — [DevForum 1267428](https://devforum.roblox.com/t/feedback-on-my-simulator-pet/1267428), [DevForum 914220](https://devforum.roblox.com/t/feedback-on-first-pet-model/914220), [DevForum 2748969, "Feedback on pet faces!"](https://devforum.roblox.com/t/feedback-on-pet-faces/2748969) (snippets, 2020 to ~2023).

**The owner's reference**
- In ZPLSQAq5q, cube heads carry a pixel-art face texture (ringed pixel-disc eyes, pink cheek squares) over three or four flat colours. — `media/tiktok/NOTES.md` (project).

### Inferences
- **The face.** Paint it at 16 px per head-side unit, Blockbench's convention, so a 32×32 or 64×64 face cell. Ship it in a SurfaceAppearance with `ResampleMode = Pixelated`.
  - If the Studio probe shows Pixelated does not hold on the target devices, upscale with nearest neighbour by 8 (64 to 512) before upload and accept some blur.
  - Memory, by arithmetic: 64² RGBA is 16 KiB and 512² is 1 MiB, uncompressed. How Roblox compresses textures on the GPU was not found.
- **The body.** Use one shared palette atlas, flat cells plus a few two-tone gradient cells for baked top-light. Per-species atlases are needed only for painted hero detail.
  - A shared atlas saves texture memory, but different meshes still cost one draw call each. Instancing only helps when many copies of the same species are on screen.
- **Rarity recolours** without new uploads: `SurfaceAppearance.Color` with `AlphaMode = TintMask` (alpha marks the tintable body, the face stays untinted) (inferred from the read docs).
- **Premium versus cheap** (inferred; no source measures it):
  - Premium: bevels catching the key light, a baked gradient or AO on the body, glossy eyes with a white highlight pixel, a symmetric face, one consistent pixel density across parts.
  - Cheap: unbevelled cubes, mismatched texel density between head and body, blurry upscaled pixel art, uneven eyes.
- **New to the project:** ResampleMode Pixelated, the TintMask mode, the instancing rule, the palette-library precedent, and the 1024-versus-4096 conflict inside the texture specifications page. `Surface-Pass.md` already has the size guide and the Color tint.

### Gaps
- Whether `ResampleMode = Pixelated` works in live games, on mobile and on Fabric or other materials: the docs say so, but no Studio test was found. It is the first probe for the Mac.
- How Roblox compresses textures and what memory a 512 versus a 1024 pet texture really costs on a phone.
- How Pet Simulator 99 or Adopt Me textures their pets: no primary source was found.

---

## 3. Budgets: triangles, textures, collision and rendering fidelity for many pets on screen

### Takeaway
The only hard number is 20,000 triangles per mesh. Third-party guides put repeated creatures at 2,000 to 5,000 triangles with one 512 to 1024 texture; the style library keeps most assets under 4,000. Roblox's own advice for many objects is about draw calls and memory, not triangle count:
- reuse identical mesh and texture ids;
- `CollisionFidelity = Box`;
- leave `RenderFidelity` on Automatic or Performance, never Precise;
- turn off shadows on small moving parts;
- avoid moving skinned meshes in a Model that has no Humanoid.

### Cited Findings
**Roblox's rules (read)**
- 20,000 triangles per mesh at most. — [specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) (read).
- `RenderFidelity` defaults to Automatic: Highest under 250 studs, Medium from 250 to 500, Lowest at 500 and beyond. — [`MeshPart.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MeshPart.yaml), [`RenderFidelity.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/RenderFidelity.yaml) (read).
- "Performance" behaves like Automatic but also trims triangles when the frame rate drops. — [DevForum 1319217, "MeshPart Usage, Performance & Optimizations"](https://devforum.roblox.com/t/meshpart-usage-performance-optimizations/1319217) (snippet, ~2021).
- `CollisionFidelity` values: **Default** is a voxel-based convex-hull decomposition, **Hull** the convex hull, **Box** the bounding box, and **PreciseConvexDecomposition** the most accurate. It "cannot be read or manipulated by scripts during runtime". — [`CollisionFidelity.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/CollisionFidelity.yaml), [`TriangleMeshPart.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/TriangleMeshPart.yaml) (read).
- Further advice from the performance guide — [creator-docs `performance-optimization/improve.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md) (read; the skinned-mesh paragraph is older than 2026-03-04 in the history):
  - "`Box` has the lowest memory overhead, and `Default` and `Precise` are generally more expensive".
  - Precise `RenderFidelity` "on too many meshes" is a common problem.
  - Use `CastShadow` off on small parts, disable `Light.Shadows`, "Disable shadows on moving objects when possible".
  - "Instantiating, modifying, and respawning models with Humanoids or skinned MeshParts frequently" is costly.
  - "Skinned MeshParts that are part of a Model without a Humanoid are grouped using spatially-organized FastClusters. When these MeshParts move, they must be continually added to and removed from these spatial clusters". The workaround is to "embed a Humanoid within the Model", "reserved exclusively for MeshParts with expected movement".
  - `Model.LevelOfDetail = SLIM` with instance streaming renders lightweight meshes at distance.
- Highlight: "Studio only displays 255 simultaneous `Highlight` instances" (raised from 31 in the docs on 2026-04-03, commit `7da1823`). The first Highlight costs "up to 1 millisecond of GPU time on mobile devices". Adding or removing one causes a geometry rebuild, so toggle its properties instead. — [creator-docs `effects/highlighting.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/highlighting.md) (read).

**Third-party guides (snippets)**
- 2,000 to 4,000 triangles for repeated props; Box collision with CanCollide, CanTouch and CanQuery off for decorative parts. — [nilo.io, optimize accessories](https://nilo.io/articles/optimize-roblox-accessories-performance), [nilo.io, optimize AI meshes](https://nilo.io/articles/optimize-ai-meshes-roblox-superbullet) (snippet, vendor).
- 50 to 500 triangles for tiny items in large numbers. — [nilo.io, polygon limit](https://nilo.io/articles/optimize-3d-models-roblox-limit-3) (snippet).
- Count unique meshes, not total meshes. — [HyperDevs](https://hyperdevs.app/guides/roblox-polygon-limits/) (snippet).
- Pets "usually stay under about 2–5k triangles, use single 512–1024 px textures". — [Tripo blog](https://www.tripo3d.ai/blog/explore/pet-simulator-99-3d-model) (snippet, AI-vendor marketing, weak).
- "A forum thread" puts a reasonable model budget in this range. — [DevForum 1529723, "Reasonable amount of triangles for models"](https://devforum.roblox.com/t/reasonable-amount-of-triangles-for-models/1529723) (title only).

**The style library and the project**
- "Most assets are under 4,000 triangles". — [palette library README](https://github.com/7llamaking-collab/Roblox) (read).
- The project's cap is 1,000 to 2,500 triangles per species. — `Model-Toolchain.md`, `Look-Plan.md` (project).

### Inferences
- A blocky pet built as in section 1 is 400 to 1,700 triangles, well under any budget above. For blocky pets the cost driver is draw calls (one per MeshPart, per unique mesh-and-texture pair, per particle emitter), not triangles.
- **Draw calls.** Merge static parts into one mesh per species. Keep moving parts (wings, tail) as at most two or three extra MeshParts.
- **Settings for every follower or wild pet part:** `CanCollide`, `CanTouch` and `CanQuery` false; `CollisionFidelity` Box (set in Studio or at import, since scripts cannot change it at runtime); `CastShadow` false on small parts; `RenderFidelity` Automatic. `Massless` matters only if the part is unanchored.
- **Skinned (rigged) pets** pay the FastCluster cost when they move. Roblox's fix is a Humanoid inside the Model. The project rule is "no server-side Humanoids for creatures"; a client-only Humanoid in a client-rendered model may be allowed. That is a decision for the coordinator, and it only arises if a rigged pet is chosen.
- **New to the project:** the FastCluster and Humanoid note, the instancing conditions, the 250 and 500-stud fidelity distances, the SLIM level of detail, and the 1 ms first-Highlight cost on mobile.

### Gaps
- No measured benchmark of N pets on a phone (draw calls or frame time) was found. The only way to get one is a MicroProfiler or Render Stats (Shift+F2) run on the Mac with 50 and 100 pets.
- No official per-pet triangle or texture budget from Roblox, BIG Games or Uplift.

---

## 4. Animation: rigs (Motor6D, Bones, AnimationController) versus CFrame and tween bobbing; wings, tails and floating

### Takeaway
Simulator pets are mostly animated procedurally on the client:
- each frame, the pet's CFrame is lerped toward the player's root CFrame times an offset;
- a sine term on Y gives the bob;
- moving bits (wings, tails) are separate welded parts rotated by script.

Rigged pets are possible: an FBX or glTF with bones becomes a skinned MeshPart with an AnimationController, and clips are imported in the Animation Editor and published. Animations made in Blockbench reportedly fail to come through, and skinned meshes add a movement cost.

### Cited Findings
**Procedural motion (DevForum)**
- Lerp the pet's CFrame toward the player's `CFrame * offset` at about 0.15 per frame; bob with a sine of `tick()` added to Y. — [DevForum 3039325, "Pet follow like psx"](https://devforum.roblox.com/t/pet-follow-like-psx/3039325) and [DevForum 984575](https://devforum.roblox.com/t/pet-following-system-issue/984575) (snippets).
- Bob an attachment between 0.8 and 1.4 studs. Bob and look-at fight each other, so separate orientation from position (BodyGyro, `ToObjectSpace`). — [DevForum 3595856](https://devforum.roblox.com/t/how-would-i-make-my-pet-follow-system-have-a-smooth-transition-from-bobbling-to-standing-still-when-a-player-is-moving-not-moving/3595856) (snippet, ~2025).
- Anchor the pet with CanCollide and CanQuery off and Massless on, or use AlignPosition and AlignOrientation constraints instead of a per-frame script. — [DevForum 2176090, "Pet Follow System"](https://devforum.roblox.com/t/pet-follow-system/2176090), [DevForum 3308281](https://devforum.roblox.com/t/how-do-i-make-pet-follow-system/3308281) (snippets).
- A smooth, lively pet is a DevForum question of its own. — [DevForum 523679, "How did this game make their pets so smooth moving and lively?"](https://devforum.roblox.com/t/how-did-this-game-make-their-pets-so-smooth-moving-and-lively/523679) (title only, ~2020).
- Moving wings on a pet would be "a welded add-on part". — [DevForum 2882620](https://devforum.roblox.com/t/how-are-modern-simulator-pets-made/2882620) (snippet, cut off).
- Pet Simulator's pets are created on the client and positioned by CFrame math. — [DevForum 2779392, "How does Pet Simulator do it?"](https://devforum.roblox.com/t/how-does-pet-simulator-do-it/2779392) (snippet; community guesswork, not BIG Games).
- "Roblox doesn't support animating MeshParts with the Animation Editor", so floating or rotating pets need a script. — search summary of [DevForum 3639381](https://devforum.roblox.com/t/how-to-import-model-with-animations-that-are-made-in-blockbench-into-studio/3639381) (snippet; true for unrigged MeshParts, inferred).

**Rigged route (read)**
- Rigs without a Humanoid play through an `AnimationController` with a child `Animator`. A vertex takes at most 4 bone influences; the root bone sits at 0,0,0 with no influences; one animation track per exported file. — [specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) (read); `Model-Toolchain.md` section 2 (project).
- `MeshPart.HasSkinnedMesh` is set by the engine when the mesh has joints; scripts cannot set it. — [`MeshPart.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MeshPart.yaml) (read).
- The palette library's import recipe — [README](https://github.com/7llamaking-collab/Roblox) (read; untested here):
  - "the 3D Importer creates a skinned MeshPart with Bones and an AnimationController";
  - clips are added with "Animation Editor on the rig → ⋯ → Import → From FBX Animation", one FBX per clip (Idle, Walk, plus Fly or Swim), then published;
  - bones are `Root, Body, Head, LegFL, LegFR, LegBL, LegBR, Tail, WingL, WingR, FinL, FinR, ArmL, ArmR, Tentacle1..8`, and "each body part follows one bone rigidly, which is the cleanest deformation for low poly".
- Moving skinned MeshParts in a Model without a Humanoid force FastCluster rebuilds. — [improve.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md) (read).

**The project**
- Decision B39: idle motion is procedural (bob, hover, flap, stride, spin, breathe) by part CFrame tweens from a data table, and a rig is a later decision. — `docs/vault/07-alien-game/Decisions.md` (project).

### Inferences
- For a blocky pet, the rigid-parts approach costs the least:
  - Build the pet as a Model of 2 to 4 MeshParts: body and head merged, each wing, the tail.
  - Drive each part with a client-side CFrame offset: wing flap is rotation about the hinge, `A·sin(2π·f·t)` at about 15 to 30° and 3 to 6 Hz; tail wag 10 to 20° at 1 to 2 Hz; bob 0.2 to 0.5 studs at about 0.5 to 1 Hz. These numbers are mine, not from a source; tune them in Studio.
  - This needs no Bones, no published Animation assets and no FastCluster cost, and it matches B39.
- Rigid bone-per-part skinning, as the palette library does it, is the upgrade path for walk cycles on hero species. Its clips are authored in Blender and imported as FBX in the Animation Editor; animations made in Blockbench are not a reliable route.
- In Blender, put each moving part's origin on its hinge (wing root, tail base) before export, so the Roblox pivot is right without offsets (inferred; the same idea as the toolchain note's group origins).
- **New to the project:** the Animation Editor "Import → From FBX Animation" path for a prebuilt rig, the rigid one-bone-per-part convention, and the community numbers for follow, lerp and bob.

### Gaps
- No primary source on how Pet Simulator 99 or Adopt Me animate wings or idles.
- Whether the Importer's glTF route (rather than FBX) gives the same AnimationController setup is still the Mac probe's job (`Model-Toolchain.md` section 6).

---

## 5. VFX for pets: particles, Beams, Trails, Highlight, Neon and ForceField, lights; making VFX textures in Blender; mobile rules

### Takeaway
Pet VFX is built from these parts:
- ParticleEmitters, where a flipbook sheet animates the texture;
- Beams and Trails between Attachments;
- Neon or emissive mesh pieces, Highlight outlines, and small PointLights.

Creators make the textures in Blender in one of two ways:
- render frames (Cycles or Eevee, an emissive shader on black or transparent), pack them into a 1024×1024 sheet with gutters, and play it as a 2×2, 4×4, 8×8 or Custom flipbook at 30 fps or less;
- model low-poly "mesh VFX" (rings, columns, ribbons, shards) with gradient transparency or Neon, tweened in Roblox.

On mobile:
- an emitter makes 100 particles a second at most;
- fill-rate and overdraw are the cost;
- flipbooks switch off on low-memory phones;
- Glass refraction does not run.

### Cited Findings
**ParticleEmitter — [creator-docs `effects/particle-emitters.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/particle-emitters.md) and [`ParticleEmitter.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/ParticleEmitter.yaml) (read)**
- Texture: use a `.png` with a transparent background. "If your texture is grayscale with no alpha channel, try setting... `LightEmission` to 1 to hide the darker regions".
- Blending: `LightEmission` 0 is normal blending and 1 is additive. It "does not cause particles to light the environment"; use a PointLight for that. `Brightness` scales the emitted light when `LightInfluence` is 0.
- Cost: "Particle size can impact performance due to fill-rate", and particle count costs through overdraw. "A single particle emitter can create up to 400 particles per second (100 per second on mobile)". `TimeScale` runs from 0 to 1.
- Flipbook layouts are 2×2, 4×4, 8×8 or Custom (`FlipbookSizeX`, `FlipbookSizeY`). The example is "1024×1024 image has an 8×8 layout... 64-frame".
- Spacing: "include spacing between each of the particle frames. In some cases, mip filtering might require even more spacing".
- `FlipbookFramerate` runs to 30 fps at most. **OneShot** spreads the frames over the particle's lifetime. `FlipbookStartRandom` with framerate 0 gives a random static frame per particle.
- Memory: flipbooks cost memory, and "clients automatically deactivate flipbooks when they are low on memory, which is likely for older mobile phones... Reusing textures costs less memory than using unique textures".
- Check particles across the editor's quality levels.
- `Squash` stretches particles: positive values for streaks, negative with VelocityParallel.
- History: the Custom layout predates 2026-03-04 in the docs (read). It was announced as a client beta, along with non-square sheets. — [DevForum 4005128](https://devforum.roblox.com/t/client-beta-optimize-your-particle-animations-with-custom-flipbook-layouts/4005128) (snippet, ~2025).
- The 2022 flipbook beta needed "a 1024x1024 texture with flipbook frames in a 2x2, 4x4, or 8x8 layout", with Blender exports at a fixed 1024 by 1024 and trim and rotate turned off. — [DevForum 1718023](https://devforum.roblox.com/t/animated-particles-with-the-particle-flipbooks-beta/1718023) (snippet, 2022, older).

**Beam and Trail**
- A Beam "renders its texture using two triangles drawn between `Segments`", laid out between the two attachments' orientations. — [creator-docs `effects/beams.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/beams.md) (read).
- A Trail has `Lifetime` (seconds; shorter is faster and shorter), `TextureLength`, and `TextureMode` Wrap, Static or Stretch. Stretch repeats the texture `TextureLength` times along the trail. — [creator-docs `effects/trails.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/trails.md) (read).

**Highlight, lights and materials**
- Highlight: 255 per client; the first one costs up to 1 ms of GPU on mobile; on mobile the cost grows with screen coverage; disabled or invisible highlights cost nothing. — [highlighting.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/highlighting.md) (read).
- Lights: put a PointLight in an Attachment ("recommended for point-specific light emission"); "a higher Brightness value doesn't light up a larger region". The performance guide says to disable `Light.Shadows`, limit range and angle, and use fewer lights. — [creator-docs `effects/light-sources.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/light-sources.md), [improve.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md) (read).
- Materials: Neon and ForceField are "unique and/or its texture assets are bundled with Studio". "Refraction of light through the glass material is not supported on mobile devices". — [creator-docs `parts/materials.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/materials.md) (read).

**Blender-made flipbook textures (DevForum)**
- "How to make Animated Slash Effects with only Blender!" (~2022):
  - a Voronoi and gradient shader with animated colour ramps;
  - each frame rendered as PNG on a completely black background;
  - the frames packed into a sprite sheet, with the black removed in Photopea;
  - played in Roblox as a 4×4 OneShot flipbook.
  — [DevForum 1794034](https://devforum.roblox.com/t/how-to-make-animated-slash-effects-with-only-blender/1794034) (snippet; older Studio steps).
- Explosions rendered in Blender Cycles with a transparent background. A tool that trims transparent margins rescales frames, so the effect starts large and shrinks; keep the full frame. Free flipbooks can look right on black but leave semi-opaque pixels at frame edges. — [DevForum 3035597, "2 Free Realistic Flipbook Particle Explosions"](https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597) (snippet, ~2024).
- Keep art about 8 px from the edge of each 128 px frame of an 8×8 sheet (a 120×120 square in each frame); an 8×8 sheet at about 15 fps worked for one user. — DevForum flipbook threads, [1718023 page 4](https://devforum.roblox.com/t/animated-particles-with-the-particle-flipbooks-beta/1718023?page=4) (snippet).
- One thread is titled "Transparent particles do not render at all above graphics quality 7". — [DevForum 2019985](https://devforum.roblox.com/t/transparent-particles-do-not-render-at-all-above-graphics-quality-7/2019985) (title only, ~2022, may be fixed).

**Mesh VFX**
- One method makes a cone in Blender, projects a 0 to 100% opacity gradient onto it through its UVs, and uses that image as a SurfaceAppearance ColorMap with `AlphaMode = Transparency`. Shade smooth, delete the cone's flat cap, and set `DoubleSided = true`. The alternative is vertex-colour alpha, which avoids texture blur and works with Neon; it needs FBX and `MeshPart.Transparency` above 0. — [DevForum 3941014](https://devforum.roblox.com/t/how-do-i-make-a-transparency-gradient-in-blender/3941014), [DevForum 2412540](https://devforum.roblox.com/t/neon-gradient-transparency-on-mesh-vertex-painting/2412540) (snippets).
- `MeshPart.DoubleSided` is meant "for meshes that are typically modeled as cards such as a leaf, hair, or cloth". — [`MeshPart.yaml`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MeshPart.yaml) (read).
- VFX meshes are animated with tweens, for example with "JV's Mesh plugin". — [YouTube, "Easiest Way To Animate VFX In Roblox"](https://www.youtube.com/watch?v=zRKn3Ry-npw) (snippet).

**The owner's reference and tutorials**
- In ZPLSQ1o7Q, "VFX made in Blender" means low-poly emissive meshes: flat rings and thin cylinders for light columns, zig-zag ribbons for lightning, faceted shards, one coloured ring pad per power. The motion is on the Roblox side. — `media/tiktok/NOTES.md` (project).
- Introductory particle tutorials: [DevForum 2068650, "Introduction to VFX: Particles"](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650) (snippet, ~2022) and [DevForum 872437, "VFX Tutorial"](https://devforum.roblox.com/t/vfx-tutorial-roblox/872437) (title only, ~2020).

### Inferences
**A headless VFX texture recipe (inferred from the sources above)**
- Render 16 or 64 frames at 128×128 (or 256×256 for a 4×4 sheet) with Eevee or Cycles: an emission shader, film transparent on (or a black world for additive textures), no trimming.
- Pack them into a 1024×1024 sheet with Pillow, leaving 8 px of transparent gutter in each 128 px cell, and premultiply or clean any edge alpha.
- Play it with `LightEmission` 1 for glows and 0 for smoke, `FlipbookMode` OneShot for bursts and Loop for auras, at 15 to 30 fps.
- A static random-frame sheet (`FlipbookStartRandom`, framerate 0) gives four or sixteen sparkle or star shapes for the price of one texture.

**Mesh VFX recipe**
- Ring pads, light columns and orbit rings come from bpy as open, `DoubleSided` meshes with a UV gradient.
- Use Neon for solid glow, or a SurfaceAppearance (Transparency mode plus emissive) for fades.
- Animate with client tweens (spin, scale pulse, transparency).

**Mobile rules for pets**
- Keep each pet's particle total inside the project's per-tier caps. Prefer few, small, reused textures (one shared sparkle sheet).
- Use `LightEmission` rather than a PointLight wherever possible, and give lights Shadows off.
- Use at most one Highlight per selected pet.
- No Glass on pets; it does not refract on mobile anyway.
- Toggle effects by `Enabled` or Transparency, not by creating and destroying them.

**New to the project:** the Custom flipbook layout, the deactivation of flipbooks on low-memory clients, the gutter and trim rules, the Blender render-and-pack recipe and the gradient mesh-VFX method. The 100-per-second cap, the Beams and the 255 Highlights are already in `Roster-Redesign.md` and `Species-Effects.md`.

### Gaps
- No primary source gives Roblox's total on-screen particle ceiling per device. The project's "reported phone ceiling of 3,600" in `Roster-Redesign.md` was not re-verified here.
- No source gives the maximum `FlipbookSizeX` or `FlipbookSizeY`, or whether non-power-of-two sheets are mip-safe.
- I could not read jarvislabsreal's actual Blender settings; the clip shows only results.

---

## 6. Tutorials by real Roblox pet and VFX creators, with concrete steps

### Takeaway
The concrete, step-level tutorials are DevForum community posts (pet modelling ~2020 to 2021, VFX ~2022 to 2025), Roblox's own Creator Docs, and a handful of YouTube videos. None could be opened or watched from this container, so their steps above come from search snippets. The Creator Docs, the Blockbench source and Blender itself were read or measured directly.

### Cited Findings
**Pet modelling**
- [Creating Simulator-Styled Pets in Blender (DevForum 517174)](https://devforum.roblox.com/t/creating-simulator-styled-pets-in-blender/517174): loop cut, proportional edit (O), bevel the side edges with Ctrl+B, keep animated parts separate (snippet).
- [How to make Pets in Blender (DevForum 1468850)](https://devforum.roblox.com/t/how-to-make-pets-in-blender/1468850): a hotkey list (snippet).
- [How are modern simulator pets made? (DevForum 2882620)](https://devforum.roblox.com/t/how-are-modern-simulator-pets-made/2882620): Blender or Maya, Photoshop or Substance, gradient-lit textures, wings as welded parts (snippet).
- [note.com/robloxken](https://note.com/robloxken/n/n9e2195f7fea7?hl=en): square pets in Blender and Studio (title only).
- YouTube, not watched: [Mck-ndoI_yA](https://www.youtube.com/watch?v=Mck-ndoI_yA) (Pet Sim 99 and Pet Sim X style pet), [3MNMq2J72UE](https://www.youtube.com/watch?v=3MNMq2J72UE), [Ied8ktbjmlQ](https://www.youtube.com/watch?v=Ied8ktbjmlQ).
- A DevForum thread covers rendering pets into inventory icons. — [DevForum 2668167, "How to render out pets for a pet inventory like arm wrestle simulator"](https://devforum.roblox.com/t/how-to-render-out-pets-for-a-pet-inventory-like-arm-wrestle-simulator/2668167) (title only, ~2023).

**VFX**
- [How to make Animated Slash Effects with only Blender! (DevForum 1794034)](https://devforum.roblox.com/t/how-to-make-animated-slash-effects-with-only-blender/1794034): Voronoi and gradient shader, PNG frames on black, packed sheet, black removed, 4×4 OneShot (snippet).
- [2 Free Realistic Flipbook Particle Explosions (DevForum 3035597)](https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597): Cycles with a transparent background, no auto-trim (snippet).
- [Introduction to VFX: Particles (DevForum 2068650)](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650): insert an emitter, colour, size, squash, texture swap (snippet).
- [Transparency gradient in Blender (DevForum 3941014)](https://devforum.roblox.com/t/how-do-i-make-a-transparency-gradient-in-blender/3941014): UV-projected gradient, AlphaMode Transparency, DoubleSided, or vertex-colour alpha via FBX (snippet).
- [The Roblox Sprite Sheet Tutorial (YouTube)](https://www.youtube.com/watch?v=ihbM-LOUyrM): sprite sheets versus flipbooks and importing them (snippet; posted ~August 2026).
- Roblox's own particle curriculum. — [Roblox Creator Docs, "Work with particle emitters"](https://create.roblox.com/docs/tutorials/curriculums/artist/work-with-particle-emitters) (snippet; the docs' repository source was read for the particle-emitter page itself).

**Pet scripting**
- [Pet follow like psx (DevForum 3039325)](https://devforum.roblox.com/t/pet-follow-like-psx/3039325) and [Pet follow bobbing transition (DevForum 3595856)](https://devforum.roblox.com/t/how-would-i-make-my-pet-follow-system-have-a-smooth-transition-from-bobbling-to-standing-still-when-a-player-is-moving-not-moving/3595856): CFrame lerp about 0.15, sine bob, separate orientation from position (snippets).

**Primary references read**
- Roblox creator-docs at `58f787e` (2026-10-16): [specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md), [texture-specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md), [surface-appearance.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/surface-appearance.md), [particle-emitters.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/particle-emitters.md), [beams.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/beams.md), [trails.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/trails.md), [highlighting.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/highlighting.md), [light-sources.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/light-sources.md), [materials.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/materials.md), [improve.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md), and the class and enum YAML (MeshPart, TriangleMeshPart, SurfaceAppearance, ParticleEmitter, RenderFidelity, CollisionFidelity, ParticleFlipbookLayout).
- The Blockbench source at `7c92e27`: [add_mesh.ts](https://github.com/JannisX11/blockbench/blob/master/js/modeling/mesh/add_mesh.ts), [lang/en.json](https://github.com/JannisX11/blockbench/blob/master/lang/en.json).

### Inferences
- Every pet-modelling tutorial found is Blender-based, and none is Blockbench-based. That matches the owner's TikTok creators, who show only Blender. Blender (headless, as now) stays the builder, and Blockbench is at most the face-painting desk (inferred).
- The VFX tutorials agree on one pipeline: Blender for the art, Roblox emitters, Beams and tweens for the motion. Our bpy plus Pillow tools can reproduce it with no paid tool (inferred).

### Gaps
- No real creator's video was watched, and no DevForum post's full text was read. A Mac session with a browser could open DevForum 517174, 2882620, 1794034 and 3035597 and the three YouTube pet tutorials, and copy down any numeric bevel widths, texture sizes and frame counts.
- No X, TikTok or YouTube post by a named pet studio (BIG Games, Uplift Games) describing its own pipeline was found.
