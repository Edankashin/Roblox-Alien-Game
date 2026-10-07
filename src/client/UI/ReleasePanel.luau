--!strict
-- StarterPlayerScripts.Client.UI.ReleasePanel: the card over the Aliens screen where aliens are released for Scrap
-- (data/Storage, milestone 50). One card, three views:
--   alien   opened by holding an alien's card: its name, tier and level, a Release button that shows "+N Scrap", a second
--           tap on it within Storage.ConfirmSeconds to confirm (the button turns red and reads "Tap again to release"),
--           or, for an alien that works, follows or is on display, a grey disabled button and the reason in words;
--   menu    "Release all unused Commons" and "... Uncommons" (data/Storage BulkReleaseTiers), each with how many aliens
--           and how much Scrap it would pay, and a hint about holding a card;
--   confirm after a menu button: "Release 312 Common aliens for +1,560 Scrap?" with Cancel and Release.
-- The counts and values are StorageMath over the profile mirror, so the card shows what the server will do; the
-- server decides (ReleaseAliens, ReleaseAllOfTier, which re-check everything) and the cards redraw from its pushes.
-- Nothing here changes the mirror. The card lives in the Aliens screen's ScreenGui and closes with it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local StorageMath = require(Shared:WaitForChild("StorageMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Storage = require(Shared:WaitForChild("data"):WaitForChild("Storage"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local ReleasePanel = {}

type View = "alien" | "menu" | "confirm"
-- One "Release all unused <tier>" row of the menu: its button, its count line and what the mirror says it would release.
type BulkRow = { tier: string, button: Frame, info: TextLabel, count: number, scrap: number }

-- The card, as fractions of the screen; the aspect keeps it in proportion at any size. At iPhone SE (667x375) it is
-- about 328x262 px.
local CARD_POSITION = UDim2.fromScale(0.5, 0.55)
local CARD_SIZE = UDim2.fromScale(0.54, 0.7)
local CARD_ASPECT = 1.25
local DIM_Z = 20 -- over the Aliens panel (2) and everything in it
local CARD_Z = DIM_Z + 1
local BODY_Z = DIM_Z + 2

-- Fractions of the card.
local TITLE_Y = 0.03
local TITLE_H = 0.13
local TITLE_W = 0.7
local INFO_Y = 0.17
local INFO_H = 0.085
local SWATCH_Y = 0.27
local SWATCH_H = 0.23
local REASON_Y = 0.52
local REASON_H = 0.19
local BUTTONS_Y = 0.75
local BUTTONS_H = 0.2
local CANCEL_X = 0.04
local CANCEL_W = 0.3
local ACT_X = 0.38
local ACT_W = 0.58
local ROW_Y = 0.2 -- the first bulk row's button; each row steps down by ROW_STEP
local ROW_H = 0.14
local ROW_INFO_H = 0.07
local ROW_STEP = 0.27
local HINT_Y = 0.78
local HINT_H = 0.1
local QUESTION_Y = 0.22
local QUESTION_H = 0.45
local MARGIN = 0.04
local CLOSE_X = 0.985
local CLOSE_Y = 0.02
local CLOSE_W = 0.14
local CLOSE_H = 0.17

local dim: TextButton? = nil
local card: Frame? = nil
local titleLabel: TextLabel? = nil
local pages: { [string]: Frame } = {}
local swatch: Frame? = nil
local infoLabel: TextLabel? = nil
local reasonLabel: TextLabel? = nil
local releaseButton: Frame? = nil
local questionLabel: TextLabel? = nil
local rows: { BulkRow } = {}

local isOpen = false
local view: View = "menu"
local currentUid: string? = nil
local currentName = ""
local confirmTier = "" -- the tier the confirm view is about
local armed = false -- the Release button was tapped once and waits for its second tap
local armToken = 0
local busy = false -- one request in flight at a time

-- Helpers ----------------------------------------------------------------

local function tierOf(record: Types.AlienRecord): Types.Tier
	local def = Species.ById[record.species]
	return if def then def.tier else "Common"
end

-- The words for why an alien cannot be released, or nil when it can.
local function reasonText(reason: StorageMath.InUseReason?): string?
	if reason == "Seated" then
		return Strings.RELEASE_REASON_SEATED
	elseif reason == "Following" then
		return Strings.RELEASE_REASON_FOLLOWING
	elseif reason == "Displayed" then
		return Strings.RELEASE_REASON_DISPLAYED
	end
	return nil
end

local function bulkLabel(tier: string): string
	if tier == "Common" then
		return Strings.RELEASE_ALL_COMMON
	elseif tier == "Uncommon" then
		return Strings.RELEASE_ALL_UNCOMMON
	end
	return Strings.RELEASE_ALL_TIER:format(Builder.text("TIER_" .. tier))
end

-- One request that answers (ok, reason, first, second); first and second are the numbers after the reason (the Scrap
-- for ReleaseAliens; the count and the Scrap for ReleaseAllOfTier), 0 when absent. Guarded so an erroring remote
-- never leaves `busy` set. Yields: callers run it inside task.spawn.
local function ask(name: string, ...: any): (boolean, string?, number, number)
	local remote = Net.func(name)
	local called, ok, reason, first, second = pcall(remote.InvokeServer, remote, ...)
	if not called then
		return false, tostring(ok), 0, 0
	end
	return ok == true, if reason ~= nil then tostring(reason) else nil, if type(first) == "number" then first else 0, if type(second) == "number" then second else 0
end

local function show(which: View)
	view = which
	armed = false
	armToken += 1
	for name, page in pairs(pages) do
		page.Visible = name == which
	end
end

-- Views --------------------------------------------------------------------

local hide: () -> ()

local function refreshAlien()
	local uid = currentUid
	if not uid or not State.Has() then
		return
	end
	local profile = State.Get()
	local record = profile.aliens[uid]
	if not record then
		hide() -- released, or fused away, while the card was up
		return
	end
	-- Annotated locals: the type checker widens an unannotated local of a singleton union to string.
	local tier: Types.Tier = tierOf(record)
	local inUse: StorageMath.InUseReason? = StorageMath.InUse(record, profile.companions)
	local why = reasonText(inUse)
	if inUse ~= nil then
		armed = false
	end
	if infoLabel then
		infoLabel.Text = Strings.RELEASE_TIER_LEVEL:format(Builder.text("TIER_" .. tier), record.level)
		infoLabel.TextColor3 = Builder.tierColor(tier)
	end
	if swatch then
		local stroke = swatch:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Builder.tierColor(tier)
		end
	end
	if reasonLabel then
		reasonLabel.Text = why or ""
		reasonLabel.Visible = why ~= nil
	end
	local value = Builder.formatNumber(StorageMath.ReleaseValue(tier))
	if inUse ~= nil then
		Builder.restyleButton(releaseButton, Strings.RELEASE_ALIEN_BUTTON:format(value), Theme.Rarity.Common, false)
	elseif armed then
		Builder.restyleButton(releaseButton, Strings.RELEASE_TAP_AGAIN, Theme.Colors.Close, true)
	else
		Builder.restyleButton(releaseButton, Strings.RELEASE_ALIEN_BUTTON:format(value), Theme.Colors.Featured, true)
	end
end

local function refreshMenu()
	if not State.Has() then
		return
	end
	local profile = State.Get()
	for _, row in ipairs(rows) do
		local uids, scrap = StorageMath.Releasable(profile.aliens, profile.companions, row.tier :: Types.Tier)
		row.count = #uids
		row.scrap = scrap
		if row.count == 0 then
			row.info.Text = Strings.RELEASE_ROW_NONE
		elseif row.count == 1 then
			row.info.Text = Strings.RELEASE_ROW_ONE:format(Builder.formatNumber(row.scrap))
		else
			row.info.Text = Strings.RELEASE_ROW_INFO:format(Builder.formatNumber(row.count), Builder.formatNumber(row.scrap))
		end
		Builder.restyleButton(row.button, bulkLabel(row.tier), if row.count > 0 then Theme.Colors.Featured else Theme.Rarity.Common, row.count > 0)
	end
end

local function refreshConfirm()
	if not State.Has() then
		return
	end
	local profile = State.Get()
	local uids, scrap = StorageMath.Releasable(profile.aliens, profile.companions, confirmTier :: Types.Tier)
	if #uids == 0 then
		show("menu") -- everything it listed went (a fusion, a station taking one): back to the menu
		if titleLabel then
			titleLabel.Text = Strings.RELEASE_TITLE
		end
		refreshMenu()
		return
	end
	if questionLabel then
		questionLabel.Text = Strings.RELEASE_BULK_CONFIRM:format(Builder.formatNumber(#uids), Builder.text("TIER_" .. confirmTier), Builder.formatNumber(scrap))
	end
end

local function refresh()
	if not isOpen then
		return
	end
	if view == "alien" then
		refreshAlien()
	elseif view == "menu" then
		refreshMenu()
	else
		refreshConfirm()
	end
end

-- Requests -----------------------------------------------------------------

-- The second tap: asks the server to release the alien the card shows. The cards redraw from its push.
local function releaseCurrent()
	local uid = currentUid
	if busy or not uid then
		return
	end
	busy = true
	local name = currentName
	task.spawn(function()
		local ok, reason, scrap = ask("ReleaseAliens", { uid })
		busy = false
		if ok then
			Toast.Show(Strings.TOAST_RELEASED_ONE:format(name, Builder.formatNumber(scrap)), Theme.Colors.Featured)
			hide()
			return
		end
		print(("[%s] ReleaseAliens refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		Toast.Show(if reason == "InUse" then Strings.TOAST_RELEASE_INUSE else Strings.TOAST_RELEASE_FAILED, Theme.Rarity.Common)
		armed = false
		refresh()
	end)
end

local function onReleaseTapped()
	if busy or not isOpen or view ~= "alien" or not State.Has() then
		return
	end
	local uid = currentUid
	local record = if uid then State.Get().aliens[uid] else nil
	if not record or StorageMath.InUse(record, State.Get().companions) ~= nil then
		return -- the button is grey and says why
	end
	if armed then
		releaseCurrent()
		return
	end
	armed = true
	armToken += 1
	local mine = armToken
	refreshAlien()
	task.delay(Storage.ConfirmSeconds, function()
		if armToken == mine and armed then
			armed = false
			refreshAlien()
		end
	end)
end

-- The confirm view's Release: asks the server to release every free alien of the tier.
local function releaseTier()
	if busy then
		return
	end
	busy = true
	local tier = confirmTier
	task.spawn(function()
		local ok, reason, count, scrap = ask("ReleaseAllOfTier", tier)
		busy = false
		if ok then
			if count == 0 then
				Toast.Show(Strings.TOAST_RELEASE_FAILED, Theme.Rarity.Common)
			elseif count == 1 then
				Toast.Show(Strings.TOAST_RELEASED_BULK_ONE:format(Builder.formatNumber(scrap)), Theme.Colors.Featured)
			else
				Toast.Show(Strings.TOAST_RELEASED_BULK:format(Builder.formatNumber(count), Builder.formatNumber(scrap)), Theme.Colors.Featured)
			end
			hide()
			return
		end
		print(("[%s] ReleaseAllOfTier refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		Toast.Show(Strings.TOAST_RELEASE_FAILED, Theme.Rarity.Common)
		refresh()
	end)
end

-- Build --------------------------------------------------------------------

local function newPage(parent: Frame, name: string): Frame
	local page = Builder.frame({ parent = parent, name = name, zIndex = BODY_Z })
	page.Visible = false
	pages[name] = page
	return page
end

local function addButtons(page: Frame, actionName: string, onCancel: () -> (), onAction: () -> ()): (Frame, Frame)
	local cancel = Builder.button({
		parent = page,
		name = "Cancel",
		text = Strings.RELEASE_CANCEL,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(CANCEL_X, BUTTONS_Y),
		size = UDim2.fromScale(CANCEL_W, BUTTONS_H),
		textSize = Theme.TextSize.Label,
		zIndex = BODY_Z,
	}, onCancel)
	local action = Builder.button({
		parent = page,
		name = actionName,
		text = Strings.RELEASE_BUTTON,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(ACT_X, BUTTONS_Y),
		size = UDim2.fromScale(ACT_W, BUTTONS_H),
		textSize = Theme.TextSize.Label,
		zIndex = BODY_Z,
	}, onAction)
	return cancel, action
end

local function build(parent: ScreenGui)
	if dim then
		return
	end
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "ReleaseDim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = DIM_Z
	backdrop.Visible = false
	backdrop.Parent = parent
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		hide()
	end)
	dim = backdrop

	-- The card is a sibling of the dim, above it, and Active so a press on it never falls through to the dim (which closes).
	local body = Builder.frame({
		parent = parent,
		name = "ReleaseCard",
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = CARD_ASPECT,
		zIndex = CARD_Z,
	})
	body.Active = true
	body.Visible = false
	card = body

	titleLabel = Builder.label({
		parent = body,
		name = "Title",
		text = Strings.RELEASE_TITLE,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(MARGIN, TITLE_Y),
		size = UDim2.fromScale(TITLE_W, TITLE_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = BODY_Z,
	})
	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(CLOSE_X, CLOSE_Y),
		size = UDim2.fromScale(CLOSE_W, CLOSE_H),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = BODY_Z,
	}, function()
		hide()
	end)

	-- Alien view.
	local alien = newPage(body, "alien")
	infoLabel = Builder.label({
		parent = alien,
		name = "Info",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(MARGIN, INFO_Y),
		size = UDim2.fromScale(1 - MARGIN * 2, INFO_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = BODY_Z,
	})
	swatch = Builder.frame({
		parent = alien,
		name = "Swatch",
		position = UDim2.fromScale(0.5, SWATCH_Y),
		size = UDim2.fromScale(SWATCH_H, SWATCH_H),
		anchor = Vector2.new(0.5, 0),
		corner = Theme.Corner.Card,
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		aspect = 1,
		zIndex = BODY_Z,
	})
	local reason = Builder.label({
		parent = alien,
		name = "Reason",
		text = "",
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(MARGIN, REASON_Y),
		size = UDim2.fromScale(1 - MARGIN * 2, REASON_H),
		zIndex = BODY_Z,
	})
	reason.TextWrapped = true
	reasonLabel = reason
	local _, release = addButtons(alien, "Release", hide, onReleaseTapped)
	releaseButton = release

	-- Menu view: one row per bulk tier, then the hold hint.
	local menu = newPage(body, "menu")
	for index, tier in ipairs(Storage.BulkReleaseTiers) do
		local top = ROW_Y + (index - 1) * ROW_STEP
		local button = Builder.button({
			parent = menu,
			name = "Release" .. tier,
			text = bulkLabel(tier),
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(MARGIN, top),
			size = UDim2.fromScale(1 - MARGIN * 2, ROW_H),
			textSize = Theme.TextSize.Label,
			zIndex = BODY_Z,
		}, function()
			for _, row in ipairs(rows) do
				if row.tier == tier and row.count > 0 and not busy then
					confirmTier = tier
					show("confirm")
					refreshConfirm()
				end
			end
		end)
		local info = Builder.label({
			parent = menu,
			name = "Info" .. tier,
			text = "",
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(MARGIN, top + ROW_H + 0.005),
			size = UDim2.fromScale(1 - MARGIN * 2, ROW_INFO_H),
			zIndex = BODY_Z,
		})
		table.insert(rows, { tier = tier, button = button, info = info, count = 0, scrap = 0 })
	end
	Builder.label({
		parent = menu,
		name = "Hint",
		text = Strings.RELEASE_HOLD_HINT,
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(MARGIN, HINT_Y),
		size = UDim2.fromScale(1 - MARGIN * 2, HINT_H),
		zIndex = BODY_Z,
	})

	-- Confirm view.
	local confirm = newPage(body, "confirm")
	local question = Builder.label({
		parent = confirm,
		name = "Question",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(MARGIN, QUESTION_Y),
		size = UDim2.fromScale(1 - MARGIN * 2, QUESTION_H),
		zIndex = BODY_Z,
	})
	question.TextWrapped = true
	questionLabel = question
	local back, go = addButtons(confirm, "Confirm", function()
		show("menu")
		if titleLabel then
			titleLabel.Text = Strings.RELEASE_TITLE
		end
		refreshMenu()
	end, releaseTier)
	Builder.restyleButton(go, Strings.RELEASE_CONFIRM_BUTTON, Theme.Colors.Close, true)
	back.Name = "Back"

	for _, topic in ipairs({ "stations", "companions" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

local function open()
	local backdrop, body = dim, card
	if not backdrop or not body then
		return
	end
	isOpen = true
	backdrop.Visible = true
	Builder.open(body)
end

hide = function()
	if not isOpen then
		return
	end
	isOpen = false
	armed = false
	armToken += 1
	local backdrop, body = dim, card
	if backdrop and body then
		Builder.close(body, function()
			if not isOpen then
				backdrop.Visible = false
			end
		end)
	end
end

-- Public API -------------------------------------------------------------

-- Creates the card (hidden) inside the Aliens screen's ScreenGui. Safe to call again.
function ReleasePanel.Build(parent: ScreenGui)
	build(parent)
end

function ReleasePanel.IsOpen(): boolean
	return isOpen
end

-- The Release panel for one alien: its uid, the species name for the toast, and the swatch colour.
function ReleasePanel.ShowAlien(uid: string, name: string, color: Color3)
	if not dim or not State.Has() or not State.Get().aliens[uid] then
		return
	end
	currentUid = uid
	currentName = name
	if swatch then
		swatch.BackgroundColor3 = color
	end
	if titleLabel then
		titleLabel.Text = name
	end
	show("alien")
	refreshAlien()
	if not isOpen then
		open()
	end
end

-- The bulk menu: "Release all unused" for each bulk tier.
function ReleasePanel.ShowMenu()
	if not dim or not State.Has() then
		return
	end
	currentUid = nil
	if titleLabel then
		titleLabel.Text = Strings.RELEASE_TITLE
	end
	show("menu")
	refreshMenu()
	if not isOpen then
		open()
	end
end

function ReleasePanel.Hide()
	hide()
end

return ReleasePanel
