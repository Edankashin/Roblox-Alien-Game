--!strict
-- ReplicatedStorage.Shared.data.WorldFx: the ambient effects that live at a place in a generated world (client only,
-- StarterPlayerScripts.Client.World.WorldFx). Where each one stands comes from the world's rows (data/WorldGen<id> Fx: a kind, a
-- point and a size, authored in tools/blocky/worlds/world<id>.json); how it looks is a row here by kind. Four sorts:
--   particles  a ParticleEmitter in a box `size` studs across (times `box`), on by day, by night or always
--   butterflies  little block-built butterflies (two wing blocks and a body) fluttering round the point by day: World 1's meadow
--   shaft      a soft vertical beam of light from a roof hole to the floor: the cave light shafts
--   ribbon     aurora ribbons high in the sky at night: World 2
-- Phone budget: only the MaxActive nearest particle or butterfly places within ActiveRadius of the camera run; each particle row keeps
-- rate x longest lifetime (particles alive at once) under PerEmitterMax, so the effects together stay under ParticleBudget, and
-- ParticleBudget plus data/Weather's LayerParticleMax plus the heaviest weather sheet stays under Config.WeatherParticleMax
-- (tests/WorldFx.spec.luau), with the places paused in the weathers listed in PauseIn. Reduced Motion: no particles, no butterflies, no drifting water; the shafts and a still aurora stay.
-- Sprites are data/Icons.Particles ids (0 keeps Roblox's default sparkle until the pack is uploaded).

local Icons = require(script.Parent.Icons)

export type When = "day" | "night" | "always"
export type Particles = {
	sort: "particles",
	when: When,
	rate: number, -- particles a second
	lifetime: { number }, -- {min, max} seconds
	speed: { number },
	sizeStart: number,
	sizeEnd: number,
	color: { string }, -- hex; two colours make a gradient over the particle's life
	transparency: number, -- at the particle's middle; it fades in and out
	lightEmission: number,
	spread: number, -- degrees
	direction: { number }, -- emit direction {x, y, z}
	acceleration: { number }, -- studs/s/s {x, y, z}
	drag: number,
	box: { number }, -- the emitter box as fractions of the place's size {x, y, z}
	texture: number,
	rotation: { number }, -- {min, max} degrees a second
}
export type Butterflies = {
	sort: "butterflies",
	when: When,
	count: number,
	colors: { string },
	wing: { number }, -- one wing block {x, y, z} studs
	body: { number },
	bodyColor: string,
	flapSeconds: number, -- a full wing beat
	loopSeconds: number, -- one lap of the flight path
	height: { number }, -- {min, max} studs over the ground
}
-- endTransparency: the beam's transparency at its foot (a light shaft fades out, 1; a glowing waterfall stays, lower).
export type Shaft = { sort: "shaft", when: When, color: string, width: number, height: number, transparency: number, lightEmission: number, endTransparency: number }
export type Ribbon = {
	sort: "ribbon",
	when: When,
	count: number, -- ribbons across the place's size
	colors: { string }, -- along a ribbon
	width: number, -- studs, the curtain's height
	transparency: number,
	lightEmission: number,
	sway: number, -- studs the curtain's curve swings
	swaySeconds: number,
}
export type Row = Particles | Butterflies | Shaft | Ribbon

local Kinds: { [string]: Row } = {
	-- World 1
	FallMist = { sort = "particles", when = "always", rate = 6, lifetime = { 1.6, 2.4 }, speed = { 1.5, 3 }, sizeStart = 2.2, sizeEnd = 4.5, color = { "F4FBFF" }, transparency = 0.6, lightEmission = 0.2, spread = 70, direction = { 0, 1, 0 }, acceleration = { 0, -0.4, 0 }, drag = 1.2, box = { 1, 0.2, 0.4 }, texture = Icons.Particles.Wisp, rotation = { -20, 20 } },
	WaterSparkle = { sort = "particles", when = "day", rate = 4, lifetime = { 0.6, 1 }, speed = { 0, 0.2 }, sizeStart = 0.45, sizeEnd = 0, color = { "FFFFFF" }, transparency = 0.1, lightEmission = 1, spread = 0, direction = { 0, 1, 0 }, acceleration = { 0, 0, 0 }, drag = 0, box = { 0.8, 0.05, 0.8 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	Petals = { sort = "particles", when = "day", rate = 2, lifetime = { 5, 7 }, speed = { 0.5, 1.2 }, sizeStart = 0.35, sizeEnd = 0.3, color = { "F7B6D2", "FFD9E8" }, transparency = 0.1, lightEmission = 0.1, spread = 40, direction = { 0.4, -1, 0.2 }, acceleration = { 0.3, -0.5, 0.1 }, drag = 0.8, box = { 1, 0.2, 1 }, texture = 0, rotation = { -90, 90 } },
	GrottoGlint = { sort = "particles", when = "always", rate = 3, lifetime = { 1.5, 2.5 }, speed = { 0.1, 0.4 }, sizeStart = 0.3, sizeEnd = 0, color = { "A8F0FA", "B49CFF" }, transparency = 0.1, lightEmission = 1, spread = 180, direction = { 0, 1, 0 }, acceleration = { 0, 0.2, 0 }, drag = 0.4, box = { 1, 0.5, 1 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	Fireflies = { sort = "particles", when = "night", rate = 1.5, lifetime = { 6, 8 }, speed = { 0.3, 0.8 }, sizeStart = 0.45, sizeEnd = 0.3, color = { "FFE27A" }, transparency = 0.1, lightEmission = 1, spread = 180, direction = { 0, 0.2, 0 }, acceleration = { 0, 0, 0 }, drag = 0.6, box = { 1, 0.3, 1 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	Butterflies = { sort = "butterflies", when = "day", count = 4, colors = { "FFD447", "F28CB8", "8FD3FF", "FFFFFF" }, wing = { 0.5, 0.06, 0.4 }, body = { 0.12, 0.12, 0.45 }, bodyColor = "4A3A2E", flapSeconds = 0.35, loopSeconds = 14, height = { 1, 3.5 } },
	-- the crash site (Props/CrashWreck.md): smoke from the hot engine (EngineSmoke) and sparks from the torn wires (WireSparks)
	WreckSmoke = { sort = "particles", when = "always", rate = 2.5, lifetime = { 3.5, 5 }, speed = { 1.8, 2.6 }, sizeStart = 1.2, sizeEnd = 4.5, color = { "5E5853", "B9B4AD" }, transparency = 0.45, lightEmission = 0, spread = 12, direction = { 0, 1, 0 }, acceleration = { 0.35, 0.25, 0.15 }, drag = 0.5, box = { 0.6, 0.1, 0.6 }, texture = Icons.Particles.Wisp, rotation = { -20, 20 } },
	WreckSparks = { sort = "particles", when = "always", rate = 5, lifetime = { 0.3, 0.6 }, speed = { 3, 6 }, sizeStart = 0.3, sizeEnd = 0, color = { "FFE27A", "FF8A3D" }, transparency = 0, lightEmission = 1, spread = 70, direction = { 0, 1, 0 }, acceleration = { 0, -14, 0 }, drag = 0.4, box = { 0.4, 0.4, 0.4 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	LightShaft = { sort = "shaft", when = "day", color = "FFF2C8", width = 1, height = 14, transparency = 0.82, lightEmission = 0.8, endTransparency = 1 },
	-- World 1's Starhollow Forest (B48), moonlit at any hour: the glowing fall from the Star Island into the forest (a beam and a stream of
	-- glowing drops), the light shaft over the moon pool and the sparkle on its water.
	IslandFall = { sort = "shaft", when = "always", color = "8FE6FF", width = 0.8, height = 44, transparency = 0.3, lightEmission = 1, endTransparency = 0.55 },
	FallStream = { sort = "particles", when = "always", rate = 5, lifetime = { 2.2, 2.6 }, speed = { 16, 20 }, sizeStart = 0.7, sizeEnd = 0.35, color = { "BFF6FF", "8FE6FF" }, transparency = 0.1, lightEmission = 1, spread = 4, direction = { 0, -1, 0 }, acceleration = { 0, -2, 0 }, drag = 0, box = { 0.6, 0.05, 0.25 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	MoonShaft = { sort = "shaft", when = "always", color = "E8DEFF", width = 0.8, height = 42, transparency = 0.78, lightEmission = 1, endTransparency = 0.95 },
	MoonSparkle = { sort = "particles", when = "always", rate = 4, lifetime = { 0.8, 1.2 }, speed = { 0, 0.3 }, sizeStart = 0.45, sizeEnd = 0, color = { "FFFFFF", "BFF6FF" }, transparency = 0.05, lightEmission = 1, spread = 0, direction = { 0, 1, 0 }, acceleration = { 0, 0.3, 0 }, drag = 0, box = { 0.8, 0.05, 0.8 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	-- World 2
	LakeMist = { sort = "particles", when = "always", rate = 1.8, lifetime = { 6, 8 }, speed = { 0.4, 0.8 }, sizeStart = 5, sizeEnd = 9, color = { "EAF6FF" }, transparency = 0.8, lightEmission = 0.1, spread = 40, direction = { 1, 0.1, 0.3 }, acceleration = { 0.1, 0, 0 }, drag = 0.4, box = { 0.8, 0.05, 0.6 }, texture = Icons.Particles.Wisp, rotation = { -5, 5 } },
	IceGlint = { sort = "particles", when = "always", rate = 3, lifetime = { 0.5, 0.9 }, speed = { 0, 0.1 }, sizeStart = 0.5, sizeEnd = 0, color = { "FFFFFF", "BFEBFA" }, transparency = 0.05, lightEmission = 1, spread = 0, direction = { 0, 1, 0 }, acceleration = { 0, 0, 0 }, drag = 0, box = { 0.8, 0.3, 0.8 }, texture = Icons.Particles.Glow, rotation = { 0, 0 } },
	Steam = { sort = "particles", when = "always", rate = 3, lifetime = { 2.5, 3.5 }, speed = { 1.5, 2.5 }, sizeStart = 1.5, sizeEnd = 4, color = { "FFFFFF" }, transparency = 0.65, lightEmission = 0.1, spread = 15, direction = { 0, 1, 0 }, acceleration = { 0.2, 0.3, 0 }, drag = 0.6, box = { 0.6, 0.05, 0.6 }, texture = Icons.Particles.Wisp, rotation = { -15, 15 } },
	Flurry = { sort = "particles", when = "always", rate = 3, lifetime = { 3.5, 4 }, speed = { 2, 3 }, sizeStart = 0.5, sizeEnd = 0.4, color = { "FFFFFF" }, transparency = 0.15, lightEmission = 0.2, spread = 25, direction = { 0.15, -1, 0.1 }, acceleration = { 0, -0.5, 0 }, drag = 0.8, box = { 1, 0.05, 1 }, texture = Icons.Particles.Flake, rotation = { -40, 40 } },
	Aurora = { sort = "ribbon", when = "night", count = 3, colors = { "5CF2B0", "7CF5C2", "B48CFF" }, width = 26, transparency = 0.55, lightEmission = 1, sway = 18, swaySeconds = 14 },
}

return {
	Kinds = Kinds,
	ActiveRadius = 150, -- studs from the camera inside which a place's particles or butterflies run
	MaxActive = 4, -- particle or butterfly places running at once, the nearest first
	PerEmitterMax = 15, -- particles alive at once from one place (rate x longest lifetime)
	ParticleBudget = 60, -- MaxActive x PerEmitterMax: every place running at once
	CheckSeconds = 0.5, -- how often the nearest places are re-picked and day or night re-read
	FadeSeconds = 1, -- a place's rate ramps in and out over this
	-- Weathers whose own sheet is heavy enough that the places pause while they run (a white-out hides them anyway): with them out,
	-- the heaviest remaining sheet plus the world's layers plus ParticleBudget stays under Config.WeatherParticleMax.
	PauseIn = { Blizzard = true, Snow = true } :: { [string]: boolean },
}
