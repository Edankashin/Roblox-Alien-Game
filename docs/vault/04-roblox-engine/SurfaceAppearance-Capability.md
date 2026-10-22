---
tags: [roblox-engine, engine, surface, capability]
aliases: [SurfaceAppearance capability, SurfaceTemplates]
up: "[[Roblox-Engine]]"
---
# SurfaceAppearance: a Script cannot make one, so it clones one

Back to [[Roblox-Engine]]; the look pass this serves is [[Surface-Pass]], layer C (the shared texture sets).

## The rule

A game Script cannot write a SurfaceAppearance's map properties. In a live server (Studio Play included), `Instance.new("SurfaceAppearance")` followed by `.ColorMap = ...` fails with `The current thread cannot write 'ColorMap' (lacking capability Plugin)`; `ColorMapContent` fails the same way. The same goes for the normal, roughness and metalness maps. Found by the Mac session's Studio probe on 2026-10-15 ([[2026-10-15]], "Mac session (morning)", job 24 (c)). The loader's first version did exactly that inside a `pcall`, so it warned once and left every part plain.

What a Script may do: **clone a SurfaceAppearance that already exists** and set its `Color` (the property the docs also allow at runtime), then parent the clone. The clone keeps the maps it was built with and they draw.

## The route

1. `src/shared/data/Textures.luau` is the only place the Image ids live (one row per texture key).
2. `python3 -I tools/surface_templates.py --write` turns each row into `src/shared/SurfaceTemplates/<key>.model.json` (a Rojo model file: ClassName `SurfaceAppearance`, ColorMap, NormalMap and RoughnessMap as `rbxassetid://<id>`, AlphaMode Overlay, Color white). A zero id leaves that property out and the loader skips the row. `--check` fails when a file is stale; `tools/tests/test_surfaces.py` runs it, so CI catches an edited `Textures` without a regenerated template.
3. Rojo reads the files at build time, as the plugin does, so the instances are made with the right capability and arrive in the place as `ReplicatedStorage.Shared.SurfaceTemplates.<key>` (`src/shared` is mapped as `ReplicatedStorage.Shared` in all three project files, so no mapping of their own). The rebuilt place file stores the maps as `ColorMapContent` and the like.
4. `ServerScriptService.Server.Services.Models` resolves the folder once in `Init` (`WaitForChild`, `Config.SurfaceTemplatesWaitSeconds`), and for a textured slot clones `<folder>[<texture key>]`, sets `Color` to the part's colour and parents it. A missing folder or template warns once and the part keeps its plain look. There is no `Instance.new` fallback: it fails identically at runtime, and the loader never runs in Edit mode, so a fallback would be dead code and noise.

New texture row, or new ids after an upload: edit `Textures.luau`, run `--write`, commit the data and the five-line diff together.

## Related findings

- A hand-installed model in a Studio place does not get surfaces at all (the installer does not apply them), so this concerns the runtime loader only.
- Fabric darkens saturated warm colours: Sparkfox's `FF6B35` read as a dark maroon in daylight, so its Body is SmoothPlastic now. `python3 -I tools/fabric_audit.py` lists the other slots on Fabric, Grass, Slate or Sand with a luminance and flags the warm mid-light ones for a look in Studio; it changes nothing ([[Surface-Pass]]).

## CollisionFidelity is not script-writable either (2026-10-22)

`MeshPart.CollisionFidelity` set from a game Script fails with `The current thread cannot write 'CollisionFidelity' (lacking capability PluginOrOpenCloud)`. A runtime-loaded mesh keeps the fidelity it was uploaded or installed with; only an Edit-mode plugin (the installer, the command bar) or Open Cloud can change it. `Shared/Props.Place` skips a match and warns once instead of throwing (it used to kill `Meadow.Init`, so no world was built).

The FBX import also gives a glow part a SurfaceAppearance whose EmissiveMap names a texture the upload never carried (`rbxassetid://3`, `5`, `6`...), which errors on every load (`Unable to load ... EmissiveMap 'rbxassetid://3'`). Neon draws without it, so `Services/Models` and the installer destroy it on Neon parts. A script can destroy a SurfaceAppearance; it cannot make one.
