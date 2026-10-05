--!strict
-- Weather particles (Look plan pass L3, particles): one emitter sheet that follows the camera, switched
-- by the clock's weather name. Everything a sheet needs is here; the client's WeatherFx only reads it.
-- Textures are Roblox's default particle (0) until the icon pack brings proper ones. Rates are per second
-- across the whole sheet; rate x max lifetime (the particles alive at once) stays under
-- Config.WeatherParticleMax, the phone budget.

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
	texture: number, -- asset id, 0 for the default particle
	squash: number, -- stretch along the particle's up axis (1 is round); with velocityParallel a streak
	velocityParallel: boolean, -- orient each particle along its velocity (rain streaks) instead of facing the camera
	mode: "fall" | "drift", -- fall: the sheet is a plane perpendicular to direction (rain, snow); drift: a horizontal sheet at `height` whose particles start still and are pushed along direction (fog, haze)
}

local Sheets: { [string]: Sheet } = {
	Rain = { rate = 190, lifetime = { 0.6, 0.9 }, speed = { 60, 80 }, sizeStart = 0.6, sizeEnd = 0.6, color = "D6E8F8", transparency = 0.15, direction = { 0.15, -1, 0 }, spread = 4, span = 36, height = 24, lightEmission = 0.3, drag = 0, rotationSpeed = { 0, 0 }, texture = 0, squash = 3, velocityParallel = true, mode = "fall" },
	Fog = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "DDE2E6", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0, squash = 1, velocityParallel = false, mode = "drift" },
	Snow = { rate = 36, lifetime = { 3, 5 }, speed = { 6, 10 }, sizeStart = 0.9, sizeEnd = 0.7, color = "FFFFFF", transparency = 0.1, direction = { 0.1, -1, 0.1 }, spread = 25, span = 40, height = 30, lightEmission = 0.15, drag = 1.5, rotationSpeed = { -40, 40 }, texture = 0, squash = 1, velocityParallel = false, mode = "fall" },
	Blizzard = { rate = 95, lifetime = { 1.2, 2 }, speed = { 35, 50 }, sizeStart = 0.8, sizeEnd = 0.6, color = "F2F7FB", transparency = 0.15, direction = { 0.8, -0.7, 0 }, spread = 10, span = 40, height = 22, lightEmission = 0.1, drag = 0, rotationSpeed = { -60, 60 }, texture = 0, squash = 2, velocityParallel = true, mode = "fall" },
	Smog = { rate = 10, lifetime = { 5, 8 }, speed = { 1, 3 }, sizeStart = 8, sizeEnd = 14, color = "9A8F7A", transparency = 0.8, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 6, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0, squash = 1, velocityParallel = false, mode = "drift" },
	Haze = { rate = 8, lifetime = { 5, 8 }, speed = { 1, 2 }, sizeStart = 9, sizeEnd = 15, color = "E0B089", transparency = 0.85, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 5, lightEmission = 0.05, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0, squash = 1, velocityParallel = false, mode = "drift" },
	Ashfall = { rate = 38, lifetime = { 3, 5 }, speed = { 4, 8 }, sizeStart = 0.3, sizeEnd = 0.2, color = "4A4A4A", transparency = 0.2, direction = { 0.2, -1, 0 }, spread = 20, span = 60, height = 35, lightEmission = 0, drag = 1, rotationSpeed = { -30, 30 }, texture = 0, squash = 1, velocityParallel = false, mode = "fall" },
	Mist = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "CFE6EC", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0, squash = 1, velocityParallel = false, mode = "drift" },
}

return {
	Sheets = Sheets,
	FollowSeconds = 0.1, -- the sheet re-centres over the camera this often
	FadeSeconds = 1.5, -- a weather change ramps the old sheet's rate to 0 and the new one up over this long
}
