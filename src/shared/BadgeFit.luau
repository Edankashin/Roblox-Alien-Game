--!strict
-- Shared.BadgeFit: how wide an overlay badge must be (and, on a crowded card, how many lines) for its name to show
-- whole. Pure arithmetic over text widths the client measured once with TextService at the 14 px floor
-- (Builder.overlayName), so tests/BadgeFit.spec.luau runs it headless.
-- A badge's label fills `textFraction` of the badge's width (the UI Playbook's 0.9 for chips), so a text `px` wide needs a
-- badge (px + slackPx) / (textFraction * parentPx) wide, as a Scale of its parent. TextScaled shrinks the text to fit but
-- never under the 14 px floor, so a label narrower than the floor-size text wraps and cuts: that was "Launch" and "Launc".

local BadgeFit = {}

export type Line = { text: string, px: number }
-- A name as measured: the whole string on one line, and each of its words on its own.
export type Name = { whole: Line, words: { Line } }

export type Params = {
	textFraction: number, -- the label's width over the badge's
	slackPx: number, -- rounding room on top of the measured text
	minWidth: number, -- never narrower than this (Scale of the parent): the badge's size before it was fitted
	maxWidth: number, -- never wider than this: the room the badge's row has (a name still longer overflows and shrinks)
	besideMax: number?, -- card only: the widest a badge can be and still leave the speed chip its corner on the same row
}

-- Where each piece of a card's top-left stack goes, in rows of the card's corner band (row 0 is the top).
export type Plan = {
	texts: { string }, -- one badge line per entry: the whole name, or one word per line when the name does not fit
	widths: { number }, -- Scale of the card, one per line
	speedRow: number, -- the row the speed chip takes at the top right: 0 beside the first line, else the first row it clears
	levelRow: number, -- the row a fused copy's level chip takes at the left: always under the badge
}

-- The width, as a Scale of a parent `parentPx` wide, a badge needs to hold text `px` wide on one line, kept inside
-- [minWidth, maxWidth]. A parent of unknown size (0) gives the minimum.
function BadgeFit.Width(px: number, parentPx: number, params: Params): number
	if parentPx <= 0 then
		return params.minWidth
	end
	local wanted = (px + params.slackPx) / (params.textFraction * parentPx)
	return math.min(math.max(wanted, params.minWidth), math.max(params.minWidth, params.maxWidth))
end

-- The badge stack of one alien card `cardPx` wide (the card is square, so a Scale of its width is also one of its height).
-- The whole name on one line when it fits the row; otherwise, for a name of several words, one line per word, each its own
-- pill so the speed chip can take the row beside a short last word. The speed chip stays at the top right while the first
-- line leaves it room (besideMax); else it moves to the first row that does, or under the badge.
function BadgeFit.Card(name: Name, cardPx: number, params: Params): Plan
	local besideMax = params.besideMax or params.maxWidth
	local oneLine = BadgeFit.Width(name.whole.px, cardPx, params)
	local wanted = if cardPx > 0 then (name.whole.px + params.slackPx) / (params.textFraction * cardPx) else 0
	if wanted <= params.maxWidth or #name.words < 2 then
		return {
			texts = { name.whole.text },
			widths = { oneLine },
			speedRow = if oneLine <= besideMax then 0 else 1,
			levelRow = 1,
		}
	end
	local texts: { string } = {}
	local widths: { number } = {}
	local speedRow: number? = nil
	for index, word in ipairs(name.words) do
		texts[index] = word.text
		widths[index] = BadgeFit.Width(word.px, cardPx, params)
		if speedRow == nil and widths[index] <= besideMax then
			speedRow = index - 1
		end
	end
	return { texts = texts, widths = widths, speedRow = speedRow or #texts, levelRow = #texts }
end

return BadgeFit
