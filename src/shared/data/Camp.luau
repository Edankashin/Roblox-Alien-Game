--!strict
-- Placeholder layout of a player's camp around the pad at the origin: the ship (five module parts that
-- appear as each module completes) and the three stations with a row of worker slots beside each.
-- The client renders its own camp from these numbers; nothing here is replicated.
export type PlaceholderPart = { offset: Vector3, size: Vector3, color: string, shape: "Ball" | "Block" | "Cylinder" }
export type StationLayout = { offset: Vector3, size: Vector3, color: string, slotDirection: Vector3 }

local Modules: { [string]: PlaceholderPart } = {
	HullFrame = { offset = Vector3.new(0, 2, 0), size = Vector3.new(10, 4, 16), color = "C8CCD4", shape = "Block" },
	Thrusters = { offset = Vector3.new(0, 1.5, 9.5), size = Vector3.new(8, 3, 3), color = "FF8C42", shape = "Block" },
	LifePod = { offset = Vector3.new(0, 6.5, -2), size = Vector3.new(6, 5, 6), color = "68C9FE", shape = "Ball" },
	NavArray = { offset = Vector3.new(0, 10.5, -5), size = Vector3.new(3, 1, 1), color = "FFC83D", shape = "Cylinder" },
	EngineCore = { offset = Vector3.new(0, 2.5, 4.5), size = Vector3.new(4, 4, 4), color = "C026D3", shape = "Ball" },
}

local Stations: { [string]: StationLayout } = {
	-- Picnic Table: a low wide slab
	Gather = { offset = Vector3.new(-17, 0, 6), size = Vector3.new(6, 1.5, 3), color = "FFC83D", slotDirection = Vector3.new(0, 0, 1) },
	-- Treehouse Bench: a taller block
	Build = { offset = Vector3.new(17, 0, 6), size = Vector3.new(5, 2.5, 3), color = "8B5A2B", slotDirection = Vector3.new(0, 0, 1) },
	-- Glow Flower: a thin bright column
	Spark = { offset = Vector3.new(0, 0, 19), size = Vector3.new(2, 4, 2), color = "A855F7", slotDirection = Vector3.new(1, 0, 0) },
}

return {
	ShipOffset = Vector3.new(0, 0, -20), -- from the camp pad centre; the spawn faces -Z so the ship is straight ahead
	ShipBaseSize = Vector3.new(12, 0.5, 20), -- a landing pad under the ship
	ShipBaseColor = "5B6472",
	GhostTransparency = 0.8, -- modules not yet built render as ghosts
	ActivePulseSeconds = 1.2, -- the module being built pulses between ghost and half-visible
	SnapPopScale = 1.3, -- a completed module pops in from this scale
	Modules = Modules,
	Stations = Stations,
	SlotSpacing = 3, -- studs between worker slots beside a station
	SlotOffsetFromStation = 3.5, -- the slot row sits this far from the station centre
	WorkerScale = 0.7, -- workers render smaller than wild aliens
	WorkerBobStuds = 0.2,
	WorkerBobHz = 1.2,
}
