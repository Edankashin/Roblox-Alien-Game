# Sculpt pass: one fluid skin per creature (prototype, 2026-10-15)

Ethan, 2026-10-15, looking at the silhouette and surface sheets: "You can tell these designs were made with AI. Especially in Frostbyte it all uses simple shapes to create a figure. The character designs should seem seamless, fluid, and complete, not like a bunch of shapes mashed together." He is right about how they are built: [[Silhouette-Pass]] and [[Surface-Pass]] join the recipe's primitives (`tools/blender/species_bodies.py`), so every limb, ear and accessory sits on the body and the join shows, and many of the triangles are spent inside other shapes where nobody sees them.

This note is the prototype that answers it: `tools/blender/species_sculpt.py` turns the same recipe into ONE mesh whose joins are blended, whose face is carved into the skin, and whose seven material slots are assigned by face afterwards (so `materials.json`, `ModelAssets` and the slot order do not change). Done for four species on a scratch copy of the model folders: Mossbop (round), Sparkfox (limbs, ears, tail), Gaiabloom (a quadruped with antlers and a halo) and Flufflet (Frostbyte: a snowball with a scarf). Nothing under `assets/models/` changed; `species_recipes.py` is untouched (the sculpt's own edits to a recipe live in the script).

![Before and after: the four species, lit, and their black shapes at 64 px](refs/sculpt-pass/before_after.jpg)

Top: the current bodies. Middle: the sculpted ones. Bottom: the black shapes at 64 px (magnified so the pixels show). The silhouettes hold: all four are still the same four shapes. Side and back views: ![The four from three sides](refs/sculpt-pass/views.jpg)

## The method that won: metaballs

Both candidates were built on Mossbop first, then on Sparkfox and Gaiabloom, with the same decimate, slot and face steps after the fuse (`--method metaball` or `--method remesh`):

| | Metaball (kept) | Boolean carve + voxel remesh + smooth (`--method remesh`) |
|---|---|---|
| How the join is blended | Every volume is a field element and the fields ADD, so the surface swells into a fillet where two meet. The width of the blend is the element's stiffness (3 wide and soft, 5 tight). | A hard union, then a SMOOTH pass (30 iterations, 0.6) rounds the crease. One setting for the whole body. |
| Mossbop | Soft clumps and soft feet. | The same look; clumps a little crisper, surface a little cleaner. A tie. |
| Sparkfox | Ears, tail and cheeks kept. | Also kept; surface cleaner. A tie. |
| Gaiabloom | Hooves, antler tines and blossoms all kept. | Hooves gone (legs end in stumps), blossoms shrunk, tine tips eroded: at a voxel of 0.018 of the height (0.075 studs) a 0.1-stud antler is one voxel. A finer voxel costs more than it gains, and the smoothing erodes the rest. |
| Geometric faceting (mean / 95th percentile dihedral angle, degrees, whole mesh) | 11.8 / 35.8, 14.8 / 38.2, 16.6 / 47.1, 10.7 / 34.2 (Mossbop, Sparkfox, Gaiabloom, Flufflet) | 12.3 / 35.7, 13.8 / 35.8, 13.8 / 38.3, 9.7 / 32.6. Smoother on all four, but by smoothing detail away. The current bodies: 21.1 / 50.3, 21.3 / 40.0, 15.0 / 38.9, 18.2 / 45.0. |
| Time per species (whole build) | 1 to 3 s (the polygonizer itself is 0.1 to 0.2 s) | 4 to 12 s (the remesh is 3 to 11 s) |
| Face | Sockets and the mouth are negative elements (soft dents), a lid is a positive element that grows out of the head like a brow. | Sockets and the mouth are exact booleans (a hard rim), lids are the recipe's half spheres. |

![Remesh above, metaball below: Mossbop and Gaiabloom](refs/sculpt-pass/methods.jpg)

Why metaballs: thin parts survive (each element is sized in the field, the polygonizer cell is separate from the decimate), the blend is a number per element and not a global smoothing, it is three to four times faster, and the same field gives the slot assignment, the shading normals and the soft face for free. What remesh does better: it takes every primitive in the recipe unchanged (cubes, cones with flat caps, tori) with no calibration, and its surface is a little cleaner on pure organic bodies. It is the fallback for hard-surface bodies (crystals, planks), which neither method makes crisp (see "what still reads as assembled"). Both are in the script; the remesh numbers above are the best settings found (`--set voxel=0.018 --set smooth_iter=30 --set smooth_fac=0.6`).

## How a species is built

1. **Elements.** `species_recipes.expand` gives the parts. A sphere becomes one ellipsoid element sized so that alone it has the recipe's radii (an element of stiffness s and reach 1 has its surface at K = sqrt(1 - (0.6 / s)^(1/3)) of its reach, checked against Blender's own polygonizer to the third decimal). A rod, cone or cylinder becomes a chain of balls along its axis and a torus a ring of them, each ball calibrated (bisection on the summed field) so the chain's surface sits at the recipe's radius and its caps end where the primitive ended. A cube is one rounded-box element (the thinnest half-extent is the rounding, so a band stays a band).
2. **Face on the fused field.** Eyes and mouth are snapped to where the real fused skin is, not the host sphere. Each eye gets a negative element (the socket), the mouth a negative element (the indent), a lid is a positive Body ellipsoid over the eye's top.
3. **Polygonize and reduce.** `object.convert` polygonizes the field (40,000 to 90,000 triangles in 0.1 to 0.2 s). A COLLAPSE decimate takes it to about 80 percent of the budget with a vertex-group weight that keeps more triangles round the eyes and mouth and on fine features, five rounds of SMOOTH + SHRINKWRAP put the vertices back on the polygonized surface, then the skin is cut along every slot contour (an exact bisection on the field), so each colour boundary is a clean line.
4. **Slots and shading.** A face gets the slot whose elements have the largest summed field there; faces inside the mouth ellipsoid get Mouth. The skin is shaded with the field's own normals (central-difference gradient), so it is smooth however coarse the triangles are; they are written to the GLB.
5. **Join and export.** Eyes (glossy spheres, sunk 0.35 to 0.45 of an eye radius into the socket), `separate` shells (halo, ground ring, flowers, sprout, tassels), `ribbons` bands, then fit to the height (pivot on the feet), smart-project UVs, the Surface-pass gradient, texture tiling, GLB and FBX, notes.md. All seven slots used, names and order checked against the current GLBs (same names, same order, same colours, one primitive per slot).

### The numbers (`DEFAULTS` and `SPECIES` in the script)

| Key | Default | What it does | What moved it |
|---|---|---|---|
| `stiff`, `stiff_thin` | 3, 3 | blend width of the volumes and of the chains | 5 and 4 on Mossbop (3 melted the moss clumps into the body: a bumpy skyline needs a tight blend), 4.5 and 4 Sparkfox, 4 and 4 Gaiabloom, 3.5 Flufflet |
| `res` | 0.04 | polygonizer cell, studs | 0.03 for Flufflet's thin scarf |
| `tris` | 2400 | whole-mesh target (cap 2500) | |
| `cut_share` | 0.8 | share of the budget the decimate aims at; the cuts add the rest (each cut is two triangles: 410 to 580 triangles, 17 to 24 percent of the mesh) | the loop lowers the decimate target until the total fits |
| `relax` | 5 | rounds of smooth + shrinkwrap | 2 left the head faceted |
| `fine`, `fine_detail` | 0.2, 0.4 | a chain thinner than this (studs of radius) keeps more triangles | 0.16 Gaiabloom, 0.1 Flufflet (the scarf ring is not a fine feature) |
| `face.sink` | 0.4 | how deep the eyeball sits in its socket, in eye radii | |
| `face.socket_stiff`, `socket_reach` | 1.5, (1.55, 1.25, 1.55) | dent depth and width | 0.9 and (1.4, 1.2, 1.4) on Flufflet (1.5 made under-eye bags on a snow face) |
| `face.lid_grow` | 1.0 | brow size | 0.8 Sparkfox, 0.7 Gaiabloom, 0.55 Flufflet (full-size lids read worried or angry) |
| `face.eye_boost` | 1.2 | the recipe's `eye_scale` times this | a sunk eye reads smaller; the goofy big-eyed look needs it |
| `face.mouth_scale` | 1.3 | mouth ellipsoid and dent | a 0.4-stud mouth was four triangles |
| `separate` | none | steps built as their own shells | Mossbop sprout, Gaiabloom halo, ground ring and flowers, Flufflet tassels |
| `edit` | none | a function on the recipe's parts | Mossbop's longer stalk and higher bud, Sparkfox's blunt ear and cheek tubes (a point thinner than the cell is lost), Gaiabloom's thicker legs, Flufflet's streamer dropped for a lofted band |

## Triangles and time

| Species | Now | Sculpt | Skin | Raw polygonized | Elements | Cuts | Build |
|---|---|---|---|---|---|---|---|
| Mossbop | 1,680 | 2,392 | 1,808 | 42,624 | 15 | 292 | 1 s |
| Sparkfox | 1,734 | 2,356 | 1,972 | 48,444 | 105 | 220 | 2 s |
| Gaiabloom | 2,136 | 2,356 | 1,564 | 62,908 | 135 | 206 | 3 s |
| Flufflet | 1,564 | 2,362 | 1,878 | 53,372 | 68 | 224 | 2 s |

Everything outside the skin is the eyes (192 triangles an eye), shells and a ribbon. The sculpt spends the whole budget (the skin is the decimated surface plus the colour cuts): the fluid look costs 220 to 800 triangles more than the current bodies, and none of the four meets its tier target (1,800 up to Rare, 2,200 above) though all are under the 2,500 cap. A lower `tris` is one number, not a redesign (try 2000 and look), but the colour cuts and the eyes (384) are a fixed bill.

**How long a species takes.** One build is 1 to 3 s and a lit before/after render about 20 s at 520 px, so a tuning loop (edit, build, render, look) is 1 to 2 minutes. These four took about 45 minutes in one go, most of it writing the engine; with the engine, a soft species with no thin parts is about 5 to 10 minutes (set the stiffness, the face, look three times), a limbed one with ears or a tail 15 to 25 (add an `edit` for any part thinner than 0.1 stud, a `separate` list), and a hard-surface one longer because its crystals, planks and rings stay shells. Estimate for the other 28: 6 to 10 worker-hours, about 3 hours calendar with four workers, run in batches of four with one before/after sheet per batch (`tools/blender/sculpt_sheet.py`).

## What still reads as assembled, and why

- **Floating or thin parts stay shells.** Gaiabloom's halo, ground ring and flowers, Mossbop's sprout (stalk, leaves, bud), Flufflet's scarf tail and tassels are separate meshes with their base sunk into the body, so you can still see a stalk go in and a band pass through its knot. Fusing them lost them (the stalk was swallowed by the blend). A shell can be given a metaball collar (a ball at the root), not done here.
- **Eyes** are separate glossy spheres by design; the socket is a dent, not a lid fold.
- **The face resolution.** The mouth is 12 (Gaiabloom), 28 (Sparkfox), 91 (Mossbop) and 115 (Flufflet) triangles; Sparkfox's grin and Gaiabloom's small mouth read as a dark cutout, not a lip. More weight on the face zone costs the body.
- **Slot boundaries cost triangles.** Each clean colour line is two triangles per crossed edge, so a creature with many colour patches pays for it: Mossbop's moss and feet are 584 triangles of its 2,392 (292 cuts), Sparkfox 440, Gaiabloom 412, Flufflet 448. A fewer-patches design, or a vertex colour for the soft ones, would buy that back. Sparkfox's three-ball tail still reads as three bulges in profile (a softer `stiff_thin` on the tail would merge them).
- **Faceting is traded, not gone.** Round bodies are smoother (Mossbop 21 to 12 degrees mean dihedral, Flufflet 18 to 11) but Gaiabloom is a little more faceted than before (15.0 to 16.6) because its budget goes to antlers and legs; the field normals hide it in shading, the silhouette of a leg or an antler (six sides) shows it.
- **Hard shapes.** A metaball cannot make a sharp edge: crystals, shards, planks, a teapot, a pick, a backpack must stay shells (or take the remesh route with a crease angle). None of the four needed it; the Frostbyte hard-surface species will.
- **Height drift.** Elements add, so the unfitted body is 1 to 4 percent off the recipe (fit x0.96 to x1.04), then the whole creature is scaled to the notes.md height; a longer sprout costs the Mossbop body 4 percent.

## Blender facts this needed

- A metaball element of stiffness s, reach r and threshold 0.6 has its surface at r * sqrt(1 - (0.6 / s)^(1/3)); an ellipsoid's size_x/y/z scale each axis, a capsule's size_x is a half length added to the radius, a cube's sizes are the box half extents and the radius the rounding. Stiffness tops out at 10, sizes at 20.
- `object.convert` on a metaball object polygonizes at the viewport resolution, quads and triangles, 0.1 s for 50,000.
- Decimate (COLLAPSE) with a vertex group: weight 0 locks a vertex, a SMALLER weight collapses less. Its symmetry option leaves flipped slivers on the mirror plane (thin dark lines down the back of the creature): off.
- QuadriFlow refused every polygonized skin ("the mesh needs to be manifold and have face normals that point in a consistent direction") even after recalculating normals and with no non-manifold edges; not used.
- A slot contour cut: `bmesh.utils.edge_split` at the bisected crossing, `face_split` between the new vertices, triangulate. Skip crossings within 0.002 of zero or a second contour re-cuts the first into slivers.
- `Mesh.normals_split_custom_set_from_vertices` survives `object.join` and the glTF exporter writes it; the FBX exporter was left on face smoothing, so the FBX is flatter than the GLB (check what Studio does with each).

## To run it on the next species

1. Copy the folders to a scratch place, never `assets/models` (the script refuses it): `cp -r assets/models/<Id> /scratch/models/<Id>`.
2. Add a `SPECIES["<Id>"]` entry: nothing is needed for a soft body; add `separate` for rings, flowers, tassels and sprouts, an `edit` for any tube thinner than 0.1 stud (use a blunt tip: `SR.rod(slot, a, b, r, r2)` with r2 at least 0.06), `face` and `face_recipe` for the brow and the sockets.
3. `python3 tools/blender/species_sculpt.py --species <Id> --models /scratch/models`, then `python3 tools/blender/preview.py --lit --models /scratch/models --compare assets/models --textures /nonexistent --species <Id> --out /scratch/renders` (`--textures /nonexistent` so neither side has baked maps) and `python3 tools/blender/preview.py --models /scratch/models --species <Id>` for the black shape. `tools/blender/sculpt_sheet.py` makes the before/after sheet (under 500 KB).
4. Look three times; change one number a time (`--set stiff=4 --set face.sink=0.3`); copy the folder into `assets/models` only when Ethan has said yes.

## Open

- Ethan's look at the sheet. Nothing here replaces a model in the repo until he does.
- The Mac: how Studio imports the GLB's custom normals and the FBX (a probe: import both, compare the shading), the `ModelAssets` upload path with a body that has 300 to 800 more triangles, and a phone draw-call and triangle count for a dozen at once.
- Hard-surface species (crystals, planks) and the three Haunted Nebula stubs are not covered.
