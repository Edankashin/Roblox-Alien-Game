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
describe("RevealMath ladder (B46: rarer is far more exclusive)", function()
	local NUMBERS_UP = { "Pop", "Sparkles", "SparkleBursts", "Starburst", "HoldExtra" }
	local FLAGS_UP = { "GoldFrame", "Sky", "SpellName" }
	it("every tier has a rung, and no column ever drops from one tier to the next", function()
		local previous: RevealMath.LadderRow? = nil
		for _, tier in ipairs(Tiers.Order) do
			local rung = RevealData.Ladder[tier]
			assert(rung ~= nil, tier .. " has no rung")
			local before = previous
			if before then
				for _, key in ipairs(NUMBERS_UP) do
					assert((rung :: any)[key] >= (before :: any)[key], tier .. "." .. key .. " drops")
				end
				for _, key in ipairs(FLAGS_UP) do
					assert(not (before :: any)[key] or (rung :: any)[key], tier .. "." .. key .. " drops")
				end
				assert(rung.Wash <= before.Wash, tier .. ".Wash gets fainter")
				assert(rung.TurnScale <= before.TurnScale, tier .. ".TurnScale speeds up")
			end
			assert((rung.RayCells > 0) == RevealMath.Flags(tier).Rays, tier .. ": ray cells exactly where the tier has rays")
			previous = rung
		end
	end)
	it("climbs steeply: a Cosmic reveal draws five times a Common's effects or more, and every rung draws more than the last", function()
		local common = RevealMath.EffectFrames("Common")
		expect(RevealMath.EffectFrames("Cosmic") >= 5 * common).toEqual(true)
		expect(RevealMath.EffectFrames("Secret") >= 5 * common).toEqual(true)
		local previous = 0
		for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic" }) do
			local frames = RevealMath.EffectFrames(tier)
			assert(frames > previous, tier .. " draws no more than the tier below")
			previous = frames
		end
	end)
	it("keeps the Cosmic peak under 320 effect frames (the frame-rate check is Overnight job 38)", function()
		for _, tier in ipairs(Tiers.Order) do
			assert(RevealMath.EffectFrames(tier) <= 320, tier .. " draws " .. RevealMath.EffectFrames(tier) .. " effect frames")
		end
	end)
	it("the hold grows by the tier's HoldExtra, and Total carries it", function()
		expect(RevealMath.HoldSeconds("Common")).toBeClose(RevealData.HoldSeconds, 1e-9)
		expect(RevealMath.HoldSeconds("Cosmic")).toBeClose(RevealData.HoldSeconds + RevealData.Ladder.Cosmic.HoldExtra, 1e-9)
		local cosmic = RevealMath.CrackSeconds() + RevealMath.ShardBeatSeconds("Cosmic") + RevealData.CardDropSeconds + RevealMath.HoldSeconds("Cosmic")
		expect(RevealMath.Total("Cosmic", true)).toBeClose(cosmic, 1e-9)
	end)
	it("spells a name a letter a step, and the top tiers' names are in before the buttons", function()
		expect(RevealMath.SpellSeconds("Zorp")).toBeClose(4 * RevealData.SpellSecondsPerLetter, 1e-9)
		expect(RevealMath.SpellSeconds("")).toEqual(0)
		for _, tier in ipairs(Tiers.Order) do
			if RevealMath.Ladder(tier).SpellName then
				local window = RevealData.ButtonDelaySeconds + RevealMath.Ladder(tier).HoldExtra
				assert(RevealMath.SpellSeconds("Abcdefghijklmn") <= window, tier .. ": a 14-letter name is still spelling when the buttons come")
			end
		end
	end)
	it("an unknown tier reads as Common", function()
		expect(RevealMath.Ladder("Mythic")).toEqual(RevealData.Ladder.Common)
	end)
end)

describe("RevealMath pixel egg", function()
	it("rings the egg's colour with ink exactly one pixel thick, inside the grid", function()
		local ink, fill = RevealMath.EggBars()
		local cols, rows = RevealData.EggCols, RevealData.EggRows
		expect(cols / rows).toBeClose(RevealData.EggAspect, 1e-9)
		local function cover(bars: { RevealMath.Bar }): { [number]: boolean }
			local out: { [number]: boolean } = {}
			for _, bar in ipairs(bars) do
				assert(bar.x >= 0 and bar.y >= 0 and bar.x + bar.w <= cols and bar.y + bar.h <= rows, "a bar leaves the grid")
				for y = bar.y, bar.y + bar.h - 1 do
					for x = bar.x, bar.x + bar.w - 1 do
						out[y * cols + x] = true
					end
				end
			end
			return out
		end
		local inked, filled = cover(ink), cover(fill)
		for y = 0, rows - 1 do
			for x = 0, cols - 1 do
				local near = false
				for dy = -1, 1 do
					for dx = -1, 1 do
						local nx, ny = x + dx, y + dy
						if nx >= 0 and ny >= 0 and nx < cols and ny < rows and filled[ny * cols + nx] then
							near = true
						end
					end
				end
				assert((inked[y * cols + x] == true) == near, "pixel " .. x .. "," .. y .. " is ink " .. tostring(inked[y * cols + x]))
			end
		end
	end)
	it("lights its top rows and shades its bottom rows of colour", function()
		local _, _, lit, shade = RevealMath.EggBars()
		local litRows, shadeRows = 0, 0
		for _, bar in ipairs(lit) do
			litRows += bar.h
		end
		for _, bar in ipairs(shade) do
			shadeRows += bar.h
		end
		expect(litRows).toEqual(RevealData.EggLitRows)
		expect(shadeRows).toEqual(RevealData.EggShadeRows)
	end)
	it("draws each tap's crack as a few pixels inside the egg's colour", function()
		for tap = 1, RevealData.CrackTaps do
			local cells = RevealMath.CrackCells(tap)
			assert(#cells >= 3 and #cells <= 24, "tap " .. tap .. " cracks " .. #cells .. " pixels")
		end
	end)
end)

return true
