--!strict
-- Shared.MenuMath: the arithmetic of the HUD's Menu drop-down (UI Playbook "Menu drop-down and icons (B52)", Decision B53).
-- The drop-down is a column of full-width rows under the Menu button: every screen but the Shop, one row each. Everything here is a
-- fraction of the screen height (the HUD's unit) so the UI places it with Scale only; the row is never under the 44 px tap floor, the
-- panel never runs past the bottom of the screen (it scrolls instead), and the badges of the rows add up on the Menu button.
-- Pure numbers, no Roblox types: tests/MenuMath.spec.luau runs it headless, including iPhone SE (667 by 375) and an iPad.

local MenuMath = {}

-- The panel's layout. `height` is the visible height; `canvas` is the rows' total height over the visible one (1 when everything
-- fits, more when it scrolls); `rowY` and `rowH` are each row's top and height as fractions of the canvas.
export type Layout = {
	height: number,
	canvas: number,
	rowY: { number },
	rowH: number,
	scrolls: boolean,
}

-- A left-column slot's real height as a fraction of the screen height: `slotH` on a wide screen; on a tall one the slot's aspect
-- (width over height) keeps it narrow, `slotW` of the width, so it is shorter. The drop-down hangs from the Menu slot's bottom.
function MenuMath.SlotHeight(slotH: number, slotW: number, aspect: number, screenW: number, screenH: number): number
	if screenW <= 0 or screenH <= 0 or aspect <= 0 then
		return slotH
	end
	return math.min(slotH, slotW * screenW / aspect / screenH)
end

-- A row's height as a fraction of the screen height: `frac`, but never fewer than `minPx` pixels on a screen `screenPx` tall.
function MenuMath.RowHeight(screenPx: number, frac: number, minPx: number): number
	if screenPx <= 0 then
		return frac
	end
	return math.max(frac, minPx / screenPx)
end

-- The panel: `count` rows `rowH` tall with `gap` between them and `pad` round them (all fractions of the screen height), shown in
-- at most `available`. Rows past what fits scroll; with no rows the panel is empty.
function MenuMath.Panel(count: number, rowH: number, gap: number, pad: number, available: number): Layout
	local rows = math.max(0, math.floor(count))
	if rows == 0 then
		return { height = 0, canvas = 1, rowY = {}, rowH = 1, scrolls = false }
	end
	local content = 2 * pad + rows * rowH + (rows - 1) * gap
	local height = math.max(0, math.min(content, available))
	if height <= 0 then
		return { height = 0, canvas = 1, rowY = {}, rowH = 1, scrolls = false }
	end
	local rowY: { number } = {}
	for index = 1, rows do
		rowY[index] = (pad + (index - 1) * (rowH + gap)) / content
	end
	return { height = height, canvas = content / height, rowY = rowY, rowH = rowH / content, scrolls = content > height + 1e-9 }
end

-- The panel's width as a fraction of the screen width: a row is `aspect` times as wide as it is tall in pixels, never wider than
-- `maxFrac` of the screen (a narrow phone in portrait takes the cap).
function MenuMath.PanelWidth(screenW: number, screenH: number, rowH: number, aspect: number, maxFrac: number): number
	if screenW <= 0 or screenH <= 0 then
		return maxFrac
	end
	return math.min(maxFrac, rowH * aspect * screenH / screenW)
end

-- How many rows fit whole in a panel `height` tall (the count a player sees before scrolling).
function MenuMath.RowsShown(layout: Layout): number
	if layout.rowH <= 0 then
		return 0
	end
	local shown = 0
	for _, y in ipairs(layout.rowY) do
		if (y + layout.rowH) * layout.height * layout.canvas <= layout.height + 1e-9 then
			shown += 1
		end
	end
	return shown
end

-- The number on the Menu button: the badge counts of the rows that show, added up (a hidden row counts nothing).
function MenuMath.BadgeTotal(counts: { [string]: number }, hidden: { [string]: boolean }): number
	local total = 0
	for id, count in pairs(counts) do
		if not hidden[id] and count > 0 then
			total += count
		end
	end
	return total
end

-- A badge's text: the count, or "99+" past two digits; nothing at zero.
function MenuMath.BadgeText(count: number): string
	if count <= 0 then
		return ""
	end
	if count > 99 then
		return "99+"
	end
	return tostring(math.floor(count))
end

-- Zero-value lines stay off the HUD: the luck line shows only when luck, read to one decimal as it is shown, is not x1.0.
function MenuMath.LuckShown(luck: number): boolean
	return math.floor(luck * 10 + 0.5) ~= 10
end

-- The Friend Boost chip shows only while the boost, read as the whole percent it is shown as, is above +0%.
function MenuMath.FriendBoostShown(boost: number): boolean
	return math.floor(boost * 100 + 0.5) > 0
end

return MenuMath
