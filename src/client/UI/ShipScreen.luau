--!strict
-- StarterPlayerScripts.Client.UI.ShipScreen: the ship panel. Five module rows build in order: the
-- active one is expanded (Pay button, key-part count with an Add button, a live progress bar, the
-- time left and the crew speed); finished rows are compact with a full bar; later rows are compact
-- and dimmed. Every value shown is read from the profile mirror in State and extrapolated with the
-- shared Economy math; every tap asks the server (ModulePay, ModuleInsertKey, StationOptimize) and
-- a refusal becomes a toast. Nothing here decides an outcome.
-- The look is block cells (UI Playbook "Screens after the HUD", Decisions B44): the panel a cream plate at the panel cell with
-- the gold header and the close; a module card a fitted edged block (it re-picks its rows between compact and expanded) whose
-- face and ink follow its state, its badge and Paid chip flat blocks, Pay and Add flat block buttons, its progress bar a flat
-- dark block filled cell-true in gold; Star Chart and Optimize block buttons in cells.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local ShopMath = require(Shared:WaitForChild("ShopMath"))
local Place = require(Shared:WaitForChild("Place"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Modules = require(Shared:WaitForChild("data"):WaitForChild("Modules"))
local KeyMaterials = require(Shared:WaitForChild("data"):WaitForChild("KeyMaterials"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Screens = require(script.Parent.Screens)

local ShipScreen = {}

local materials: { [string]: KeyMaterials.KeyMaterialDef } = KeyMaterials

-- One module row. Children are built once and re-laid-out for the compact or expanded shape.
type Row = {
	card: Frame,
	badge: Frame,
	badgeLabel: TextLabel,
	name: TextLabel,
	crew: TextLabel,
	pay: Frame,
	payFace: TextButton,
	paid: Frame,
	keyLabel: TextLabel,
	add: Frame,
	addFace: TextButton,
	bar: Frame, -- a flat dark block; setBar fills it cell-true (Builder.blockBar)
	setBar: (number) -> (),
	percent: TextLabel,
	status: TextLabel,
}

local REFRESH_SECONDS = 0.25 -- live progress and time-left refresh while open
local FOOTER_W = 0.24 -- of the panel: the width of the Star Chart and Optimize buttons
-- The panel: PANEL_W of the screen wide and PANEL_H tall at most, kept at PANEL_ASPECT, centred at PANEL_Y.
local PANEL_W, PANEL_H, PANEL_ASPECT, PANEL_Y = 0.8, 0.78, 1.35, 0.55
local ROW_COMPACT = 0.125 -- of the list height
local ROW_EXPANDED = 0.425
local ROW_GAP = 0.0175

local gui: ScreenGui? = nil
local panel: Frame? = nil
local helpLabel: TextLabel? = nil
local list: Frame? = nil
local completeLabel: TextLabel? = nil
local rows: { Row } = {}
local open = false
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local pending = false -- one server request in flight at a time

-- Helpers ----------------------------------------------------------------

local function formatTime(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.ceil(seconds))
	if total >= 3600 then
		return Strings.TIME_HM:format(total // 3600, (total % 3600) // 60)
	elseif total >= 60 then
		return Strings.TIME_MS:format(total // 60, total % 60)
	end
	return Strings.TIME_S:format(total)
end

-- Recolours a block button in place (its face and lip), keeping its text.
local function recolorButton(container: Frame, color: Color3)
	Builder.recolorBlockButton(container, color)
end

local function setFill(row: Row, progress: number)
	local p = math.clamp(progress, 0, 1)
	row.setBar(p)
	row.percent.Text = Strings.UI_PERCENT:format(math.floor(p * 100))
end

local function materialName(id: string): string
	return Builder.text("MATERIAL_" .. id)
end

-- Server calls -------------------------------------------------------------

local function handleRefusal(name: string, moduleId: string?, reason: any)
	if reason == "NotEnoughScrap" then
		-- How much more the module still needs, never a bare refusal (TikTok batch 9 lesson 3).
		local price: number? = nil
		local held = 0
		if moduleId and State.Has() then
			local profile = State.Get()
			held = profile.scrap
			local worldId = profile.world.current
			local def = Economy.moduleDef(worldId, moduleId)
			if def then
				local state = Economy.moduleState(profile, worldId, moduleId)
				price = def.scrap - (if state then state.scrapPaid else 0)
			end
		end
		Toast.Show(ShopMath.ShortLine(price, held, Strings.TOAST_SCRAP_SHORT, Strings.TOAST_NOT_ENOUGH_SCRAP, Builder.formatNumber), Theme.Colors.Close)
		return
	end
	if reason == "InFlight" then
		Toast.Show(Strings.TOAST_IN_FLIGHT, Theme.Colors.Select) -- a launch or flight is in progress (Exploit-Review D4)
		return
	end
	if reason == "NoMaterial" and moduleId and State.Has() then
		local def = Economy.moduleDef(State.Get().world.current, moduleId)
		if def then
			local material = materials[def.keyMaterial]
			local biome = if material then Builder.text("BIOME_" .. material.biome) else ""
			Toast.Show(Strings.TOAST_NO_MATERIAL:format(materialName(def.keyMaterial), biome), Theme.Colors.Select)
			return
		end
	end
	print(("[%s] %s refused: %s"):format(Config.WorkingTitle, name, tostring(reason)))
end

-- Invokes a RemoteFunction that answers (ok, reason). Runs in its own thread: callers are taps.
local function ask(name: string, moduleId: string?)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason
		if moduleId then
			ok, reason = Net.func(name):InvokeServer(moduleId)
		else
			ok, reason = Net.func(name):InvokeServer()
		end
		pending = false
		if ok ~= true then
			handleRefusal(name, moduleId, reason)
		elseif name == "ModuleInsertKey" then
			Builder.playSound(Sounds.PartSnap) -- the key part went in; the server's push redraws the row
		end
	end)
end

local function moduleIdAt(index: number): string?
	if not State.Has() then
		return nil
	end
	local def = Economy.moduleDefs(State.Get().world.current)[index]
	return if def then def.id else nil
end

-- Rows ---------------------------------------------------------------------

local function buildRow(parent: Frame, index: number): Row
	local card = Builder.blockPlate({
		parent = parent,
		name = "Module" .. index,
		size = UDim2.fromScale(1, ROW_COMPACT),
		color = Theme.Colors.White,
		ink = Theme.Rarity.Common,
		cells = false,
		edges = true,
		zIndex = 3,
	})
	card.LayoutOrder = index

	local badge = Builder.blockPlate({
		parent = card,
		name = "Badge",
		color = Theme.Rarity.Common,
		rows = Theme.Block.MinRows,
		cells = false,
		aspect = 1,
		zIndex = Builder.blockTop(card),
	})
	local badgeLabel = Builder.label({
		parent = badge,
		name = "Index",
		text = tostring(index),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.85),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(badge),
	})
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = Builder.blockTop(card),
	})
	local crew = Builder.label({
		parent = card,
		name = "Crew",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.6, 0.03),
		size = UDim2.fromScale(0.39, 0.24),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = Builder.blockTop(card),
	})

	local pay = Builder.blockButton({
		parent = card,
		name = "Pay",
		text = Strings.SHIP_PAY:format("0"),
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.09, 0.31),
		size = UDim2.fromScale(0.23, 0.4),
		textSize = Theme.TextSize.Label,
		rows = Theme.Block.MinRows,
		cells = false, -- one on every module card: a flat face
		zIndex = Builder.blockTop(card),
	}, function()
		local moduleId = moduleIdAt(index)
		if moduleId then
			ask("ModulePay", moduleId)
		end
	end)
	local payFace = pay:FindFirstChild("Face") :: TextButton
	local paid = Builder.blockPlate({
		parent = card,
		name = "Paid",
		position = UDim2.fromScale(0.09, 0.31),
		size = UDim2.fromScale(0.23, 0.36),
		color = Theme.Colors.Confirm,
		rows = Theme.Block.MinRows,
		cells = false,
		zIndex = Builder.blockTop(card),
	})
	Builder.label({
		parent = paid,
		name = "Text",
		text = Strings.SHIP_PAID,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(paid),
	})
	local keyLabel = Builder.label({
		parent = card,
		name = "Key",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.335, 0.31),
		size = UDim2.fromScale(0.305, 0.4),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = Builder.blockTop(card),
	})
	local add = Builder.blockButton({
		parent = card,
		name = "Add",
		text = Strings.SHIP_ADD:format(""),
		color = Theme.Colors.Select,
		position = UDim2.fromScale(0.655, 0.31),
		size = UDim2.fromScale(0.335, 0.4),
		textSize = Theme.TextSize.Label,
		rows = Theme.Block.MinRows,
		cells = false, -- one on every module card: a flat face
		zIndex = Builder.blockTop(card),
	}, function()
		local moduleId = moduleIdAt(index)
		if moduleId then
			ask("ModuleInsertKey", moduleId)
		end
	end)
	local addFace = add:FindFirstChild("Face") :: TextButton

	-- The progress bar: a fitted flat dark block filled cell-true in gold (Builder.blockBar); layoutRow resizes it.
	local bar = Builder.blockPlate({
		parent = card,
		name = "Bar",
		color = Theme.Block.Trough,
		rows = Theme.Block.MinRows,
		cells = false,
		zIndex = Builder.blockTop(card),
	})
	local setBar = Builder.blockBar(bar, Theme.Colors.Featured)
	local percent = Builder.label({
		parent = bar,
		name = "Percent",
		text = Strings.UI_PERCENT:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(bar),
	})
	local status = Builder.label({
		parent = card,
		name = "Status",
		text = "",
		textSize = Theme.TextSize.Body,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = Builder.blockTop(card),
	})

	return {
		card = card,
		badge = badge,
		badgeLabel = badgeLabel,
		name = name,
		crew = crew,
		pay = pay,
		payFace = payFace,
		paid = paid,
		keyLabel = keyLabel,
		add = add,
		addFace = addFace,
		bar = bar,
		setBar = setBar,
		percent = percent,
		status = status,
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

local function setCardStyle(row: Row, cardColor: Color3, accent: Color3)
	Builder.setBlockColor(row.card, cardColor)
	Builder.setBlockInk(row.card, accent)
	Builder.setBlockColor(row.badge, accent)
end

-- Positions the shared children for the expanded (active) or compact (done, locked) shape.
local function layoutRow(row: Row, expanded: boolean, showBar: boolean)
	row.card.Size = UDim2.fromScale(1, if expanded then ROW_EXPANDED else ROW_COMPACT)
	row.crew.Visible = expanded
	row.keyLabel.Visible = expanded
	row.add.Visible = expanded
	row.bar.Visible = showBar
	if expanded then
		row.badge.Position = UDim2.fromScale(0.012, 0.15)
		row.badge.AnchorPoint = Vector2.new(0, 0.5)
		row.badge.Size = UDim2.fromScale(0.08, 0.24)
		row.name.Position = UDim2.fromScale(0.09, 0.03)
		row.name.Size = UDim2.fromScale(0.5, 0.24)
		row.bar.Position = UDim2.fromScale(0.09, 0.86)
		row.bar.AnchorPoint = Vector2.new(0, 0.5)
		row.bar.Size = UDim2.fromScale(0.36, 0.2)
		row.status.Position = UDim2.fromScale(0.47, 0.75)
		row.status.Size = UDim2.fromScale(0.52, 0.22)
	else
		row.pay.Visible = false
		row.paid.Visible = false
		row.badge.Position = UDim2.fromScale(0.012, 0.5)
		row.badge.AnchorPoint = Vector2.new(0, 0.5)
		row.badge.Size = UDim2.fromScale(0.06, 0.78)
		row.name.Position = UDim2.fromScale(0.08, 0.1)
		row.name.Size = UDim2.fromScale(0.38, 0.8)
		if showBar then
			row.bar.Position = UDim2.fromScale(0.47, 0.5)
			row.bar.AnchorPoint = Vector2.new(0, 0.5)
			row.bar.Size = UDim2.fromScale(0.28, 0.72)
			row.status.Position = UDim2.fromScale(0.77, 0.1)
			row.status.Size = UDim2.fromScale(0.22, 0.8)
		else
			row.status.Position = UDim2.fromScale(0.47, 0.1)
			row.status.Size = UDim2.fromScale(0.52, 0.8)
		end
	end
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local worldId = profile.world.current
	local defs = Economy.moduleDefs(worldId)
	local activeIndex = Economy.activeModuleIndex(profile, worldId)
	local speeds = State.GetRate().assemblySpeed
	local now = State.Now()
	ensureRows(#defs)

	for index, row in ipairs(rows) do
		local def: Modules.ModuleDef? = defs[index]
		if not def then
			row.card.Visible = false
			continue
		end
		row.card.Visible = true
		row.name.Text = Builder.text("MODULE_" .. def.id)
		local state = Economy.moduleState(profile, worldId, def.id)
		local speed = speeds[def.job] or Config.AssemblyPlayerSpeed

		if activeIndex ~= nil and index > activeIndex then
			-- Locked: dimmed, waiting on the module above.
			layoutRow(row, false, false)
			setCardStyle(row, Builder.lighter(Theme.Rarity.Common, 0.6), Theme.Rarity.Common)
			row.status.Text = Strings.SHIP_LOCKED
			row.status.TextColor3 = Theme.Colors.White
		elseif Economy.isComplete(state) then
			layoutRow(row, false, true)
			setCardStyle(row, Theme.Colors.White, Theme.Colors.Confirm)
			setFill(row, 1)
			row.status.Text = Strings.SHIP_DONE
			row.status.TextColor3 = Theme.Colors.Confirm
		else
			-- Active: both gates, the live bar, the time left and the crew speed.
			layoutRow(row, true, true)
			setCardStyle(row, Theme.Colors.White, Theme.Colors.Featured)
			local scrapPaid = if state then state.scrapPaid else 0
			local keyPaid = if state then state.keyPaid else 0
			local scrapDone = scrapPaid >= def.scrap
			row.paid.Visible = scrapDone
			row.pay.Visible = not scrapDone
			if not scrapDone then
				row.payFace.Text = Strings.SHIP_PAY:format(Builder.formatNumber(def.scrap))
				local affordable = profile.scrap >= def.scrap - scrapPaid
				recolorButton(row.pay, if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
			end
			local material = materialName(def.keyMaterial)
			row.keyLabel.Text = Strings.SHIP_KEY_COUNT:format(keyPaid, def.keyCount, material)
			row.addFace.Text = Strings.SHIP_ADD:format(material)
			local owned = profile.inventory.keyMaterials[def.keyMaterial] or 0
			local canAdd = owned > 0 and keyPaid < def.keyCount
			recolorButton(row.add, if canAdd then Theme.Colors.Select else Theme.Rarity.Common)

			local progress = if state then Economy.progressAt(def, state, speed, now) else 0
			setFill(row, progress)
			row.status.TextColor3 = Theme.Colors.White
			if not state or not Economy.gatesPaid(def, state) then
				row.status.Text = Strings.SHIP_WAITING
			elseif progress >= 1 then
				row.status.Text = Strings.SHIP_DONE
			else
				row.status.Text = Strings.SHIP_ASSEMBLING:format(formatTime(Economy.secondsLeft(def, state, speed, now)))
			end
			row.crew.Text = Strings.SHIP_CREW_SPEED:format(("%.1f"):format(speed))
		end
	end

	local help = helpLabel
	if help then
		local activeDef = if activeIndex then defs[activeIndex] else nil
		help.Visible = activeDef ~= nil
		if activeDef then
			help.Text = Strings.SHIP_HELP:format(Builder.text("JOB_" .. activeDef.job))
		end
	end
	if completeLabel then
		-- "Walk to the ship and launch": never at home, where the server refuses a launch; the home has no modules,
		-- so its empty panel says where building happens instead
		local atHome = Place.IsHome()
		completeLabel.Text = if atHome then Strings.SHIP_HOME else Strings.SHIP_COMPLETE
		completeLabel.Visible = atHome or (activeIndex == nil and #defs > 0)
	end
end

-- Build ----------------------------------------------------------------------

-- In a tall narrow window the HUD's menu column reaches into the centred panel and hides the Star Chart button's left end:
-- the panel slides right by what the column covers, and never off the screen. Wide screens leave it centred.
local function clearMenu(root: ScreenGui, body: Frame)
	local screen = root.AbsoluteSize
	if screen.X <= 0 or screen.Y <= 0 then
		return
	end
	local half = math.min(PANEL_W, PANEL_H * PANEL_ASPECT * screen.Y / screen.X) / 2 -- the panel's half width, of the screen
	local covered = Builder.menuRight(screen) + Theme.Menu.Gap - (0.5 - half)
	local shift = math.clamp(covered, 0, math.max(0, 0.5 - half - Theme.Margin))
	body.Position = UDim2.fromScale(0.5 + shift, PANEL_Y)
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("ShipScreen", 20)
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
		ShipScreen.Close()
	end)

	local body = Builder.blockPlate({
		parent = root,
		name = "Panel",
		color = Theme.Colors.Panel,
		aspect = PANEL_ASPECT,
		rows = Builder.blockPanelRows(PANEL_H), -- a cream block plate at the panel cell (UI Playbook "Screens after the HUD")
		position = UDim2.fromScale(0.5, PANEL_Y), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(PANEL_W, PANEL_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	panel = body
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		clearMenu(root, body)
	end)

	-- Header tab straddling the top edge, title in white outlined text.
	Builder.blockHeader(body, PANEL_ASPECT, Strings.SHIP_TITLE, Theme.Colors.Featured, Vector2.new(0.42, 0.11))

	Builder.blockClose(body, PANEL_H, function()
		ShipScreen.Close()
	end)

	helpLabel = Builder.label({
		parent = body,
		name = "Help",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(Theme.Margin, 0.085),
		size = UDim2.fromScale(0.84, 0.065),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = Builder.blockTop(body),
	})

	local rowsFrame = Builder.frame({
		parent = body,
		name = "Modules",
		position = UDim2.fromScale(Theme.Margin, 0.16),
		size = UDim2.fromScale(1 - Theme.Margin * 2, 0.68),
		zIndex = Builder.blockTop(body),
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = rowsFrame
	list = rowsFrame

	local complete = Builder.label({
		parent = body,
		name = "Complete",
		text = Strings.SHIP_COMPLETE,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(FOOTER_W + 2 * Theme.Margin, 1 - Theme.Margin), -- between the Star Chart and Optimize buttons
		size = UDim2.fromScale(1 - 2 * FOOTER_W - 4 * Theme.Margin, 0.1),
		anchor = Vector2.new(0, 1),
		color = Theme.Colors.Featured,
		xAlign = Enum.TextXAlignment.Left,
		zIndex = Builder.blockTop(body),
	})
	complete.Visible = false
	completeLabel = complete

	-- Star Chart, bottom left: closes this screen and opens the chart. Mirrors Optimize on the right.
	Builder.blockButton({
		parent = body,
		name = "StarChart",
		text = Strings.STARCHART_OPEN,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(Theme.Margin, 1 - Theme.Margin),
		size = UDim2.fromScale(FOOTER_W, 0.1),
		anchor = Vector2.new(0, 1),
		textSize = Theme.TextSize.Label,
		rows = Theme.Block.MinRows,
		zIndex = Builder.blockTop(body) + 1,
	}, function()
		Screens.Open("StarChart") -- closes the Ship screen on the way
	end)

	Builder.blockButton({
		parent = body,
		name = "Optimize",
		text = Strings.OPTIMIZE,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin, 1 - Theme.Margin),
		size = UDim2.fromScale(FOOTER_W, 0.1),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		rows = Theme.Block.MinRows,
		zIndex = Builder.blockTop(body) + 1,
	}, function()
		ask("StationOptimize", nil)
	end)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "modules", "inventory", "scrap", "rate" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

-- Public API -------------------------------------------------------------

function ShipScreen.IsOpen(): boolean
	return open
end

function ShipScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	clearMenu(root, body)
	Builder.open(body)
	accumulator = 0
	if heartbeat then
		heartbeat:Disconnect()
	end
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < REFRESH_SECONDS then
			return
		end
		accumulator = 0
		refresh()
	end)
end

function ShipScreen.Close()
	if not open then
		return
	end
	open = false
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
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

function ShipScreen.Toggle()
	if open then
		ShipScreen.Close()
	else
		ShipScreen.Open()
	end
end

return ShipScreen
