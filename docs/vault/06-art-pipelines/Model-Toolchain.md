---
tags: [art-pipelines, tools, blockbench, substance]
aliases: [Model toolchain]
up: "[[Art-Pipelines]]"
---
# Model toolchain: Blockbench, Blender and Substance 3D Painter for the species

2026-10-15, research worker. Ethan: "Incorporate Blockbench, Blender and Substance Painter to create these character models." This note says what each tool does for a 1,000 to 2,500 triangle cute creature, what crosses each hand-off, whether the rig and animation route that [[Character-Pipeline]] said we lacked at launch now exists, what a cloud session can write without a GUI, what costs money, and what we build next. Background: [[Character-Pipeline]], [[Sculpt-Pass]], [[Surface-Pass]], [[Blender-MCP]], [[Tools-Status]].

Sources are tagged: **(read)** I read the primary text (the Blockbench source on GitHub at 5.2.2, the Roblox `creator-docs` repository, the Khronos glTF exporter and specification repositories); **(snippet)** a search-result summary of a page I could not open (every Adobe page: `helpx.adobe.com`, `experienceleague.adobe.com` and `substance3d.adobe.com` do not resolve here, nor do `blockbench.net`, `docs.blender.org` or `khronos.org`); **(memory)** my own recollection; **(inferred)** a conclusion from read code. Nothing here was tested on a machine with the three apps installed; the probes at the end are how it gets tested.

**The answer in five lines.**
1. Blender stays the builder (headless, as now). Blockbench is the free, light editor where a person hand-paints pixel textures and keyframes idle, walk and hatch on a rig. Substance 3D Painter is the optional PBR coat for hero species, and it is the only one of the three that costs money or needs a login.
2. The rig route exists. Blockbench's glTF export carries bones (groups as bones, or armatures with painted weights) and one clip per animation; Blender's glTF export carries skins and actions; the Roblox Importer reads "rigs ... animation data" from `.gltf` and `.fbx`; a creature without a Humanoid plays them through an `AnimationController` with an `Animator`. Animations must be published from Studio (Open Cloud takes none).
3. A cloud session can write a `.bbmodel` directly: it is plain JSON with base64 PNG textures, and the schema is below. Blockbench itself has no command line or headless mode, so painting and animating happen in the app on the Mac.
4. Painter runs scripts, but only inside the running app (plugin folders, or a remote port when launched with `--enable-remote-scripting`). A script can create a project from our GLB, set OpenGL normals, insert a smart material and export the maps.
5. Needs Ethan's money or login: only Painter (Steam perpetual about $200, Adobe about $60 a month, or the free student licence, which is non-commercial). Blockbench is free and needs no account. Blender is installed. The 8 GB Mac is below Painter's published 16 GB minimum, so trial before buying.

---

## 1. The chain

Today a species goes recipe to `species_sculpt.py` (headless `bpy`) to a GLB with one MeshPart per material slot and `COLOR_0` vertex colours, through `tools/upload_assets.py` (Open Cloud Assets API) into Studio, where `materials.json` restores the seven slot colours ([[Sculpt-Pass]], [[Map-Dressing]]). The new chain keeps that spine and adds two optional stops. Steps 3 and 4 are the person's; everything else is a script.

| Step | Tool | What it does for a 1,000 to 2,500 triangle creature | In | Out |
|---|---|---|---|---|
| 1. Block-out, fuse, retopo | Blender, headless `bpy` (as now) | the recipe to one fused skin, QuadriFlow or Decimate to budget, face by ray cast, the three ship checks; **new**: a UV unwrap and a palette bake, because Blockbench and Painter paint on UVs, not vertex colours | recipe (`species_recipes.py`) | `<Id>.glb` with UVs, `COLOR_0`, custom normals, one material per slot; `materials.json`; `notes.md` |
| 2. Project file | the cloud bbmodel writer, `tools/blockbench/to_bbmodel.py` (built, see The writer) | turns the species folder into a Blockbench project: one mesh per slot, the baked palette as a texture, groups as bones with origins from the recipe, an empty idle | `<Id>.glb`, `materials.json`, recipe | `<Id>.bbmodel` (JSON, Generic Model, format 5.0) |
| 3. Paint and animate | Blockbench on the Mac (free) | pixel-accurate texture painting on the UV, group or armature rig, keyframes with linear, catmull-rom, bezier or step interpolation, IK | `<Id>.bbmodel` | `<Id>.bbmodel` (saved), `<Id>.glb` (File > Export > glTF: textures embedded, bones, one clip per animation), PNG texture |
| 4. PBR coat (hero species only) | Substance 3D Painter on the Mac (paid or student) | one texture set per material slot, a smart material, baked curvature or AO, export preset for our maps | `<Id>.glb` or `.fbx` with UVs | `<Id>_<Slot>_color.png`, `_normal.png` (OpenGL), `_roughness.png`, `_metalness.png`, `_emissive.png`; the `.spp` project |
| 5. Upload the mesh | `upload_assets.py` (Open Cloud) | the GLB as a Model asset, PNG maps as Decals then Image ids (`--textures`), `materials.json` for slot colours | `<Id>.glb`, PNGs | asset ids in `asset_ids.json`, `Textures.luau` rows |
| 6. Import the rig and animation | Studio 3D Importer, on the Mac | `.gltf` or `.fbx` with Rig Type Custom; bones become `Bone` instances, the animation lands in `AnimSaves`; the Animation Editor publishes it for an asset id | `<Id>.glb` from step 3 | a `Model` with `Bone`s; an Animation asset id per clip |
| 7. Play | our loader and renderer (client) | `AnimationController` plus `Animator` on the creature model, ids from a data table | asset ids | idle, walk, hatch in game |

Units and axes at the hand-offs: Blockbench exports positions divided by its `model_export_scale` (default 16, so 16 Blockbench units are one glTF metre) **(read, `gltf.js` `scale_factor: 1/options.scale`; `fbx.ts` falls back to 16)**; glTF's units are metres with +Y up and the front facing +Z **(read, glTF spec)**; Blender's exporter writes +Y up by default and has no scale option, so one Blender unit is one glTF metre **(read, `io_scene_gltf2/__init__.py`; inferred)**; the Roblox Importer's Scale Unit defaults to Studs **(read, `importer.md`)**, and what one glTF metre becomes in studs is not stated in the pages read: the Mac probe measures it. Blockbench's formats default to a forward direction of `-z` **(read, `format.ts`)** while glTF's front is +Z, so a creature modelled facing "forward" in Blockbench may arrive in Studio facing the other way from one built in Blender (ours face -Y in Blender, which the exporter turns into +Z).

### What survives each step

| | Blender GLB (step 1) | into Blockbench (step 2 or 3) | Blockbench GLB (step 3) | Painter (step 4) | Roblox import (steps 5 and 6) |
|---|---|---|---|---|---|
| Vertex colours | yes, `COLOR_0` when exported with `export_vertex_color` set to ACTIVE or through the material **(read)** | **lost**: a Blockbench mesh has vertices, faces, UVs and a texture, no colour attribute **(read, `mesh.js`; inferred)**; the bbmodel writer bakes them to a palette texture instead | none | not exported; usable as a bake source for an ID map **(memory)** | read from `.fbx` and `.gltf` (Ignore Vertex Colors is a toggle) **(read)**; ignored by SurfaceAppearance (the report) |
| UVs | yes | yes, stored in pixel units of the project resolution, normalised on export **(read, `mesh.js` `updateUV`)** | yes | required; one texture set per material **(snippet)** | one UV set in 0:1, overlaps allowed **(read)** |
| Bones and weights | an armature with up to 4 influences per vertex by default **(read)** | groups (no weights) or armatures with `vertex_weights` per bone, at most four per vertex when deforming **(read)** | groups become `THREE.Bone`s with every vertex weighted 1.0 to its group's bone; armatures write four `skinIndex`/`skinWeight` slots, extra influences dropped silently **(read)** | ignored, mesh kept | `Bone` instances; "A vertex can not be influenced by more than 4 bones or joints"; root at 0,0,0 with no influences **(read)** |
| Animations | actions and NLA tracks as glTF animations **(read)** | the glTF importer plugin reads "meshes, textures, groups, and animations", not armatures yet **(read, plugin about)** | one `AnimationClip` per Blockbench animation, named after it; rotation as quaternions; non-linear keyframes resampled **(read)** | none | "animation data" from `.fbx` and `.gltf` **(read)**; saved to `AnimSaves` on import **(snippet)**; published from the Animation Editor **(read)** |
| Materials | PBR materials with textures **(read)** | one texture per face or mesh, flat; `pbr: true` in the Generic Model (texture channels) **(read)** | the texture embedded; `embed_textures` default on **(read)** | the five Roblox maps as PNG **(snippet)** | "basic and PBR textures" **(read)**; our `materials.json` restores slot colours when a GLB arrives grey |
| Custom normals | written **(read, `export_normals`)** | Blockbench meshes shade `flat` or `smooth` per mesh **(read)** | three.js normals | kept | the open probe in [[Sculpt-Pass]] |

Three consequences. First, our vertex-colour route and the Blockbench route are exclusive: a species that goes through Blockbench or Painter carries its colour as a texture, so step 1 must bake the palette and unwrap before export (a new job for the Blender worker, untested headless). Second, a textured, rigged species is one skinned MeshPart with one SurfaceAppearance, not seven MeshParts, which is the draw-call win [[Character-Pipeline]] wanted and also means the slot colours live in the texture (rarity recolours become tints or texture swaps, the report's "rarity is a recolour"). Third, the budget: Blockbench's own glTF scaling and the Roblox 20,000-triangle cap are not the limit; our 2,500 cap is ([[Look-Plan]]).

---

## 2. Animation: does the rig route exist now?

Yes, on paper, with gotchas; nothing is verified in Studio yet (the Mac probe in section 6).

**Roblox side (read, creator-docs).** The Importer takes "`.fbx`, `.obj`, or `.gltf`" and "The `.fbx` and `.gltf` formats support multiple mesh objects and hierachies, basic and PBR textures, cage mesh objects, rigs, avatar components, animation data, and vertex colors" (`studio/importer.md`). Rig Type is R15, Custom or No Rig and is auto-detected "based on the detected rigging and skinning data". Rules (`art/modeling/specifications.md`): "Individual meshes can not exceed 20,000 triangles"; "A vertex can not be influenced by more than 4 bones or joints"; bones frozen at scale 1; "The root bone or joint should always be set to `0`, `0`, `0`"; "Do not apply influences to the Root bone or joint"; "Only a single animation track can be exported with a mesh or model"; "All geometry must be watertight without exposed holes or backfaces". Playback (`animation/using.md`): "To play animations on rigs that do not contain a Humanoid, you must create an AnimationController with a child Animator", then `Animator:LoadAnimation()` on an `Animation` with the `AnimationId`. The asset id comes from the Animation Editor: "Select Publish to Roblox from the contextual menu" and "copy the animation's asset ID from the Toolbox" (`animation/editor.md`); "You can only create animations using rigs". Open Cloud accepts the Animation type only as `.rbxm` or `.rbxmx` (the report), so every clip is published by hand in Studio. Studio's own glTF export "Does not support animation data" (`gltf-export.md`, beta), which is about leaving Studio, not entering it.

**Roblox side (snippet).** The glTF importer beta of 2023 started with meshes and PBR, with "rigged models, skinning, and animations to follow"; the team "aimed to have rigs and animations working by early/mid-summer" 2023; a 2024 recap drew praise for the glTF support; a May to August 2025 recap lists a fixed glTF skinning bug (skinned parts imported at the origin), so use a current Studio. The "Animation Import Improvements" DevForum post: the Importer now saves a model's animation data to `AnimSaves` automatically; the Animation Clip Editor importer gained Rig Scale ("a stud is 0.28 meters"), Rest Pose Source, Rig Type R15 or Custom ("Custom suits non-humanoid characters") and track selection; one commenter reports the "Animation General" section missing for glTF imports and that joints as `AnimationConstraint`s are not supported for custom rigs. The 3D Importer full release claimed "importing multiple animations from one file", which contradicts the single-track line in `specifications.md`: plan one clip per file for the probe and test two afterwards.

**Blockbench side (read, `js/formats/standards/gltf.js` and `fbx.ts`).** The glTF codec uses `THREE.GLTFExporter` with options `encoding` (ASCII glTF or binary glb), `scale` (the `model_export_scale` setting), `embed_textures` (default true), `armature` (default false; turns root groups into bones), `merge_armature` (merge the meshes of an armature into one skinned mesh) and `animations` (default true). `buildAnimationTracks` makes one `THREE.AnimationClip` per Blockbench animation named `animation.name` and `animation.length` long; rotation channels become quaternion tracks; keyframes that are not linear, or that hold MoLang scripts, are resampled at the `animation_sample_rate` setting; animators with no bone are skipped with a console log. With groups as bones, each group is a `THREE.Bone`, child meshes merge into one skinned mesh and every vertex is weighted 1.0 to its group's bone. With a Blockbench 5 armature, bones carry `vertex_weights` and the export writes four `skinIndex` and `skinWeight` slots per vertex, normalised over four; a fifth influence is dropped without a warning. 5.2.0 added "option to export armatures to GLTF with multiple separate meshes" and "IK compatibility with armatures"; 5.2.1 fixed "glTF animation export issue with multiple animations using IK". The FBX codec (FBX 7.3, ASCII or experimental binary) writes animation stacks and curves, but skin clusters only for armature bones (groups become `Null` nodes with no skin), and the dialog warns "Armature export to FBX is currently experimental, glTF is recommended instead."

**Blender side (read, Khronos `glTF-Blender-IO`).** `bpy.ops.export_scene.gltf` has `export_animations` (default True, "Exports active actions and NLA tracks as glTF animations"), `export_animation_mode` (default ACTIONS: "An action will be exported if it is the active action on an object, or it is stashed to an NLA track"; also ACTIVE_ACTIONS merged, NLA_TRACKS one animation per track, SCENE), `export_skins` (True), `export_influence_nb` (default 4; "Models may appear incorrectly in many viewers with value different to 4 or 8"), `export_all_influences` (False), `export_def_bones` (False), `export_force_sampling` (True), `export_rest_position_armature` (True), `export_anim_single_armature` (True, "Export all actions, bound to a single armature"), `export_apply` (Apply Modifiers "excluding Armatures", which also "prevents exporting shape keys"), `export_yup` (True), `export_vertex_color` (MATERIAL, ACTIVE or NONE), `export_normals` (True). All of this runs headless, so a Blender-rigged species can be exported by the same `bpy` scripts we already run. Roblox's own Blender notes are for FBX (`export-requirements.md`, `character-bodies/export.md`): Apply Scalings to FBX Unit Scale, Add Leaf Bones off, Bake Animation only "exporting content with animation keyframes", "ensure that your animation timeline Start and End include the entire range of your animations", NLA Strips and All Actions off, Simplify 0.0.

**Gotchas, in the order they will bite.**
1. **Scale.** Model at 16 Blockbench units per metre (the default export scale), or set the glTF dialog's scale to match; in Studio set Scale Unit to the unit the file was modelled in. The metre-to-stud factor is the first number the probe writes down.
2. **Axis and facing.** glTF is +Y up, front +Z (read); Blockbench's default forward is -Z (read); Blender's exporter converts to +Y up (read). Check which way the creature faces in Studio before the loader's `face on -Y` assumption is trusted for Blockbench-made species.
3. **The Root.** Roblox wants a root bone at the origin with no influences (read). Blockbench's groups-as-bones path weights every mesh to its own group, so give each species an empty top-level `Root` group that holds the body group, never a mesh.
4. **Names.** Animations are matched to bones by name in Studio (snippet), and Blockbench enforces unique ASCII bone names only when a format's `bone_rig` is on (read, `armature_bone.ts`, `name_regex` `a-zA-Z0-9_`): use unique ASCII names with no spaces for groups, bones and animations; Blockbench's glTF path does not sanitise them (only the Bedrock codec does, 5.1.5).
5. **Looping.** A Blockbench animation's `loop` ('once', 'hold', 'loop') is not a glTF concept; `THREE.AnimationClip` has no loop flag (inferred). Set `AnimationTrack.Looped` in the loader from the data table.
6. **Influences.** Four per vertex everywhere (glTF spec per set, Blockbench's export, Roblox's rule); Blender's default is four. Never tick Include All Bone Influences.
7. **One track per file** until the probe shows two import cleanly.
8. **Rest pose.** If a glTF import comes in posed wrongly (the missing Animation General section, snippet), export the same rig as FBX from Blender; do not use Blockbench's experimental armature FBX.
9. **Bone count.** No cap appears in the pages read; the triangle cap and four influences are the limits. Keep rigs small anyway (a body, a head, four legs, a tail, an ear or two: 10 bones) for the phone.
10. **Merged meshes.** `merge_armature` folds the per-slot meshes into one skinned mesh, which is what we want for a rigged species; the slot colours must then be in the texture, not in `materials.json`.

---

## 3. What a cloud session can write without a GUI

### 3.1 The `.bbmodel` file (read, Blockbench 5.2.2 source)

A `.bbmodel` is a JSON document. The codec (`js/formats/bbmodel.js`) writes `meta.format_version` from `const FORMATV = '5.0'`, `meta.model_format` from the format id (`free` is the Generic Model, `js/formats/generic.ts`), `meta.box_uv`, the `ModelProject` properties (`name`, `model_identifier`, `visible_box`, `variable_placeholders`, ...), `resolution` `{width, height}` (defaults 16), `elements` (each element's `getSaveCopy`), `groups` (each group's childless copy), `outliner` (`Outliner.toJSON()`: a nested tree of `{uuid, isOpen, children}` for groups and bare uuid strings for elements), `textures` (with `source` as a PNG data URL and `internal: true` when embedded) and `animations` (each animation's undo copy with its animators). Loading reverses it: `OutlinerElement.fromSave(template)` per element, `new Group(template, template.uuid).init()` per group, `Outliner.loadJSON(model.outliner)` to arrange them (an outliner entry that is an object with a `name` is built as a legacy group, so the 4.x nested form still loads), `new Texture(tex, tex.uuid).add(false)` then `fromDataURL(tex.source)`, and `new Animation().extend(ani).add()`. Older files are migrated (`processCompatibility`: pre-3.2 Z inversion, pre-5.0 MoLang and bezier sign changes), and a newer `format_version` than the app's is refused.

Units: a Blockbench unit is a sixteenth of a Minecraft block; 16 units export as one glTF metre at the default scale. UVs are stored in pixels of the project resolution (`resolution.width` by `height`, or the texture's `uv_width` by `uv_height` when per-texture UV size is on) and divided down to 0..1 only when rendering or exporting (`mesh.js` `updateUV`). Vertex keys are random 4-character strings and face keys 8-character strings (`bbuid(4)`, `bbuid(8)`); any unique ASCII strings work. A face's `texture` is written as the texture's index in the `textures` array when a bbmodel is compiled (`Blockbench.hasFlag('compiling_bbmodel')`), as a uuid otherwise, `null` for a transparent face (`face.ts`); the writer uses the index. Mesh face vertex order: "The vertices go around the face counter-clockwise when looking at the front side of the face" (blockbench-types); faces may be triangles, quads or n-gons. Data points in keyframes are MoLang strings, not numbers ('0', or '1' for scale). Group origins default to `[0, 0, 0]` on a centred grid (the Generic Model is `centered_grid: true`).

The skeleton a writer emits (one mesh, one texture, two groups as bones, one idle; `...` marks repetition):

```json
{
  "meta": { "format_version": "5.0", "model_format": "free", "box_uv": false },
  "name": "Sparkfox",
  "model_identifier": "sparkfox",
  "visible_box": [1, 1, 0],
  "variable_placeholders": "",
  "variable_placeholder_buttons": [],
  "timeline_setups": [],
  "unhandled_root_fields": {},
  "resolution": { "width": 128, "height": 128 },
  "elements": [
    {
      "type": "mesh",
      "uuid": "6f1d2c5a-0000-4000-8000-000000000001",
      "name": "Body",
      "color": 0,
      "origin": [0, 0, 0],
      "rotation": [0, 0, 0],
      "shading": "smooth",
      "export": true,
      "visibility": true,
      "locked": false,
      "render_order": "default",
      "vertices": { "v001": [0, 8, 4], "v002": [4, 8, 0], "v003": [0, 8, -4], "...": "..." },
      "faces": {
        "f0000001": { "vertices": ["v001", "v002", "v003"], "uv": { "v001": [0, 0], "v002": [16, 0], "v003": [16, 16] }, "texture": 0 },
        "...": "..."
      }
    },
    {
      "type": "cube",
      "uuid": "6f1d2c5a-0000-4000-8000-000000000002",
      "name": "EyeL",
      "from": [1, 9, 4], "to": [3, 11, 5],
      "origin": [0, 0, 0], "rotation": [0, 0, 0],
      "inflate": 0, "autouv": 0, "color": 1, "visibility": true, "box_uv": false, "uv_offset": [0, 0],
      "faces": {
        "north": { "uv": [0, 0, 2, 2], "texture": 0 }, "east": { "uv": [0, 0, 1, 2], "texture": 0 },
        "south": { "uv": [0, 0, 2, 2], "texture": 0 }, "west": { "uv": [0, 0, 1, 2], "texture": 0 },
        "up": { "uv": [0, 0, 2, 1], "texture": 0 }, "down": { "uv": [0, 0, 2, 1], "texture": 0 }
      }
    }
  ],
  "groups": [
    { "uuid": "6f1d2c5a-0000-4000-8000-00000000000a", "name": "Root", "origin": [0, 0, 0], "rotation": [0, 0, 0], "export": true, "isOpen": true, "locked": false, "visibility": true, "autouv": 0, "mirror_uv": false, "shade": true, "color": 0 },
    { "uuid": "6f1d2c5a-0000-4000-8000-00000000000b", "name": "Body", "origin": [0, 6, 0], "rotation": [0, 0, 0], "export": true, "isOpen": true, "locked": false, "visibility": true, "autouv": 0, "mirror_uv": false, "shade": true, "color": 0 }
  ],
  "outliner": [
    { "uuid": "6f1d2c5a-0000-4000-8000-00000000000a", "isOpen": true, "children": [
      { "uuid": "6f1d2c5a-0000-4000-8000-00000000000b", "isOpen": true, "children": [
        "6f1d2c5a-0000-4000-8000-000000000001",
        "6f1d2c5a-0000-4000-8000-000000000002"
      ] }
    ] }
  ],
  "textures": [
    {
      "uuid": "6f1d2c5a-0000-4000-8000-0000000000f0",
      "name": "Sparkfox.png", "path": "", "folder": "", "namespace": "", "id": "0", "group": "",
      "width": 128, "height": 128, "uv_width": 128, "uv_height": 128,
      "particle": false, "use_as_default": false, "layers_enabled": false, "sync_to_project": "",
      "file_format": "png", "render_mode": "default", "render_sides": "auto", "wrap_mode": "limited", "pbr_channel": "color",
      "fps": 7, "frame_time": 1, "frame_order_type": "loop", "frame_order": "", "frame_interpolate": false,
      "visible": true, "internal": true, "saved": false,
      "source": "data:image/png;base64,iVBORw0KGgo..."
    }
  ],
  "animations": [
    {
      "uuid": "6f1d2c5a-0000-4000-8000-0000000000a0",
      "name": "idle", "loop": "loop", "override": false, "length": 1.0, "snapping": 24, "selected": false,
      "anim_time_update": "", "blend_weight": "", "start_delay": "", "loop_delay": "",
      "animators": {
        "6f1d2c5a-0000-4000-8000-00000000000b": {
          "name": "Body", "type": "bone",
          "keyframes": [
            { "channel": "position", "data_points": [{ "x": "0", "y": "0", "z": "0" }], "uuid": "6f1d2c5a-0000-4000-8000-0000000000b1", "time": 0, "color": -1, "interpolation": "catmullrom" },
            { "channel": "position", "data_points": [{ "x": "0", "y": "0.5", "z": "0" }], "uuid": "6f1d2c5a-0000-4000-8000-0000000000b2", "time": 0.5, "color": -1, "interpolation": "catmullrom" },
            { "channel": "position", "data_points": [{ "x": "0", "y": "0", "z": "0" }], "uuid": "6f1d2c5a-0000-4000-8000-0000000000b3", "time": 1.0, "color": -1, "interpolation": "catmullrom" }
          ]
        }
      }
    }
  ]
}
```

Field notes from the source. Cube: `from`, `to`, `origin`, `faces`, `autouv`, `color`, `type`, `uuid` always; `rotation`, `inflate`, `uv_offset`, `visibility`, `export`, `shade`, `mirror_uv` only when not the default; faces are `north, east, south, west, up, down` with `uv` as `[x1, y1, x2, y2]`, plus optional `rotation` (0), `tint` (-1), `cullface`, `material_name`. Mesh: `name`, `color`, `origin`, `rotation`, `shading` (`flat` or `smooth`), `export`, `visibility`, `locked`, `render_order`, `vertices`, `faces`. Group: `name`, `origin`, `rotation`, `export`, `isOpen`, `locked`, `visibility`, `autouv`, `mirror_uv`, `shade`, `color`, `bedrock_binding` (bedrock only). Armature (Blockbench 5; optional, for weight painting): an element `{"type": "armature", "name", "origin", "isOpen", "children": [uuids]}` whose children are `{"type": "armature_bone", "name", "origin", "rotation", "length": 8, "width": 2, "connected": true, "color", "vertex_weights": {"<first 6 of mesh uuid>:<vkey>": 1.0}, "children": [uuids]}` and meshes; the writer can start with groups and let the person convert. Animation: `uuid`, `name`, `loop`, `override`, `length`, `snapping`, `selected`, `anim_time_update`, `blend_weight`, `start_delay`, `loop_delay` (MoLang strings), optional `markers`, `animators` keyed by the group or bone uuid (`effects` is the particle and sound animator). Keyframe: `channel` (`rotation`, `position`, `scale`; `particle`, `sound`, `timeline` for effects), `data_points` (`x`, `y`, `z` as strings; `effect`, `locator`, `script`, `file` for effects), `uuid`, `time`, `color` (-1), `interpolation` (`linear` default, `catmullrom`, `bezier`, `step`), `uniform` (scale only), and the four `bezier_*` vectors only when bezier. Textures: `visible`, `internal`, `saved`, `uuid` and the Property list above; `source` only when embedded.

Feasibility: **yes.** The writer needs a uuid generator, a PNG encoder (Pillow is in use) and this schema; every field has a default in the app (`Property.reset` and `merge`), so a minimal file loads. A third-party CLI already does the reverse of our GLB path, glTF 2.0 to bbmodel 5.0 with cubes, meshes, UVs, textures, groups and animations (PROMETHIA's `gltf2bbmodel` on Codeberg, last commit 2026-01-16; "Higher-level rigging features will have to be baked, like IK constraints"; each Blender object becomes a group plus a mesh) **(snippet)**. The one thing the writer cannot do is run Blockbench: the repository has no command line or headless mode (the README's only commands are `npm install`, `npm run dev`, `npm run serve`; the app is Electron, with a web build at `web.blockbench.net` **(snippet)**), and plugins are JavaScript that runs inside the app (`plugin_loader.ts`; the plugin registry `plugins.json` holds Minecraft, Hytale and Cosmic Reach exporters, a glTF importer, "Export to Blender (.blend)" and no Roblox entry **(read)**). So the first open of every generated file is a person's job on the Mac, which is the verification we want anyway.

### 3.2 Substance 3D Painter automation (snippet, Adobe's API and user guide pages)

- **Where scripts run.** Python modules in `~/Documents/Adobe/Adobe Substance 3D Painter/python/plugins` (enabled by hand under Python > Plugins) or `python/startup` (loaded at launch), shared code in `python/modules`; each module exposes `start_plugin()` and `close_plugin()`; the Python menu has Plugins Folder and Reload Plugins Folder. There is a Python console in the app.
- **Remote.** Launch Painter with `--enable-remote-scripting`; Adobe's `lib_remote.py` talks to it over HTTP on `localhost:60041` (`RemotePainter(port=60041, host='localhost')`, `execScript(code, "python")`); "scripts may fail if the application is still starting up". The user-guide page is titled "Remote control / headless", but its body was not readable here, and no page read says Painter runs without its window; treat "headless" as "driven from outside while the app is open". Command line: `--mesh <file>` creates a project or updates the mesh of one, `--export-path`, `--mesh-map`, `--split-by-udim`.
- **What a script can do.** `substance_painter.project.create(mesh_file_path=..., settings=substance_painter.project.Settings(import_cameras=True, normal_map_format=substance_painter.project.NormalMapFormat.OpenGL, ...))` (also `project_workflow`, `default_texture_resolution`); `project.open`, `is_open`, `needs_saving`, `save_as`; `substance_painter.layerstack.insert_smart_material(position, smart_material)` returns the new group layer (the layer-stack API arrived in Painter 10.0; `insert_smart_mask`, `insert_paint` too); `substance_painter.export.export_project_textures(json_config)` with `exportPath`, `exportList` (`rootPath` per texture set), `defaultExportPreset`, `exportPresets` (the maps, channels, `fileFormat`, `bitDepth`, `sizeLog2`, padding) and `exportParameters`, returning a `TextureExportResult` with status and file list; errors raise. API 0.3.5 is documented with 0.3.7 in the changelog. Importing a `.spsm` smart material from disk goes through the `resource` module's import function **(memory, not read)**.
- **Mesh in.** `.fbx`, `.obj`, `.abc`, `.dae`, `.ply`, `.gltf`, `.glb`, `.usd` and variants (Adobe FAQ). Our GLB qualifies once it has UVs.
- **Maps out for Roblox.** No Roblox preset ships; an export preset is a JSON `exportPresets` entry (or a saved `.spexp`). Roblox wants five maps (`surface-appearance.md`, read): colour RGB, normal RGB in "OpenGL format - Tangent Space", roughness, metalness and emissive mask as 8-bit greyscale (`texture-specifications.md`), 1024 px at most for PBR on characters, 256 px for a 5-stud object. Our preset writes `<key>_color.png`, `<key>_normal.png`, `<key>_roughness.png` (plus `_metalness` and `_emissive`) under `assets/textures/<key>/`, which is the layout `upload_assets.py --textures` already uploads and `Textures.luau` already consumes.
- **So:** a cloud session writes `tools/painter/export_species.py` and the preset; the Mac runs it inside Painter (or through the remote port) with Painter open. Nothing in Painter is scriptable from this container.

---

## 4. Cost and install

| Tool | Price | Login | Install | Fits the 8 GB Mac? |
|---|---|---|---|---|
| Blockbench 5.2.2 (8 Oct 2026) | free, GPL v3 **(read)** | none | macOS build from `blockbench.net` **(read: "download the app from the website")**; a browser build at `web.blockbench.net` with PWA install **(snippet)**; Apple-silicon and Intel builds **(snippet)** | yes (an Electron app) |
| Blender | free; installed (5.2.2 on the Mac, `bpy` 5.0.1 in the cloud, [[Tools-Status]]) | none | done | yes, when Studio is closed ([[Setup-and-Tips]]) |
| Substance 3D Painter, Steam "2026" | **$199.99 perpetual** (released 17 March 2026; "lifetime access" to that version; updates stop when the 2027 version ships, expected March; no Substance 3D Assets library and no generative features, which are Adobe-subscription only) **(snippet, Adobe community manager and Steam listing)** | a Steam account; no Adobe login needed for the app | Steam | **below the published minimum**: macOS 12+, Apple M1 minimum CPU and GPU (Adobe page), 16 GB RAM minimum per aggregators and the Steam Windows listing **(snippet)** |
| Substance 3D Painter, Adobe | Substance 3D Collection **$59.99 a month** individual (Painter, Sampler, Designer, Stager, Modeler, Assets), 30-day trial on the plan page (an older source says 7 days); the Texturing plan was $24.99 a month after the 2025 increase and may no longer be sold **(snippet)** | Adobe ID | Creative Cloud app | same |
| Substance 3D Painter, student | **free** for students and teachers "at accredited higher education institutions", a 12-month licence, renewable, proof of enrolment, **non-commercial use**, no Substance Assets **(snippet)** | Adobe ID with the education check | Creative Cloud app | same |

Plainly: Blockbench and Blender cost nothing and need no account; only Painter needs Ethan's money or login. The student licence is the cheapest route to try Painter, but its non-commercial clause does not fit textures shipped in a game that sells Robux items, so it is a trial licence, not the production one; production is the Steam perpetual or the Adobe plan, after the trial shows Painter runs on the 8 GB Mac at all. All prices are search snippets of third-party and Adobe pages; Ethan checks the live pages before paying.

---

## 5. How pet creators use these tools

What the repository already holds (read): `media/tiktok/NOTES.md` (27 videos plus batch 6) names neither Blockbench nor Substance; the creators use Claude Design, Meshy, 3D AI Studio, Tripo and headless Blender ([[Character-Pipeline]] section 1). The research notes behind the report (`research_notes/.../creature_models.md`, snippets) put Substance at the top of the trade: Uplift Games' job posts ask for "C4D, Blender, Maya" plus Substance and "in-depth PBR knowledge"; an ArtStation "Pet Generator - Roblox Game Asset" was made in Blender 4.5.1 and Substance 3D Painter "aiming for clean topology, PBR textures, and a cartoon style"; a course teaches "PBR+Handpaint" for Roblox characters; a DevForum answer says model in Blender or Maya, paint in an image editor, "optionally finish in Substance 3D Painter for extra lighting and detail", and the community route to Pet Simulator-style pets is "pull them from the Toolbox as `.obj` and rebuild in Blender with Photoshop textures and Substance Painter"; a YouTube "Making a Roblox pet dog in Blender" uses Blender plus Painter. The texture style the report settled (read): one palette texture of colour squares shared across models, flat colours, big glossy eyes, decal faces in the simulator style, Neon regions planned into the mesh.

Blockbench and Roblox: no readable creator post, forum thread or repository shows a Blockbench-to-Roblox pet workflow; the searches returned Minecraft work, Fiverr listings for Minecraft assets and Roblox's own importer pages, and Blockbench's plugin registry has no Roblox entry (read). Blockbench's community is Minecraft, Hytale and Godot or Unity indie work, and its strengths (cuboids, pixel textures, group rigs, the Bedrock animation model) match the voxel look of the dinosaur-ranch reference (ZPL8MtkYu) more than our organic skins. Inference: for this roster Blockbench earns its place as the animation and hand-paint desk with a cheap, scriptable input file, not as the modeller; Painter is the Adopt-Me-tier finish for a few hero species, after the licence and memory questions. This section should be rewritten the day the Mac adds a reference that shows either tool in use.

### From the owner's references (batch 8)

2026-10-15, the reference worker. Ethan's six links (`media/tiktok/NOTES.md`, batch 8) were watched for these three tools. **None of them shows or names Blockbench or Substance 3D Painter**: not in speech, captions, slides or on any screen; the one visible dock holds Blender, Claude, ChatGPT, Obsidian, Chrome and Roblox Studio among its readable icons. So the paragraph above stands: no creator here is evidence for either tool, and the rewrite it asks for is still open. Tagged **(watched)**: I looked at the frames or read the slides. What the creators do show:

| Creator | Tool and operation shown **(watched)** | What reaches Roblox |
|---|---|---|
| deep.haul.studios, photo post (ZPLSQrYcW) | Claude on a Pro or Max plan with the Roblox Studio MCP; an Obsidian vault of about a hundred notes (hubs Home, Roadmap, Board Pulse, Playtest Log; art notes Blender AI Workflow, ART_AND_ANIMATION, 3D Model Gallery, Import authored models, MCP_WORKFLOW); Blender 5.2.2 LTS on the Layout workspace in Object Mode with one scene file, `HarborLayout_Cinematic.blend`, whose objects are named per piece; the status bar warns "active object has non-uniform scale" | "upload Blender models into Roblox Studio"; no file format, no import setting shown |
| jarvislabsreal, ZPLSQ1o7Q | "VFX made in Blender": flat rings and thin cylinders for light columns, zig-zag ribbons for lightning, faceted rock, crystal and brick shards, all emissive, one coloured ring pad per power | meshes moved in Studio (inferred); no export shown |
| jarvislabsreal, ZPLSQAq5q | fourteen characters: a cube head with a pixel-art face texture, bevelled cubes, faceted ball hands, cone spikes, three or four flat colours; the turntable looks like a Blender render | not shown; ZPLSQAhnb shows the same models as render icons in an Index and a roll reel |
| jarvislabsreal, ZPLSxw532 | a dark plated titan with thin emissive stripes that light in sequence, fog, sparks and bloom | Roblox lighting and particles (inferred) |
| jarvislabsreal, ZPLSQAhnb | caption: "24 hours: a Claude model + Blender + Claude Design" over ten screens, a charge mechanic and a roll reel | the game's screens and models |
| vos_studiostt, ZPLSQ8AAE and ZPLSxwKHm (the batch 6 files again) | Claude Design "Model a 3D object": handoff documents, star ratings, a reference image, two prompts | a GLB from the viewer; the viewer's ring, particles and idle are not in it |

What it changes:
1. The chain the creators actually use is Claude (with the Studio MCP) driving Blender for models and effects, Claude Design for screens and 3D viewers, and Studio at the end. That is our steps 1 and 5 to 7; none of them uses steps 2 to 4.
2. The look Ethan points at (chunky cube-head characters) is flat colour plus one small pixel face texture. A pixel-accurate hand-painted face on a cube is Blockbench's job, and nothing about it needs a PBR coat: for this look Painter earns nothing, so it stays what section 4 made it, an optional coat for hero species after the trial. This is inference; no video shows either tool.
3. One Blender gotcha is on screen: a non-uniform scale on the active object. Apply scale before export; our species GLBs are written at 1 unit = 1 stud (`notes.md`).
4. Their effects are Blender meshes with the motion on the Roblox side, which matches [[Roster-Redesign]] section 6 (tweened MeshParts, no animation export to solve).
5. No creator shows an export setting, an import dialog or an animation: the Mac probe in section 6 is still the only source for scale, facing and rigged animation.

---

## 6. What we will build

1. **The bbmodel writer** (cloud). Built 2026-10-15 as `tools/blockbench/to_bbmodel.py`, see The writer below; it differs from this plan by writing one flat group per slot, using the GLB's own uvs and not baking vertex colours, and the origins from the recipe and the Blender-side unwrap and bake are still to do. The plan as first written: `tools/bbmodel_write.py --species <Id>`, standard library plus Pillow. Reads `assets/models/<Id>/<Id>.glb` (or the recipe), writes `<Id>.bbmodel` per section 3.1: one mesh per material slot (or one merged mesh with the slot cut lines kept as UV islands), the palette baked from `materials.json` and the vertex colours into a 128 or 256 px PNG embedded as base64, groups `Root > Body > {Head, LegFL, LegFR, LegBL, LegBR, Tail, ...}` with origins from the recipe's step positions, and a one-second `idle` stub. Prerequisite on the Blender side: a UV unwrap (Smart UV Project) and a palette bake added to the sculpt export, headless; untested. Test without Blender: a fixture GLB round-trips to a bbmodel that a JSON schema check passes; the real test is the Mac opening it.
2. **The Painter preset and script** (cloud, written blind until Painter exists on the Mac): `tools/painter/roblox_species.spexp` (or the JSON block) for the seven slots as texture sets, maps `_color`, `_normal` (OpenGL), `_roughness`, `_metalness`, `_emissive`, PNG 8-bit, 256 or 512 px; `tools/painter/export_species.py` that creates the project from the GLB with OpenGL normals, inserts a named smart material, exports into `assets/textures/<Id>_<Slot>/`, so `upload_assets.py --textures` and `Textures.luau` need no change.
3. **Loader plumbing** (cloud, after the probe): an `Animations.luau` data table (species id to idle, walk, hatch asset ids, loop flags), `AnimationController` plus `Animator` in the client creature renderer, and one SurfaceAppearance per slot from `Textures.luau` for species that carry a texture set. Scale and facing constants from the probe go in the data table, never in logic.
4. **Board rows** ([[Board]]): Ethan installs Blockbench and decides the Painter licence; the Mac runs the glTF animation probe; the cloud builds the writer. Tools rows in [[Tools-Status]].

**The Mac probe, written out.** In Blockbench (Generic Model): a body cube, a head cube in a `Head` group, a tail cube in a `Tail` group, all under `Body` under an empty `Root`; one 1-second `idle` with a head bob and a tail wag; File > Export > glTF, binary, Export Animations on, scale 16, textures embedded; a second export of a lone 16-unit cube. In Studio (current build): File > Import 3D, Rig Type Custom, note the Scale Unit, import; check the `Bone` instances, the `AnimSaves` folder, the Animation Editor loads and plays `idle`, Publish to Roblox gives an id; measure the lone cube in studs (that is the metre-to-stud factor) and note which way the creature faces. Then the same with a Blender-rigged cube exported by `bpy.ops.export_scene.gltf(export_animations=True, export_skins=True)`. Write the numbers under "Probe results" below and flip the Tools rows to in use.

## The writer

Built 2026-10-15: `tools/blockbench/to_bbmodel.py`, standard library plus Pillow (a built-in PNG encoder takes over when Pillow is missing, so it runs on the Mac as it is). It reads `assets/models/<Id>/<Id>.glb` with its own GLB reader (no Blender) and `materials.json`, and writes a Blockbench Generic Model project in format 5.0 to `media/blockbench/<Id>.bbmodel`.

```
python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox            # writes media/blockbench/Sparkfox.bbmodel
python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox Mossbop    # several
python3 -I tools/blockbench/to_bbmodel.py --all --out /tmp/bb           # every species folder (35 build in about 2 s)
python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox --check    # re-read the written file, validate it, write nothing
```

Options: `--models` and `--out` (relative to the repo root), `--size` (palette side, default 128), `--no-idle` (an empty `animations` list). `tools/tests/test_to_bbmodel.py` builds Sparkfox and Mossbop into a temporary folder and checks the structure; `--check` is the same invariant set the writer runs on its own output (every face's vertices exist, one uv per face vertex and inside the resolution, texture indices valid, the PNG decodes at the entry's size, uuids unique, every element and group in the outliner once, unique ASCII group names, keyframe times inside the animation).

**What is in the file** (Sparkfox: 7 meshes, 1,734 faces equal to the GLB's 1,734 triangles, 1,130 welded vertices, 262 KB):

- One `mesh` element per material slot, named `<Slot>Mesh`, and one `group` per slot named after it (Body, EyeWhite, Pupil, Mouth, BodyDark, Accessory, EyeHighlight), top level, in slot order, each holding its mesh. A group's origin is the slot's area-weighted surface centroid, so rotating it pivots about the middle of that part; a rig is made by moving the origins to the joints and dragging groups into each other. Vertices are welded by position and normal, so smooth surfaces stay connected and the hard edges the Surface pass cut stay cut. Shading is `smooth`.
- A 128 by 128 palette texture, `<Id>.png`, embedded: a flat block of each slot's `materials.json` hex in a 3 by 3 grid (42 px blocks, the spare cells transparent). Each slot's uvs are the GLB's own, fitted into its block. The file opens already coloured; some slots are tiled past 0..1 in the GLB (Body is 3 by 3 tiles), so their uvs overlap inside the block and detail painting wants a re-unwrap in Blockbench first.
- `meta.model_format "free"`, `box_uv false`, `resolution` 128 by 128, texture entry `width`, `height`, `uv_width`, `uv_height` the same. UUIDs are derived from names, so a rerun writes identical ids.
- One example animation, `idle`: 2 s, loop, three position keyframes on the Body group (0, then 2 percent of the model's height, then 0, catmull-rom). The other groups are siblings, not children, so only the body bobs until the others are dragged under Body; once they are, do not also key them or the bob doubles.

**Unit rule.** The note's rule: Blockbench writes glTF positions divided by its export scale, 16 by default, so 16 Blockbench units are one glTF unit. The species GLBs are 1 unit = 1 stud (`notes.md`: Sparkfox is 2.5 units tall), so the writer multiplies by 16 (Sparkfox is 40 units tall) and copies the axes as they are, Y up, no flip: the exact inverse of Blockbench's own exporter, so File > Export > glTF at the default scale 16 returns the GLB's scale. The face stays on +Z, which Blockbench draws as "south" (its own forward is -Z). Do not rotate the model to face north: the export would then face the wrong way for `Config.ModelFacesPlusZ`. How many studs one glTF unit becomes in Studio is still the probe's number.

**What the Mac does next** (on [[Board]]; it needs Blockbench installed, which waits on Ethan):

1. Open `media/blockbench/Sparkfox.bbmodel` in Blockbench (File > Open Model, or drag it in). Expect seven groups in the outliner, a flat-coloured fox about 40 units tall standing on the grid, one 128 by 128 texture, and `idle` in the Animate tab. Screenshot it and write down anything that fails to load or looks wrong, then do the same for Mossbop.
2. Paint: re-unwrap the mesh you want to paint, then paint on the texture (the Paint tab). The palette blocks are the starting colours.
3. Rig by parenting groups: add an empty group named `Root` at 0, 0, 0 (Roblox wants a root bone at the origin with no influences), drag the groups under it, build the hierarchy (head and tail groups under Body, and so on), put each group's origin on its joint. Keep names unique ASCII with no spaces ([[Model-Toolchain]] section 2, gotcha 4).
4. Keyframe: Animate tab, edit `idle` or add walk and hatch; look at how the example's keyframes are shaped first.
5. File > Export > glTF (binary), Export Animations on, Embed Textures on, scale 16, the armature option on to turn root groups into bones (section 2). Save the `.bbmodel` back to `media/blockbench/` as well.
6. Studio: File > Import 3D with Rig Type Custom; note the Scale Unit and the imported size (the probe's metre-to-stud factor), the `Bone` instances, the `AnimSaves` entry, and which way the fox faces.

**Known limits.** The uvs are the GLB's, not an unwrap, so overlap is expected until the Blender side adds a Smart UV Project and a palette bake ([[Board]]). Vertex colours (`COLOR_0`, the greyscale gradient) are read and not written, because a Blockbench mesh has no colour attribute; the shading gradient is lost. The slot properties in `materials.json` other than the colour (Neon, Fabric, glossy) do not travel in the file; once a rigged species is one merged skinned mesh they would come back through the texture or a SurfaceAppearance, not through the loader's per-slot parts. Nothing here has been opened in Blockbench: the first open is the verification ([[Tools-Status]]).

**What the Mac must verify.** That 5.2.2 opens the file without an error or a migration prompt; that the mesh shows coloured and not black, with sane normals under `smooth` (if the shading looks wrong, switch the mesh to flat); that the group pivots sit where the centroids say; that `idle` plays; that painting works after a re-unwrap; that a glTF export with animations and the armature option has bones named after the groups; and the facing and size in Studio.

## Probe results

Not run yet.

## Sources

- Blockbench source, GitHub `JannisX11/blockbench` at 5.2.2 (8 Oct 2026): `README.md`; `js/formats/bbmodel.js`, `js/formats/generic.ts`, `js/formats/standards/gltf.js`, `fbx.ts`, `obj.js`; `js/outliner/types/mesh.js`, `cube.js`, `group.js`, `armature.ts`, `armature_bone.ts`; `js/outliner/abstract/face.ts`; `js/outliner/outliner.js`; `js/animations/animation.js`, `keyframe.js`; `js/texturing/textures.js`; `js/io/format.ts`; the releases page (5.1.2 to 5.2.2 notes). `JannisX11/blockbench-types` (`mesh.d.ts`, `cube.d.ts`, `group.d.ts`, `animation.d.ts`, `keyframe.d.ts`). `JannisX11/blockbench-plugins` (`plugins.json`; `plugins/gltf_importer/about.md`).
- Roblox `creator-docs` on GitHub: `content/en-us/studio/importer.md`, `art/modeling/specifications.md`, `rigging.md`, `surface-appearance.md`, `texture-specifications.md`, `export-requirements.md`, `gltf-export.md`, `animation/using.md`, `animation/editor.md`, `avatar/character-bodies/export.md` and `import.md`.
- Khronos: `glTF-Blender-IO` (`docs/blender_docs/scene_gltf2.rst`, `addons/io_scene_gltf2/__init__.py`, `README.md`); `glTF` specification 2.0 (`specification/2.0/Specification.adoc`).
- Snippets only (pages unreadable here): Adobe Substance 3D Painter Python API (project, export, layerstack smart material, plugins folder, create-a-plugin tutorial, remote control), Painter command lines and remote control pages, system requirements, the Adobe FAQ on mesh formats, Substance pricing (Adobe pricing-change FAQ, Steam listing, Adobe community threads, third-party price trackers), Substance education licence (Adobe education page, 80.lv, The Rookies); Roblox DevForum "3D Importer" recaps 2023 to 2025 and "Animation Import Improvements"; the Khronos news item on Roblox's glTF beta; Blockbench web app and macOS builds (third-party guides); the Defold forum's Blockbench animation guide (the glTF dialog's scale 16 and armature option); PROMETHIA `gltf2bbmodel` on Codeberg.
- This repository: `media/tiktok/NOTES.md`, `research_notes/Roblox creature UI and Claude workflows/creature_models.md` and `blender_claude.md`, the report, `assets/models/Sparkfox/materials.json`, `tools/upload_assets.py --help`.
