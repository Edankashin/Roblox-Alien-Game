--!strict
-- The house grid on the home planet (docs/GAME_DESIGN.md section 10, "House (Bloxburg-lite)"): prefab rooms and
-- furniture placed on the plot's cells (data/Home PlotCells x PlotCells, PlotCellStuds each), paid in Scrap and
-- priced below ship parts so a house never blocks a launch. No free-form building: an item covers whole cells,
-- turns in quarter steps, and the plot's size and the caps are the capacity (upgrades come later). The server
-- owns every placement; the client only previews on the grid and draws what the profile says. Every number here.

export type Kind = "room" | "furniture" | "habitat"

export type Item = {
	id: string,
	kind: Kind,
	cellsX: number, -- footprint in cells before rotation
	cellsZ: number,
	scrap: number,
	prop: string?, -- an imported prop (Shared/Props) drawn when it exists; nil or missing draws the placeholder
	placeholder: { shape: "Block" | "Cylinder" | "Ball", color: string, height: number }, -- studs tall; the footprint sets width and depth
	worldId: number?, -- habitat only: the world whose aliens it shows (data/Habitats)
	capacity: number?, -- habitat only: aliens on display at once
}

local Items: { Item } = {
	{ id = "RoomCabin", kind = "room", cellsX = 2, cellsZ = 2, scrap = 300, prop = "RoomCabin", placeholder = { shape = "Block", color = "C8A27A", height = 6 } },
	{ id = "RoomDome", kind = "room", cellsX = 2, cellsZ = 2, scrap = 450, prop = "RoomDome", placeholder = { shape = "Ball", color = "9ED6F0", height = 7 } },
	{ id = "RoomTower", kind = "room", cellsX = 1, cellsZ = 1, scrap = 350, prop = "RoomTower", placeholder = { shape = "Cylinder", color = "B9B9C9", height = 10 } },
	{ id = "Bench", kind = "furniture", cellsX = 1, cellsZ = 1, scrap = 60, prop = "Bench", placeholder = { shape = "Block", color = "7B4A2D", height = 1.2 } },
	{ id = "Lamp", kind = "furniture", cellsX = 1, cellsZ = 1, scrap = 80, prop = "HeaterLamp", placeholder = { shape = "Cylinder", color = "FFC83D", height = 4 } },
	{ id = "Planter", kind = "furniture", cellsX = 1, cellsZ = 1, scrap = 50, prop = "Planter", placeholder = { shape = "Block", color = "3F9B3A", height = 1.5 } },
	{ id = "Fountain", kind = "furniture", cellsX = 2, cellsZ = 2, scrap = 250, prop = "Fountain", placeholder = { shape = "Cylinder", color = "68C9FE", height = 2.5 } },
	{ id = "Flag", kind = "furniture", cellsX = 1, cellsZ = 1, scrap = 40, prop = "Flag", placeholder = { shape = "Cylinder", color = "FF8AD8", height = 6 } },
	-- habitats (data/Habitats): a pad with a fence where up to `capacity` resting aliens of `worldId` roam on display
	{ id = "HabitatVerdant", kind = "habitat", cellsX = 3, cellsZ = 3, scrap = 600, prop = "HabitatVerdant", placeholder = { shape = "Block", color = "6FBF4A", height = 0.3 }, worldId = 1, capacity = 3 },
	{ id = "HabitatFrostbyte", kind = "habitat", cellsX = 3, cellsZ = 3, scrap = 800, prop = "HabitatFrostbyte", placeholder = { shape = "Block", color = "DCEFF7", height = 0.3 }, worldId = 2, capacity = 3 },
}

local ById: { [string]: Item } = {}
for _, item in ipairs(Items) do
	ById[item.id] = item
end

return {
	Items = Items, -- in display order
	ById = ById,
	Caps = { room = 4, furniture = 12, habitat = 2 }, -- items of each kind on the plot at once (the monetised capacity, later)
	RotationSteps = 4, -- quarter turns; rotation is 0..3
	DecorateInteractDistance = 18, -- studs from the plot's centre to offer "Decorate"
	PreviewLift = 0.05, -- the ghost sits this far over the plot so it never z-fights
	GhostTransparency = 0.5,
	RemoveRefund = 0, -- fraction of the price paid back on remove (none: a kid's choice stands, and Scrap stays one-way)
}
