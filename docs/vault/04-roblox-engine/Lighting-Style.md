---
tags: [roblox-engine, engine, lighting]
aliases: [LightingStyle, Lighting technology]
up: "[[Roblox-Engine]]"
---
# Lighting style

`Lighting.Technology` (Voxel, ShadowMap, Future, Unified) is deprecated. Roblox superseded it with `Lighting.LightingStyle` plus `Lighting.PrioritizeLightingQuality`. Back to [[Roblox-Engine]]; the look passes that use it are in [[Look-Plan]].

## The enum and the fields

- `Enum.LightingStyle`: `Realistic` (the most advanced lighting and shadows) or `Soft` (flat, retro-Roblox, softer lights and shadows). We ship `Realistic`.
- `Lighting.PrioritizeLightingQuality` (bool): true keeps advanced shadows and high-quality shaders at closer distances as quality drops; false keeps view distance. We ship true.
- `ShadowSoftness` only applies under Realistic, so the Base look's 0.2 does nothing on a Soft client.

## Where it lives

- `src/shared/data/Lighting.luau` carries `Style`, `PrioritizeLightingQuality` and `Technology` at the top level of the returned table (place-level, not part of any tweened look).
- `src/client/World/LightingDirector.luau` applies them once at `Start`, in this order, each in its own `pcall`: `LightingStyle` (looked up by name with `Enum.LightingStyle:FromName`), `PrioritizeLightingQuality`, then `Technology`.
- `Technology` stays as the fallback for older clients. It is not scriptable at runtime (confirmed from the Mac, 2026-10-05), so the director's write is expected to fail quietly and the Rojo project files (`default.project.json`, `world2.project.json`, `home.project.json`) still set `Technology` to `Future` on the place. The analyzer's Roblox definitions know all three properties, so no `any` cast is needed.

## The rule: check every grade twice

The client, not the developer, decides the final lighting on a low-end device: lowering graphics quality below level 4 switches Realistic to Soft and turns shadows off, with no developer override. A phone player on low settings therefore sees voxel light and no shadows whatever the data says.

So every night and weather grade (Night, the World 1 and Forest night rows, Aurora, Rain, Fog, Snow, Blizzard, Shower) is checked a second time with shadows off and Soft forced, in the iPhone SE emulator at quality 1 to 3. The catch bar and the wild aliens must stay readable in both. The standing rule that a night row never lowers Brightness or ExposureCompensation below the plain Night (held by `tests/Lighting.spec.luau`) is what protects the Soft case.

Sources: the worlds section of `reports/Roblox creature UI and Claude workflows.md` and `research_notes/Roblox creature UI and Claude workflows/worlds_and_props.md`.
