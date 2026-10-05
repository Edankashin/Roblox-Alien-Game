--!strict
-- StarterPlayerScripts.Client.UI.QuestsScreen: the Field Notes panel, a quest board for the current
-- world's chain (Quests.FieldNotes[world]). The chain is one list in order: finished steps as compact
-- rows marked Claimed, the current step as a big card (title, legend, the objectives with their counts,
-- the rewards and a Claim button that turns green when every objective is met), and the later steps as
-- compact dimmed rows. Past the last step the whole chain is compact under a done line. Everything
-- shown is read from the profile mirror in State and the shared data tables; the Claim tap asks the
-- server (QuestClaim), which advances the step and pushes QuestsChanged. Nothing here decides an
-- outcome: a grey Claim button only clicks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("data"):WaitForChild("Quests"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
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

local LIST_TOP = 0.155 -- below the step header line
local ROW_COMPACT = 0.1 -- of the list height
local ROW_GAP = 0.012
local MIN_EXPANDED = 0.45 -- the current step's card never shrinks below this, whatever the chain length
local DONE_HEIGHT = 0.3 -- the done line under a finished chain
local OBJECTIVE_TEXT_WIDTH = 0.78 -- the rest of an objective line is its count

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

-- Text --------------------------------------------------------------------

-- The OBJ_<kind> template filled by kind: counts, tier names and condition phrases from the strings table.
local function objectiveText(objective: Quests.Objective): string
	local template = Builder.text("OBJ_" .. objective.kind)
	local kind = objective.kind
	local tier = Builder.text("TIER_" .. (objective.tier or "Common"))
	local phrase = Builder.text("COND_PHRASE_" .. (objective.condition or "Any"))
	if kind == "catchCount" then
		return template:format(objective.count)
	elseif kind == "catchCondition" or kind == "soundHorn" then
		return template:format(phrase)
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

-- The REWARD_<kind> template filled by kind; an encounter names the species.
local function rewardText(reward: Quests.Reward): string
	local template = Builder.text("REWARD_" .. reward.kind)
	local kind = reward.kind
	local id = reward.id or ""
	local amount = reward.amount or 0
	if kind == "gear" then
		return template:format(Builder.text("GEAR_" .. id))
	elseif kind == "lure" then
		return template:format(amount, Builder.text("LURE_" .. id))
	elseif kind == "scrap" then
		return template:format(Builder.formatNumber(amount))
	elseif kind == "spin" then
		return template:format(amount)
	elseif kind == "item" then
		return template:format(Builder.text("ITEM_" .. id))
	elseif kind == "encounter" then
		local def = Species.ById[id]
		return template:format(if def then def.name else id)
	end
	return template
end

local function rewardsLine(step: Quests.Step): string
	local parts: { string } = {}
	for _, reward in ipairs(step.rewards) do
		table.insert(parts, rewardText(reward))
	end
	return table.concat(parts, ", ")
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

	-- Expanded-only children: the legend in the body font (navy, no stroke: long text on a white card),
	-- the objectives under a yellow heading, the rewards line and the Claim button.
	local legend = Builder.label({
		parent = card,
		name = "Legend",
		text = "",
		textSize = Theme.TextSize.Body,
		font = Theme.BodyFont,
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

local function refresh()
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

	-- Header tab straddling the top edge, gold for the Field Notes, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.QUESTS_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

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

	-- Server pushes: redraw whenever the quest mirror changes (cheap while closed: refresh returns early).
	State.OnChanged("quests", refresh)
end

-- Public API -------------------------------------------------------------

function QuestsScreen.IsOpen(): boolean
	return open
end

function QuestsScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function QuestsScreen.Close()
	if not open then
		return
	end
	open = false
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
