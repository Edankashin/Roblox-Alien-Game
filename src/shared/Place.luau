--!strict
-- ReplicatedStorage.Shared.Place: which world this place runs. Every world is its own Roblox place in
-- one universe running the same code (GAME_DESIGN sections 8 and 17); the place says which world it is
-- through the Workspace attribute WorldId, set per place by its Rojo project file (default.project.json
-- is World 1, world2.project.json is World 2). Everything that used to be hard-wired to World 1 (the
-- world builder, node scatter, the Field Notes chain, the warden, egg species, the weather list) asks
-- here instead. Shared, so the client's biome chip and renderers read the same answer as the server.

local Workspace = game:GetService("Workspace")

local Worlds = require(script.Parent.data.Worlds)
local Layouts = require(script.Parent.data.Layouts)

local Place = {}

local ATTRIBUTE = "WorldId"
local DEFAULT_WORLD = 1 -- a place with no attribute, or one naming a world that does not exist, is World 1

local cached: number? = nil

-- The world id this place runs: the WorldId attribute when it is a number naming a world in
-- data/Worlds.luau, else 1. Read once and cached: a place never changes world while it runs.
function Place.WorldId(): number
	local known = cached
	if known then
		return known
	end
	local value = Workspace:GetAttribute(ATTRIBUTE)
	local id = DEFAULT_WORLD
	if type(value) == "number" and Worlds[value] ~= nil then
		id = value
	end
	cached = id
	return id
end

-- The layout the world builder, Biomes and the node scatter read for this place. A world whose layout
-- is not written yet (data/Layouts.luau lists them) falls back to World 1's so the place still boots.
function Place.Layout(): Layouts.Layout
	local id = Place.WorldId()
	local layout = Layouts[id]
	if layout == nil then
		warn(("Place: no layout for world %d; building World %d's"):format(id, DEFAULT_WORLD))
		return Layouts[DEFAULT_WORLD]
	end
	return layout
end

return Place
