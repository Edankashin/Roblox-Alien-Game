--!strict
-- Warden sightings (docs/GAME_DESIGN.md section 12, "Warden sightings"): on a fixed server clock the world's
-- Warden (Worlds[worldId].warden) crosses the map in the open along a path of points, uncatchable, with a
-- server-wide banner; everyone online sees the same thing. The server moves one anchored part along the path
-- (Workspace.World.Sightings); every client draws the Warden's mesh on it with a trail at its feet. The sighting
-- lives outside the Wild folder, so the capture flow and the radar never see it. Every number here, never in code.

export type Point = { x: number, z: number } -- a flat point on the floor; the server finds the height

local Paths: { [number]: { Point } } = {
	-- World 1: from the shrine, between the camp and the Forest, past the wreck, by the Cave mouth, back round to the shrine.
	[1] = { { x = 0, z = 155 }, { x = 60, z = 50 }, { x = 40, z = -30 }, { x = -60, z = -60 }, { x = -120, z = 20 }, { x = -40, z = 120 }, { x = 0, z = 155 } },
	-- World 2: the same sweep over Frostbyte (its shrine and landmarks sit at the same points).
	[2] = { { x = 0, z = 155 }, { x = 60, z = 50 }, { x = 40, z = -30 }, { x = -60, z = -60 }, { x = -120, z = 20 }, { x = -40, z = 120 }, { x = 0, z = 155 } },
}

local TrailColorByWorld: { [number]: string } = { [1] = "FF2E9A", [2] = "33B5FF" } -- flowers on World 1, frost on World 2 (deep hues: Neon and a light wash a pale tint out to white)

return {
	Paths = Paths,
	IntervalSeconds = 1200, -- fixed server clock: a sighting starts at every multiple of this since the epoch (like the shower)
	SpeedStudsPerSecond = 8, -- the Warden's walking speed along the path
	TickSeconds = 0.1, -- how often the server moves the part (the client smooths between ticks)
	PushSeconds = 10, -- how often the server refreshes the sighting clock on clients while one runs
	Scale = 1.3, -- model scale over the species' own (the Warden looms a little when it walks free)
	FaceLerp = 0.15, -- fraction of the turn toward the travel direction the client applies each frame
	-- The client walks the model at SpeedStudsPerSecond toward the server part (which steps ten times a second), so the
	-- motion is even; past CatchUpGapStuds behind it walks CatchUpScale times faster until it is close again.
	CatchUpGapStuds = 2,
	CatchUpScale = 1.5,
	TrailStepStuds = 3, -- a trail puff is left every this many studs walked
	TrailLifeSeconds = 20, -- a puff fades out over this
	TrailSizeStuds = 1.2,
	TrailColorByWorld = TrailColorByWorld,
	TrailLightRange = 8, -- the point light each puff carries while it lives
	TrailLightBrightness = 0.5, -- dimmer than Roblox's default 1, so the puff keeps its colour by day
	Hidden = {}, -- world ids with no sighting (none yet; a world without a path has none either)
}
