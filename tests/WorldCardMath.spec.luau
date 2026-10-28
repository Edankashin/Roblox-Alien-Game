--!strict
-- Shared/WorldCardMath: the species roster of a card (Warden, weather species, tier order, ties, a world with none), the chip
-- states, the found counts, the diorama's skyline and sun, the next stop on the chart and on the Ship's strip, the card order and the
-- grid row, and the data's own contract (every world has a card, the diorama's shares sum to one).
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.WorldCardMath)
local Cards = require(Shared.data.WorldCards)
local Species = require(Shared.data.Species)
local Worlds = require(Shared.data.Worlds)
local Tiers = require(Shared.data.Tiers)

local function def(id: string, name: string, tier: string, world: number)
	return { id = id, name = name, tier = tier, world = world }
end

-- A made-up world 9 whose Warden is a Legendary and whose weather species is an Epic.
local world9 = {
	id = 9, name = "Test", biomes = {}, warden = "Boss", rule = "", placeId = 0, built = true,
	weather = { normal = { "Clear" }, special = { id = "Rain", speciesId = "Storm", chance = 0.3 } },
}
local list = {
	def("Zed", "Zed", "Common", 9),
	def("Abe", "Abe", "Common", 9),
	def("Storm", "Storm", "Epic", 9),
	def("Rare1", "Rare One", "Rare", 9),
	def("Boss", "Boss", "Legendary", 9),
	def("Hush", "Hush", "Secret", 9),
	def("Other", "Other", "Cosmic", 8),
}

describe("WorldCardMath Roster", function()
	it("puts the Warden first, the weather species second, then the rest by tier from the rarest and by name", function()
		local roster = Math.Roster(9, list, world9)
		expect(table.concat(roster, ",")).toEqual("Boss,Storm,Hush,Rare1,Abe,Zed")
	end)
	it("never lists a species of another world or the same species twice", function()
		local roster = Math.Roster(9, list, world9)
		expect(table.find(roster, "Other")).toEqual(nil)
		local seen: { [string]: boolean } = {}
		for _, id in ipairs(roster) do
			expect(seen[id]).toEqual(nil)
			seen[id] = true
		end
	end)
	it("breaks a tie of tier and name by id", function()
		local twins = { def("B", "Same", "Rare", 9), def("A", "Same", "Rare", 9) }
		expect(table.concat(Math.Roster(9, twins, world9), ",")).toEqual("A,B")
	end)
	it("skips a Warden or weather species the list does not hold, and answers empty for a world with none", function()
		local bare = { def("Abe", "Abe", "Common", 9) }
		expect(table.concat(Math.Roster(9, bare, world9), ",")).toEqual("Abe")
		expect(#Math.Roster(9, {}, world9)).toEqual(0)
		expect(#Math.Roster(0, Species.List)).toEqual(0) -- the Home planet has no species
	end)
	it("opens World 1 on Gaiabloom then Thunderhog and World 2 on Skaddle then Frostfang", function()
		local one = Math.Roster(1, Species.List)
		expect(one[1]).toEqual(Worlds[1].warden)
		expect(one[2]).toEqual(Worlds[1].weather.special.speciesId)
		local two = Math.Roster(2, Species.List)
		expect(two[1]).toEqual(Worlds[2].warden)
		expect(two[2]).toEqual(Worlds[2].weather.special.speciesId)
	end)
	it("holds every species of each built world exactly once", function()
		for _, id in ipairs({ 1, 2 }) do
			local expected = 0
			for _, species in ipairs(Species.List) do
				if species.world == id then
					expected += 1
				end
			end
			expect(#Math.Roster(id, Species.List)).toEqual(expected)
		end
	end)
end)

describe("WorldCardMath chips and counts", function()
	it("counts a species found when the codex has an entry for it", function()
		local found, total = Math.Counts(9, list, { Boss = { count = 1 }, Zed = { count = 3 }, Other = { count = 1 } })
		expect(found).toEqual(2)
		expect(total).toEqual(6)
		local none, all = Math.Counts(9, list, {})
		expect(none).toEqual(0)
		expect(all).toEqual(6)
	end)
	it("shows a caught species by its colour, an uncaught one and any Secret as a question mark", function()
		expect(Math.ChipState("Rare", true)).toEqual("Caught")
		expect(Math.ChipState("Rare", false)).toEqual("Unknown")
		expect(Math.ChipState("Secret", true)).toEqual("Unknown")
		expect(Math.ChipState("Secret", false)).toEqual("Unknown")
	end)
	it("drops a chip under the narrow panel width (iPhone SE) and keeps five at the default window and the iPad", function()
		expect(Math.ChipCount(Cards.NarrowPanelPx - 1)).toEqual(Cards.RowNarrow)
		expect(Math.ChipCount(Cards.NarrowPanelPx)).toEqual(Cards.Row)
		expect(Math.ChipCount(900)).toEqual(Cards.Row)
		expect(Math.ChipCount(0)).toEqual(Cards.Row) -- a panel not measured yet shows the full row
		expect(Cards.RowNarrow < Cards.Row).toEqual(true)
	end)
end)

describe("WorldCardMath diorama", function()
	local columns = Cards.Diorama.Columns
	local rows = Math.DioramaRows(columns, Cards.Aspect)
	it("keeps cells square: the rows are the columns over the aspect", function()
		expect(rows).toEqual(20)
		expect(Math.DioramaRows(columns, 9)).toEqual(5)
		expect(Math.DioramaRows(columns, 0)).toEqual(columns)
	end)
	it("draws one to three towers, inside the box, never above the sky bands, the same every time", function()
		local t = Cards.Diorama.Towers
		local skyRows = math.floor(rows * (Cards.Diorama.SkyShare + Cards.Diorama.SkyLowShare))
		for world = 0, 7 do
			local a = Math.Towers(world, columns, rows)
			local b = Math.Towers(world, columns, rows)
			expect(#a >= t.Min and #a <= t.Max).toEqual(true)
			expect(#a).toEqual(#b)
			for index, tower in ipairs(a) do
				expect(tower.col).toEqual(b[index].col)
				expect(tower.height).toEqual(b[index].height)
				expect(tower.col >= 0 and tower.col + tower.width <= columns).toEqual(true)
				expect(tower.height >= 1 and tower.height < skyRows).toEqual(true)
			end
		end
	end)
	it("never overlaps two towers of one world", function()
		for world = 0, 7 do
			local towers = Math.Towers(world, columns, rows)
			for index = 2, #towers do
				expect(towers[index].col >= towers[index - 1].col + towers[index - 1].width).toEqual(true)
			end
		end
	end)
	it("keeps the sun inside the box on every world and on the Ship's strip", function()
		for world = 0, 7 do
			for _, shape in ipairs({ rows, Math.DioramaRows(columns, 9) }) do
				local sun = Math.Accent(world, columns, shape)
				expect(sun.col >= 0 and sun.col + sun.cells <= columns).toEqual(true)
				expect(sun.row >= 0 and sun.row + sun.cells <= math.max(shape, sun.cells)).toEqual(true)
			end
		end
	end)
	it("shares the card's height between four bands that sum to one", function()
		local d = Cards.Diorama
		expect(math.abs(d.SkyShare + d.SkyLowShare + d.FarShare + d.GroundShare - 1) < 1e-9).toEqual(true)
	end)
end)

describe("WorldCardMath order and next stop", function()
	it("orders the Home planet first and then the worlds", function()
		expect(table.concat(Math.Order(3), ",")).toEqual("0,1,2,3")
		expect(table.concat(Math.Order(#Worlds), ",")).toEqual("0,1,2,3,4,5,6,7")
	end)
	it("names the next stop on the chart: the first locked world past the highest unlocked one", function()
		local ids = Math.Order(7)
		expect(Math.NextLocked(ids, { [1] = true }, 1)).toEqual(2)
		expect(Math.NextLocked(ids, { [1] = true, [2] = true }, 2)).toEqual(3)
		expect(Math.NextLocked(ids, { [1] = true, [3] = true }, 3)).toEqual(4)
		expect(Math.NextLocked(Math.Order(2), { [1] = true, [2] = true }, 2)).toEqual(nil)
		expect(Math.NextLocked(ids, { [0] = true }, 0)).toEqual(1) -- on the Home planet the first world is next
	end)
	it("names the Ship's strip: the first world past the current one, else the one before", function()
		local ids = Math.Order(7)
		expect(Math.NextStop(ids, 1)).toEqual(2)
		expect(Math.NextStop(ids, 3)).toEqual(4)
		expect(Math.NextStop(ids, 0)).toEqual(1) -- at home the first world is the destination
		expect(Math.NextStop(ids, 7)).toEqual(1) -- at the last world the way back
		expect(Math.NextStop({ 0, 1 }, 1)).toEqual(nil) -- nowhere else to go
	end)
	it("finds the grid row a card sits in and which cards are near the viewport", function()
		expect(Math.Row(1, 2)).toEqual(0)
		expect(Math.Row(2, 2)).toEqual(0)
		expect(Math.Row(3, 2)).toEqual(1)
		expect(Math.Row(8, 2)).toEqual(3)
		expect(Math.Near(0, 100, 0, 200, 1)).toEqual(true)
		expect(Math.Near(500, 600, 0, 200, 1)).toEqual(false) -- 500 is past 200 + one window
		expect(Math.Near(380, 480, 0, 200, 1)).toEqual(true)
		expect(Math.Near(0, 100, 600, 200, 1)).toEqual(false)
	end)
end)

describe("data/WorldCards", function()
	it("has a card for every world and the Home planet, in the world's own colours", function()
		for id = 0, #Worlds do
			local card = Cards.Cards[id]
			expect(card ~= nil).toEqual(true)
			for _, hex in ipairs({ card.color, card.palette.sky, card.palette.skyLow, card.palette.far, card.palette.ground, card.palette.accent }) do
				expect(string.match(hex, "^%x%x%x%x%x%x$") ~= nil).toEqual(true)
			end
			expect(card.image).toEqual(0) -- nothing uploaded yet: the diorama draws
		end
	end)
	it("never uses a rarity colour as a place colour", function()
		for id = 0, #Worlds do
			for _, tier in ipairs(Tiers.Order) do
				expect(Cards.Cards[id].color:upper() ~= Tiers.Tiers[tier].color:upper()).toEqual(true)
			end
		end
	end)
	it("opens each world after the one before it", function()
		for id = 2, #Worlds do
			expect(Cards.Cards[id].unlockAfter).toEqual(id - 1)
		end
	end)
end)

return true
