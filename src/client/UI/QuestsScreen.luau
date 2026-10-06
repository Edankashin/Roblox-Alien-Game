--!strict
-- StarterPlayerScripts.Client.UI.QuestsScreen: the Field Notes panel, a quest board for the current
-- world's chain (Quests.FieldNotes[world]). The chain is one list in order: finished steps as compact
-- rows marked Claimed, the current step as a big card (title, legend, the objectives with their counts,
-- the rewards and a Claim button that turns green when every objective is met), and the later steps as
-- compact dimmed rows. Past the last step the whole chain is compact under a done line. Everything
-- shown is read from the profile mirror in State and the shared data tables; the Claim tap asks the
-- server (QuestClaim), which advances the step and pushes QuestsChanged. Nothing here decides an
-- outcome: a grey Claim button only clicks.
--
-- Two header tabs switch the body: Field Notes (the board above) and Daily & Weekly, a scrolling list
-- of the three daily and three weekly quests dealt to the player. Each row shows its objective, a
-- progress bar, the reward and a Claim button (dailies also a Reroll button). The sets come from the
-- profile mirror (State, filled by GetDailyQuests when the tab opens and by DailyQuestsChanged pushes);
-- the reset countdowns tick once a minute while the tab is showing. Claim and Reroll ask the server
-- (ClaimDailyQuest, RerollDailyQuest, one request in flight) and the toast says what it answered.
--
-- A third tab, Event, exists only while a seasonal event runs (State.GetSeason, data/Seasons): a title, a hint
-- that every row is free, then one card per quest of the season's track in the Daily & Weekly card's look. The
-- counts and claims come from the mirror State keeps (SeasonProgressChanged, GetSeasonProgress); a Claim asks the
-- server (ClaimSeasonQuest, one request in flight) and a row that paid an alien opens the Reveal through the
-- bootstrap's hook (QuestsScreen.OnGrant), as a gift egg does. The tab goes, and the view falls back to Field Notes,
-- when the season ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("data"):WaitForChild("Quests"))
local DailyQuests = require(Shared:WaitForChild("data"):WaitForChild("DailyQuests"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Seasons = require(Shared:WaitForChild("data"):WaitForChild("Seasons"))
local SeasonMath = require(Shared:WaitForChild("SeasonMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local QuestsScreen = {}

-- One objective line inside the expanded card: the task on the left, its count on the right.
type ObjectiveLine = { frame: Frame, text: TextLabel, progress: TextLabel }

-- One step row. Children are built once and re-laid-out for the compact or expanded shape.
type Row = {
	card: Frame,
	badge: Frame,
	badgeLabel: TextLabel,
	title: TextLabel,
	status: TextLabel,
	legend: TextLabel,
	todo: TextLabel,
	objectives: Frame,
	lines: { ObjectiveLine },
	rewardHeading: TextLabel,
	rewards: TextLabel,
	claim: Frame,
	claimReady: boolean,
}

-- One daily or weekly row. Children are built once; refreshDaily fills them from the profile mirror.
type DailyRow = {
	period: "daily" | "weekly",
	slot: number, -- index into the period's dealt ids
	card: Frame,
	objective: TextLabel,
	reward: TextLabel,
	fill: Frame,
	count: TextLabel,
	claim: Frame,
	reroll: Frame?, -- dailies only
	questId: string, -- the quest this row shows now; "" while hidden
	objectiveText: string, -- for the claimed toast
	claimed: boolean,
	claimReady: boolean,
}

-- One Event row: the shared card plus what its Claim tap needs. Built once per track position, refilled by refreshEvent.
type EventRow = {
	card: Frame,
	objective: TextLabel,
	reward: TextLabel,
	fill: Frame,
	count: TextLabel,
	claim: Frame,
	questId: string, -- the track quest this row shows now; "" while hidden
	rewardsText: string, -- for the claimed toast, read before the call
	claimed: boolean,
	claimReady: boolean,
}

type ViewName = "notes" | "daily" | "event"
-- A header tab: where it sits (x, with the anchor it pairs with) and whether it shows at all (the Event tab only
-- while a season runs); layoutTabs sets the three, applyView raises the active one.
type Tab = { frame: Frame, color: Color3, x: number, visible: boolean }

local LIST_TOP = 0.155 -- below the step header line
local ROW_COMPACT = 0.1 -- of the list height
local ROW_GAP = 0.012
local MIN_EXPANDED = 0.45 -- the current step's card never shrinks below this, whatever the chain length
local DONE_HEIGHT = 0.3 -- the done line under a finished chain
local OBJECTIVE_TEXT_WIDTH = 0.78 -- the rest of an objective line is its count

-- Header tabs, as fractions of the panel; they straddle the top edge. Two tabs (the usual look) sit left and right
-- of the centre line; while a season runs the Event tab joins and the three take thirds of the span left of the
-- Close button (which starts at 0.875). A third is 0.2767 of the panel: 109 px at iPhone SE size, where the longest
-- label, "Daily & Weekly", is 100.6 px at the minimum text size (Fredoka metrics), so it still fits on one line.
local TAB_W = 0.33 -- two tabs
local TAB_CENTRE_GAP = 0.01
local TAB_SPAN_LEFT = 0.02 -- three tabs: the span they share
local TAB_SPAN_RIGHT = 0.87
local TAB_GAP = 0.01
local TAB_COUNT_WITH_EVENT = 3
local TAB_W3 = (TAB_SPAN_RIGHT - TAB_SPAN_LEFT - (TAB_COUNT_WITH_EVENT - 1) * TAB_GAP) / TAB_COUNT_WITH_EVENT
local TAB_H = 0.12
local TAB_RAISED = 0 -- the active tab's centre sits on the panel's top edge
local TAB_LOWERED = 0.02 -- the other one sits a little lower
local NOTES_COLOR = Theme.Colors.Featured
local DAILY_COLOR = Theme.Colors.Select
local EVENT_COLOR = Theme.Colors.Codex
local TAB_ORDER: { ViewName } = { "notes", "daily", "event" }

-- Event list. Heights are in windows (1 = the scroller's visible height) and become fractions of the canvas by
-- dividing by the page count; the canvas itself is `pages * EV_LIST_SHARE` of the body, because CanvasSize scales
-- against the ScrollingFrame's parent, not against the frame (docs/vault/04-roblox-engine/UI-Rules.md). At iPhone SE
-- size a window is about 240 px: the title, the hint and the first two rows show, the other three are a scroll away.
local EV_LIST_SHARE = 1 - LIST_TOP - Theme.Margin -- the list's height as a share of its parent (the body)
local EV_HEAD_H = 0.12
local EV_HINT_H = 0.1
local EV_ROW_H = 0.32
local EV_GAP = 0.025

-- Daily & Weekly list. Heights are in windows (1 = the scroller's visible height); the canvas is
-- DQ_PAGES windows tall and every child of the scroller divides its height by that. One section (heading
-- plus its rows) fills exactly one window, so the daily set shows first and the weekly set is a scroll away.
local DQ_ROWS = math.max(DailyQuests.DailyCount, DailyQuests.WeeklyCount)
local DQ_HEAD_H = 0.11
local DQ_ROW_H = 0.27
local DQ_GAP = 0.02
local DQ_SECTION_H = DQ_HEAD_H + DQ_GAP + DQ_ROWS * (DQ_ROW_H + DQ_GAP)
local DQ_PAGES = 2 * DQ_SECTION_H
local SCROLLBAR_PX = 6
local MINUTE = 60
local HOUR = 3600
local DAY = 86400

local gui: ScreenGui? = nil
local panel: Frame? = nil
local stepLabel: TextLabel? = nil
local list: Frame? = nil
local doneLabel: TextLabel? = nil
local rows: { Row } = {}
local open = false
local pending = false -- one QuestClaim in flight at a time
local claimReady = false -- every objective of the current step is met (the server still decides)
local claimRewards = "" -- the current step's rewards line, for the claimed toast

local view: ViewName = "notes"
local tabs: { [string]: Tab } = {}
local scroller: ScrollingFrame? = nil -- the Daily & Weekly list
local dailyRows: { DailyRow } = {}
local dailyCountdown: TextLabel? = nil
local weeklyCountdown: TextLabel? = nil
local eventScroller: ScrollingFrame? = nil -- the Event tab's list
local eventTitle: TextLabel? = nil
local eventHint: TextLabel? = nil
local eventRows: { EventRow } = {}
local eventPending = false -- one ClaimSeasonQuest in flight at a time
local onGrant: ((Types.GrantResult) -> ())? = nil -- the bootstrap's hook: a row that paid an alien opens the Reveal
local dailyPending = false -- one ClaimDailyQuest / RerollDailyQuest in flight at a time
local fetching = false -- one GetDailyQuests in flight at a time
local tickToken = 0 -- bumped to stop the countdown loop (tab switch, close)
local staleFetchedFor = 0 -- the reset instants already re-fetched after they passed
local dailyById: { [string]: DailyQuests.Quest } = {}
local weeklyById: { [string]: DailyQuests.Quest } = {}
for _, quest in ipairs(DailyQuests.Daily) do
	dailyById[quest.id] = quest
end
for _, quest in ipairs(DailyQuests.Weekly) do
	weeklyById[quest.id] = quest
end

-- Text --------------------------------------------------------------------

-- The OBJ_<kind> template filled by kind: counts, tier names and condition phrases from the strings table.
local function objectiveText(objective: Quests.Objective): string
	local template = Builder.text("OBJ_" .. objective.kind)
	local kind = objective.kind
	local tier = Builder.text("TIER_" .. (objective.tier or "Common"))
	local phrase = Builder.text("COND_PHRASE_" .. (objective.condition or "Any"))
	if kind == "catchCount" then
		return template:format(objective.count)
	elseif kind == "catchCondition" and objective.count > 1 then
		return Builder.text("OBJ_catchCondition_many"):format(objective.count, phrase)
	elseif kind == "catchCondition" or kind == "soundHorn" then
		return template:format(phrase)
	elseif kind == "catchTier" and objective.count > 1 then
		return Builder.text("OBJ_catchTier_many"):format(objective.count, tier)
	elseif kind == "catchTier" then
		return template:format(tier)
	elseif kind == "catchTierCondition" then
		return template:format(tier, phrase)
	elseif kind == "collect" then
		return template:format(Builder.text("MATERIAL_" .. (objective.material or "")))
	elseif kind == "craft" then
		return template:format(Builder.text("LURE_" .. (objective.lure or "")))
	end
	return template
end

-- The REWARD_<kind> template filled by kind; an encounter and an alien name the species, one free spin reads
-- singular. Takes the three fields, not a row, so every reward table (Field Notes, daily, event) can call it.
local function rewardText(kind: string, rewardId: string?, rewardAmount: number?): string
	local template = Builder.text("REWARD_" .. kind)
	local id = rewardId or ""
	local amount = rewardAmount or 0
	if kind == "gear" then
		return template:format(Builder.text("GEAR_" .. id))
	elseif kind == "lure" then
		return template:format(amount, Builder.text("LURE_" .. id))
	elseif kind == "scrap" then
		return template:format(Builder.formatNumber(amount))
	elseif kind == "spin" then
		return if amount == 1 then Strings.REWARD_spin_ONE else template:format(amount)
	elseif kind == "item" then
		return template:format(Builder.text("ITEM_" .. id))
	elseif kind == "powerUp" then
		return template:format(amount, Builder.text("POWERUP_" .. id))
	elseif kind == "encounter" or kind == "alien" then
		local def = Species.ById[id]
		return template:format(if def then def.name else id)
	end
	return template
end

local function rewardsLine(step: Quests.Step): string
	local parts: { string } = {}
	for _, reward in ipairs(step.rewards) do
		table.insert(parts, rewardText(reward.kind, reward.id, reward.amount))
	end
	return table.concat(parts, ", ")
end

-- The same line for the reward lists of the daily quests and the promo codes (a subset of the kinds above).
local function rewardsList(rewards: { DailyQuests.Reward }): string
	local parts: { string } = {}
	for _, reward in ipairs(rewards) do
		table.insert(parts, rewardText(reward.kind, reward.id, reward.amount))
	end
	return table.concat(parts, ", ")
end

-- The same line for an event track row, whose rewards may also be an alien.
local function seasonRewardsLine(rewards: { Seasons.Reward }): string
	local parts: { string } = {}
	for _, reward in ipairs(rewards) do
		table.insert(parts, rewardText(reward.kind, reward.id, reward.amount))
	end
	return table.concat(parts, ", ")
end

-- The OBJ_<kind> line of an event track row: catchEvent and showerCount take the count, catchOverlay the count and
-- the season's overlay by name, catchCount the count as the Field Notes line does.
local function seasonObjectiveText(objective: Seasons.Objective, season: Seasons.Season): string
	local template = Builder.text("OBJ_" .. objective.kind)
	if objective.kind == "catchOverlay" then
		local overlayName = Builder.text("OVERLAY_" .. (season.overlay or "None"))
		if objective.count == 1 then
			return Strings.OBJ_catchOverlay_ONE:format(overlayName) -- "Catch an alien with ...", not "1 aliens"
		end
		return template:format(objective.count, overlayName)
	end
	return template:format(objective.count)
end

-- The current world's special weather by name ("Rain", "Blizzard"), for the catchSpecial quests.
local function specialWeatherName(): string
	local def = Worlds[State.Get().world.current] or Worlds[1]
	return Builder.text("WEATHER_" .. def.weather.special.id)
end

-- The OBJ_<kind> template filled for a daily or weekly quest. The Field Notes phrases (tier names, condition
-- phrases, lure names) are reused; the count is the progress line's job except where the template takes it.
local function dailyObjectiveText(objective: DailyQuests.Objective): string
	local kind = objective.kind
	local template = Builder.text("OBJ_" .. kind)
	if kind == "catchCondition" then
		local phrase = Builder.text("COND_PHRASE_" .. (objective.condition or "Any"))
		if objective.count > 1 then
			return Builder.text("OBJ_catchCondition_many"):format(objective.count, phrase)
		end
		return template:format(phrase)
	elseif kind == "catchTier" then
		local tier = Builder.text("TIER_" .. (objective.tier or "Common"))
		if objective.count > 1 then
			return Builder.text("OBJ_catchTier_many"):format(objective.count, tier)
		end
		return template:format(tier)
	elseif kind == "craft" then
		return template:format(Builder.text("LURE_" .. (objective.lure or "")))
	elseif kind == "catchSpecial" then
		return template:format(objective.count, specialWeatherName())
	end
	-- catchCount, catchWithFriend, perfectCount, collectAny, dailyClaims: the count is the one blank
	return template:format(objective.count)
end

-- "Nd Nh" from a day up (weekly only), "Nh Nm" from an hour up, "Nm" under it (minutes round up so the
-- last minute reads 1m).
local function timeLeftText(seconds: number, allowDays: boolean): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.floor(seconds))
	if allowDays and total >= DAY then
		return Strings.TIME_DH:format(total // DAY, (total % DAY) // HOUR)
	elseif total >= HOUR then
		return Strings.TIME_HM:format(total // HOUR, (total % HOUR) // MINUTE)
	end
	return Strings.TIME_M:format(math.ceil(total / MINUTE))
end

-- Helpers ----------------------------------------------------------------

-- Recolours a Builder.button in place (lip, face, thick stroke, gradient).
local function recolorButton(container: Frame, color: Color3)
	local dark = Builder.darker(color)
	local lip = container:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = dark
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.BackgroundColor3 = color
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.Thickness == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

local function setCardStyle(row: Row, cardColor: Color3, accent: Color3)
	row.card.BackgroundColor3 = cardColor
	local stroke = row.card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = accent
	end
	row.badge.BackgroundColor3 = accent
	local gradient = row.badge:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(accent), accent)
	end
end

-- Server call --------------------------------------------------------------

-- Asks the server to claim the current step. Runs in its own thread: the caller is a tap. A grey
-- button (objectives unmet) only clicks; the server would refuse it anyway.
local function claim()
	if pending or not claimReady then
		return
	end
	local summary = claimRewards
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("QuestClaim"):InvokeServer()
		pending = false
		if ok == true then
			Toast.Show(Strings.TOAST_QUEST_CLAIMED:format(summary), Theme.Colors.Confirm)
			return
		end
		if reason == "NotComplete" then
			-- also the case while the Warden is summoned but not yet caught: the step reads complete, the claim waits
			Toast.Show(Strings.TOAST_QUEST_NOT_COMPLETE, Theme.Colors.Select)
			return
		end
		print(("[%s] QuestClaim refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end)
end

-- Rows ---------------------------------------------------------------------

local function buildObjectiveLine(parent: Frame, index: number): ObjectiveLine
	local line = Builder.frame({
		parent = parent,
		name = "Objective" .. index,
		size = UDim2.fromScale(1, 1),
		zIndex = 4,
	})
	line.LayoutOrder = index
	local text = Builder.label({
		parent = line,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		size = UDim2.fromScale(OBJECTIVE_TEXT_WIDTH, 1),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local progress = Builder.label({
		parent = line,
		name = "Progress",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(OBJECTIVE_TEXT_WIDTH + 0.02, 0),
		size = UDim2.fromScale(1 - OBJECTIVE_TEXT_WIDTH - 0.02, 1),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})
	return { frame = line, text = text, progress = progress }
end

local function ensureLines(row: Row, count: number)
	while #row.lines < count do
		table.insert(row.lines, buildObjectiveLine(row.objectives, #row.lines + 1))
	end
end

local function buildRow(parent: Frame, index: number): Row
	local card = Builder.frame({
		parent = parent,
		name = "Step" .. index,
		size = UDim2.fromScale(1, ROW_COMPACT),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	card.LayoutOrder = index

	local badge = Builder.pill({
		parent = card,
		name = "Badge",
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Text,
		aspect = 1,
		zIndex = 4,
	})
	Builder.gradient(badge, Theme.Rarity.Common)
	local badgeLabel = Builder.label({
		parent = badge,
		name = "Index",
		text = tostring(index),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.85),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	local title = Builder.label({
		parent = card,
		name = "Title",
		text = "",
		textSize = Theme.TextSize.Label,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local status = Builder.label({
		parent = card,
		name = "Status",
		text = "",
		textSize = Theme.TextSize.Body,
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})

	-- Expanded-only children: the legend (navy, no stroke: long text on a light card),
	-- the objectives under a yellow heading, the rewards line and the Claim button.
	local legend = Builder.label({
		parent = card,
		name = "Legend",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.09, 0.2),
		size = UDim2.fromScale(0.88, 0.2),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	legend.TextYAlignment = Enum.TextYAlignment.Top
	local todo = Builder.label({
		parent = card,
		name = "ToDo",
		text = Strings.QUESTS_OBJECTIVES,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0.09, 0.42),
		size = UDim2.fromScale(0.5, 0.11),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local objectives = Builder.frame({
		parent = card,
		name = "Objectives",
		position = UDim2.fromScale(0.09, 0.53),
		size = UDim2.fromScale(0.55, 0.27),
		zIndex = 4,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = objectives
	local rewardHeading = Builder.label({
		parent = card,
		name = "RewardHeading",
		text = Strings.QUESTS_REWARDS,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0.09, 0.82),
		size = UDim2.fromScale(0.16, 0.14),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local rewards = Builder.label({
		parent = card,
		name = "Rewards",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.26, 0.82),
		size = UDim2.fromScale(0.38, 0.14),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local claimButton = Builder.button({
		parent = card,
		name = "Claim",
		text = Strings.QUESTS_CLAIM,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.97, 0.9),
		size = UDim2.fromScale(0.3, 0.42),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, claim)

	return {
		card = card,
		badge = badge,
		badgeLabel = badgeLabel,
		title = title,
		status = status,
		legend = legend,
		todo = todo,
		objectives = objectives,
		lines = {},
		rewardHeading = rewardHeading,
		rewards = rewards,
		claim = claimButton,
		claimReady = false,
	}
end

local function ensureRows(count: number)
	local parent = list
	if not parent then
		return
	end
	while #rows < count do
		table.insert(rows, buildRow(parent, #rows + 1))
	end
end

-- Positions the shared children for the expanded (current) or compact (claimed, locked) shape.
local function layoutRow(row: Row, expanded: boolean, height: number)
	row.card.Size = UDim2.fromScale(1, height)
	row.status.Visible = not expanded
	row.legend.Visible = expanded
	row.todo.Visible = expanded
	row.objectives.Visible = expanded
	row.rewardHeading.Visible = expanded
	row.rewards.Visible = expanded
	row.claim.Visible = expanded
	row.badge.AnchorPoint = Vector2.new(0, 0.5)
	if expanded then
		row.badge.Position = UDim2.fromScale(0.012, 0.11)
		row.badge.Size = UDim2.fromScale(0.07, 0.17)
		row.title.Position = UDim2.fromScale(0.09, 0.02)
		row.title.Size = UDim2.fromScale(0.6, 0.18)
	else
		row.badge.Position = UDim2.fromScale(0.012, 0.5)
		row.badge.Size = UDim2.fromScale(0.06, 0.78)
		row.title.Position = UDim2.fromScale(0.08, 0.1)
		row.title.Size = UDim2.fromScale(0.42, 0.8)
		row.status.Position = UDim2.fromScale(0.52, 0.1)
		row.status.Size = UDim2.fromScale(0.46, 0.8)
	end
end

-- Fills the current step's card: legend, each objective with its count (green once met), the rewards
-- line and the Claim button's colour. Returns whether every objective is met.
local function fillCurrent(row: Row, step: Quests.Step, progress: { [string]: number }): boolean
	row.legend.Text = Builder.text("FN_" .. step.id .. "_LEGEND")
	local count = #step.objectives
	ensureLines(row, count)
	local allDone = count > 0
	for index, line in ipairs(row.lines) do
		local objective = step.objectives[index]
		if not objective then
			line.frame.Visible = false
			continue
		end
		line.frame.Visible = true
		line.frame.Size = UDim2.fromScale(1, 1 / count)
		local have = progress[objective.id] or 0
		local done = have >= objective.count
		if not done then
			allDone = false
		end
		local color = if done then Theme.Colors.Confirm else Theme.Colors.White
		line.text.Text = objectiveText(objective)
		line.text.TextColor3 = color
		line.progress.Text = Strings.OBJ_PROGRESS:format(math.min(have, objective.count), objective.count)
		line.progress.TextColor3 = color
	end
	row.rewards.Text = rewardsLine(step)
	recolorButton(row.claim, if allDone then Theme.Colors.Confirm else Theme.Rarity.Common)
	if allDone and not row.claimReady then
		Builder.pop(row.claim, 1.12) -- the button turning green is the moment the board asks for a tap
	end
	row.claimReady = allDone
	return allDone
end

local function refreshNotes()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local world = profile.world.current
	local steps: { Quests.Step }? = Quests.FieldNotes[world]
	local quests = State.GetQuests()
	local total = if steps then #steps else 0
	claimReady = false
	claimRewards = ""

	if not steps or total == 0 then
		-- No chain for this world yet: an empty board.
		for _, row in ipairs(rows) do
			row.card.Visible = false
		end
		if stepLabel then
			stepLabel.Text = ""
		end
		if doneLabel then
			doneLabel.Visible = false
		end
		return
	end

	local index = quests.fieldNotes[tostring(world)] or 1
	local finished = index > total
	ensureRows(total)
	if stepLabel then
		stepLabel.Text = Strings.QUESTS_STEP:format(math.min(index, total), total)
	end
	local compactCount = if finished then total else total - 1
	local expandedHeight = math.max(MIN_EXPANDED, 1 - compactCount * (ROW_COMPACT + ROW_GAP))

	for i, row in ipairs(rows) do
		local step: Quests.Step? = steps[i]
		if not step then
			row.card.Visible = false
			continue
		end
		row.card.Visible = true
		row.title.Text = Builder.text("FN_" .. step.id .. "_TITLE")
		if i < index then
			-- Claimed: compact, green.
			layoutRow(row, false, ROW_COMPACT)
			setCardStyle(row, Theme.Colors.White, Theme.Colors.Confirm)
			row.status.Text = Strings.QUESTS_CLAIMED
			row.status.TextColor3 = Theme.Colors.Confirm
			row.claimReady = false
		elseif i == index then
			-- Current: the big card.
			layoutRow(row, true, expandedHeight)
			setCardStyle(row, Theme.Colors.White, Theme.Colors.Featured)
			claimReady = fillCurrent(row, step, quests.progress)
			claimRewards = row.rewards.Text
		else
			-- Locked: compact, dimmed, waiting on the step above.
			layoutRow(row, false, ROW_COMPACT)
			setCardStyle(row, Builder.lighter(Theme.Rarity.Common, 0.6), Theme.Rarity.Common)
			row.status.Text = Strings.QUESTS_LOCKED_HINT
			row.status.TextColor3 = Theme.Colors.White
			row.claimReady = false
		end
	end
	if doneLabel then
		doneLabel.Visible = finished
	end
end

-- Daily & Weekly ------------------------------------------------------------

local function setFaceText(container: Frame, text: string)
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = text
	end
end

-- Colours a progress fill (face and its gradient).
local function tintFill(fill: Frame, color: Color3)
	fill.BackgroundColor3 = color
	local gradient = fill:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(color), color)
	end
end

-- Asks the server for both sets and their reset instants; State mirrors the answer and fires "quests".
-- A nil answer (rate limited, profile not loaded) leaves the mirror as it was.
local function fetchDaily()
	if fetching then
		return
	end
	fetching = true
	task.spawn(function()
		local result: any = Net.func("GetDailyQuests"):InvokeServer()
		fetching = false
		if
			type(result) == "table"
			and type(result.daily) == "table"
			and type(result.weekly) == "table"
			and type(result.dailyResetsAt) == "number"
			and type(result.weeklyResetsAt) == "number"
		then
			State.SetDailyQuests(result)
		end
	end)
end

-- Claim tap on a daily or weekly row. A row that is not finished still asks: the server answers NotDone and
-- the toast says so. A refusal that means the mirror is stale (NotDealt, AlreadyClaimed) pulls a fresh copy.
local function claimDaily(row: DailyRow)
	if dailyPending or row.questId == "" or row.claimed then
		return
	end
	local period: string = row.period
	local id = row.questId
	local summary = row.objectiveText
	dailyPending = true
	task.spawn(function()
		local ok, reason = Net.func("ClaimDailyQuest"):InvokeServer(period, id)
		dailyPending = false
		if ok == true then
			Toast.Show(Strings.TOAST_DQ_CLAIMED:format(summary), Theme.Colors.Confirm)
		elseif reason == "NotDone" then
			Toast.Show(Strings.TOAST_DQ_NOT_DONE, Theme.Colors.Select)
		else
			print(("[%s] ClaimDailyQuest refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			if reason == "NotDealt" or reason == "AlreadyClaimed" then
				fetchDaily()
			end
		end
	end)
end

-- Reroll tap on a daily row (the server swaps the quest and pushes the new set).
local function rerollDaily(row: DailyRow)
	if dailyPending or row.questId == "" or row.claimed then
		return
	end
	local id = row.questId
	dailyPending = true
	task.spawn(function()
		local ok, reason = Net.func("RerollDailyQuest"):InvokeServer(id)
		dailyPending = false
		if ok == true then
			Toast.Show(Strings.TOAST_DQ_REROLLED, Theme.Colors.Confirm)
		elseif reason == "NoRerolls" then
			Toast.Show(Strings.TOAST_DQ_NO_REROLL, Theme.Colors.Select)
		else
			print(("[%s] RerollDailyQuest refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			if reason == "NotDealt" or reason == "AlreadyClaimed" then
				fetchDaily()
			end
		end
	end)
end

-- Top of a row in canvas scale: `section` 0 for the daily set, 1 for the weekly one.
local function rowTop(section: number, slot: number): number
	return (section * DQ_SECTION_H + DQ_HEAD_H + DQ_GAP + (slot - 1) * (DQ_ROW_H + DQ_GAP)) / DQ_PAGES
end

-- One quest card, the look of the Daily & Weekly list and of the Event tab: objective on top, the reward under it,
-- the progress bar at the bottom; the Claim button on the right (over a Reroll on a daily; a single taller one,
-- centred, when `tall`). `onClaim` is the tap.
type CardParts = { card: Frame, objective: TextLabel, reward: TextLabel, fill: Frame, count: TextLabel, claim: Frame }

local function buildQuestCard(parent: Instance, name: string, position: UDim2, size: UDim2, tall: boolean, claimText: string, onClaim: () -> ()): CardParts
	local card = Builder.frame({
		parent = parent,
		name = name,
		position = position,
		size = size,
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	local objective = Builder.label({
		parent = card,
		name = "Objective",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.025, 0.04),
		size = UDim2.fromScale(0.58, 0.44),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local reward = Builder.label({
		parent = card,
		name = "Reward",
		text = "",
		textSize = Theme.TextSize.Body,
		stroke = 2,
		position = UDim2.fromScale(0.025, 0.49),
		size = UDim2.fromScale(0.58, 0.22),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local trough = Builder.pill({
		parent = card,
		name = "Trough",
		position = UDim2.fromScale(0.025, 0.73),
		size = UDim2.fromScale(0.58, 0.23),
		color = Theme.Colors.Trough,
		zIndex = 4,
	})
	local fill = Builder.pill({
		parent = trough,
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		color = Theme.Colors.Select,
		zIndex = 5,
	})
	Builder.gradient(fill, Theme.Colors.Select)
	local count = Builder.label({
		parent = trough,
		name = "Count",
		text = "",
		textSize = Theme.TextSize.Body,
		stroke = 2,
		zIndex = 6,
	})
	local claim = Builder.button({
		parent = card,
		name = "Claim",
		text = claimText,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.98, if tall then 0.5 else 0.06),
		size = UDim2.fromScale(0.34, if tall then 0.6 else 0.42),
		anchor = Vector2.new(1, if tall then 0.5 else 0),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, onClaim)
	return { card = card, objective = objective, reward = reward, fill = fill, count = count, claim = claim }
end

-- One daily or weekly card: the shared card, plus a Reroll button under the Claim of a daily.
local function buildDailyRow(parent: ScrollingFrame, period: "daily" | "weekly", slot: number): DailyRow
	local daily = period == "daily"
	local ref: DailyRow? = nil
	local parts = buildQuestCard(
		parent,
		(if daily then "Daily" else "Weekly") .. slot,
		UDim2.fromScale(0, rowTop(if daily then 0 else 1, slot)),
		UDim2.fromScale(1, DQ_ROW_H / DQ_PAGES),
		not daily,
		Strings.DQ_CLAIM,
		function()
			local row = ref
			if row then
				claimDaily(row)
			end
		end
	)
	local reroll: Frame? = nil
	if daily then
		reroll = Builder.button({
			parent = parts.card,
			name = "Reroll",
			text = Strings.DQ_REROLL,
			color = Theme.Colors.Select,
			position = UDim2.fromScale(0.98, 0.94),
			size = UDim2.fromScale(0.34, 0.38),
			anchor = Vector2.new(1, 1),
			textSize = Theme.TextSize.Body,
			zIndex = 4,
		}, function()
			local row = ref
			if row then
				rerollDaily(row)
			end
		end)
	end

	local row: DailyRow = {
		period = period,
		slot = slot,
		card = parts.card,
		objective = parts.objective,
		reward = parts.reward,
		fill = parts.fill,
		count = parts.count,
		claim = parts.claim,
		reroll = reroll,
		questId = "",
		objectiveText = "",
		claimed = false,
		claimReady = false,
	}
	ref = row
	return row
end

-- The two "Resets in ..." lines, from the last snapshot's instants and the server clock.
local function updateCountdowns()
	local dailyAt, weeklyAt = State.GetQuestResets()
	local now = State.Now()
	local dailyLabel, weeklyLabel = dailyCountdown, weeklyCountdown
	if dailyLabel then
		dailyLabel.Text = if dailyAt > 0 then Strings.DQ_RESETS:format(timeLeftText(dailyAt - now, false)) else ""
	end
	if weeklyLabel then
		weeklyLabel.Text = if weeklyAt > 0 then Strings.DQ_RESETS:format(timeLeftText(weeklyAt - now, true)) else ""
	end
end

-- Fills every row from the profile mirror: the dealt ids, their progress and claimed flags, the reroll count.
local function refreshDaily()
	local quests = State.Get().quests
	for _, row in ipairs(dailyRows) do
		local isDaily = row.period == "daily"
		local state = if isDaily then quests.daily else quests.weekly
		local byId = if isDaily then dailyById else weeklyById
		local id: string? = state.ids[row.slot]
		local quest: DailyQuests.Quest? = if id then byId[id] else nil
		if not id or not quest then
			row.card.Visible = false
			row.questId = ""
			row.claimed = false
			row.claimReady = false
			continue
		end
		local need = quest.objective.count
		local have = math.min(state.progress[id] or 0, need)
		local claimed = state.claimed[id] == true
		local ready = not claimed and have >= need
		row.card.Visible = true
		row.questId = id
		row.objectiveText = dailyObjectiveText(quest.objective)
		row.objective.Text = row.objectiveText
		row.reward.Text = rewardsList(quest.rewards)
		row.count.Text = Strings.OBJ_PROGRESS:format(have, need)
		row.fill.Size = UDim2.fromScale(if need > 0 then have / need else 1, 1)
		tintFill(row.fill, if have >= need then Theme.Colors.Confirm else Theme.Colors.Select)

		local dim = Builder.lighter(Theme.Rarity.Common, 0.45)
		local card = row.card
		card.BackgroundColor3 = if claimed then Builder.lighter(Theme.Rarity.Common, 0.6) else Theme.Colors.White
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if ready then Theme.Colors.Confirm else Theme.Rarity.Common
		end
		recolorButton(row.claim, if ready then Theme.Colors.Confirm elseif claimed then dim else Theme.Rarity.Common)
		setFaceText(row.claim, if claimed then Strings.DQ_CLAIMED else Strings.DQ_CLAIM)
		if ready and not row.claimReady then
			Builder.pop(row.claim, 1.12) -- the button turning green is the moment the list asks for a tap
		end
		row.claimed = claimed
		row.claimReady = ready

		local reroll = row.reroll
		if reroll then
			local spent = claimed or state.rerolls >= DailyQuests.RerollsPerDay
			recolorButton(reroll, if spent then dim else Theme.Colors.Select)
			setFaceText(reroll, if spent then Strings.DQ_REROLL_USED else Strings.DQ_REROLL)
		end
	end
	updateCountdowns()
end

-- Event ---------------------------------------------------------------------

-- Claim tap on an event row. A row that is not finished still asks (the dim button stays tappable): the server
-- answers NotDone and the mirror is not touched. A row the mirror already shows as claimed sends nothing. The
-- rewards line is read before the call, since the server's push can redraw the row before the answer lands. A
-- row that paid an alien comes back with its GrantResult, which the bootstrap turns into the Reveal.
local function claimEvent(row: EventRow)
	if eventPending or row.questId == "" or row.claimed then
		return
	end
	local id = row.questId
	local summary = row.rewardsText
	eventPending = true
	task.spawn(function()
		local ok, reason, raw = Net.func("ClaimSeasonQuest"):InvokeServer(id)
		eventPending = false
		if ok == true then
			Builder.playSound(Sounds.GiftClaim)
			Toast.Show(Strings.TOAST_SEASON_CLAIMED:format(summary), Theme.Colors.Confirm)
			local grant = raw :: Types.GrantResult?
			local callback = onGrant
			if grant and callback then
				callback(grant)
			end
		else
			-- Claimed (the mirror was behind) and NotDone need no words: the row redraws from the server's push.
			print(("[%s] ClaimSeasonQuest refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

local function buildEventRow(parent: ScrollingFrame, index: number): EventRow
	local ref: EventRow? = nil
	local parts = buildQuestCard(
		parent,
		"Event" .. index,
		UDim2.fromScale(0, 0), -- layoutEvent places it
		UDim2.fromScale(1, 0.1),
		true,
		Strings.EVENT_CLAIM,
		function()
			local row = ref
			if row then
				claimEvent(row)
			end
		end
	)
	local row: EventRow = {
		card = parts.card,
		objective = parts.objective,
		reward = parts.reward,
		fill = parts.fill,
		count = parts.count,
		claim = parts.claim,
		questId = "",
		rewardsText = "",
		claimed = false,
		claimReady = false,
	}
	ref = row
	return row
end

-- Sizes the canvas for `count` rows and places the title, the hint and every row (children are fractions of the
-- canvas, no layout objects, so nothing feeds back into the canvas).
local function layoutEvent(count: number)
	local frame, title, hint = eventScroller, eventTitle, eventHint
	if not frame or not title or not hint then
		return
	end
	local pages = EV_HEAD_H + EV_HINT_H + count * (EV_ROW_H + EV_GAP)
	frame.CanvasSize = UDim2.fromScale(0, pages * EV_LIST_SHARE)
	title.Position = UDim2.fromScale(0.01, 0)
	title.Size = UDim2.fromScale(0.98, EV_HEAD_H / pages)
	hint.Position = UDim2.fromScale(0.01, EV_HEAD_H / pages)
	hint.Size = UDim2.fromScale(0.98, EV_HINT_H / pages)
	for index, row in ipairs(eventRows) do
		row.card.Position = UDim2.fromScale(0, (EV_HEAD_H + EV_HINT_H + (index - 1) * (EV_ROW_H + EV_GAP)) / pages)
		row.card.Size = UDim2.fromScale(1, EV_ROW_H / pages)
	end
end

-- Fills the Event tab from the running season and the track mirror: one card per track quest in order, its
-- objective, the rewards, n/N, and the Claim button (green when done and unclaimed, Common grey reading Done once
-- claimed, dim otherwise but still tappable).
local function refreshEvent()
	local current = State.GetSeason()
	local frame, title = eventScroller, eventTitle
	if not current or not frame or not title then
		return
	end
	local season = current.season
	local track = season.track
	title.Text = Strings.EVENT_TRACK_TITLE:format(Builder.text("SEASON_" .. season.id))
	-- The saved counts count only for the season they belong to: after a change the old track stays in the mirror
	-- until the answer for the new one lands.
	local savedId, saved = State.GetSeasonProgress()
	local progress: { [string]: number } = if savedId == season.id and saved then saved.progress else {}
	local claimedIds: { [string]: boolean } = if savedId == season.id and saved then saved.claimed else {}
	while #eventRows < #track do
		table.insert(eventRows, buildEventRow(frame, #eventRows + 1))
	end
	layoutEvent(#track)
	local dim = Builder.lighter(Theme.Rarity.Common, 0.45)
	for index, row in ipairs(eventRows) do
		local quest: Seasons.Quest? = track[index]
		if not quest then
			row.card.Visible = false
			row.questId = ""
			row.claimed = false
			row.claimReady = false
			continue
		end
		local need = quest.objective.count
		local have = math.min(progress[quest.id] or 0, need)
		local claimed = claimedIds[quest.id] == true
		local ready = not claimed and SeasonMath.TrackDone(quest, progress)
		row.card.Visible = true
		row.questId = quest.id
		row.rewardsText = seasonRewardsLine(quest.rewards)
		row.objective.Text = seasonObjectiveText(quest.objective, season)
		row.reward.Text = row.rewardsText
		row.count.Text = Strings.OBJ_PROGRESS:format(have, need)
		row.fill.Size = UDim2.fromScale(if need > 0 then have / need else 1, 1)
		tintFill(row.fill, if have >= need then Theme.Colors.Confirm else Theme.Colors.Select)
		row.card.BackgroundColor3 = if claimed then Builder.lighter(Theme.Rarity.Common, 0.6) else Theme.Colors.White
		local stroke = row.card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if ready then Theme.Colors.Confirm else Theme.Rarity.Common
		end
		recolorButton(row.claim, if ready then Theme.Colors.Confirm elseif claimed then Theme.Rarity.Common else dim)
		setFaceText(row.claim, if claimed then Strings.EVENT_CLAIMED else Strings.EVENT_CLAIM)
		if ready and not row.claimReady then
			Builder.pop(row.claim, 1.12) -- the button turning green is the moment the list asks for a tap
		end
		row.claimed = claimed
		row.claimReady = ready
	end
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	if view == "daily" then
		refreshDaily()
	elseif view == "event" then
		refreshEvent()
	else
		refreshNotes()
	end
end

-- Seconds until the next whole-minute change in either countdown (at most a minute, at least a second).
local function secondsToNextMinute(): number
	local now = State.Now()
	local dailyAt, weeklyAt = State.GetQuestResets()
	local wait = MINUTE
	for _, target in ipairs({ dailyAt, weeklyAt }) do
		local left = target - now
		if left > 0 then
			wait = math.min(wait, left % MINUTE)
		end
	end
	return math.max(1, wait) + 0.2
end

local function stopTicker()
	tickToken += 1
end

-- Redraws the countdowns once a minute while the Daily & Weekly tab is showing; ends when the tab is left
-- or the screen closes (the token changes, or open/view no longer hold). A reset instant that has passed
-- means the server has dealt new sets, so the loop asks for them once per instant.
local function startTicker()
	tickToken += 1
	local token = tickToken
	task.spawn(function()
		while open and view == "daily" and token == tickToken do
			updateCountdowns()
			local dailyAt, weeklyAt = State.GetQuestResets()
			local now = State.Now()
			local key = (if dailyAt > 0 and now >= dailyAt then dailyAt else 0) + (if weeklyAt > 0 and now >= weeklyAt then weeklyAt else 0)
			if key > 0 and key ~= staleFetchedFor then
				staleFetchedFor = key
				fetchDaily()
			end
			task.wait(secondsToNextMinute())
		end
	end)
end

-- Places the tabs that show. Without a season there are two, left and right of the centre line (the Event tab is
-- hidden); with one there are three, in thirds of the span left of the Close button. Run whenever the season may
-- have started or ended.
local function layoutTabs()
	local withEvent = State.GetSeason() ~= nil
	local shown: { Tab } = {}
	for _, key in ipairs(TAB_ORDER) do
		local tab = tabs[key]
		if not tab then
			continue
		end
		tab.visible = key ~= "event" or withEvent
		if tab.visible then
			table.insert(shown, tab)
		end
	end
	for index, tab in ipairs(shown) do
		if #shown < TAB_COUNT_WITH_EVENT then
			local left = index == 1
			tab.x = if left then 0.5 - TAB_CENTRE_GAP / 2 else 0.5 + TAB_CENTRE_GAP / 2
			tab.frame.AnchorPoint = Vector2.new(if left then 1 else 0, 0.5)
			tab.frame.Size = UDim2.fromScale(TAB_W, TAB_H)
		else
			tab.x = TAB_SPAN_LEFT + (index - 1) * (TAB_W3 + TAB_GAP)
			tab.frame.AnchorPoint = Vector2.new(0, 0.5)
			tab.frame.Size = UDim2.fromScale(TAB_W3, TAB_H)
		end
	end
end

-- Shows the body of the current view and styles the tabs: the active one raised and in its colour, the
-- other lower and grey; the Event tab only while a season runs.
local function applyView()
	layoutTabs()
	local notes = view == "notes"
	if stepLabel then
		stepLabel.Visible = notes
	end
	if list then
		list.Visible = notes
	end
	if scroller then
		scroller.Visible = view == "daily"
	end
	if eventScroller then
		eventScroller.Visible = view == "event"
	end
	for key, tab in pairs(tabs) do
		local active = key == view
		tab.frame.Visible = tab.visible
		recolorButton(tab.frame, if active then tab.color else Theme.Rarity.Common)
		tab.frame.Position = UDim2.fromScale(tab.x, if active then TAB_RAISED else TAB_LOWERED)
	end
end

local function setView(next: ViewName)
	if view == next then
		return
	end
	if next == "event" and State.GetSeason() == nil then
		return -- the tab is hidden without a season
	end
	view = next
	applyView()
	if next == "daily" then
		fetchDaily()
		startTicker()
	else
		stopTicker()
	end
	if next == "event" and eventScroller then
		eventScroller.CanvasPosition = Vector2.zero -- opens at the title
	end
	refresh()
end

local function buildTab(parent: Frame, key: ViewName, text: string, color: Color3)
	local frame = Builder.button({
		parent = parent,
		name = if key == "notes" then "NotesTab" elseif key == "daily" then "DailyTab" else "EventTab",
		text = text,
		color = color,
		position = UDim2.fromScale(0.5, TAB_LOWERED), -- layoutTabs places it
		size = UDim2.fromScale(TAB_W, TAB_H),
		anchor = Vector2.new(0, 0.5),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		setView(key)
	end)
	tabs[key] = { frame = frame, color = color, x = 0.5, visible = true }
end

-- The season started, moved or ended (or the track's counts changed): the Event tab comes or goes, and if it was
-- the view when the season ended the screen falls back to Field Notes.
local function onSeasonChanged()
	if view == "event" and State.GetSeason() == nil then
		view = "notes"
		stopTicker()
	end
	if gui then
		applyView()
	end
	refresh()
end

-- One section heading inside the scroller: the name on the left, the countdown on the right.
local function buildHeading(parent: ScrollingFrame, section: number, text: string): TextLabel
	local top = section * DQ_SECTION_H / DQ_PAGES
	local height = DQ_HEAD_H / DQ_PAGES
	Builder.label({
		parent = parent,
		name = if section == 0 then "DailyHeading" else "WeeklyHeading",
		text = text,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0.01, top),
		size = UDim2.fromScale(0.4, height),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})
	return Builder.label({
		parent = parent,
		name = if section == 0 then "DailyResets" else "WeeklyResets",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.42, top),
		size = UDim2.fromScale(0.57, height),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 3,
	})
end

-- The Daily & Weekly list: a ScrollingFrame with a thin dark bar, both headings and all rows built once.
local function buildDailyList(body: Frame)
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "DailyList"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(Theme.Margin, LIST_TOP)
	frame.Size = UDim2.fromScale(1 - Theme.Margin * 2, 1 - LIST_TOP - Theme.Margin)
	frame.ZIndex = 3
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	frame.CanvasSize = UDim2.fromScale(0, DQ_PAGES)
	frame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	frame.ScrollBarThickness = SCROLLBAR_PX
	frame.ScrollBarImageColor3 = Theme.Colors.Trough
	frame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	frame.Visible = false
	frame.Parent = body
	scroller = frame

	dailyCountdown = buildHeading(frame, 0, Strings.DQ_DAILY)
	weeklyCountdown = buildHeading(frame, 1, Strings.DQ_WEEKLY)
	dailyRows = {}
	for slot = 1, DailyQuests.DailyCount do
		table.insert(dailyRows, buildDailyRow(frame, "daily", slot))
	end
	for slot = 1, DailyQuests.WeeklyCount do
		table.insert(dailyRows, buildDailyRow(frame, "weekly", slot))
	end
end

-- The Event tab's list: a ScrollingFrame with the same thin dark bar, the title in the section-heading yellow and
-- the hint in helper text (navy, no outline) built once; the rows are added and placed by refreshEvent, since how
-- many there are is the running season's track.
local function buildEventList(body: Frame)
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "EventList"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(Theme.Margin, LIST_TOP)
	frame.Size = UDim2.fromScale(1 - Theme.Margin * 2, EV_LIST_SHARE)
	frame.ZIndex = 3
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	frame.CanvasSize = UDim2.fromScale(0, EV_LIST_SHARE)
	frame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	frame.ScrollBarThickness = SCROLLBAR_PX
	frame.ScrollBarImageColor3 = Theme.Colors.Trough
	frame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	frame.Visible = false
	frame.Parent = body
	eventScroller = frame

	eventTitle = Builder.label({
		parent = frame,
		name = "EventTitle",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})
	eventHint = Builder.label({
		parent = frame,
		name = "EventHint",
		text = Strings.EVENT_TRACK_HINT,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})
	eventRows = {}
	layoutEvent(0)
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("QuestsScreen", 20)
	root.Enabled = false
	gui = root

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		QuestsScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.35,
		zIndex = 2,
	})
	panel = body

	-- Header tabs straddling the top edge: Field Notes (gold), Daily & Weekly (blue) and, while a season runs,
	-- Event (Codex purple). The tapped one is raised and bright, the others lower and grey; layoutTabs spaces
	-- them (applyView).
	buildTab(body, "notes", Strings.DQ_TAB_NOTES, NOTES_COLOR)
	buildTab(body, "daily", Strings.DQ_TAB_DAILY, DAILY_COLOR)
	buildTab(body, "event", Strings.DQ_TAB_EVENT, EVENT_COLOR)

	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(0.985, 0.015),
		size = UDim2.fromScale(0.11, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		QuestsScreen.Close()
	end)

	stepLabel = Builder.label({
		parent = body,
		name = "Step",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(Theme.Margin, 0.085),
		size = UDim2.fromScale(0.84, 0.065),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})

	local stepsFrame = Builder.frame({
		parent = body,
		name = "Steps",
		position = UDim2.fromScale(Theme.Margin, LIST_TOP),
		size = UDim2.fromScale(1 - Theme.Margin * 2, 1 - LIST_TOP - Theme.Margin),
		zIndex = 3,
	})
	stepsFrame.ClipsDescendants = true
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = stepsFrame
	list = stepsFrame

	-- The done line sorts after every step row and only shows once the chain is finished.
	local done = Builder.label({
		parent = stepsFrame,
		name = "Done",
		text = Strings.QUESTS_DONE,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(0.9, DONE_HEIGHT),
		color = Theme.Colors.Featured,
		zIndex = 3,
	})
	done.LayoutOrder = 1000
	done.Visible = false
	doneLabel = done

	buildDailyList(body)
	buildEventList(body)
	applyView()

	-- Server pushes: redraw whenever the quest mirror changes (cheap while closed: refresh returns early).
	State.OnChanged("quests", refresh)
	State.OnChanged("season", onSeasonChanged) -- the season starts or ends, or its track's counts change
end

-- Public API -------------------------------------------------------------

function QuestsScreen.IsOpen(): boolean
	return open
end

-- The bootstrap's hook for an alien an event row paid: the server's GrantResult, to show as a Reveal (as a gift egg).
function QuestsScreen.OnGrant(callback: (Types.GrantResult) -> ())
	onGrant = callback
end

-- The reward line ("500 Scrap, 2 x Twig Lure") for a daily quest's or a promo code's reward list.
function QuestsScreen.RewardsText(rewards: { DailyQuests.Reward }): string
	return rewardsList(rewards)
end

function QuestsScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	view = "notes" -- always opens on the Field Notes, whichever tab was showing last
	applyView()
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function QuestsScreen.Close()
	if not open then
		return
	end
	open = false
	stopTicker()
	local root, body = gui, panel
	if root and body then
		Builder.close(body, function()
			if not open then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

function QuestsScreen.Toggle()
	if open then
		QuestsScreen.Close()
	else
		QuestsScreen.Open()
	end
end

return QuestsScreen
