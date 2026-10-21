--!strict
-- ReplicatedStorage.Shared.ShelfMath: the arithmetic of the Shop's shelf (the one row of tall cards, UI Playbook "Shop shelf"),
-- pure so the headless tests can run it: where the cards sit along the row, which tab the scroll position belongs to, how big
-- the scrollbar's thumb is and where the pointer puts it, which edge arrows show, and whether an item can be bought yet. The
-- screen reads pixels once (the window and the card height) and hands them in; the numbers (gaps, slack, edge distance) are
-- data/Shop.Shelf, passed in by the caller.

local ShelfMath = {}

-- The part of a data/Shop row the live check reads.
export type Sellable = { kind: "pass" | "product", productId: number?, passId: number?, offSale: boolean? }

-- The left edge of every card and the length of the whole row, from each card's width, the `gap` between neighbours and the
-- `pad` at both ends (all in the same unit, px in the screen). No cards is a row of length 0.
function ShelfMath.Place(widths: { number }, gap: number, pad: number): ({ number }, number)
	local lefts: { number } = {}
	local x = pad
	for index, width in ipairs(widths) do
		lefts[index] = x
		x += width + gap
	end
	if #widths == 0 then
		return lefts, 0
	end
	return lefts, x - gap + pad
end

-- The furthest the row can scroll: its length less the window's, never below 0.
function ShelfMath.MaxOffset(canvas: number, window: number): number
	return math.max(0, canvas - window)
end

-- The scroll offset that brings the section starting at `start` to the left edge, kept inside what the row can reach.
function ShelfMath.ScrollTarget(start: number, maxOffset: number): number
	return math.clamp(start, 0, math.max(0, maxOffset))
end

-- The index of the section the scroll position belongs to. `starts` are the offsets that put each section at the left edge, in
-- order; a section is current once its start is within `slack` of the left edge. At the far end the last section is current,
-- since a short last section can never reach the left edge (`edge` is how close to the end counts as the end).
function ShelfMath.ActiveSection(offset: number, starts: { number }, maxOffset: number, slack: number, edge: number): number
	local count = #starts
	if count == 0 then
		return 0
	end
	if maxOffset > 0 and offset >= maxOffset - edge then
		return count
	end
	local active = 1
	for index = 1, count do
		if starts[index] <= offset + slack then
			active = index
		end
	end
	return active
end

-- The scrollbar's thumb as fractions of its track: the size (the window over the row, never under `minSize`) and the left
-- edge (the offset's share of the way along, over the track the thumb leaves free). A row that fits has a thumb as long as the
-- track.
function ShelfMath.Thumb(offset: number, window: number, canvas: number, minSize: number): (number, number)
	if canvas <= window or window <= 0 then
		return 1, 0
	end
	local size = math.min(1, math.max(minSize, window / canvas))
	local share = math.clamp(offset / (canvas - window), 0, 1)
	return size, (1 - size) * share
end

-- The scroll offset a pointer at `fraction` along the track asks for, the thumb's middle under it (the inverse of Thumb).
function ShelfMath.OffsetFromPointer(fraction: number, window: number, canvas: number, minSize: number): number
	if canvas <= window or window <= 0 then
		return 0
	end
	local size = math.min(1, math.max(minSize, window / canvas))
	local free = 1 - size
	if free <= 0 then
		return 0
	end
	local share = math.clamp((fraction - size / 2) / free, 0, 1)
	return share * (canvas - window)
end

-- Whether there is more to scroll to the left and to the right (more than `edge` away from that end).
function ShelfMath.Arrows(offset: number, maxOffset: number, edge: number): (boolean, boolean)
	return offset > edge, offset < maxOffset - edge
end

-- Whether an item has an id on the Creator Dashboard yet (the same rule the server's PromptPurchase answers NotLive by:
-- a pass reads passId, anything else productId, and a missing id or 0 is a placeholder). The tap on one that is not live
-- shows "Coming soon"; the server still decides every purchase.
function ShelfMath.IsLive(item: Sellable): boolean
	if item.offSale == true then
		return false -- held off sale in data (data/Shop `offSale`), whatever its id
	end
	local id = if item.kind == "pass" then item.passId else item.productId
	return id ~= nil and id ~= 0
end

-- Whether a purchase of the item can hand anything over: it is live and data/Shop.Grants gives it at least one row (a
-- pass's passFlag counts). The server maps only these to receipts and pass prompts, so a product created on the dashboard
-- before its feature exists (DirectRare, ModuleRush and the rest have no Grants row) never takes Robux for nothing.
function ShelfMath.IsSellable(item: Sellable, grants: { any }?): boolean
	return ShelfMath.IsLive(item) and grants ~= nil and #grants > 0
end

return ShelfMath
