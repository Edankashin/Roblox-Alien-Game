--!strict
-- Shared.PanelHeaderMath: the arithmetic of a panel's header band (UI richness pass, docs/vault/05-ui-design/UI-Richness-Pass.md
-- section 2, package A). A band holds an icon, the title, one or two status pills and the X: which pills fit beside the title (they
-- drop from the last, the title never wraps), how wide a pill is for its text, how a pill's template is filled from its values, and
-- the aspect a panel takes at the shell's height so it keeps its screen's width. Pure numbers and strings, no Roblox types:
-- tests/PanelHeaderMath.spec.luau runs it headless, including iPhone SE (667 by 375) and an iPad. UI/Builder.panelHeader measures
-- the text with TextService and calls these.

local PanelHeaderMath = {}

-- How many of `pills` (their widths in px, the plain pill first) fit in `widthPx` beside a title `titlePx` wide, with `gapPx` before
-- each pill. The pills drop from the last until the rest fit; the title is never dropped or wrapped, so with room for none the
-- answer is 0. A width that is not a number of pixels (a panel not measured yet) lets every pill show.
function PanelHeaderMath.Fit(widthPx: number, titlePx: number, pills: { number }, gapPx: number?): number
	if widthPx <= 0 then
		return #pills
	end
	local gap = gapPx or 0
	local count = #pills
	while count > 0 do
		local used = titlePx
		for index = 1, count do
			used += (pills[index] :: number) + gap
		end
		if used <= widthPx then
			return count
		end
		count -= 1
	end
	return 0
end

-- A pill's width: its text plus `pad` (a share of the pill's height) of margin at each side.
function PanelHeaderMath.PillWidth(textPx: number, heightPx: number, pad: number): number
	return textPx + 2 * pad * heightPx
end

local function group(n: number): string
	local text = tostring(math.floor(math.abs(n) + 0.5))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return if n < 0 then "-" .. out else out
end

-- A pill's text from its template ("Aliens %d / %d", "Scrap %s") and its values: each %d takes the next value as a whole number
-- with thousands separators, each %s the next value as it is; "%%" is a percent sign. A missing value leaves "0" for a %d and nothing
-- for a %s, and a value left over is ignored, so a pill never errors on a count that has not arrived. One template per pill, so it
-- translates whole.
function PanelHeaderMath.Format(template: string, values: { any }): string
	local index = 0
	local out = string.gsub(template, "%%([ds%%])", function(kind: string): string
		if kind == "%" then
			return "%"
		end
		index += 1
		local value = values[index]
		if kind == "d" then
			return group(if type(value) == "number" then value else tonumber(value) or 0)
		end
		return if value == nil then "" else tostring(value)
	end)
	return out
end

-- The aspect (width over height) a panel built at `oldHeight` of the screen with `aspect` takes at `newHeight`, holding its width
-- in px (the panel is aspect-limited on every window the game runs in): the shell makes panels taller, not wider.
function PanelHeaderMath.ShellAspect(aspect: number, oldHeight: number, newHeight: number): number
	if newHeight <= 0 then
		return aspect
	end
	return aspect * oldHeight / newHeight
end

return PanelHeaderMath
