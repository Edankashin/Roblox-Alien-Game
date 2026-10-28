--!strict
-- StarterPlayerScripts.Client.UI.WorldCard: one world as a picture card (UI richness pass, package B,
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 3; reference zpl-avd/mines.jpg). The Star Chart's grid builds one per world, the
-- Home planet first, and the Ship panel builds one compact strip for the next stop. A card is a fitted edged block in the world's
-- colour (data/WorldCards): the world's render fills the face (an ImageLabel, id 0 until the uploader fills it); until then, or
-- while it loads, the cell diorama draws instead (five flat bands from the world's palette, a skyline of one to three cell towers
-- and a sun, the same on every build: Shared/WorldCardMath); a stepped dark scrim keeps the text readable. Over it: a number badge
-- (the Home planet wears the pixel house), the name, up to five species chips with a "3 / 19" count (a caught one in its colour and
-- tier ink, an uncaught one and any Secret a "?"), and one button: HERE (grey, with the Check), TRAVEL (the main green), "Return"
-- for a guest whose ship waits here, nothing on a locked or unbuilt card (a pixel padlock, and the line that says what opens it).
-- An outpost adds "Lv 2" at the top right and a green dot while something is ready; the next stop wears a gold ink and a NEXT
-- ribbon; a selected card takes the gold ink.
-- The card draws what the screen tells it (Set) and decides nothing: a tap on the card calls onSelect, a tap on its button calls
-- onAction with the kind of button it was. Every number is data/WorldCards; every word a string.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local OutpostMath = require(Shared:WaitForChild("OutpostMath"))
local WorldCardMath = require(Shared:WaitForChild("WorldCardMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Data =require(Shared:WaitForChild("data"):WaitForChild("WorldCards"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)

local WorldCard = {}

export type Kind = "Here" | "Travel" | "Return" | "Locked" | "Soon"

-- What the screen tells a card to show.
export type View = {
	kind: Kind,
	next: boolean, -- the next stop: a gold ink and the NEXT ribbon
	selected: boolean, -- the selected card takes the gold ink
	codex: { [string]: any }, -- profile.codex: a species id keyed to its entry (empty for a locked card)
	level: number?, -- an outpost's level, when the world has one
	ready: boolean, -- the outpost has something to collect
}

export type Options = {
	aspect: number?, -- the card's width over its height (the Star Chart's grid: Data.Aspect; the Ship's strip is wide)
	heightShare: number?, -- the card's height as a share of the screen, for its cell rows
	panelPx: number?, -- the panel's width in px, for how many chips fit (WorldCardMath.ChipCount)
	onSelect: ((worldId: number) -> ())?, -- a tap on the card
	onAction: ((worldId: number, kind: string) -> ())?, -- a tap on its button: "Here", "Travel" or "Return"
}

export type Card = {
	worldId: number,
	frame: Frame, -- the edged block
	Set: (View) -> (),
	SetNear: (boolean) -> (), -- a picture loads once its card is near the viewport; id 0 draws nothing
}

type Piece = { frame: Frame, base: Color3 }

local IMAGE_LOAD_SECONDS = 6 -- a picture that has not loaded by now stays under the diorama

-- The world's name from the strings table (WORLD_<id>), or the Worlds row, or the key itself.
function WorldCard.WorldName(worldId: number): string
	local key = "WORLD_" .. tostring(worldId)
	local text = Builder.text(key)
	if text ~= key then
		return text
	end
	local def = Worlds[worldId]
	return if def then def.name else key
end

-- Which worlds are open: the profile's list, the one the ship stands on, the home once launched. Returns the set and the highest id
-- in it (the next stop is the first locked world past it).
function WorldCard.OpenWorlds(profile: Types.Profile): ({ [number]: boolean }, number)
	local unlocked: { [number]: boolean } = {}
	local highest = 0
	for _, id in ipairs(profile.world.unlocked) do
		unlocked[id] = true
		highest = math.max(highest, id)
	end
	unlocked[profile.world.current] = true
	highest = math.max(highest, profile.world.current)
	local home: Types.HomeState? = profile.home -- a mirror older than the field reads as locked
	if home and home.unlocked then
		unlocked[0] = true
	end
	return unlocked, highest
end

-- What a world's card shows, read from the profile mirror (the screens decide nothing): HERE on the world the ship stands on
-- ("Return" for a guest, State.IsGuest: visiting a home, or a ship that is not on this place's world), TRAVEL on any other open
-- world, a locked card otherwise, an unbuilt world that is not the next stop "Soon". The outpost's level and whether it has something
-- ready come with it. `selected` is the world the screen has selected.
function WorldCard.ViewFor(profile: Types.Profile, worldId: number, unlocked: { [number]: boolean }, nextLocked: number?, selected: number?, now: number): View
	local def = Worlds[worldId]
	local isNext = worldId == nextLocked
	local kind: Kind
	if worldId == profile.world.current then
		kind = if State.IsGuest() then "Return" else "Here"
	elseif unlocked[worldId] then
		kind = "Travel"
	elseif def ~= nil and not def.built and not isNext then
		kind = "Soon"
	else
		kind = "Locked"
	end
	local level: number? = nil
	local ready = false
	local outposts: { [string]: Types.OutpostState }? = profile.world.outposts -- a mirror older than the field reads as none
	local state = if worldId == 0 or not unlocked[worldId] or not outposts then nil else outposts[tostring(worldId)]
	if state then
		level = state.level
		local pending = OutpostMath.Pending(state, worldId, now)
		ready = pending.scrap > 0 or pending.materialCount > 0
	end
	return {
		kind = kind,
		next = isNext,
		selected = worldId == selected,
		codex = profile.codex,
		level = level,
		ready = ready,
	}
end

-- The line a card says under its name for a kind (nil: none).
local function lineFor(worldId: number, kind: Kind, built: boolean): string?
	if kind == "Soon" then
		return Strings.WORLDCARD_SOON
	elseif kind == "Return" then
		return Strings.STARCHART_RETURN_LINE
	elseif kind == "Locked" then
		local card = Data.Cards[worldId]
		local template = Builder.text(if card then card.unlockLineKey else "STARCHART_LOCKED")
		local after = if card then card.unlockAfter else 0
		if not built and worldId > 0 and after == 0 then
			return Strings.WORLDCARD_SOON
		end
		return string.format(template, WorldCard.WorldName(after))
	end
	return nil
end

-- A flat rectangle inside the scene (fractions of the card), a band or a block.
local function rect(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3, transparency: number?, z: number): Frame
	return Builder.frame({
		parent = parent,
		name = name,
		position = UDim2.fromScale(x, y),
		size = UDim2.fromScale(w, h),
		color = color,
		transparency = transparency,
		zIndex = z,
	})
end

function WorldCard.Build(parent: Instance, worldId: number, compact: boolean, options: Options?): Card
	local opts: Options = options or {}
	local aspect = opts.aspect or Data.Aspect
	local def = Data.Cards[worldId] or Data.Cards[1]
	local worldColor = Theme.Hex(def.color)
	local worldDef = Worlds[worldId]
	local built = worldDef ~= nil and worldDef.built
	local L = Data.Layout
	local shape = Data.Diorama

	local frame = Builder.blockPlate({
		parent = parent,
		name = "WorldCard_" .. tostring(worldId),
		color = Theme.Colors.Panel,
		ink = worldColor,
		cells = false,
		edges = true,
		aspect = aspect,
		rows = Builder.blockRows(opts.heightShare or Data.HeightShare),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(1 - 2 * Data.Gap, 1 - 2 * Data.Gap),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	local top = Builder.blockTop(frame)
	local function square(height: number): UDim2
		return UDim2.fromScale(height / aspect, height)
	end

	-- The scene: the diorama's bands, skyline and sun, the picture over them, the scrim over that. Clipped to the card's face.
	local innerPosition, innerSize = Builder.blockInner(frame)
	local scene = Builder.frame({ parent = frame, name = "Scene", position = innerPosition, size = innerSize, zIndex = top })
	scene.ClipsDescendants = true
	local pieces: { Piece } = {}
	local function piece(name: string, x: number, y: number, w: number, h: number, hex: string)
		local color = Theme.Hex(hex)
		local block = rect(scene, name, x, y, w, h, color, nil, top)
		table.insert(pieces, { frame = block, base = color })
	end
	local columns = shape.Columns
	local rows = WorldCardMath.DioramaRows(columns, aspect)
	local p = def.palette
	local farTop = shape.SkyShare + shape.SkyLowShare
	piece("Sky", 0, 0, 1, shape.SkyShare, p.sky)
	piece("SkyLow", 0, shape.SkyShare, 1, shape.SkyLowShare, p.skyLow)
	piece("Far", 0, farTop, 1, shape.FarShare, p.far)
	piece("Ground", 0, farTop + shape.FarShare, 1, shape.GroundShare, p.ground)
	for index, tower in ipairs(WorldCardMath.Towers(worldId, columns, rows)) do
		local heightShare = tower.height / rows
		piece("Tower" .. index, tower.col / columns, farTop - heightShare, tower.width / columns, heightShare, p.far)
	end
	local sun = WorldCardMath.Accent(worldId, columns, rows)
	piece("Accent", sun.col / columns, sun.row / rows, sun.cells / columns, sun.cells / rows, p.accent)

	local image: ImageLabel? = nil
	local imageWanted = def.image ~= 0
	local locked = false
	local function loadImage()
		if image or not imageWanted then
			return
		end
		local label = Instance.new("ImageLabel")
		label.Name = "Picture"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = UDim2.fromScale(1, 1)
		label.ScaleType = Enum.ScaleType.Crop
		label.Image = "rbxassetid://" .. tostring(def.image)
		label.ImageTransparency = 1 -- the diorama shows until it has loaded
		label.ImageColor3 = if locked then Theme.Hex(Data.LockedGrey) else Theme.Colors.White
		label.ZIndex = top + 1
		label.Parent = scene
		image = label
		task.spawn(function()
			local waited = 0
			while not label.IsLoaded and waited < IMAGE_LOAD_SECONDS and label.Parent ~= nil do
				waited += task.wait(0.25)
			end
			if label.IsLoaded then
				label.ImageTransparency = 0
			end
		end)
	end

	-- The stepped scrim: the lower share across the full width and the left share of what is above it, two flat blocks.
	local scrim = Data.Scrim
	local scrimTop = 1 - scrim.LowerShare
	rect(scene, "ScrimLow", 0, scrimTop, 1, scrim.LowerShare, Theme.Colors.Black, scrim.Transparency, top + 2)
	rect(scene, "ScrimLeft", 0, 0, scrim.LeftShare, scrimTop, Theme.Colors.Black, scrim.Transparency, top + 2)

	local content = top + 3

	-- The number badge: a pixel octagon in the world's colour with the world's number; the Home planet wears the pixel house.
	local badgeHeight = if compact then L.CompactBadge else Data.Badge
	local badge = Builder.pixelOctagon({
		parent = frame,
		name = "Badge",
		color = worldColor,
		position = if compact then UDim2.fromScale(L.PadX / 2, 0.5) else UDim2.fromScale(L.PadX, L.BadgeY),
		size = square(badgeHeight),
		anchor = if compact then Vector2.new(0, 0.5) else Vector2.zero,
		zIndex = content,
	})
	if worldId == 0 then
		Builder.pixelIcon({
			parent = badge.holder,
			name = "Home",
			key = "Home",
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.7, 0.7),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Builder.octagonTop(badge),
		})
	else
		Builder.label({
			parent = badge.holder,
			name = "Number",
			text = tostring(worldId),
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.8, 0.8),
			anchor = Vector2.new(0.5, 0.5),
			stroke = 2,
			zIndex = Builder.octagonTop(badge),
		})
	end

	local textX = if compact then L.PadX / 2 + badgeHeight / aspect + L.PadX / 2 else L.PadX
	local function textWidth(withButton: boolean): number
		if compact then
			return 1 - textX - L.CompactButtonWidth - L.PadX
		end
		return if withButton then L.TextWidthButton else L.TextWidthFull
	end
	local name = Builder.label({
		parent = frame,
		name = "Name",
		text = WorldCard.WorldName(worldId),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(textX, if compact then L.CompactNameY else L.NameYNoLine),
		size = UDim2.fromScale(textWidth(true), if compact then L.CompactNameHeight else L.NameHeight),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = content,
	})
	name.TextWrapped = false
	local line = Builder.label({
		parent = frame,
		name = "Line",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(textX, if compact then L.CompactLineY else L.LineY),
		size = UDim2.fromScale(textWidth(false), if compact then L.CompactLineHeight else L.LineHeight),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = content,
	})
	line.TextWrapped = true
	line.TextYAlignment = Enum.TextYAlignment.Top

	-- The species row: Data.Row chips (the first ChipCount show) and the count. The roster is the same for every build.
	local roster = WorldCardMath.Roster(worldId, Species.List)
	local chipSize = Data.Chip
	local chips: { { holder: Frame, face: Frame, mark: TextLabel, id: string, tier: string, color: Color3 } } = {}
	local count: TextLabel? = nil
	if not compact and #roster > 0 then
		local gap = Data.ChipGap / aspect
		local side = chipSize / aspect
		for index = 1, math.min(Data.Row, #roster) do
			local id = roster[index]
			local def_ = Species.ById[id]
			local holder = Builder.frame({
				parent = frame,
				name = "Chip" .. index,
				position = UDim2.fromScale(L.PadX + (index - 1) * (side + gap), L.RowY),
				size = UDim2.fromScale(side, chipSize),
				color = Theme.Colors.Outline,
				zIndex = content,
			})
			local face = Builder.frame({
				parent = holder,
				name = "Face",
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(0.76, 0.76),
				anchor = Vector2.new(0.5, 0.5),
				color = Theme.Hex(Data.UnknownTint),
				zIndex = content + 1,
			})
			local mark = Builder.label({
				parent = face,
				name = "Mark",
				text = Strings.WORLDCARD_UNKNOWN,
				textSize = Theme.TextSize.Min,
				stroke = 0,
				zIndex = content + 2,
			})
			table.insert(chips, {
				holder = holder,
				face = face,
				mark = mark,
				id = id,
				tier = def_.tier :: string,
				color = Theme.Hex(def_.placeholder.color),
			})
		end
		local made = Builder.label({
			parent = frame,
			name = "Count",
			text = "",
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(L.PadX + Data.Row * (side + gap) + gap, L.RowY),
			size = UDim2.fromScale(0.3, chipSize),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = content,
		})
		made.TextWrapped = false
		count = made
	elseif compact and #roster > 0 then
		local made = Builder.label({ -- the strip's second row: the found count
			parent = frame,
			name = "Count",
			text = "",
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(textX, L.CompactLineY),
			size = UDim2.fromScale(textWidth(true), L.CompactLineHeight),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = content,
		})
		made.TextWrapped = false
		count = made
	end

	-- The outpost's level chip and its ready dot, top right; the NEXT ribbon takes the same place on a locked next stop.
	local levelChip = Builder.blockPlate({
		parent = frame,
		name = "Level",
		color = Theme.Block.Trough,
		cells = false,
		rows = Theme.Block.MinRows,
		position = UDim2.fromScale(1 - L.PadX, L.BadgeY),
		size = UDim2.fromScale(L.LevelWidth, L.LevelHeight),
		anchor = Vector2.new(1, 0),
		zIndex = content,
	})
	levelChip.Visible = false
	local levelText = Builder.label({
		parent = levelChip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.84),
		anchor = Vector2.new(0.5, 0.5),
		stroke = 0,
		zIndex = Builder.blockTop(levelChip),
	})
	local dot = Builder.pixelOctagon({
		parent = frame,
		name = "Ready",
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(1 - L.PadX, L.BadgeY),
		size = square(L.LevelHeight * 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = content + 3,
	}).holder
	dot.Visible = false
	local ribbon = Builder.blockPlate({
		parent = frame,
		name = "Next",
		color = Theme.Colors.Featured,
		cells = false,
		rows = Theme.Block.MinRows,
		position = if compact then UDim2.fromScale(1 - L.CompactButtonWidth - L.PadX * 1.5, 0.5) else UDim2.fromScale(1 - L.PadX, L.BadgeY),
		size = UDim2.fromScale(Data.Ribbon.Width, Data.Ribbon.Height),
		anchor = if compact then Vector2.new(1, 0.5) else Vector2.new(1, 0),
		zIndex = content,
	})
	ribbon.Visible = false
	Builder.label({
		parent = ribbon,
		name = "Text",
		text = Strings.WORLDCARD_NEXT,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.84),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(ribbon),
	})

	-- The padlock of a locked card, where its button would be.
	local lock = Builder.pixelIcon({
		parent = frame,
		name = "Lock",
		key = "Lock",
		position = if compact then UDim2.fromScale(1 - L.PadX, 0.5) else UDim2.fromScale(1 - L.PadX, L.ButtonBottom),
		size = if compact then square(L.CompactButtonHeight * 0.8) else square(L.ButtonHeight * 0.8),
		anchor = if compact then Vector2.new(1, 0.5) else Vector2.new(1, 1),
		zIndex = content,
	})
	if lock then
		lock.Visible = false
	end

	-- The tap on the card (not its button) selects it; the button sits above it.
	local hit = Instance.new("TextButton")
	hit.Name = "Select"
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = content - 1
	hit.Parent = frame
	hit.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		local select = opts.onSelect
		if select then
			select(worldId)
		end
	end)

	-- The one button: fitted, flat (a button repeated down a grid), with the 44 px hit area.
	local buttonKind: Kind = "Travel"
	local buttonShare = (if compact then L.CompactButtonHeight else L.ButtonHeight) * (opts.heightShare or Data.HeightShare)
	local button = Builder.blockButton({
		parent = frame,
		name = "Action",
		text = Strings.WORLDCARD_TRAVEL,
		color = Builder.roleColor("main"),
		position = if compact then UDim2.fromScale(1 - L.PadX, 0.5) else UDim2.fromScale(1 - L.PadX, L.ButtonBottom),
		size = if compact then UDim2.fromScale(L.CompactButtonWidth, L.CompactButtonHeight) else UDim2.fromScale(L.ButtonWidth, L.ButtonHeight),
		anchor = if compact then Vector2.new(1, 0.5) else Vector2.new(1, 1),
		textSize = Theme.TextSize.Body,
		rows = Builder.blockButtonRows(buttonShare),
		cells = false,
		hit = true,
		zIndex = content + 1,
	}, function()
		local action = opts.onAction
		if action then
			action(worldId, buttonKind)
		end
	end)
	button.Visible = false

	local function showLevel(level: number?, ready: boolean)
		levelChip.Visible = level ~= nil and not compact
		dot.Visible = level ~= nil and ready and not compact
		if level then
			levelText.Text = Strings.STARCHART_LEVEL_CHIP:format(level)
		end
	end

	local function paintChips(view: View, shown: number)
		for index, chip in ipairs(chips) do
			chip.holder.Visible = index <= shown
			local caught = view.codex[chip.id] ~= nil
			local state = WorldCardMath.ChipState(chip.tier, caught)
			if state == "Caught" then
				chip.holder.BackgroundColor3 = Builder.tierColor(chip.tier)
				chip.face.BackgroundColor3 = chip.color
				chip.mark.Visible = false
			else
				chip.holder.BackgroundColor3 = Theme.Colors.Outline
				chip.face.BackgroundColor3 = Theme.Hex(Data.UnknownTint)
				chip.mark.Visible = true
			end
		end
	end

	local function set(view: View)
		locked = view.kind == "Locked" or view.kind == "Soon"
		local hasRow = built and worldId > 0 and #roster > 0 and view.kind ~= "Soon"
		local lineText = lineFor(worldId, view.kind, built)
		local hasButton = view.kind == "Here" or view.kind == "Travel" or view.kind == "Return"

		-- ink and face: gold when selected or the next stop, the world's colour otherwise, grey and faded when locked
		local ink = worldColor
		if view.selected or (view.next and locked) then
			ink = Theme.Colors.Featured
		elseif locked then
			ink = Theme.Rarity.Common
		end
		Builder.setBlockInk(frame, ink)
		Builder.setBlockFade(frame, if locked then Data.LockedFade else 0)
		local grey = Theme.Hex(Data.LockedGrey)
		for _, part in ipairs(pieces) do
			part.frame.BackgroundColor3 = if locked then part.base:Lerp(grey, Data.LockedGreyShare) else part.base
		end
		local picture = image
		if picture then
			picture.ImageColor3 = if locked then grey else Theme.Colors.White
		end

		-- the line and the name's place above it
		line.Visible = lineText ~= nil
		line.Text = lineText or ""
		if not compact then
			name.Position = UDim2.fromScale(textX, if lineText then L.NameYLine else L.NameYNoLine)
			line.Size = UDim2.fromScale(textWidth(hasButton), L.LineHeight)
			name.Size = UDim2.fromScale(textWidth(hasButton), L.NameHeight)
		end

		-- the species row
		for _, chip in ipairs(chips) do
			chip.holder.Visible = hasRow
		end
		local shown = math.min(#chips, WorldCardMath.ChipCount(opts.panelPx or 0))
		if hasRow then
			local view2: View = if view.kind == "Locked" then { kind = view.kind, next = view.next, selected = view.selected, codex = {}, level = nil, ready = false } else view
			paintChips(view2, shown)
		end
		local counter = count
		if counter then
			counter.Visible = hasRow
			if hasRow then
				if not compact then -- the count follows the last chip that shows
					counter.Position = UDim2.fromScale(L.PadX + shown * (chipSize + Data.ChipGap) / aspect + Data.ChipGap / aspect, L.RowY)
				end
				local found, total = WorldCardMath.Counts(worldId, Species.List, if view.kind == "Locked" then {} else view.codex)
				counter.Text = Strings.WORLDCARD_COUNT:format(found, total)
			end
		end
		if compact and counter and lineText then
			counter.Visible = false -- the strip shows the line or the count, never both
		end

		-- the button, the padlock, the ribbon, the outpost
		button.Visible = hasButton
		if hasButton then
			buttonKind = view.kind
			if view.kind == "Here" then
				Builder.restyleBlockButton(button, Strings.WORLDCARD_HERE, Builder.roleColor("current"), true)
				Builder.setButtonMark(button, "Check")
			else
				Builder.restyleBlockButton(button, if view.kind == "Return" then Strings.WORLDCARD_RETURN else Strings.WORLDCARD_TRAVEL, Builder.roleColor("main"), true)
				Builder.setButtonMark(button, nil)
			end
		end
		if lock then
			lock.Visible = view.kind == "Locked"
		end
		ribbon.Visible = view.next and locked
		showLevel(if view.kind == "Locked" or view.kind == "Soon" then nil else view.level, view.ready)
	end
	return {
		worldId = worldId,
		frame = frame,
		Set = set,
		SetNear = function(near: boolean)
			if near then
				loadImage()
			end
		end,
	}
end

return WorldCard
