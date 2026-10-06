--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Economy = require(Shared.Economy)
local Config = require(Shared.data.Config)
local Species = require(Shared.data.Species)
local Tiers = require(Shared.data.Tiers)
local Growth = require(Shared.data.Growth)
local Sizes = require(Shared.data.Sizes)
local Overlays = require(Shared.data.Overlays)
local Jobs = require(Shared.data.Jobs)
local F = require(script.Parent.Fixtures)
local species = Species.ById.Mossbop
local record = {
	uid = species.id, species = species.id, level = F.one, overlay = "None",
	caughtAt = F.zero, size = Sizes.Default, workedSeconds = Growth.ById.Hatchling.workedSeconds,
}
local speed = Tiers.Tiers.Common.workSpeed * Overlays.Overlays.None.multiplier
local profile = { aliens = { [record.uid] = record }, stations = {} }
for _, job in ipairs(Jobs.Order) do
	profile.stations[job] = { assigned = {} }
end
profile.stations[species.jobs[F.one].job].assigned = { record.uid }
describe("Economy", function()
	it("Common level one has base work speed", function()
		expect(Economy.workSpeed(record)).toEqual(speed)
	end)
	it("Grown speed includes the data bonus", function()
		local grown = table.clone(record)
		grown.workedSeconds = Growth.ById.Grown.workedSeconds
		expect(Economy.workSpeed(grown)).toBeClose(speed * (F.one + Growth.ById.Grown.speedBonus), F.tolerance)
	end)
	for name, elapsed in pairs({ negative = -F.tick, zero = F.zero, below = Config.OfflineCapSeconds - F.tick, cap = Config.OfflineCapSeconds, beyond = Config.OfflineCapSeconds + Config.GiftDaySeconds }) do
		it("offlineScrap " .. name, function()
			local counted = math.clamp(elapsed, F.zero, Config.OfflineCapSeconds)
			expect(Economy.offlineScrap(profile, elapsed)).toEqual(math.floor(Config.BaseScrapPerSecond * speed * Config.OfflineRate * counted))
		end)
	end
end)
return true
