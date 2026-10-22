--!strict
-- Weather particles (Look plan pass L3, particles): one emitter sheet that follows the camera, switched
-- by the clock's weather name. Everything a sheet needs is here; the client's WeatherFx only reads it.
-- Textures come from data/Icons.Particles (Raindrop, Flake, Wisp); an id of 0 keeps Roblox's default particle
-- until the pack is uploaded. Rates are per second across the whole sheet; rate x max lifetime (the
-- particles alive at once) stays under Config.WeatherParticleMax, the phone budget.
-- Layers (below) are ambient sheets that do not depend on the weather: they run beside whichever weather sheet is
-- on, switched by the clock (night), the place's world and the biome the player stands in.

local Icons = require(script.Parent.Icons)

export type Sheet = {
	rate: number, -- particles per second from the sheet
	lifetime: { number }, -- {min, max} seconds
	speed: { number }, -- {min, max} studs per second
	sizeStart: number, -- studs
	sizeEnd: number,
	color: string, -- hex
	transparency: number, -- 0 solid .. 1 invisible, at the particle's middle
	direction: { number }, -- {x, y, z} the sheet's emit direction (down is {0, -1, 0})
	spread: number, -- degrees of cone spread around the direction
	span: number, -- studs: the sheet is span x span, centred over the camera
	height: number, -- studs above the camera the sheet floats
	lightEmission: number, -- 0 .. 1
	drag: number, -- ParticleEmitter.Drag
	rotationSpeed: { number }, -- {min, max} degrees per second
	texture: number, -- asset id from Icons.Particles; 0 (not uploaded yet) keeps Roblox's default particle
	squash: number, -- stretch along the particle's up axis (1 is round); with velocityParallel a streak
	velocityParallel: boolean, -- orient each particle along its velocity (rain streaks) instead of facing the camera
	mode: "fall" | "drift", -- fall: the sheet is a plane perpendicular to direction (rain, snow); drift: a horizontal sheet at `height` whose particles start still and are pushed along direction (fog, haze)
	thickness: number?, -- studs: the sheet's depth along its up axis, the band particles are born in (1 when absent; fireflies use a thick one to fill the air above the ground)
}

-- An ambient layer: a sheet that is on while every condition it names holds (WeatherFx reads State and Place).
export type Layer = {
	night: boolean, -- true: only while the clock says night
	world: number, -- only in this world's place (data/Worlds ids)
	biome: string?, -- only while the player stands in this biome (Types.Biome); nil: anywhere in the world
	sheet: Sheet,
}

local Sheets: { [string]: Sheet } = {
	Rain = { rate = 190, lifetime = { 0.35, 0.5 }, speed = { 50, 70 }, sizeStart = 0.8, sizeEnd = 0.8, color = "E6F2FF", transparency = 0.1, direction = { 0.15, -1, 0 }, spread = 4, span = 18, height = 14, lightEmission = 0.5, drag = 0, rotationSpeed = { 0, 0 }, texture = Icons.Particles.Raindrop, squash = 4, velocityParallel = true, mode = "fall" },
	Fog = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "DDE2E6", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = Icons.Particles.Wisp, squash = 1, velocityParallel = false, mode = "drift" },
	-- The weekly drop's Aurora (data/Weekly): slow glowing wisps high over the camera, drifting across the sky.
	Aurora = { rate = 4, lifetime = { 8, 12 }, speed = { 1, 2 }, sizeStart = 14, sizeEnd = 22, color = "7CF5C2", transparency = 0.88, direction = { 1, 0.05, 0.3 }, spread = 20, span = 70, height = 24, lightEmission = 0.6, drag = 0.3, rotationSpeed = { -2, 2 }, texture = Icons.Particles.Wisp, squash = 1, velocityParallel = false, mode = "drift" },
	Snow = { rate = 36, lifetime = { 2.5, 4 }, speed = { 6, 10 }, sizeStart = 0.9, sizeEnd = 0.7, color = "FFFFFF", transparency = 0.1, direction = { 0.1, -1, 0.1 }, spread = 25, span = 28, height = 20, lightEmission = 0.15, drag = 1.5, rotationSpeed = { -40, 40 }, texture = Icons.Particles.Flake, squash = 1, velocityParallel = false, mode = "fall" },
	Blizzard = { rate = 95, lifetime = { 1.2, 2 }, speed = { 35, 50 }, sizeStart = 0.8, sizeEnd = 0.6, color = "F2F7FB", transparency = 0.15, direction = { 0.8, -0.7, 0 }, spread = 10, span = 40, height = 22, lightEmission = 0.1, drag = 0, rotationSpeed = { -60, 60 }, texture = Icons.Particles.Flake, squash = 2, velocityParallel = true, mode = "fall" },
	Smog = { rate = 10, lifetime = { 5, 8 }, speed = { 1, 3 }, sizeStart = 8, sizeEnd = 14, color = "9A8F7A", transparency = 0.8, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 6, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = Icons.Particles.Wisp, squash = 1, velocityParallel = false, mode = "drift" },
	Haze = { rate = 8, lifetime = { 5, 8 }, speed = { 1, 2 }, sizeStart = 9, sizeEnd = 15, color = "E0B089", transparency = 0.85, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 5, lightEmission = 0.05, drag = 0.5, rotationSpeed = { -3, 3 }, texture = Icons.Particles.Wisp, squash = 1, velocityParallel = false, mode = "drift" },
	Ashfall = { rate = 38, lifetime = { 3, 5 }, speed = { 4, 8 }, sizeStart = 0.3, sizeEnd = 0.2, color = "4A4A4A", transparency = 0.2, direction = { 0.2, -1, 0 }, spread = 20, span = 60, height = 35, lightEmission = 0, drag = 1, rotationSpeed = { -30, 30 }, texture = Icons.Particles.Flake, squash = 1, velocityParallel = false, mode = "fall" },
	Mist = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "CFE6EC", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = Icons.Particles.Wisp, squash = 1, velocityParallel = false, mode = "drift" },
}

-- World 1's Moonlit Forest at night (media/tiktok/NOTES.md ZPLYSA3uR: "fireflies, slow, small, everywhere"). Two slow motes,
-- both local, following the player like a weather sheet and fading with it: warm Fireflies and teal SporeMotes. They replaced the
-- first pair (Fireflies and LightDrips, falling pale streaks) on 2026-10-22: the Mac's game shot (job 53 step 5) showed the
-- streaks as white rain over a navy forest, big and fast. Motes are the point: small (0.2 to 0.3 studs), a few, drifting at
-- 0.1 to 0.5 studs a second with a wide spread so each wanders its own way, wearing the PixelMote sprite (real, no new upload).
-- Phone budget, particles alive at once (rate x max lifetime): Fireflies 1.6 x 9 = 14.4, SporeMotes 2 x 9 = 18, Pollen (every
-- hour, below) 7.5: 39.9 for the three, under LayerParticleMax below (45); the night pair alone is 32.4. On top of
-- World 1's heaviest weather sheet (Rain, 190 x 0.5 = 95) and the places of data/WorldFx (ParticleBudget 60) that stays under
-- Config.WeatherParticleMax (200). tests/Weather.spec.luau holds two lines (a world's layers under LayerParticleMax, and
-- LayerParticleMax plus that world's heaviest weather sheet under WeatherParticleMax), so a busier row fails the test before it
-- reaches a phone. Reduced Motion: WeatherFx turns every layer off (no drifting particles).
-- Fireflies are born in a 6-stud-thick band centred 1 stud over the player's root part, about 1 to 7 studs above the ground.
-- Pollen (World 1, 2026-10-21, the worlds pass): a few warm motes drifting at head height everywhere in the world, day and night (at
-- night they read as faint dust in the lantern light; texture unchanged, so the day look is too).
local Layers: { [string]: Layer } = {
	Pollen = {
		night = false,
		world = 1,
		biome = nil,
		sheet = { rate = 1.5, lifetime = { 4, 5 }, speed = { 0.2, 0.6 }, sizeStart = 0.22, sizeEnd = 0.15, color = "FFF1B8", transparency = 0.25, direction = { 0.6, 0.15, 0.3 }, spread = 180, span = 40, height = 1, lightEmission = 0.6, drag = 0.5, rotationSpeed = { 0, 0 }, texture = Icons.Particles.Glow, squash = 1, velocityParallel = false, mode = "drift", thickness = 5 },
	},
	Fireflies = {
		night = true,
		world = 1,
		biome = "Forest",
		sheet = { rate = 1.6, lifetime = { 6, 9 }, speed = { 0.15, 0.5 }, sizeStart = 0.3, sizeEnd = 0.2, color = "FFD36A", transparency = 0.1, direction = { 0.3, 0.1, 0.2 }, spread = 180, span = 36, height = 1, lightEmission = 1, drag = 0.8, rotationSpeed = { 0, 0 }, texture = Icons.Particles.PixelMote, squash = 1, velocityParallel = false, mode = "drift", thickness = 6 },
	},
	SporeMotes = {
		night = true,
		world = 1,
		biome = "Forest",
		sheet = { rate = 2, lifetime = { 6, 9 }, speed = { 0.1, 0.4 }, sizeStart = 0.26, sizeEnd = 0.16, color = "7FF0E0", transparency = 0.2, direction = { 0.15, 0.5, 0.1 }, spread = 180, span = 34, height = 1, lightEmission = 1, drag = 0.8, rotationSpeed = { 0, 0 }, texture = Icons.Particles.PixelMote, squash = 1, velocityParallel = false, mode = "drift", thickness = 7 },
	},
}

return {
	Sheets = Sheets,
	Layers = Layers,
	LayerParticleMax = 45, -- the layers on at once together: their summed rate x max lifetime stays under this (a phone budget, with a weather sheet and a Shower on top)
	FollowSeconds = 0.1, -- the sheet re-centres over the camera this often
	FadeSeconds = 1.5, -- a weather change ramps the old sheet's rate to 0 and the new one up over this long
}
