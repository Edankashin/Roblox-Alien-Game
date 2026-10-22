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
export type LadderRow = RevealData.LadderRow
export type Bar = { x: number, y: number, w: number, h: number } -- a rectangle on the pixel egg's grid, in pixels

local FALLBACK_TIER = "Common"
local MIN_ONE_IN = 2 -- "1 in 1" says nothing: the smallest N printed
local MIN_PERCENT = 0.01 -- under this the line is hidden rather than printed as 0

-- The flags of a tier (an unknown tier reads as Common, so a new tier never crashes the Reveal).
function RevealMath.Flags(tier: string): Flags
	return RevealData.Tiers[tier] or RevealData.Tiers[FALLBACK_TIER]
end

-- A tier's rung of the intensity ladder (data/Reveal Ladder); an unknown tier reads as Common.
function RevealMath.Ladder(tier: string): LadderRow
	return RevealData.Ladder[tier] or RevealData.Ladder[FALLBACK_TIER]
end

-- The card's hold for a tier: HoldSeconds plus the tier's HoldExtra (the top tiers hold the moment longer).
function RevealMath.HoldSeconds(tier: string): number
	return RevealData.HoldSeconds + RevealMath.Ladder(tier).HoldExtra
end

-- How many frames a tier's show adds at its peak, over the card's own: the sparkle cells of every burst, the starburst's cells,
-- the ray ring's cells (RayCount bars through the middle, a ray each side), the wash, the gold frame, the sky's bands and stars,
-- the confetti and the spelling cursor. The UI Playbook's frame budget for the Reveal counts with it.
function RevealMath.EffectFrames(tier: string): number
	local rung = RevealMath.Ladder(tier)
	local flags = RevealMath.Flags(tier)
	local frames = rung.Sparkles * rung.SparkleBursts + rung.Starburst * RevealData.StarburstCells
	if flags.Rays then
		frames += RevealData.RayCount * 2 * rung.RayCells
	end
	if rung.Wash < 1 then
		frames += 1
	end
	if rung.GoldFrame then
		frames += RevealData.GoldFrameCells
	end
	if rung.Sky then
		frames += RevealData.SkyBands + RevealData.SkyStars
	end
	if rung.SpellName then
		frames += 1
	end
	return frames + RevealMath.ConfettiCount(tier)
end

-- How long the name takes to spell in: a letter a step (utf8 letters, so an accent counts once).
function RevealMath.SpellSeconds(name: string): number
	local letters = utf8.len(name) or #name
	return letters * RevealData.SpellSecondsPerLetter
end

-- Rows of a grid as rectangles: runs of rows with the same span merged into one bar. `spans` maps a row to { left, width }.
local function rowBars(spans: { [number]: { number } }, rows: number): { Bar }
	local out: { Bar } = {}
	local open: Bar? = nil
	for row = 0, rows - 1 do
		local span = spans[row]
		if span and open and open.x == span[1] and open.w == span[2] and open.y + open.h == row then
			open.h += 1
		elseif span then
			open = { x = span[1], y = row, w = span[2], h = 1 }
			table.insert(out, open :: Bar)
		else
			open = nil
		end
	end
	return out
end

-- The pixel egg as bars on its EggCols by EggRows grid: the ink (the colour grown by one pixel all round, so the ink is one
-- pixel thick round every step, the way the stepped pixel octagon's is) and the colour, each row run merged down; then the lit
-- top rows and the shaded bottom rows of the colour (EggLitRows, EggShadeRows).
function RevealMath.EggBars(): ({ Bar }, { Bar }, { Bar }, { Bar })
	local fill: { [number]: { number } } = {}
	local first, last = math.huge, -math.huge
	for _, row in ipairs(RevealData.EggSpans) do
		fill[row[1]] = { row[2], row[3] }
		first, last = math.min(first, row[1]), math.max(last, row[1])
	end
	local ink: { [number]: { number } } = {}
	for row = 0, RevealData.EggRows - 1 do
		local left, right = math.huge, -math.huge
		for near = row - 1, row + 1 do
			local span = fill[near]
			if span then
				left, right = math.min(left, span[1] - 1), math.max(right, span[1] + span[2] + 1)
			end
		end
		if left < right then
			left, right = math.max(0, left), math.min(RevealData.EggCols, right)
			ink[row] = { left, right - left }
		end
	end
	local lit: { [number]: { number } } = {}
	local shade: { [number]: { number } } = {}
	for row = first, last do
		local span = fill[row]
		if span and row < first + RevealData.EggLitRows then
			lit[row] = span
		elseif span and row > last - RevealData.EggShadeRows then
			shade[row] = span
		end
	end
	local rows = RevealData.EggRows
	return rowBars(ink, rows), rowBars(fill, rows), rowBars(lit, rows), rowBars(shade, rows)
end

-- Whether pixel (x, y) is in the egg's colour.
local function inEgg(x: number, y: number): boolean
	for _, row in ipairs(RevealData.EggSpans) do
		if row[1] == y then
			return x >= row[2] and x < row[2] + row[3]
		end
	end
	return false
end

-- The crack tap number `tap` draws, as pixels of the egg's grid: each bar of its CrackLine (a centre, a length in egg heights and
-- a tilt) traced from end to end a pixel at a time, so the crack is a stepped pixel zig-zag; pixels outside the colour dropped.
function RevealMath.CrackCells(tap: number): { { number } }
	local cols, rows = RevealData.EggCols, RevealData.EggRows
	local out: { { number } } = {}
	local seen: { [number]: boolean } = {}
	for _, bar in ipairs(RevealMath.CrackLine(tap)) do
		local cx, cy = bar[1] * cols, bar[2] * rows
		local half = bar[3] * rows / 2
		local angle = math.rad(bar[4])
		local dx, dy = math.cos(angle) * half, math.sin(angle) * half
		local steps = math.max(1, math.ceil(2 * math.max(math.abs(dx), math.abs(dy))))
		for step = 0, steps do
			local t = step / steps
			local x = math.floor(cx - dx + 2 * dx * t)
			local y = math.floor(cy - dy + 2 * dy * t)
			local key = y * cols + x
			if not seen[key] and inEgg(x, y) then
				seen[key] = true
				table.insert(out, { x, y })
			end
		end
	end
	return out
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

-- The whole sequence for a tier, to the moment the buttons are up: beat 1 (when it runs), beat 2, the card's drop and its hold
-- (the tier's, with its HoldExtra).
function RevealMath.Total(tier: string, withCrack: boolean): number
	local crack = if withCrack then RevealMath.CrackSeconds() else 0
	return crack + RevealMath.ShardBeatSeconds(tier) + RevealData.CardDropSeconds + RevealMath.HoldSeconds(tier)
end

-- The quiet moment Toast.QuietFor is asked for: the sequence (the still frame under Reduced Motion) and the calm after it.
function RevealMath.QuietTotal(tier: string, withCrack: boolean, reduced: boolean): number
	local sequence = if reduced then RevealData.ReducedMotionSeconds else RevealMath.Total(tier, withCrack)
	return sequence + RevealData.QuietSeconds
end

-- What decides the ceremony of one reveal: the tier, whether the server called the species new to the codex, whether it is a grant (an egg
-- claim, a Peddler egg, a quest alien), and whether anything about it is special (an overlay, a size band that names itself, a storage
-- overflow ribbon).
export type ModeInput = { tier: string, isNew: boolean, fromEgg: boolean, overlay: string, labelledSize: boolean, overflow: boolean }

-- Whether a reveal is the quick card (the Clean UI pass): a wild catch (never an egg) of a species the codex already has, at one of
-- data/Reveal QuickTiers, with nothing special about it. Everything else keeps the three beats. The novelty is the server's word (isNew), so
-- this never guesses.
function RevealMath.IsQuick(input: ModeInput): boolean
	if input.fromEgg or input.isNew or input.overlay ~= "None" or input.labelledSize or input.overflow then
		return false
	end
	return table.find(RevealData.QuickTiers, input.tier) ~= nil
end

-- The quiet moment Toast.QuietFor is asked for while a quick card shows: just its time.
function RevealMath.QuickQuietSeconds(): number
	return RevealData.QuickSeconds
end

-- The seconds the quick card holds still between sliding in and fading out.
function RevealMath.QuickHoldSeconds(): number
	return math.max(0, RevealData.QuickSeconds - RevealData.QuickInSeconds - RevealData.QuickOutSeconds)
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
