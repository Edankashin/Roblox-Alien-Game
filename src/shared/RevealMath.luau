--!strict
-- ReplicatedStorage.Shared.RevealMath: the pure half of the Reveal's three beats (UI/Reveal.luau), shared so the client and the
-- headless tests agree. Everything it reads is data/Reveal and data/Tiers; nothing here touches an instance or a clock.
--   * the lengths: the crack beat, the shard beat of a tier (scaled for Legendary and above), the whole sequence, and the
--     quiet moment the Toast queue is given for it (Toast.QuietFor);
--   * the per-tier scaling: how many times as long and as big a tier's shard beat is, and how many confetti pieces it throws;
--   * the crack beat's feel: the glow behind the egg and the wobble of each tap, the crack line a tap draws;
--   * the chance line: "1 in N · x% chance" from a percent, and nil (hide the line) whenever there is no honest number.
-- The percent comes from the server's egg draw (GrantResult.oddsPercent, EggMath.Percent) or, for a wild catch, from the
-- tier's spawn share in data/Tiers (SpawnPercent); this module never makes a number up.

local RevealData = require(script.Parent.data.Reveal)
local Tiers = require(script.Parent.data.Tiers)
local Strings = require(script.Parent.strings.en)

local RevealMath = {}

export type Flags = RevealData.TierFlags

local FALLBACK_TIER = "Common"
local MIN_ONE_IN = 2 -- "1 in 1" says nothing: the smallest N printed
local MIN_PERCENT = 0.01 -- under this the line is hidden rather than printed as 0

-- The flags of a tier (an unknown tier reads as Common, so a new tier never crashes the Reveal).
function RevealMath.Flags(tier: string): Flags
	return RevealData.Tiers[tier] or RevealData.Tiers[FALLBACK_TIER]
end

-- How many times as long (and as big) the tier's shard beat is: LegendaryShardScale from Legendary up, else 1.
function RevealMath.ShardScale(tier: string): number
	return if RevealMath.Flags(tier).Grand then RevealData.LegendaryShardScale else 1
end

-- Whether a reveal runs beat 1: every egg does, a wild catch only when the data says it has a capsule to crack.
function RevealMath.PlansCrack(fromEgg: boolean): boolean
	return fromEgg or RevealData.CatchCrack
end

-- Beat 1 as authored: CrackTaps taps of CrackSecondsPerTap each.
function RevealMath.CrackSeconds(): number
	return RevealData.CrackTaps * RevealData.CrackSecondsPerTap
end

-- Beat 2 as authored: the shards, then the rays spin up (a tier with Rays) or the iris opens (Secret); a tier with neither
-- ends with the shards. Times the tier's shard scale.
function RevealMath.ShardBeatSeconds(tier: string): number
	local flags = RevealMath.Flags(tier)
	local seconds = RevealData.ShardSeconds
	if flags.Rays or flags.Iris then
		seconds += RevealData.RaySpinSeconds
	end
	return seconds * RevealMath.ShardScale(tier)
end

-- The whole sequence for a tier, to the moment the buttons are up: beat 1 (when it runs), beat 2, the card's drop and its hold.
function RevealMath.Total(tier: string, withCrack: boolean): number
	local crack = if withCrack then RevealMath.CrackSeconds() else 0
	return crack + RevealMath.ShardBeatSeconds(tier) + RevealData.CardDropSeconds + RevealData.HoldSeconds
end

-- The quiet moment Toast.QuietFor is asked for: the sequence (the still frame under Reduced Motion) and the calm after it.
function RevealMath.QuietTotal(tier: string, withCrack: boolean, reduced: boolean): number
	local sequence = if reduced then RevealData.ReducedMotionSeconds else RevealMath.Total(tier, withCrack)
	return sequence + RevealData.QuietSeconds
end

-- The confetti pieces the burst throws: none for a tier without Confetti, else ConfettiCount times the shard scale, whole.
function RevealMath.ConfettiCount(tier: string): number
	if not RevealMath.Flags(tier).Confetti then
		return 0
	end
	return math.floor(RevealData.ConfettiCount * RevealMath.ShardScale(tier) + 0.5)
end

-- Taps made, as a share of CrackTaps, from 0 to 1.
local function tapShare(taps: number): number
	return math.clamp(taps / math.max(1, RevealData.CrackTaps), 0, 1)
end

-- The transparency of the tier-colour glow behind the egg after `taps` taps: GlowTransparencyStart with none, End with all.
function RevealMath.GlowTransparency(taps: number): number
	local share = tapShare(taps)
	return RevealData.GlowTransparencyStart + (RevealData.GlowTransparencyEnd - RevealData.GlowTransparencyStart) * share
end

-- The wobble of tap number `tap` (1 to CrackTaps), in degrees: WobbleStartDegrees on the first tap, harder to
-- WobbleEndDegrees on the last.
function RevealMath.WobbleDegrees(tap: number): number
	local share = if RevealData.CrackTaps <= 1 then 1 else math.clamp((tap - 1) / (RevealData.CrackTaps - 1), 0, 1)
	return RevealData.WobbleStartDegrees + (RevealData.WobbleEndDegrees - RevealData.WobbleStartDegrees) * share
end

-- The crack line tap number `tap` draws: row `tap` of CrackLines, wrapping round when there are more taps than rows.
function RevealMath.CrackLine(tap: number): { { number } }
	local rows = RevealData.CrackLines
	return rows[(math.max(1, tap) - 1) % #rows + 1]
end

-- A size in px at the reference height as a Scale of the screen's height.
function RevealMath.PxToScale(px: number): number
	return px / RevealData.ReferenceHeight
end

-- The share of wild spawns that are this tier, in percent (data/Tiers share), or nil where the table has none: Cosmic and
-- Secret have no wild share of their own (a shower or a quest brings them), so a catch of one shows no chance line.
function RevealMath.SpawnPercent(tier: string): number?
	local row = Tiers.Tiers[tier]
	if row == nil or row.share <= 0 then
		return nil
	end
	return row.share
end

-- 1234 -> "1,234".
local function grouped(n: number): string
	local text = tostring(math.floor(n + 0.5))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

-- A percent with one decimal from 1 up and two below, trailing zeros trimmed: 6 -> "6", 12.5 -> "12.5", 0.25 -> "0.25".
local function percentText(percent: number): string
	local text = string.format(if percent >= 1 then "%.1f" else "%.2f", percent)
	if text:find(".", 1, true) then
		text = text:gsub("0+$", "")
		if text:sub(-1) == "." then
			text = text:sub(1, -2)
		end
	end
	return text
end

-- The two numbers of the chance line from a percent chance: N of "1 in N" (100 over the percent, rounded, at least 2, with
-- thousands commas) and the percent text. nil, nil where there is no number worth printing: no percent, not a number,
-- zero or less, under MIN_PERCENT, or 100 and over (a certainty is no chance).
function RevealMath.OddsParts(percent: number?): (string?, string?)
	if percent == nil or percent ~= percent or percent < MIN_PERCENT or percent >= 100 then
		return nil, nil
	end
	local oneIn = math.max(MIN_ONE_IN, math.floor(100 / percent + 0.5))
	return grouped(oneIn), percentText(percent)
end

-- "1 in 17 · 6% chance" for a 6 percent chance; nil (hide the line, never invent one) where OddsParts has no numbers.
function RevealMath.OddsLine(percent: number?): string?
	local oneIn, text = RevealMath.OddsParts(percent)
	if oneIn == nil or text == nil then
		return nil
	end
	return Strings.REVEAL_ODDS:format(oneIn, text)
end

return RevealMath
