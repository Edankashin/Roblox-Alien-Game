--!strict
-- Shared.FeaturedMath and data/Panels.Featured (UI richness pass, package C): the side and strip modes, the Aliens default selection
-- and order, the featured card's buttons by context, the flavour line's key and the 35 lines, the Codex's tier sections, counts,
-- columns and sectioned grid, and the card's layout in both modes (nothing overlaps, nothing leaves the card). The panel sizes are
-- the real ones: Aliens keeps the aspect 1.35 at 0.84 of the screen, the Codex 1.2536 (its old 1.35 at 0.78 holding its width).
local Shared = game:GetService("ReplicatedStorage").Shared
local FeaturedMath = require(Shared.FeaturedMath)
local Panels = require(Shared.data.Panels)
local Species = require(Shared.data.Species)
local Strings = require(Shared.strings.en)
local Tiers = require(Shared.data.Tiers)

local SE = { name = "iPhone SE", w = 667, h = 375 }
local IPAD = { name = "iPad", w = 1080, h = 810 }
local DEFAULT = { name = "default window", w = 1154, h = 663 }
local SHELL_HEIGHT = 0.84
local ALIENS_ASPECT = 1.35
local CODEX_ASPECT = 1.35 * 0.78 / SHELL_HEIGHT

-- A panel's px at `screen`: the plate keeps its aspect inside 0.8 of the width and 0.84 of the height.
local function panelPx(screen: { w: number, h: number }, aspect: number): (number, number)
	local h = SHELL_HEIGHT * screen.h
	local w = h * aspect
	if w > 0.8 * screen.w then
		w = 0.8 * screen.w
		h = w / aspect
	end
	return w, h
end

describe("Featured mode", function()
	it("shows the strip at an iPhone SE panel and the side card at the default window and an iPad", function()
		local sw, sh = panelPx(SE, ALIENS_ASPECT)
		expect(FeaturedMath.Mode(sw, sh)).toEqual("strip")
		local dw, dh = panelPx(DEFAULT, ALIENS_ASPECT)
		expect(FeaturedMath.Mode(dw, dh)).toEqual("side")
		local iw, ih = panelPx(IPAD, ALIENS_ASPECT)
		expect(FeaturedMath.Mode(iw, ih)).toEqual("side")
		local cw, ch = panelPx(DEFAULT, CODEX_ASPECT)
		expect(FeaturedMath.Mode(cw, ch)).toEqual("side")
		local csw, csh = panelPx(SE, CODEX_ASPECT)
		expect(FeaturedMath.Mode(csw, csh)).toEqual("strip")
	end)
	it("switches exactly at the minimum width and height", function()
		local f = Panels.Featured
		expect(FeaturedMath.Mode(f.MinPanelW, f.MinPanelH)).toEqual("side")
		expect(FeaturedMath.Mode(f.MinPanelW - 1, f.MinPanelH)).toEqual("strip")
		expect(FeaturedMath.Mode(f.MinPanelW, f.MinPanelH - 1)).toEqual("strip")
	end)
	it("gives the Aliens grid three columns in the side mode and five in the strip mode, filling the canvas", function()
		local sideCols, sideCell, sideGap = FeaturedMath.AliensGrid("side")
		local stripCols, stripCell, stripGap = FeaturedMath.AliensGrid("strip")
		expect(sideCols).toEqual(3)
		expect(stripCols).toEqual(5)
		assert(sideCols * sideCell + (sideCols - 1) * sideGap <= 1.0001, "the side columns overflow the canvas")
		assert(stripCols * stripCell + (stripCols - 1) * stripGap <= 1.0001, "the strip columns overflow the canvas")
	end)
	it("keeps the card and the grid side by side inside the panel", function()
		local side = Panels.Featured.Side
		assert(side.CardX + side.CardW < side.GridX, "the card and the grid overlap")
		assert(side.GridX + side.GridW <= 1, "the grid leaves the panel")
	end)
end)

describe("Aliens selection", function()
	local caught = { a = 10, b = 30, c = 20, d = 30 }
	it("opens on the mount you ride", function()
		expect(FeaturedMath.AliensDefault("c", { "a" }, caught)).toEqual("c")
	end)
	it("else on the first companion", function()
		expect(FeaturedMath.AliensDefault(nil, { "c", "a" }, caught)).toEqual("c")
	end)
	it("skips a ride or a companion that is no longer owned", function()
		expect(FeaturedMath.AliensDefault("gone", { "gone", "a" }, caught)).toEqual("a")
	end)
	it("else on the newest alien, a tie going to the greater uid", function()
		expect(FeaturedMath.AliensDefault(nil, {}, caught)).toEqual("d")
		expect(FeaturedMath.AliensDefault(nil, {}, { x = 5 })).toEqual("x")
	end)
	it("is nil when nothing is owned", function()
		assert(FeaturedMath.AliensDefault(nil, {}, {}) == nil, "an empty store selects nothing")
		assert(FeaturedMath.AliensDefault("a", { "b" }, {}) == nil, "a stale ride and companion select nothing")
	end)
end)

describe("Aliens order", function()
	local function item(uid: string, riding: boolean, following: boolean, tier: string, speed: number, name: string): FeaturedMath.SortItem
		return { riding = riding, following = following, tierRank = FeaturedMath.TierRank(tier), speed = speed, name = name, uid = uid }
	end
	local function sorted(list: { FeaturedMath.SortItem }): string
		table.sort(list, FeaturedMath.Before)
		local out: { string } = {}
		for _, entry in ipairs(list) do
			table.insert(out, entry.uid)
		end
		return table.concat(out, ",")
	end
	it("ranks the tiers from Common up", function()
		expect(FeaturedMath.TierRank("Common")).toEqual(1)
		expect(FeaturedMath.TierRank("Secret")).toEqual(#Tiers.Order)
		expect(FeaturedMath.TierRank("Nonsense")).toEqual(0)
	end)
	it("puts the ridden one first, then the companions, then the rarer tier first", function()
		local list = {
			item("common", false, false, "Common", 1, "A"),
			item("epic", false, false, "Epic", 6, "B"),
			item("follower", false, true, "Common", 1, "C"),
			item("ridden", true, true, "Rare", 3, "D"),
			item("rare", false, false, "Rare", 3, "E"),
		}
		expect(sorted(list)).toEqual("ridden,follower,epic,rare,common")
	end)
	it("breaks a tie by speed, then name, then uid, the same every time", function()
		local list = {
			item("u3", false, false, "Rare", 3, "Zed"),
			item("u2", false, false, "Rare", 3, "Abe"),
			item("u1", false, false, "Rare", 3, "Abe"),
			item("u4", false, false, "Rare", 4, "Zed"),
		}
		expect(sorted(list)).toEqual("u4,u1,u2,u3")
	end)
end)

describe("Featured buttons", function()
	local function ids(buttons: FeaturedMath.Buttons): string
		local main = if buttons.main then buttons.main.id .. ":" .. buttons.main.role else "-"
		local side = if buttons.side then buttons.side.id .. ":" .. buttons.side.role else "-"
		return main .. " " .. side
	end
	local function aliens(overrides: { [string]: boolean }): FeaturedMath.Context
		local context: any = { screen = "Aliens" }
		for key, value in pairs(overrides) do
			context[key] = value
		end
		return context :: FeaturedMath.Context
	end
	it("Aliens, a free slot: Follow in the main colour", function()
		expect(ids(FeaturedMath.Button(aliens({ slotFree = true })))).toEqual("Follow:main -")
	end)
	it("Aliens, slots full or working at a station: Follow in grey, so the tap can say why", function()
		expect(ids(FeaturedMath.Button(aliens({ slotFree = false })))).toEqual("Follow:current -")
		expect(ids(FeaturedMath.Button(aliens({ slotFree = true, seated = true })))).toEqual("Follow:current -")
	end)
	it("Aliens, following: Stop following in grey, with Ride in blue for a species that has one", function()
		expect(ids(FeaturedMath.Button(aliens({ following = true })))).toEqual("Unfollow:current -")
		expect(ids(FeaturedMath.Button(aliens({ following = true, canRide = true })))).toEqual("Unfollow:current Ride:select")
	end)
	it("Aliens, riding: Hop off in blue and nothing beside it", function()
		expect(ids(FeaturedMath.Button(aliens({ following = true, riding = true, canRide = true })))).toEqual("HopOff:select -")
	end)
	it("Aliens, at home with a habitat: Display in blue beside Follow; Bring back in grey once on display", function()
		expect(ids(FeaturedMath.Button(aliens({ slotFree = true, canDisplay = true })))).toEqual("Follow:main Display:select")
		expect(ids(FeaturedMath.Button(aliens({ displayed = true, canBringBack = true })))).toEqual("BringBack:current -")
		expect(ids(FeaturedMath.Button(aliens({ displayed = true })))).toEqual("- -")
	end)
	it("Aliens, a guest at another home: no button at all", function()
		expect(ids(FeaturedMath.Button(aliens({ visiting = true, slotFree = true, canDisplay = true })))).toEqual("- -")
		expect(ids(FeaturedMath.Button(aliens({ visiting = true, following = true, riding = true })))).toEqual("- -")
	end)
	it("Codex, caught: See in Aliens in green; not caught: none", function()
		expect(ids(FeaturedMath.Button({ screen = "Codex", caught = true }))).toEqual("SeeInAliens:main -")
		expect(ids(FeaturedMath.Button({ screen = "Codex", caught = false }))).toEqual("- -")
	end)
	it("names a word that exists in the strings and a role that exists in data/Panels.Roles", function()
		local contexts: { FeaturedMath.Context } = {
			aliens({ slotFree = true, canDisplay = true }),
			aliens({ following = true, canRide = true }),
			aliens({ riding = true }),
			aliens({ displayed = true, canBringBack = true }),
			{ screen = "Codex", caught = true },
		}
		local strings: { [string]: string } = Strings :: any
		for _, context in ipairs(contexts) do
			local buttons = FeaturedMath.Button(context)
			for _, action in ipairs({ buttons.main, buttons.side }) do
				assert(strings[action.word] ~= nil, "no string " .. action.word)
				assert(Panels.Roles[action.role] ~= nil, "no role " .. action.role)
			end
		end
	end)
end)

describe("Flavour lines", function()
	local strings: { [string]: string } = Strings :: any
	local function has(key: string): boolean
		return strings[key] ~= nil
	end
	it("takes the species' own line when it has one", function()
		expect(FeaturedMath.FlavourKey("Mossbop", "Common", has)).toEqual("FLAVOUR_Mossbop")
	end)
	it("falls back to its tier's line so a new species never prints a blank", function()
		expect(FeaturedMath.FlavourKey("Brandnew", "Rare", has)).toEqual("FLAVOUR_TIER_Rare")
	end)
	it("has a line for each of the 35 species, one line of at most 48 characters, and one for each tier", function()
		expect(#Species.List).toEqual(35)
		for _, def in ipairs(Species.List) do
			local line = strings["FLAVOUR_" .. def.id]
			assert(line ~= nil, "no flavour line for " .. def.id)
			assert(#line <= Panels.Featured.MaxFlavour, def.id .. " runs " .. #line .. " characters")
			assert(#line > 0 and not line:find("\n"), def.id .. " must be one line")
		end
		for _, tier in ipairs(Tiers.Order) do
			local line = strings["FLAVOUR_TIER_" .. tier]
			assert(line ~= nil and #line <= Panels.Featured.MaxFlavour, "tier line " .. tier)
		end
	end)
	it("says nothing fierce (B46: cuter, never fiercer)", function()
		local banned = { "bite", "fang", "claw attack", "kill", "fierce", "danger", "attack", "scary", "monster", "blood", "roar" }
		for _, def in ipairs(Species.List) do
			local line = (strings["FLAVOUR_" .. def.id] :: string):lower()
			for _, word in ipairs(banned) do
				assert(not line:find(word, 1, true), def.id .. " says " .. word)
			end
		end
	end)
end)

describe("Codex sections and counts", function()
	it("cuts the page into one section per tier, in order, with their counts", function()
		local tiers = { "Common", "Common", "Rare", "Rare", "Rare", "Epic" }
		local caught = { true, false, true, true, false, false }
		local sections = FeaturedMath.Sections(tiers, caught)
		expect(#sections).toEqual(3)
		expect(sections[1].tier).toEqual("Common")
		expect(sections[1].from).toEqual(1)
		expect(sections[1].to).toEqual(2)
		expect(sections[1].found).toEqual(1)
		expect(sections[1].total).toEqual(2)
		expect(sections[2].found).toEqual(2)
		expect(sections[2].total).toEqual(3)
		expect(sections[3].found).toEqual(0)
		expect(sections[3].total).toEqual(1)
	end)
	it("agrees with the page pill: the sections sum to the page's found and total", function()
		local list: { FeaturedMath.CodexEntry } = {}
		local tiers: { string } = {}
		local caughtList: { boolean } = {}
		local caught: { [string]: boolean } = {}
		for _, def in ipairs(Species.List) do
			if def.world == 1 then
				table.insert(list, { id = def.id, world = def.world })
				table.insert(tiers, def.tier)
				table.insert(caughtList, #tiers % 3 == 0)
				if #tiers % 3 == 0 then
					caught[def.id] = true
				end
			end
		end
		local _, _, pageFound, pageTotal = FeaturedMath.CodexCounts(list, caught, { [1] = true }, 1)
		local found, total = 0, 0
		for _, section in ipairs(FeaturedMath.Sections(tiers, caughtList)) do
			found += section.found
			total += section.total
		end
		expect(found).toEqual(pageFound)
		expect(total).toEqual(pageTotal)
	end)
	it("counts the found pill over the built worlds only", function()
		local list: { FeaturedMath.CodexEntry } = {
			{ id = "a", world = 1 },
			{ id = "b", world = 1 },
			{ id = "c", world = 2 },
			{ id = "d", world = 3 },
		}
		local found, total, pageFound, pageTotal = FeaturedMath.CodexCounts(list, { a = true, c = true, d = true }, { [1] = true, [2] = true }, 2)
		expect(found).toEqual(2)
		expect(total).toEqual(3)
		expect(pageFound).toEqual(1)
		expect(pageTotal).toEqual(1)
	end)
	it("picks the column count from the window's width within the limits", function()
		local c = Panels.Featured.Codex
		expect(FeaturedMath.CodexColumns(0)).toEqual(c.MaxColumns)
		expect(FeaturedMath.CodexColumns(100)).toEqual(c.MinColumns)
		expect(FeaturedMath.CodexColumns(404)).toEqual(5)
		expect(FeaturedMath.CodexColumns(330)).toEqual(4)
		expect(FeaturedMath.CodexColumns(5000)).toEqual(c.MaxColumns)
	end)
end)

describe("Codex sectioned grid", function()
	local plan = FeaturedMath.GridPlan(400, 4, 8, 22, true, { 5, 3, 1 })
	it("makes square tiles that fill the width", function()
		expect(plan.cell).toBeClose((400 - 3 * 8) / 4, 0.0001)
		for _, section in ipairs(plan.sections) do
			for _, item in ipairs(section.items) do
				assert(item.x >= 0 and item.x + plan.cell <= 400.0001, "a tile leaves the canvas")
			end
		end
	end)
	it("stacks the sections in order, each strip over its tiles, with nothing overlapping", function()
		local last = -1
		for index, section in ipairs(plan.sections) do
			assert(section.stripY > last, "section " .. index .. " starts above the one before")
			local firstTile = section.items[1]
			assert(firstTile.y >= section.stripY + 22, "the tiles start under their strip")
			for _, item in ipairs(section.items) do
				last = math.max(last, item.y + plan.cell)
			end
		end
		local lastItem = plan.sections[3].items[1]
		expect(plan.height).toBeClose(lastItem.y + plan.cell, 0.0001)
	end)
	it("wraps a section onto rows of the column count", function()
		local first = plan.sections[1].items
		expect(first[5].x).toEqual(first[1].x)
		assert(first[5].y > first[1].y, "the fifth tile of four columns starts a new row")
	end)
	it("without strips starts the first tile at the top", function()
		local bare = FeaturedMath.GridPlan(400, 4, 8, 22, false, { 5 })
		expect(bare.sections[1].items[1].y).toEqual(0)
	end)
	it("is empty for no sections", function()
		expect(FeaturedMath.GridPlan(400, 4, 8, 22, true, {}).height).toEqual(0)
	end)
end)

describe("Side card layout", function()
	local contexts = {
		{ name = "Aliens, Follow", main = true, side = false, facts = 0 },
		{ name = "Aliens, Stop following and Ride", main = true, side = true, facts = 0 },
		{ name = "Aliens, no button (a guest)", main = false, side = false, facts = 0 },
		{ name = "Codex, caught, three facts", main = true, side = false, facts = 3 },
		{ name = "Codex, not caught, two facts", main = false, side = false, facts = 2 },
	}
	for _, context in ipairs(contexts) do
		it(context.name .. ": stacks top to bottom inside the card with the view above the floor", function()
			local layout = FeaturedMath.SideLayout(context.main, context.side, context.facts)
			local boxes: { FeaturedMath.Box } = { layout.view, layout.tag, layout.name, layout.flavour }
			for _, fact in ipairs(layout.facts) do
				table.insert(boxes, fact)
			end
			local main, side = layout.main, layout.side
			if main then
				table.insert(boxes, main)
			end
			if side then
				table.insert(boxes, side)
			end
			expect(#layout.facts).toEqual(context.facts)
			expect(main ~= nil).toEqual(context.main)
			expect(side ~= nil).toEqual(context.side)
			local bottom = 0
			for index, box in ipairs(boxes) do
				assert(box.h > 0, "a box has no height")
				assert(box.y >= bottom - 0.00001, "box " .. index .. " overlaps the one above")
				bottom = box.y + box.h
			end
			assert(bottom <= 1 - Panels.Featured.Card.Pad + 0.0001, "the stack leaves the card")
			assert(layout.view.h >= Panels.Featured.Card.ViewMin, "the model view is squeezed to " .. layout.view.h)
		end)
	end
	it("at the narrowest side card the flavour box holds two lines and a fact box one at the 14 px floor", function()
		-- the card is 0.30 of a panel at least 620 wide and 330 tall at 1.35 (so at least 495 tall in practice): 0.509 of the panel's height.
		local cardPx = 0.509 * (620 / 1.35)
		local c = Panels.Featured.Card
		assert(c.Flavour * cardPx >= 2 * 14, "two 14 px lines need " .. 2 * 14 .. " px, the box is " .. c.Flavour * cardPx)
		assert(c.Fact * cardPx >= 14, "a 14 px fact line needs 14 px, the box is " .. c.Fact * cardPx)
	end)
end)

describe("Strip card layout", function()
	local function sePx(): number
		local w, h = panelPx(SE, ALIENS_ASPECT)
		return (Panels.Featured.Wide.W * w) / (Panels.Featured.Aliens.StripH * h)
	end
	it("keeps the plinth square at the iPhone SE strip", function()
		local aspect = sePx()
		local layout = FeaturedMath.StripLayout(aspect, true, false)
		expect(layout.plinth.w * aspect).toBeClose(layout.plinth.h, 0.0001)
	end)
	it("puts the plinth, the text column and the buttons side by side without overlap or leaving the strip", function()
		for _, buttons in ipairs({ { true, false }, { true, true }, { false, false } }) do
			local layout = FeaturedMath.StripLayout(sePx(), buttons[1], buttons[2])
			local plinthRight = layout.plinth.x + layout.plinth.w
			assert(layout.column.x >= plinthRight, "the column overlaps the plinth")
			local right = layout.column.x + layout.column.w
			local side, main = layout.side, layout.main
			if side then
				assert(side.x >= right - 0.00001, "the second button overlaps the column")
				right = side.x + side.w
			end
			if main then
				assert(main.x >= right - 0.00001, "the main button overlaps what is left of it")
				right = main.x + main.w
			end
			assert(right <= 1.0001, "the strip's contents leave it")
			assert(layout.column.w > 0.25, "the column is too narrow to read: " .. layout.column.w)
		end
	end)
	it("has no buttons for a card with none, so the column takes the room", function()
		local bare = FeaturedMath.StripLayout(sePx(), false, false)
		local full = FeaturedMath.StripLayout(sePx(), true, true)
		assert(bare.main == nil and bare.side == nil, "no buttons")
		assert(bare.column.w > full.column.w, "the column grows when the buttons go")
	end)
end)

return true
