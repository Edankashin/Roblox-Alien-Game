--!strict
-- Shared.PanelQuiet: the pure rules of the calm panels (Clean UI pass, package C; docs/vault/05-ui-design/Clean-UI-Pass.md "Panels,
-- the shared shell", "Per-screen changes"). A panel is the one focal point: a quiet face, one primary button, no repeated text,
-- never an empty pane. The screens draw; every decision they make from state is here, so tests/PanelQuiet.spec.luau runs it
-- headless. Numbers come from data/Panels; nothing here touches Roblox types.

local BlockMath = require(script.Parent.BlockMath)
local Panels = require(script.Parent.data.Panels)

local PanelQuiet = {}

-- The face -----------------------------------------------------------------

-- How many frames a plate of `grid` draws as a quiet panel face (Builder.blockPlate quiet = true): the ink and face bars, the lit
-- top row and shaded edges, the grout, and no jittered cells. A quiet plate is always a cells plate; `quiet` false counts the
-- ordinary one (BlockMath.Frames), so the saving is one number.
function PanelQuiet.Frames(grid: BlockMath.Grid, seed: number, quiet: boolean): number
	if not quiet then
		return BlockMath.Frames(grid, true, seed)
	end
	return BlockMath.Frames(grid, true, seed) - #BlockMath.Jittered(grid, seed)
end

-- Settings -----------------------------------------------------------------

export type SettingsItem = { kind: "heading", title: string } | { kind: "row", key: string }

-- The list the Settings screen draws: a heading, then its rows, for each section of data/Panels.SettingsSections that has a row in
-- `order` (the keys of data/Settings in display order), then any key no section names under the first heading. Every key of
-- `order` appears exactly once; a key a section names that `order` does not have is skipped.
function PanelQuiet.SettingsItems(order: { string }, sections: { Panels.Section }): { SettingsItem }
	local present: { [string]: boolean } = {}
	for _, key in ipairs(order) do
		present[key] = true
	end
	local placed: { [string]: boolean } = {}
	local groups: { { title: string, keys: { string } } } = {}
	for _, section in ipairs(sections) do
		local keys: { string } = {}
		for _, key in ipairs(section.keys) do
			if present[key] and not placed[key] then
				placed[key] = true
				table.insert(keys, key)
			end
		end
		table.insert(groups, { title = section.title, keys = keys })
	end
	local first = groups[1]
	if first then
		for _, key in ipairs(order) do
			if not placed[key] then
				placed[key] = true
				table.insert(first.keys, key)
			end
		end
	end
	local out: { SettingsItem } = {}
	for _, group in ipairs(groups) do
		if #group.keys > 0 then
			table.insert(out, { kind = "heading", title = group.title })
			for _, key in ipairs(group.keys) do
				table.insert(out, { kind = "row", key = key })
			end
		end
	end
	if not first then
		for _, key in ipairs(order) do
			table.insert(out, { kind = "row", key = key })
		end
	end
	return out
end

-- The share of the rows frame a settings row and a heading each get: `rows` rows of weight 1 (the promo-code row counts) and
-- `headings` of weight `headingWeight`, with `gap` between the `rows + headings` items. Answers (row, heading) as fractions of the
-- rows frame, so rows * row + headings * heading + gaps = 1.
function PanelQuiet.SettingsShares(rows: number, headings: number, headingWeight: number, gap: number): (number, number)
	local items = rows + headings
	local room = 1 - gap * math.max(0, items - 1)
	local weight = rows + headings * headingWeight
	if weight <= 0 then
		return 0, 0
	end
	local row = room / weight
	return row, row * headingWeight
end

-- Ship ---------------------------------------------------------------------

export type ButtonRole = "primary" | "secondary" | "idle"

-- The roles of the Pay and Add buttons in the active module card: the one green (primary) button is the next step, Pay until the
-- Scrap is paid and then Add while parts are still missing; the other is blue (secondary) while it can act and grey (idle) when it
-- has nothing to do. `partsMissing` is whether the card still wants key parts; `canAdd` whether the player holds one.
function PanelQuiet.ShipRoles(scrapPaid: boolean, partsMissing: boolean, canAdd: boolean): (ButtonRole, ButtonRole)
	local pay: ButtonRole = "idle"
	local add: ButtonRole = "idle"
	if not scrapPaid then
		pay = "primary"
		add = if partsMissing and canAdd then "secondary" else "idle"
	elseif partsMissing then
		add = "primary"
	end
	return pay, add
end

-- Whether the Ship panel's intro line ("Pay Scrap, add the parts...") shows: only until the first module is paid. `firstScrapPaid`
-- is the first module's Scrap gate met, `firstComplete` it finished. The line is for the active module only, so it also hides when
-- the active one is a later module.
function PanelQuiet.ShipIntroShown(activeIndex: number?, firstScrapPaid: boolean, firstComplete: boolean): boolean
	return activeIndex == 1 and not firstScrapPaid and not firstComplete
end

-- Whether a module row prints "Finish the module above first": only the first locked row (the one right under the active module).
function PanelQuiet.ShipLockedHint(index: number, activeIndex: number?): boolean
	return activeIndex ~= nil and index == activeIndex + 1
end

-- Codex ----------------------------------------------------------------------

-- The species the Codex's featured card shows on open: the most recently caught of `roster` (ids in display order), where `recent` maps a
-- species id to when it was last caught (the newest alien of it, or its first catch); the first entry of the roster when nothing
-- on the page is caught. Ties go to the earlier entry. Nil only for an empty roster.
function PanelQuiet.CodexDefault(roster: { string }, recent: { [string]: number }): string?
	local best: string? = nil
	local bestAt = -math.huge
	for _, id in ipairs(roster) do
		local at = recent[id]
		if at ~= nil and at > bestAt then
			best, bestAt = id, at
		end
	end
	return best or roster[1]
end

-- Quests ---------------------------------------------------------------------

-- The tab the Quests panel opens on: the first of data/Panels.QuestTabPriority with something to claim (`ready` by tab name),
-- else the default. The Event tab only counts while a season shows it.
function PanelQuiet.QuestTab(ready: { [string]: boolean }, eventShown: boolean): string
	for _, tab in ipairs(Panels.QuestTabPriority) do
		if ready[tab] == true and (tab ~= "event" or eventShown) then
			return tab
		end
	end
	return Panels.QuestTabDefault
end

export type OnSummary = { kind: "many" | "one" | "later" | "none", count: number }

-- The one line of the collapsed What's on band: how many timed things are on now, else that something is coming, else nothing.
-- `now` counts the things happening now, `later` the ones announced for later.
function PanelQuiet.OnSummary(now: number, later: number): OnSummary
	if now >= 2 then
		return { kind = "many", count = now }
	elseif now == 1 then
		return { kind = "one", count = 1 }
	elseif later > 0 then
		return { kind = "later", count = later }
	end
	return { kind = "none", count = 0 }
end

-- Gifts and Playtime -----------------------------------------------------------

export type GiftState = "claimable" | "claimed" | "future"

-- A gift tile's state: claimed once taken, claimable when reached and not taken, future before that. Only a claimable tile is green.
function PanelQuiet.GiftState(unlocked: boolean, claimed: boolean): GiftState
	if claimed then
		return "claimed"
	elseif unlocked then
		return "claimable"
	end
	return "future"
end

-- Aliens footer ----------------------------------------------------------------

export type Slot = { x: number, w: number }
export type Footer = { release: Slot, bay: Slot, token: Slot?, fuse: Slot, optimize: Slot }

-- The footer's button row as left edges and widths, fractions of the panel's width: Release then the Storage Bay button from the
-- left margin; Optimize at the right margin, Fuse left of it and, while a token is held, the token button left of Fuse. With a
-- token the Bay button and Release take their narrower widths (the Bay its short label) so nothing overlaps.
function PanelQuiet.AliensFooter(tokenHeld: boolean): Footer
	local f = Panels.AliensFooter
	local releaseW = if tokenHeld then f.ReleaseWithToken else f.Release
	local bayW = if tokenHeld then f.BayWithToken else f.Bay
	local optimizeX = 1 - f.Margin - f.Optimize
	local fuseX = optimizeX - f.Gap - f.Fuse
	local footer: Footer = {
		release = { x = f.Margin, w = releaseW },
		bay = { x = f.Margin + releaseW + f.Gap, w = bayW },
		fuse = { x = fuseX, w = f.Fuse },
		optimize = { x = optimizeX, w = f.Optimize },
	}
	if tokenHeld then
		footer.token = { x = fuseX - f.Gap - f.Token, w = f.Token }
	end
	return footer
end

return PanelQuiet
