--!strict
-- The Reveal's three beats, the pure half (Shared/RevealMath) and the data it reads (data/Reveal): the lengths and the Rare
-- band, the per-tier scaling, the crack beat's feel, and the chance line (the numbers, and every case that must hide it).
-- The colours a tier flag names cannot be checked against Theme here (no Color3 in this sandbox); tools/lint_data.py does that.
local Shared = game:GetService("ReplicatedStorage").Shared
local RevealMath = require(Shared.RevealMath)
local RevealData = require(Shared.data.Reveal)
local Tiers = require(Shared.data.Tiers)
local EggMath = require(Shared.EggMath)

local function sum(parts: { number }): number
	local total = 0
	for _, part in ipairs(parts) do
		total += part
	end
	return total
end

describe("RevealMath lengths", function()
	it("the Rare egg total is the five authored parts and lands in its band", function()
		local expected = sum({
			RevealData.CrackTaps * RevealData.CrackSecondsPerTap,
			RevealData.ShardSeconds,
			RevealData.RaySpinSeconds,
			RevealData.CardDropSeconds,
			RevealData.HoldSeconds,
		})
		expect(RevealMath.Total("Rare", true)).toBeClose(expected, 1e-9)
		expect(RevealMath.Total("Rare", true) >= RevealData.TotalMinSeconds).toEqual(true)
		expect(RevealMath.Total("Rare", true) <= RevealData.TotalMaxSeconds).toEqual(true)
	end)
	it("a wild catch skips the crack beat unless the data gives it a capsule", function()
		expect(RevealMath.PlansCrack(true)).toEqual(true)
		expect(RevealMath.PlansCrack(false)).toEqual(RevealData.CatchCrack)
		expect(RevealMath.Total("Rare", false)).toBeClose(RevealMath.Total("Rare", true) - RevealMath.CrackSeconds(), 1e-9)
	end)
	it("a tier with neither rays nor an iris spends no ray spin", function()
		expect(RevealMath.ShardBeatSeconds("Common")).toBeClose(RevealData.ShardSeconds, 1e-9)
		expect(RevealMath.ShardBeatSeconds("Uncommon")).toBeClose(RevealData.ShardSeconds, 1e-9)
		expect(RevealMath.ShardBeatSeconds("Rare")).toBeClose(RevealData.ShardSeconds + RevealData.RaySpinSeconds, 1e-9)
	end)
	it("the secret iris spends the ray spin like rays do", function()
		local scale = RevealData.LegendaryShardScale
		expect(RevealMath.ShardBeatSeconds("Secret")).toBeClose((RevealData.ShardSeconds + RevealData.RaySpinSeconds) * scale, 1e-9)
	end)
	it("no tier makes the player wait more than five seconds, and a bigger tier never plays shorter", function()
		local previous = 0
		for _, tier in ipairs(Tiers.Order) do
			local total = RevealMath.Total(tier, true)
			expect(total <= 5).toEqual(true)
			expect(total >= previous).toEqual(true)
			previous = total
		end
	end)
	it("the quiet moment is the sequence plus the calm after it, and Reduced Motion is the still frame plus the calm", function()
		expect(RevealMath.QuietTotal("Epic", true, false)).toBeClose(RevealMath.Total("Epic", true) + RevealData.QuietSeconds, 1e-9)
		expect(RevealMath.QuietTotal("Epic", false, false)).toBeClose(RevealMath.Total("Epic", false) + RevealData.QuietSeconds, 1e-9)
		expect(RevealMath.QuietTotal("Epic", true, true)).toBeClose(RevealData.ReducedMotionSeconds + RevealData.QuietSeconds, 1e-9)
	end)
	it("the card's entrance fits inside the hold", function()
		expect(RevealData.OddsDelaySeconds <= RevealData.ChipDelaySeconds).toEqual(true)
		expect(RevealData.ChipDelaySeconds <= RevealData.ButtonDelaySeconds).toEqual(true)
		expect(RevealData.ButtonDelaySeconds + RevealData.ButtonSlideSeconds <= RevealData.HoldSeconds).toEqual(true)
	end)
end)

describe("RevealMath per-tier scaling", function()
	it("Legendary and above scale the shard beat by LegendaryShardScale, the rest by 1", function()
		expect(RevealMath.ShardScale("Common")).toEqual(1)
		expect(RevealMath.ShardScale("Uncommon")).toEqual(1)
		expect(RevealMath.ShardScale("Rare")).toEqual(1)
		expect(RevealMath.ShardScale("Epic")).toEqual(1)
		expect(RevealMath.ShardScale("Legendary")).toEqual(RevealData.LegendaryShardScale)
		expect(RevealMath.ShardScale("Cosmic")).toEqual(RevealData.LegendaryShardScale)
		expect(RevealMath.ShardScale("Secret")).toEqual(RevealData.LegendaryShardScale)
	end)
	it("an unknown tier reads as Common", function()
		expect(RevealMath.ShardScale("Mythic")).toEqual(1)
		expect(RevealMath.Flags("Mythic").Rays).toEqual(false)
	end)
	it("confetti starts at Epic and is scaled with the beat", function()
		expect(RevealMath.ConfettiCount("Rare")).toEqual(0)
		expect(RevealMath.ConfettiCount("Epic")).toEqual(RevealData.ConfettiCount)
		expect(RevealMath.ConfettiCount("Legendary")).toEqual(math.floor(RevealData.ConfettiCount * RevealData.LegendaryShardScale + 0.5))
	end)
	it("every tier of the ladder has its flags, consistent with the ladder", function()
		for index, tier in ipairs(Tiers.Order) do
			local flags = RevealData.Tiers[tier]
			expect(flags ~= nil).toEqual(true)
			expect(flags.Grand).toEqual(index >= (table.find(Tiers.Order, "Legendary") :: number))
			expect(flags.GroundRing).toEqual(flags.Grand)
			expect(flags.Iris).toEqual(tier == "Secret")
			expect(flags.Rays and flags.Iris).toEqual(false)
			expect(flags.Confetti).toEqual(index >= (table.find(Tiers.Order, "Epic") :: number))
			expect(flags.Rays).toEqual(index >= (table.find(Tiers.Order, "Rare") :: number) and not flags.Iris)
		end
		expect(RevealData.Tiers.Cosmic.SecondRayColor ~= nil).toEqual(true)
		expect(RevealData.Tiers.Legendary.SecondRayColor == nil).toEqual(true)
		expect(RevealData.Tiers.Secret.DimExtra > 0).toEqual(true)
	end)
end)

describe("RevealMath crack beat", function()
	it("the glow leaks more with every tap, from its start to its end", function()
		expect(RevealMath.GlowTransparency(0)).toBeClose(RevealData.GlowTransparencyStart, 1e-9)
		expect(RevealMath.GlowTransparency(RevealData.CrackTaps)).toBeClose(RevealData.GlowTransparencyEnd, 1e-9)
		expect(RevealMath.GlowTransparency(99)).toBeClose(RevealData.GlowTransparencyEnd, 1e-9)
		for tap = 1, RevealData.CrackTaps do
			expect(RevealMath.GlowTransparency(tap) < RevealMath.GlowTransparency(tap - 1)).toEqual(true)
		end
	end)
	it("each tap wobbles harder than the last", function()
		expect(RevealMath.WobbleDegrees(1)).toBeClose(RevealData.WobbleStartDegrees, 1e-9)
		expect(RevealMath.WobbleDegrees(RevealData.CrackTaps)).toBeClose(RevealData.WobbleEndDegrees, 1e-9)
		for tap = 2, RevealData.CrackTaps do
			expect(RevealMath.WobbleDegrees(tap) > RevealMath.WobbleDegrees(tap - 1)).toEqual(true)
		end
	end)
	it("a tap draws its own crack line, and a tap past the last row wraps", function()
		local rows = #RevealData.CrackLines
		expect(RevealMath.CrackLine(1)).toEqual(RevealData.CrackLines[1])
		expect(RevealMath.CrackLine(rows)).toEqual(RevealData.CrackLines[rows])
		expect(RevealMath.CrackLine(rows + 1)).toEqual(RevealData.CrackLines[1])
		expect(RevealMath.CrackLine(0)).toEqual(RevealData.CrackLines[1])
	end)
	it("a size in px at the reference height is its share of that height", function()
		expect(RevealMath.PxToScale(RevealData.ReferenceHeight)).toEqual(1)
		expect(RevealMath.PxToScale(52)).toBeClose(52 / 375, 1e-9)
		expect(RevealMath.PxToScale(RevealData.ButtonHeightPx) * RevealData.ReferenceHeight >= 44).toEqual(true)
	end)
end)

describe("RevealMath chance line", function()
	it("prints 1 in N and the percent for a chance", function()
		expect(RevealMath.OddsLine(6)).toEqual("1 in 17 · 6% chance")
		expect(RevealMath.OddsLine(50)).toEqual("1 in 2 · 50% chance")
		expect(RevealMath.OddsLine(1.5)).toEqual("1 in 67 · 1.5% chance")
		expect(RevealMath.OddsLine(12.5)).toEqual("1 in 8 · 12.5% chance")
		expect(RevealMath.OddsLine(100 / 3)).toEqual("1 in 3 · 33.3% chance")
		expect(RevealMath.OddsLine(0.25)).toEqual("1 in 400 · 0.25% chance")
	end)
	it("groups thousands", function()
		expect(RevealMath.OddsLine(0.05)).toEqual("1 in 2,000 · 0.05% chance")
	end)
	it("keeps N at 2 or more for a likely chance", function()
		expect(RevealMath.OddsLine(80)).toEqual("1 in 2 · 80% chance")
	end)
	it("hides the line where there is no honest number", function()
		expect(RevealMath.OddsLine(nil) == nil).toEqual(true)
		expect(RevealMath.OddsLine(0) == nil).toEqual(true)
		expect(RevealMath.OddsLine(-5) == nil).toEqual(true)
		expect(RevealMath.OddsLine(100) == nil).toEqual(true)
		expect(RevealMath.OddsLine(250) == nil).toEqual(true)
		expect(RevealMath.OddsLine(0.001) == nil).toEqual(true)
		expect(RevealMath.OddsLine(0 / 0) == nil).toEqual(true)
	end)
	it("a wild catch reads the tier's spawn share; a tier with none shows nothing", function()
		expect(RevealMath.SpawnPercent("Common")).toEqual(Tiers.Tiers.Common.share)
		expect(RevealMath.SpawnPercent("Epic")).toEqual(6)
		expect(RevealMath.SpawnPercent("Legendary")).toEqual(1.5)
		expect(RevealMath.SpawnPercent("Cosmic") == nil).toEqual(true)
		expect(RevealMath.SpawnPercent("Secret") == nil).toEqual(true)
		expect(RevealMath.SpawnPercent("Mythic") == nil).toEqual(true)
		expect(RevealMath.OddsLine(RevealMath.SpawnPercent("Epic"))).toEqual("1 in 17 · 6% chance")
		expect(RevealMath.OddsLine(RevealMath.SpawnPercent("Cosmic")) == nil).toEqual(true)
	end)
	it("an egg's chance is 100 over its pool, and an empty pool has none", function()
		expect(EggMath.Percent(5)).toEqual(20)
		expect(EggMath.Percent(1)).toEqual(100)
		expect(EggMath.Percent(0) == nil).toEqual(true)
		expect(RevealMath.OddsLine(EggMath.Percent(5))).toEqual("1 in 5 · 20% chance")
		expect(RevealMath.OddsLine(EggMath.Percent(1)) == nil).toEqual(true)
		expect(RevealMath.OddsLine(EggMath.Percent(0)) == nil).toEqual(true)
	end)
end)
return true
