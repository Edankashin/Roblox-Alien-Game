# Surface pass: giving the bodies a surface

Ethan, 2026-10-14, looking at the sixteen new World 1 bodies: "They don't have any texture to them. Look at the TikToks I sent you about the design of certain props and aspects of the game. Also the top games." The bodies are flat-coloured primitives with hard shading: right silhouettes ([[Silhouette-Pass]]), no surface. This note is the plan, what shipped in the first change, and what waits. Background: [[Look-Plan]] (principle 2, "no textures on creatures", is overruled here for the creatures' surfaces; the lighting rules stay), [[Creature-Generation]], [[Map-Dressing]] (the `materials.json` and grey-import note). Review images: ![Mossbop, before | after](refs/surface-pass/Mossbop_surface.jpg) ![Sparkfox, before | after](refs/surface-pass/Sparkfox_surface.jpg) Left is the pre-pass body, right the surface build, same light (`preview.py --lit`). Blender cannot draw Roblox's Grass or Fabric, so the right-hand side shows the gradient, the glossy eyes, the Neon glow and the baked texture sets; the Roblox materials are judged in Studio.

## What the references say about surfaces

None of the TikToks shows a creature's surface up close; they teach glow, material identity and tiling. The lines that bear on it (`media/tiktok/NOTES.md`):
- ZPLRw3ubt (AI models and VFX): a generated enemy "(neon purple and cyan)" and swords "wrapped in white-blue particle VFX"; the prompt asks for "very flashy, vibrant" and "Roblox ready". Takeaway: bright emissive parts are the signature, colour comes with the model.
- ZPL8MtkYu (the dinosaur ranch): "Voxel-brick art: every surface, including the ground, is a tiled brick grid, so even simple geometry looks deliberate." Item 8: "a tiled grid material on our placeholder floor and pads so grey-box builds read as a style rather than a gap."
- ZPL8uaNaS (building end to end): "Finishing is on you"; generated cliffs were jagged and fixed by hand; "make sure all your icons are black-stroked, thick, or it just doesn't look good" (the same rule for any surface: a thick dark read).
- ZPLYSD7G9 (zones): "Hard colour identity per zone (basalt and lava orange; red rock and sand; green and water blue)": the surface says the world before the shape does.
- ZPLYSA3uR (Moonlit Forest): "a night palette ... with warm-white and pastel light sources, not a dark scene: the light comes from the props"; "giant glowing mushrooms as the signature prop"; a pool "ringed with mossy stones". Glow is a surface choice (Neon), not a light.
- ZPLSah2VR (grey imports): "The import has no colours or effects: 'gray silhouettes'"; our answer is `materials.json` per model, restored by the loader. This pass extends that file.
- ZPLS5oQoQ (a creature in Claude Design): a "grey two-legged shark with red glowing tail", "red-lit blades"; the iteration is "a thousand times better" when each pass lists exactly what to change.
- ZPLYS56X5 (the cinematic): "Bloom and a low sun on one side give the warm glow": lighting finishes what the surface starts.

## What the top games do, and what is not confirmed

The web search found no first-hand word from Pet Simulator 99, Adopt Me, Grow a Garden or Steal a Brainrot on their surface pipelines (no studio posts; the one Brainrot lead is a third-party pack seller saying every model in the pack uses textures). So this is the look as remembered, not sourced (no screenshots could be opened here); Ethan or the Mac session should check it side by side before we lean on it: the pets are textured meshes with a soft painted gradient (light crown, darker belly) and a baked occlusion, glossy eyes with a specular dot, no visible fur or fabric normal detail; Grow a Garden's plants and fruit read as bright smooth plastic with gradients, its ground as Grass material; Brainrot characters use detailed colour textures. None needs a second material system: the look is a colour texture or a vertex gradient plus glossy eyes plus Neon for light.

What the Creator docs say (read through search snippets; the docs host is blocked here): SurfaceAppearance takes colour, normal, roughness and metalness maps by asset id and reads the mesh's UVs; its `Color` tints the colour map ("save on memory by reusing a single ColorMap with different tints") and is the one property scripts may change at runtime, "most SurfaceAppearance properties cannot be modified by scripts in-game"; textures go up to 4096 but the docs suggest 256 px for a 5-stud object, 512 for 10, 1024 for 20; normal maps must be OpenGL tangent space. A DevForum guide says imported vertex colour is multiplied with the MeshPart's `Color` (set Color white to see it plainly), written for FBX; ours is a GLB upload, so it needs the probe below. `Highlight` is capped per client (31 in the main guide, 255 on a newer reference page), so it is for the hovered or selected alien only, never every creature.

## The three layers

| Layer | What | Cost and needs | Friday 2026-10-16, 8 GB Mac, headless Blender |
|---|---|---|---|
| A. Roblox materials per slot | `material` per slot in `materials.json`: Grass (moss), Fabric (fur), Slate (stone), Wood, Glass (crystal wings), Metal, Neon (glow parts); `glossy` on EyeWhite and EyeHighlight: SmoothPlastic plus `Config.ModelGlossReflectance` (a sheen, the cheap specular dot). The loader applies it from data. | No uploads, no art. One property per MeshPart; no memory cost beyond the engine's own material textures. | **Ships now** (code, data and tests in this change). Needs a Studio look. |
| B. Mesh-side softness | In `species_bodies.py` (default on, `--no-surface` for the old output): shade smooth by angle, a two-segment bevel on thick cubes and cylinders, a greyscale vertex gradient (crown 1.0, belly 0.7, 0.18 darker facing down: a fake occlusion) exported as `COLOR_0`; UVs scaled per slot texture. | Headless Blender, a few minutes for 16. Triangles: bevel adds about 100 on a thick cube; builds that cross the cap drop the bevel. Mesh re-export and re-upload of the 16 (the colour re-upload already waits on Ethan). | **Smoothing and bevel: yes** once rebuilt. **Gradient: only if the probe shows Roblox keeps `COLOR_0` through the GLB upload**; harmless if ignored. Fallback if dropped: a `Belly` slot in BodyDark under the body (one more MeshPart per species). |
| C. Real texture maps | Five shared tileable sets (fur, moss, stone, ice, scales), each colour, normal, roughness: baked by `bake_textures.py` to `assets/textures/<key>/` (512 px, under 300 KB each, near-white colour so the slot colour tints it through `SurfaceAppearance.Color`). Upload once as images, paste the Image ids into `data/Textures`; a slot picks a set by its `texture` key. | Upload step: `upload_assets.py --images` only reads `assets/icons` and `assets/particles`; a textures folder needs adding (small). Risk: the engine may refuse a script-made SurfaceAppearance (the loader sets properties before parenting inside a `pcall` and warns once). Phone memory: five sets of three 512 px maps is about 15 MB decoded if all are on screen; a shared set used by many species costs once. | **Maps and loader are ready, the gate is the upload and a Studio probe.** Not promised for Friday; do it if the probe passes. Fallback: bake the maps into each GLB (the importer then makes the SurfaceAppearance itself), at the price of a bigger upload per species. |

The eye: two layers already in every recipe (a white sphere, a dark pupil, a white highlight sphere). Gloss (A) turns the highlight into a real specular dot and the white into a wet eye. Nothing more is modelled.

## The sixteen, by concept

Body unless named. Every EyeWhite and EyeHighlight is `glossy`. The set in the last column is the `texture` key, which does nothing until its ids are uploaded.

| Species | Material | Texture set |
|---|---|---|
| Mossbop | Body Grass | Body moss |
| Pebblet | Body Slate | Body stone |
| Puffpuff | (eyes only) | none |
| Glimmo | Body Glass, Accessory Neon (the lamp) | none |
| Twiglet | Body Wood | none |
| Buzzlebee | Body Fabric | Body fur |
| Lanternewt | Accessory Neon | Body scales |
| Snailbyte | Accessory Metal (the shell) | none |
| Rocklobber | Accessory Slate | Accessory stone |
| Zapfinch, Radish | Accessory Neon | none |
| Sparkfox | Body Fabric, Accessory Neon | Body fur |
| Thunderhog | Accessory Neon | none |
| Gloomoth | Accessory Glass (the wings) | none |
| Gaiabloom | Trim Neon | none |
| Panpipe | Accessory Metal | none |

An explicit `material` beats the emission rule: Rocklobber's amber crystals and Panpipe's pipes shared their slot with the glow and lose it under Slate and Metal. If Ethan wants the glow back, set the slot to Neon (or split the crystals into their own slot in the recipe).

## What changed and how to run it

- Data: `assets/models/<Id>/materials.json` slots gain optional `material`, `texture`, `glossy`; `python3 -I tools/model_assets.py --write` carries them into `ModelAssets.Surfaces` (checked against `Textures`, the slot names and the material list); `src/shared/data/Textures.luau` holds the five rows (ids 0); `Config.ModelGlossReflectance` the gloss.
- Loader: `ModelInstall.SurfacePlan` (pure, headless-tested) returns the material name, reflectance and maps; `Services/Models` maps the name to the Enum, sets `Reflectance` and adds a `SurfaceAppearance` only when all three ids are non-zero. No field, no change. The client's shadow silhouettes lift the SurfaceAppearance off and put it back.
- Blender (Mac): `blender -b -P tools/blender/species_bodies.py -- --species world1` rebuilds the 16 (then `preview.py`, upload and `--emit-luau` as in [[Silhouette-Pass]]); `python3 tools/blender/bake_textures.py` rebakes the textures (already committed); `python3 tools/blender/preview.py --lit --models <surface build> --compare <old build> --species Mossbop --out <folder>` makes the review images.

## Probes for the Mac (one Studio session)

1. Does `COLOR_0` survive the GLB upload? Import one rebuilt body; if the Body is shaded lighter on top and darker below with its Color unchanged, yes. If flat, build the `Belly` slot.
2. Does a script-made SurfaceAppearance work in a live server? Put test ids in one `Textures` row, Play, look for the boot warning "a SurfaceAppearance could not be added".
3. Explorer: Mossbop Body is Grass, EyeWhite is SmoothPlastic with Reflectance 0.25, Glimmo's lamp Neon.
4. Phones: iPhone SE emulator with 20 aliens in view, MicroProfiler or the stats overlay, before and after; glossy eyes and materials should not move the frame time.

Left: the textures upload route, the rebuild and re-upload of the 16, Frostbyte and the 19 non-World-1 species (their `materials.json` carry no surface fields yet), props.
