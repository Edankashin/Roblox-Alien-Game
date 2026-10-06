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

-- The tutorial is this world's script (its nodes, trainees and biomes are World 1's); a profile whose
-- current world is any other is past the tutorial and is marked done.
local World = 1

-- The five-minute script (docs/vault/01-game-design/Growth-Playbook.md section 6, decision 18): the first
-- Welcome Week gift lands as the payoff of the first finished module, and the server-wide events that would
-- pull a new player off the loop (the Peddler's landing banner, the Meteor Shower chip and banner) stay
-- quiet on the client until the tutorial is done. All presentation: the server's events and timers run as ever.
local Script = {
	GiftPopAfterStep = "T6", -- once this step completes, the Gifts screen opens if the day-1 gift is unclaimed
	GiftPopWaitSeconds = 8, -- how long to wait for the module-complete camera pan and any open panel before giving up on the pop
	GiftPopPollSeconds = 0.25, -- how often that wait re-checks
	HoldEventBannersWhileActive = true, -- Peddler arrival banner, shower countdown chip and shower banner wait for the tutorial to end
}

return { Steps = Steps, World = World, Script = Script }
