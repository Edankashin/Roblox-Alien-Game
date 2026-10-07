--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.StorageMath)
local Data = require(Shared.data.Storage)
local Species = require(Shared.data.Species)
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
describe("StorageMath", function()
	it("IsFull holds from the cap and not a record below it", function()
		expect(Math.IsFull(Data.StorageCap - F.one)).toEqual(false)
		expect(Math.IsFull(Data.StorageCap)).toEqual(true)
		expect(Math.IsFull(Data.StorageCap + F.one)).toEqual(true)
		expect(Math.IsFull(F.zero)).toEqual(false)
	end)
	it("IsWarning starts at WarnFraction of the cap and a full store is a warning too", function()
		local first = Data.StorageCap * Data.WarnFraction
		expect(Math.IsWarning(first - F.one)).toEqual(false)
		expect(Math.IsWarning(first)).toEqual(true)
		expect(Math.IsWarning(Data.StorageCap)).toEqual(true)
		expect(Math.IsWarning(F.zero)).toEqual(false)
		expect(first > F.zero and first < Data.StorageCap).toEqual(true)
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
	it("the data keeps the cap above the warning line and one call inside the cap", function()
		expect(Data.StorageCap > F.zero).toEqual(true)
		expect(Data.WarnFraction > F.zero and Data.WarnFraction < F.one).toEqual(true)
		expect(Data.MaxReleasePerCall > F.zero and Data.MaxReleasePerCall <= Data.StorageCap).toEqual(true)
		expect(Data.ConfirmSeconds > F.zero and Data.HoldSeconds > F.zero and Data.HoldMovePixels > F.zero).toEqual(true)
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
