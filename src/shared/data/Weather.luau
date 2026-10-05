--!strict
-- Weather particles (Look plan pass L3, particles): one emitter sheet that follows the camera, switched
-- by the clock's weather name. Everything a sheet needs is here; the client's WeatherFx only reads it.
-- Textures are Roblox's default particle (0) until the icon pack brings proper ones. Rates are per second
-- across the whole sheet and must keep the on-screen count under Config.WeatherParticleMax on a phone.

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
}

local Sheets: { [string]: Sheet } = {
	Rain = { rate = 140, lifetime = { 0.8, 1.2 }, speed = { 60, 80 }, sizeStart = 0.25, sizeEnd = 0.25, color = "BFD8F0", transparency = 0.35, direction = { 0.15, -1, 0 }, spread = 4, span = 70, height = 45, lightEmission = 0.1, drag = 0, rotationSpeed = { 0, 0 }, texture = 0 },
	Fog = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "DDE2E6", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0 },
	Snow = { rate = 90, lifetime = { 3, 5 }, speed = { 6, 10 }, sizeStart = 0.35, sizeEnd = 0.3, color = "FFFFFF", transparency = 0.1, direction = { 0.1, -1, 0.1 }, spread = 25, span = 60, height = 35, lightEmission = 0.15, drag = 1.5, rotationSpeed = { -40, 40 }, texture = 0 },
	Blizzard = { rate = 180, lifetime = { 1.2, 2 }, speed = { 35, 50 }, sizeStart = 0.4, sizeEnd = 0.3, color = "F2F7FB", transparency = 0.15, direction = { 0.8, -0.7, 0 }, spread = 10, span = 70, height = 30, lightEmission = 0.1, drag = 0, rotationSpeed = { -60, 60 }, texture = 0 },
	Smog = { rate = 10, lifetime = { 5, 8 }, speed = { 1, 3 }, sizeStart = 8, sizeEnd = 14, color = "9A8F7A", transparency = 0.8, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 6, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0 },
	Haze = { rate = 8, lifetime = { 5, 8 }, speed = { 1, 2 }, sizeStart = 9, sizeEnd = 15, color = "E0B089", transparency = 0.85, direction = { 1, 0.1, 0 }, spread = 30, span = 60, height = 5, lightEmission = 0.05, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0 },
	Ashfall = { rate = 70, lifetime = { 3, 5 }, speed = { 4, 8 }, sizeStart = 0.3, sizeEnd = 0.2, color = "4A4A4A", transparency = 0.2, direction = { 0.2, -1, 0 }, spread = 20, span = 60, height = 35, lightEmission = 0, drag = 1, rotationSpeed = { -30, 30 }, texture = 0 },
	Mist = { rate = 6, lifetime = { 6, 9 }, speed = { 1, 2 }, sizeStart = 10, sizeEnd = 16, color = "CFE6EC", transparency = 0.85, direction = { 1, 0, 0.2 }, spread = 30, span = 60, height = 3, lightEmission = 0, drag = 0.5, rotationSpeed = { -3, 3 }, texture = 0 },
}

return {
	Sheets = Sheets,
	FollowSeconds = 0.1, -- the sheet re-centres over the camera this often
	FadeSeconds = 1.5, -- a weather change ramps the old sheet's rate to 0 and the new one up over this long
}
