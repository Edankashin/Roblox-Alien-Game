--!strict
-- The first eight minutes as data (docs/PRE_PRODUCTION.md 3.1, trimmed to the systems that exist).
-- The server advances tutorialStep when a step's trigger fires; the client shows the hint (strings key)
-- and a waypoint. A step with `spawn` keeps one reserved alien of that species near the camp for the
-- player until it is caught, so the trainee beats never depend on luck.
export type Trigger = {
	kind: "collect" | "catchSpecies" | "catchCount" | "moduleStarted" | "moduleComplete" | "biome",
	material: string?,
	species: string?,
	moduleId: string?,
	biome: string?,
	count: number?,
}
export type Step = {
	id: string,
	hint: string, -- strings key
	trigger: Trigger,
	waypoint: "node" | "spawn" | "ship" | "biome" | "none", -- what the marker points at
	waypointTarget: string?, -- material id for node, biome name for biome
	spawn: { species: string }?,
}

local Steps: { Step } = {
	{ id = "T1", hint = "TUT_1", trigger = { kind = "collect", material = "WreckPlate", count = 3 }, waypoint = "node", waypointTarget = "WreckPlate" },
	{ id = "T2", hint = "TUT_2", trigger = { kind = "catchSpecies", species = "Mossbop" }, waypoint = "spawn", spawn = { species = "Mossbop" } },
	{ id = "T3", hint = "TUT_3", trigger = { kind = "moduleStarted", moduleId = "HullFrame" }, waypoint = "ship" },
	{ id = "T4", hint = "TUT_4", trigger = { kind = "catchSpecies", species = "Puffpuff" }, waypoint = "spawn", spawn = { species = "Puffpuff" } },
	{ id = "T5", hint = "TUT_5", trigger = { kind = "catchCount", count = 3 }, waypoint = "none" },
	{ id = "T6", hint = "TUT_6", trigger = { kind = "moduleComplete", moduleId = "HullFrame" }, waypoint = "ship" },
	{ id = "T7", hint = "TUT_7", trigger = { kind = "biome", biome = "Forest" }, waypoint = "biome", waypointTarget = "Forest" },
}

return { Steps = Steps }
