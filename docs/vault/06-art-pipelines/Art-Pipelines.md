---
tags: [art-pipelines, hub]
up: "[[Start-Here]]"
---
# Art pipelines

How models, icons, scenery and music get made and into the game. The passes on the creatures run in this order: shape, surface, skin. Back to [[Start-Here]].

## The plan

- [[Look-Plan]]: how the game gets its final look, pass by pass (lighting, ground, dressing, creatures, UI, store). Read it before any art task.
- [[Blocky-Style]]: the blocky style bible (B43): nine numbered rules with a number and a do and a don't each (shape, proportions, the house face, palette, originality, the rarity ladder, VFX, moving parts, silhouettes), the spec note format and the six-step pipeline (Obsidian note, Claude Design sheet, Blender build, review, ship). Read it before designing, building or reviewing any creature; it replaces the smooth-skin passes below as the direction.

## Creatures, in the order they were done

- [[Creature-Generation]]: how the first blockouts were made and the prompt template. Read it for the history and the animation plan.
- [[Silhouette-Pass]]: the character bible: the rules and one recipe row per species (all 35), with the preview sheets of the 32 bodies. Read it before writing or changing a recipe.
- [[Surface-Pass]]: materials, glossy eyes, smooth bevelled bodies and shared texture sets, and the probes the Mac still owes. Read it before changing how a body looks up close.
- [[Sculpt-Pass]]: the fused single-skin prototype (metaballs won over the remesh; four species before and after; 5 to 25 minutes a species). Read it before running `species_sculpt.py` on a species.
- [[Hero-Aliens]]: two hero prototypes built with the hybrid sculpt, a scarier wolf Fenrir (`FenripupV2`) and a sky dragon (`Skydrake`): the recipes, the exact build commands, triangles and silhouette overlap, what is still missing and the effects each wants. Read it before adding another hero or changing the hybrid's crisp-part options.
- [[Design-Pass]]: the per-species design pass, batch 1: eight species whose shape barely changed (Mossbop, Glimmo, Puffpuff, Drippo, Kettlepuff, Flufflet, Capybubble, Pengoo) rebuilt as `<Id>V2` prototypes with a new base design and a feature set of their world, the review sheet, the 64 px overlap against the old body and every neighbour, the build commands, what still reads as assembled and the next batches. Read it before designing or swapping in a species' new shape.
- [[Design-Fixes]]: the six weak bodies of design passes 1 to 3 rebuilt in place (Raddis the winged sun, Zirrit, Skadra the snow owl, Iridia, Aurelyx, Blinkar) and the three recipes that tapered by too little (Glimmo, Kettlepuff, Flufflet), with a before and after sheet, the checks and the build commands. Read it after [[Design-Pass]] and before swapping a V2 in.
- [[Character-Pipeline]]: why the bodies read as mashed shapes, what the references did, the generation routes, the Roblox limits and the fuse-pass recommendation with its three ship checks. Read it before the next creature pass.
- [[Model-Toolchain]]: how Blockbench, Blender and Substance 3D Painter chain for a species (the hand-offs, what survives each), the rig and animation route into Studio, the `.bbmodel` schema a cloud tool writes, what Painter's Python API can do, costs, and the Mac probe. Read it before rigging, painting or animating a species.

## Scenery, tools and sound

- [[Map-Dressing]]: how a world gets its props and the bulk import through Open Cloud. Read it before importing a model or placing scenery.
- [[Blender-MCP]]: the log of what the Blender MCP built (icons, particles, props, look passes). Read it before running a Blender script.
- [[Music-Plan]]: music and sound picks per game state, with the pick tables. Read it before changing a track or filling a sound id.

## References

- [[X-Posts]]: what Roblox developers say on X about building creatures, worlds, UI and effects (66 posts from search snippets), the ten most useful, and the five things we take. Read it before a UI stroke change, a prop import change or a Claude-and-Blender claim.

Also here: `refs/` holds the preview sheets embedded in the notes above (`silhouette-pass`, `surface-pass`, `2026-10-15`).
