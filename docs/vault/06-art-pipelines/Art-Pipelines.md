---
tags: [art-pipelines, hub]
up: "[[Start-Here]]"
---
# Art pipelines

How models, icons, scenery and music get made and into the game. The passes on the creatures run in this order: shape, surface, skin. Back to [[Start-Here]].

## The plan

- [[Look-Plan]]: how the game gets its final look, pass by pass (lighting, ground, dressing, creatures, UI, store). Read it before any art task.

## Creatures, in the order they were done

- [[Creature-Generation]]: how the first blockouts were made and the prompt template. Read it for the history and the animation plan.
- [[Silhouette-Pass]]: the character bible: the rules and one recipe row per species (all 35), with the preview sheets of the 32 bodies. Read it before writing or changing a recipe.
- [[Surface-Pass]]: materials, glossy eyes, smooth bevelled bodies and shared texture sets, and the probes the Mac still owes. Read it before changing how a body looks up close.
- [[Sculpt-Pass]]: the fused single-skin prototype (metaballs won over the remesh; four species before and after; 5 to 25 minutes a species). Read it before running `species_sculpt.py` on a species.
- [[Hero-Aliens]]: two hero prototypes built with the hybrid sculpt, a scarier wolf Fenrir (`FenripupV2`) and a sky dragon (`Skydrake`): the recipes, the exact build commands, triangles and silhouette overlap, what is still missing and the effects each wants. Read it before adding another hero or changing the hybrid's crisp-part options.
- [[Character-Pipeline]]: why the bodies read as mashed shapes, what the references did, the generation routes, the Roblox limits and the fuse-pass recommendation with its three ship checks. Read it before the next creature pass.
- [[Model-Toolchain]]: how Blockbench, Blender and Substance 3D Painter chain for a species (the hand-offs, what survives each), the rig and animation route into Studio, the `.bbmodel` schema a cloud tool writes, what Painter's Python API can do, costs, and the Mac probe. Read it before rigging, painting or animating a species.

## Scenery, tools and sound

- [[Map-Dressing]]: how a world gets its props and the bulk import through Open Cloud. Read it before importing a model or placing scenery.
- [[Blender-MCP]]: the log of what the Blender MCP built (icons, particles, props, look passes). Read it before running a Blender script.
- [[Music-Plan]]: music and sound picks per game state, with the pick tables. Read it before changing a track or filling a sound id.

Also here: `refs/` holds the preview sheets embedded in the notes above (`silhouette-pass`, `surface-pass`, `2026-10-15`).
