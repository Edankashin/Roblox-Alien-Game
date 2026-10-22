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

## Night grades: a surface is its colour times the ambient

At night nothing but the lamps and the sky lights a surface, so what a part shows is about its colour times `Ambient` (shade) or `OutdoorAmbient` (open sky), times the ColorCorrection tint, times 2^`ExposureCompensation`, plus the lamps. A dark ambient on a dark tint goes dark twice: the 2026-10-21 Starhollow (ambient 50,46,96, ground tint indigo 60,48,150 at 0.6) was one flat navy in the Mac's game shot (job 53 step 5, `media/studio/2026-10-22/store-3-starhollow-night-game.png`) against the teal-and-violet of the store thumbnail. The night pass of 2026-10-22 ([[Overnight]] job 58): keep every ambient channel at or above about 70 so the hue survives, tint the ground toward a mid teal (not a deep blue), lift exposure in the always-night Forest, raise the bloom threshold above a lit surface so only Neon bleeds (at 0.9 every lit tree glowed white), and put the colour in the lamps. `media/studio/2026-10-22/night_v2.jpg` is the swatch arithmetic. Neon lamp cells in a pale colour (the old FFE7B0 glow) bloom to white; use a saturated warm amber (FFB84D) and the PointLight in the same family. A phone cannot light 55 PointLights: the server tags each recipe light and `LampDirector` keeps the nearest 12 (7 on touch) lit ([[Performance]]).

Sources: the worlds section of `reports/Roblox creature UI and Claude workflows.md` and `research_notes/Roblox creature UI and Claude workflows/worlds_and_props.md`.
