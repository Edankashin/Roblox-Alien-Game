--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.StorageMath)
local Data = require(Shared.data.Storage)
local Species = require(Shared.data.Species)
local Modules = require(Shared.data.Modules)
local Worlds = require(Shared.data.Worlds)
local Tiers = require(Shared.data.Tiers)
local Sizes = require(Shared.data.Sizes)
local F = require(script.Parent.Fixtures)
-- A plain record of the first species of a tier, with the uid the test names.
local function record(uid, tier)
	local speciesId = nil
	for _, def in ipairs(Species.List) do
		if def.tier == tier then
			speciesId = def.id
			break
		end
	end
	assert(speciesId ~= nil, "no species of tier " .. tier)
	return { uid = uid, species = speciesId, level = F.one, overlay = "None", caughtAt = F.zero, size = Sizes.Default, workedSeconds = F.zero }
end
local function mapOf(...)
	local map = {}
	for _, row in ipairs({ ... }) do
		map[row.uid] = row
	end
	return map
end
-- The storage the finished modules of one world add, and their ids, from the module and storage data.
local function worldBonus(worldId)
	local total = F.zero
	for _, def in ipairs(Modules.Worlds[worldId]) do
		total += Data.ModuleBonus[def.id]
	end
	return total
end
local function worldIds(worldId)
	local ids = {}
	for _, def in ipairs(Modules.Worlds[worldId]) do
		table.insert(ids, def.id)
	end
	return ids
end
-- Runs fn with Data.HardCap set to `value`, then restores it (the maths reads the data on every call).
local function withHardCap(value, fn)
	local saved = Data.HardCap
	Data.HardCap = value
	local ok, err = pcall(fn)
	Data.HardCap = saved
	if not ok then
		error(err, 0)
	end
end
-- A profile.modules map with the given module ids completed, one world table each.
local function modulesDone(byWorld)
	local out = {}
	for worldId, ids in pairs(byWorld) do
		out[tostring(worldId)] = {}
		for _, id in ipairs(ids) do
			out[tostring(worldId)][id] = { scrapPaid = F.zero, keyPaid = F.zero, progress = F.one, started = true, completedAt = F.tick, updatedAt = F.tick }
		end
	end
	return out
end
local worldOneLevels = F.zero
for _, level in ipairs(Data.Bay.Levels) do
	if level.world == F.one then
		worldOneLevels += F.one
	end
end
describe("StorageMath", function()
	it("IsFull holds from the cap and not a record below it", function()
		local cap = Data.BaseCap
		expect(Math.IsFull(cap - F.one, cap)).toEqual(false)
		expect(Math.IsFull(cap, cap)).toEqual(true)
		expect(Math.IsFull(cap + F.one, cap)).toEqual(true)
		expect(Math.IsFull(F.zero, cap)).toEqual(false)
	end)
	it("IsWarning starts at WarnFraction of the cap and a full store is a warning too", function()
		for _, cap in ipairs({ Data.BaseCap, Data.HardCap }) do
			local first = cap * Data.WarnFraction
			expect(Math.IsWarning(first - F.one, cap)).toEqual(false)
			expect(Math.IsWarning(first, cap)).toEqual(true)
			expect(Math.IsWarning(cap, cap)).toEqual(true)
			expect(Math.IsWarning(F.zero, cap)).toEqual(false)
			expect(first > F.zero and first < cap).toEqual(true)
		end
	end)
	it("a cap that grows moves the full and warning lines with it", function()
		local small, large = Data.BaseCap, Data.BaseCap + Data.Bay.PerLevel
		expect(Math.IsFull(small, small)).toEqual(true)
		expect(Math.IsFull(small, large)).toEqual(false)
		expect(Math.IsWarning(small, large)).toEqual(small / large >= Data.WarnFraction)
	end)
	it("ReleaseValue is the data row of every tier, rises with the tier and stays under the catch pay", function()
		local previous = F.zero
		for _, tier in ipairs(Tiers.Order) do
			expect(Math.ReleaseValue(tier)).toEqual(Data.ReleaseScrap[tier])
			expect(Math.ReleaseValue(tier) > F.zero).toEqual(true)
			expect(Math.ReleaseValue(tier) >= previous).toEqual(true)
			expect(Math.ReleaseValue(tier) < Tiers.Tiers[tier].catchScrap).toEqual(true)
			previous = Math.ReleaseValue(tier)
		end
		expect(Math.ReleaseValue("NotATier")).toEqual(F.zero)
	end)
	it("the bulk tiers are real tiers and IsBulkTier answers for them alone", function()
		for _, tier in ipairs(Data.BulkReleaseTiers) do
			expect(Tiers.Tiers[tier] ~= nil).toEqual(true)
			expect(Math.IsBulkTier(tier)).toEqual(true)
		end
		for _, tier in ipairs(Tiers.Order) do
			expect(Math.IsBulkTier(tier)).toEqual(table.find(Data.BulkReleaseTiers, tier) ~= nil)
		end
		expect(Math.IsBulkTier("NotATier")).toEqual(false)
	end)
	it("the data keeps the base under the hard cap, the warning line inside it and one call inside the hard cap", function()
		expect(Data.BaseCap > F.zero and Data.BaseCap <= Data.HardCap).toEqual(true)
		expect(Data.WarnFraction > F.zero and Data.WarnFraction < F.one).toEqual(true)
		expect(Data.MaxReleasePerCall > F.zero and Data.MaxReleasePerCall <= Data.HardCap).toEqual(true)
		expect(Data.ConfirmSeconds > F.zero and Data.HoldSeconds > F.zero and Data.HoldMovePixels > F.zero).toEqual(true)
		expect(Data.PassBonus > F.zero and Data.Bay.PerLevel > F.zero).toEqual(true)
	end)
	it("every ship module has a storage bonus and every bonus names a real module", function()
		local known = {}
		for _, defs in pairs(Modules.Worlds) do
			for _, def in ipairs(defs) do
				known[def.id] = true
				expect(type(Data.ModuleBonus[def.id])).toEqual("number")
				expect(Data.ModuleBonus[def.id] > F.zero).toEqual(true)
			end
		end
		for id in pairs(Data.ModuleBonus) do
			expect(known[id]).toEqual(true)
		end
	end)
	it("the Storage Bay levels rise in price, name a real world and never go back a world", function()
		expect(#Data.Bay.Levels > F.zero).toEqual(true)
		local price, world = F.zero, F.one
		for _, level in ipairs(Data.Bay.Levels) do
			expect(level.scrap > price).toEqual(true)
			expect(Worlds[level.world] ~= nil).toEqual(true)
			expect(level.world >= world).toEqual(true)
			price, world = level.scrap, level.world
		end
		expect(Data.Bay.Levels[F.one].world).toEqual(F.one) -- the first level opens in World 1
	end)
	it("the pass is a pass row of the shop and sells space, not Scrap", function()
		local Shop = require(Shared.data.Shop)
		local row = nil
		for _, item in ipairs(Shop.Items) do
			if item.id == Data.PassItem then
				row = item
			end
		end
		expect(row ~= nil).toEqual(true)
		expect(row.kind).toEqual("pass")
		expect(row.paidRandom).toEqual(false)
		local grants = Shop.Grants[Data.PassItem]
		expect(#grants).toEqual(F.one)
		expect(grants[F.one].kind).toEqual("passFlag")
	end)
	it("Parts of nothing is the base cap alone", function()
		local parts = Math.Parts({}, F.zero, false)
		expect(parts.base).toEqual(Data.BaseCap)
		expect(parts.modules).toEqual(F.zero)
		expect(parts.bay).toEqual(F.zero)
		expect(parts.pass).toEqual(F.zero)
		expect(parts.sum).toEqual(Data.BaseCap)
		expect(parts.cap).toEqual(Data.BaseCap)
		expect(Math.CapFor({}, F.zero, false)).toEqual(Data.BaseCap)
	end)
	it("CapFor adds each finished module's bonus, once", function()
		local first = Modules.Worlds[F.one][F.one].id
		expect(Math.CapFor({ first }, F.zero, false)).toEqual(Data.BaseCap + Data.ModuleBonus[first])
		expect(Math.CapFor({ first, first }, F.zero, false)).toEqual(Data.BaseCap + Data.ModuleBonus[first])
		expect(Math.CapFor({ "NotAModule" }, F.zero, false)).toEqual(Data.BaseCap)
		for worldId in pairs(Modules.Worlds) do
			expect(Math.CapFor(worldIds(worldId), F.zero, false)).toEqual(Data.BaseCap + worldBonus(worldId))
		end
		local both = {}
		for worldId in pairs(Modules.Worlds) do
			for _, id in ipairs(worldIds(worldId)) do
				table.insert(both, id)
			end
		end
		local total = Data.BaseCap
		for worldId in pairs(Modules.Worlds) do
			total += worldBonus(worldId)
		end
		expect(Math.CapFor(both, F.zero, false)).toEqual(total)
	end)
	it("CapFor adds the Storage Bay levels, and a level out of range counts as the nearest", function()
		for level = F.zero, #Data.Bay.Levels do
			expect(Math.CapFor({}, level, false)).toEqual(Data.BaseCap + level * Data.Bay.PerLevel)
		end
		local top = Data.BaseCap + #Data.Bay.Levels * Data.Bay.PerLevel
		expect(Math.CapFor({}, #Data.Bay.Levels + F.one, false)).toEqual(top)
		expect(Math.CapFor({}, math.huge, false)).toEqual(top)
		expect(Math.CapFor({}, -F.one, false)).toEqual(Data.BaseCap)
		expect(Math.CapFor({}, F.one + F.half, false)).toEqual(Data.BaseCap + Data.Bay.PerLevel)
		expect(Math.CapFor({}, F.zero / F.zero, false)).toEqual(Data.BaseCap)
	end)
	it("CapFor adds the pass, and the three parts stack", function()
		expect(Math.CapFor({}, F.zero, true)).toEqual(Data.BaseCap + Data.PassBonus)
		local ids = worldIds(F.one)
		local parts = Math.Parts(ids, F.two, true)
		expect(parts.modules).toEqual(worldBonus(F.one))
		expect(parts.bay).toEqual(F.two * Data.Bay.PerLevel)
		expect(parts.pass).toEqual(Data.PassBonus)
		expect(parts.sum).toEqual(Data.BaseCap + parts.modules + parts.bay + parts.pass)
		expect(parts.cap).toEqual(parts.sum)
		expect(Math.CapFor(ids, F.two, true)).toEqual(parts.cap)
	end)
	it("CapFor never passes the hard cap, whatever the sum", function()
		local ids = worldIds(F.one)
		withHardCap(Data.BaseCap + F.one, function()
			local parts = Math.Parts(ids, #Data.Bay.Levels, true)
			expect(parts.sum > Data.HardCap).toEqual(true)
			expect(parts.cap).toEqual(Data.HardCap)
			expect(Math.CapFor(ids, #Data.Bay.Levels, true)).toEqual(Data.HardCap)
			expect(Math.CapFor({}, F.zero, false)).toEqual(Data.BaseCap) -- under the ceiling the base is untouched
		end)
		expect(Math.CapFor(ids, #Data.Bay.Levels, true) <= Data.HardCap).toEqual(true)
	end)
	it("CompletedIds lists the finished modules of every world in order and skips the unfinished", function()
		local oneIds, twoIds = worldIds(F.one), worldIds(F.two)
		local modules = modulesDone({ [F.one] = { oneIds[F.one], oneIds[F.two] }, [F.two] = { twoIds[F.one] } })
		modules[tostring(F.one)][oneIds[F.two + F.one]] = { scrapPaid = F.zero, keyPaid = F.zero, progress = F.half, started = true, completedAt = nil, updatedAt = F.tick }
		local expected = { oneIds[F.one], oneIds[F.two], twoIds[F.one] }
		table.sort(expected)
		local ids = Math.CompletedIds(modules)
		expect(#ids).toEqual(#expected)
		for index, id in ipairs(expected) do
			expect(ids[index]).toEqual(id)
		end
		expect(#Math.CompletedIds({})).toEqual(F.zero)
		expect(Math.CapFor(ids, F.zero, false)).toEqual(Data.BaseCap + Data.ModuleBonus[oneIds[F.one]] + Data.ModuleBonus[oneIds[F.two]] + Data.ModuleBonus[twoIds[F.one]])
	end)
	it("NextBayLevel offers the next row while its world is unlocked", function()
		local row, reason = Math.NextBayLevel(F.zero, { F.one })
		expect(row).toEqual(Data.Bay.Levels[F.one])
		expect(reason).toEqual(nil)
		local last, lastReason = Math.NextBayLevel(worldOneLevels - F.one, { F.one })
		expect(last).toEqual(Data.Bay.Levels[worldOneLevels])
		expect(lastReason).toEqual(nil)
		local below, belowReason = Math.NextBayLevel(-F.one, { F.one })
		expect(below).toEqual(Data.Bay.Levels[F.one])
		expect(belowReason).toEqual(nil)
	end)
	it("NextBayLevel waits for the row's world, and names the row", function()
		local row, reason = Math.NextBayLevel(worldOneLevels, { F.one })
		expect(row).toEqual(Data.Bay.Levels[worldOneLevels + F.one])
		expect(reason).toEqual("NeedsWorld")
		expect(row.world > F.one).toEqual(true)
		local open, openReason = Math.NextBayLevel(worldOneLevels, { F.one, row.world })
		expect(open).toEqual(row)
		expect(openReason).toEqual(nil)
		local none, noneReason = Math.NextBayLevel(F.zero, {})
		expect(none).toEqual(Data.Bay.Levels[F.one])
		expect(noneReason).toEqual("NeedsWorld")
	end)
	it("NextBayLevel says Max once every level is bought", function()
		local everyWorld = {}
		for worldId in pairs(Worlds) do
			table.insert(everyWorld, worldId)
		end
		for _, bought in ipairs({ #Data.Bay.Levels, #Data.Bay.Levels + F.one, math.huge }) do
			local row, reason = Math.NextBayLevel(bought, everyWorld)
			expect(row).toEqual(nil)
			expect(reason).toEqual("Max")
		end
		local row = Math.NextBayLevel(#Data.Bay.Levels - F.one, everyWorld)
		expect(row).toEqual(Data.Bay.Levels[#Data.Bay.Levels])
	end)
	it("CountOf counts the records of a map", function()
		expect(Math.CountOf({})).toEqual(F.zero)
		expect(Math.CountOf(mapOf(record("a", "Common"), record("b", "Rare")))).toEqual(F.two)
	end)
	it("InUse names the seat, the follower and the display, and frees a resting record", function()
		local free = record("free", "Common")
		expect(Math.InUse(free, {})).toEqual(nil)
		local seated = record("seated", "Common")
		seated.station = "Gather"
		expect(Math.InUse(seated, {})).toEqual("Seated")
		local follower = record("follower", "Common")
		expect(Math.InUse(follower, { "other", "follower" })).toEqual("Following")
		expect(Math.InUse(follower, { "other" })).toEqual(nil)
		local shown = record("shown", "Common")
		shown.habitat = "habitat-uid"
		expect(Math.InUse(shown, {})).toEqual("Displayed")
	end)
	it("Releasable lists the free records of one tier in uid order and sums their value", function()
		local seated = record("c-seated", "Common")
		seated.station = "Gather"
		local shown = record("c-shown", "Common")
		shown.habitat = "habitat-uid"
		local aliens = mapOf(
			record("c-b", "Common"), record("c-a", "Common"), record("c-follow", "Common"), seated, shown,
			record("u-a", "Uncommon"), record("r-a", "Rare")
		)
		local uids, scrap = Math.Releasable(aliens, { "c-follow" }, "Common")
		expect(#uids).toEqual(F.two)
		expect(uids[F.one]).toEqual("c-a")
		expect(uids[F.two]).toEqual("c-b")
		expect(scrap).toEqual(F.two * Data.ReleaseScrap.Common)
		local uncommon, uncommonScrap = Math.Releasable(aliens, {}, "Uncommon")
		expect(#uncommon).toEqual(F.one)
		expect(uncommonScrap).toEqual(Data.ReleaseScrap.Uncommon)
		local none, noneScrap = Math.Releasable(aliens, {}, "Legendary")
		expect(#none).toEqual(F.zero)
		expect(noneScrap).toEqual(F.zero)
	end)
end)
return true
