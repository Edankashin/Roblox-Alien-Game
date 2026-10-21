--!strict
-- StarterPlayerScripts.Client.UI.Hud: the always-on HUD. The Scrap pill top-left (icon + rolling
-- number) with the Scrap-per-minute line under it, the ship bar top centre under the compass strip
-- (UI/Compass; tap opens the ship panel) with the luck line or the event banner under it, the
-- Day/Night + weather chip top-right (square block buttons such as the Settings cog sit just left of it,
-- AddTopButton) with the biome chip and the Meteor Shower countdown chip stacked beneath, and the contextual action
-- button bottom-right that shows "Catch!" near a wild alien. A dumb view: every value shown is pushed
-- in by the bootstrap from server state; nothing here computes anything that matters.
-- The look is block cells (Decisions B44, Decide-Now 43, the "HUD in block cells" board): every plate, chip and button is a
-- Builder.blockPlate or Builder.blockButton (square cells, stepped corners, navy ink, a lit top row, grout), icons are the 8 by 8
-- pixel icons of data/PixelIcons, and the layout is the one the HUD had (the slots other screens read did not move).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local CompassData = require(Shared:WaitForChild("data"):WaitForChild("Compass"))
local Modules = require(Shared:WaitForChild("data"):WaitForChild("Modules"))
local Builder = require(script.Parent.Builder)
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local Hud = {}

local SHIP_FILL_SECONDS = 0.4 -- the ship bar's fill eases to a new value over this
local TICK_WIDTH = 0.004 -- milestone tick marks, as a fraction of the bar width
local DEFAULT_TICK_WORLD = 1 -- every player starts here; SetShipTicks replaces these once the profile is in
local FLY_SIZE = Vector2.new(0.2, 0.08) -- a flying "+N" label, in screen Scale
local FLY_SHRINK = 0.7 -- it ends this fraction of its start size at the pill
local FLY_FADE_SECONDS = 0.15 -- then fades out over this
local FLY_FALLBACK_Y = 0.9 -- where a "+N" starts (bottom centre) while the action button is hidden
local FLY_ZINDEX = 20 -- over every other HUD element

local gui: ScreenGui? = nil
local menuGui: ScreenGui? = nil -- the icon stack sits above modal dims (MENU_DISPLAY_ORDER) so panels can be switched
local scrapPill: Frame? = nil
local setScrapValue: ((number) -> ())? = nil
local clockLabel: TextLabel? = nil
local clockChip: Frame? = nil
local biomeLabel: TextLabel? = nil
local menuButtons: { [string]: Frame } = {}
local menuCount = 0
local topButtons: { Frame } = {} -- square buttons left of the clock chip, in the order added (the first sits nearest the chip)
local topButtonIds: { [string]: boolean } = {}
local topButtonById: { [string]: Frame } = {} -- the same buttons by id, for SetBadge and SetTopButtonVisible

local CLOCK_RIGHT = 0.985 -- the clock chip's right edge, in screen Scale
local CLOCK_TOP = 0.025
local CLOCK_SIZE = Vector2.new(0.3, 0.075) -- the chip's Size bounds; its aspect constraint derives the width from the height
local CLOCK_ASPECT = 4.2
local TOP_BUTTON_H = 0.075 -- the top buttons share the chip's height
local TOP_GAP = 0.01 -- between the chip and the first button, and between buttons

local MENU_DISPLAY_ORDER = 25 -- above the modal screens (20) and their backdrops, below reveals (30) and toasts (40)
local MENU_TOP = 0.19 -- the icon stack starts here, under the Scrap pill and its rate line
local MENU_SLOT = Theme.Menu.SlotH -- vertical space per entry: the square button plus its label; six entries end at 0.97
local MENU_BUTTON = 0.095 -- square button height (width follows through the aspect constraint)
local MENU_LEFT = Theme.Menu.Left
local MENU_BADGE_SIZE = 0.34 -- the menu buttons' notification dot, as a fraction of the button
local TOP_BADGE_SIZE = 0.5 -- a top button is small (about 28 px at iPhone SE height), so its dot is bigger
local actionButton: Frame? = nil
local actionFace: TextButton? = nil
local breathe: Tween? = nil
local onAction: (() -> ())? = nil
local lastScrap = 0
local shipValue: NumberValue? = nil -- the fill (0 to 1) the bar shows; tweened, and the block bar follows it
local shipLabel: TextLabel? = nil
local shipTicks: Frame? = nil
local shipTween: Tween? = nil
local onShipTapped: (() -> ())? = nil
local rateLabel: TextLabel? = nil
local luckLabel: TextLabel? = nil
local luckShown = false -- the luck line's own rule (luck is not exactly 1); the event banner overrides it
local showerChip: Frame? = nil
local showerLabel: TextLabel? = nil
local banner: Frame? = nil
local bannerText: TextLabel? = nil
local bannerSub: TextLabel? = nil -- the smaller second line (the time left)
local bannerChip: Frame? = nil
local bannerChipLabel: TextLabel? = nil
local bannerIcon: Frame? = nil -- the placeholder square an event icon fills
local bannerIconKey: string? = nil -- the key shown now, so a repeated SetEventBanner leaves the image alone
local friendChip: Frame? = nil
local friendLabel: TextLabel? = nil
local friendCountShown = 0
local onFriendChipTapped: (() -> ())? = nil

-- The centre column (ship bar, luck line, event banner, Friend Boost chip) sits this far lower than the
-- top row so the compass strip (UI/Compass: 0.008 to 0.038) has the top edge: the strip's height plus a gap.
local CENTER_SHIFT = 0.046 -- the compass strip (0.006 + 0.04) over the centre column

local FRIEND_CHIP_TOP = 0.18 + CENTER_SHIFT -- under the luck line / event banner slot (the banner ends at 0.175 + CENTER_SHIFT), centred
local FRIEND_CHIP_SIZE = Vector2.new(0.3, 0.055) -- Size bounds; the aspect constraint derives the width from the height
local FRIEND_CHIP_ASPECT = 5.5

local BANNER_TEXT_LEFT = 0.14 -- the banner text starts after the icon square
local BANNER_TEXT_WIDTH = 0.56 -- with the luck chip showing on the right
local BANNER_TEXT_WIDTH_FULL = 0.82 -- without a chip
local BANNER_ASPECT = 6
local BANNER_CHIP = Vector2.new(0.25, 0.68) -- the luck chip, as fractions of the banner
-- The banner's lines, as fractions of its height: two lines (the name, then the time left under it) or one (either alone).
-- Two lines need the smaller one to hold the 14 px floor: on a banner under Theme.TextSize.Min / BANNER_SUB_H px tall (41 px:
-- iPhone SE's is 26) the banner shows one line at a time, the name and the time left taking turns (Theme.Tween.BannerLine each).
local BANNER_NAME_Y, BANNER_NAME_H = 0.1, 0.46
local BANNER_SUB_Y, BANNER_SUB_H = 0.56, 0.34
local BANNER_ONE_Y, BANNER_ONE_H = 0.15, 0.7

local SCRAP_ASPECT = 3.6
local CHIP_ASPECT = 4.2 -- the clock, biome and shower chips and the ship bar
local ACTION_ASPECT = 2.3
local BADGE_ROWS = 3 -- a notification dot is a flat block this many cells tall (its stepped corners read at 12 px)
local ICON_ROWS = 3 -- and so is an icon square's placeholder

-- m:ss for the event countdown chip (TIME_MS past a minute, TIME_S under it).
local function formatCountdown(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.ceil(seconds))
	if total >= 60 then
		return Strings.TIME_MS:format(total // 60, total % 60)
	end
	return Strings.TIME_S:format(total)
end

-- Tween lengths shrink by Config.ReducedMotionFactor when reduced motion is on (Prefs folds the
-- profile toggle and the system switch together).
local function motionFactor(): number
	return if Prefs.ReducedMotion() then Config.ReducedMotionFactor else 1
end

-- A GuiObject's centre in a ScreenGui's Scale space, from the absolute layout.
local function centreScale(root: ScreenGui, target: GuiObject): (number, number)
	local screen = root.AbsoluteSize
	local centre = target.AbsolutePosition + target.AbsoluteSize / 2 - root.AbsolutePosition
	return centre.X / screen.X, centre.Y / screen.Y
end

-- An icon square: a holder with a flat block placeholder ("Back", in `color`) under whatever icon it shows. setSquareIcon fills it.
local function iconSquare(parent: Instance, position: UDim2, size: UDim2, color: Color3, zIndex: number): Frame
	local square = Builder.frame({
		parent = parent,
		name = "Icon",
		position = position,
		size = size,
		anchor = Vector2.new(0, 0.5),
		aspect = 1,
		zIndex = zIndex,
	})
	Builder.blockPlate({
		parent = square,
		name = "Back",
		color = color,
		aspect = 1,
		rows = ICON_ROWS,
		cells = false,
		zIndex = zIndex,
	})
	return square
end

-- Fills an icon square with the key's icon (Builder.blockIcon: the pixel icon first, else the uploaded pack image), replacing any
-- icon it held. The placeholder block hides while an icon shows; with no key, or no icon for it, the placeholder is what shows.
local function setSquareIcon(square: Frame, key: string?)
	local previous = square:FindFirstChild("IconImage")
	if previous then
		previous:Destroy()
	end
	local icon = if key
		then Builder.blockIcon({ parent = square, name = "IconImage", key = key, zIndex = square.ZIndex + Theme.Block.Layer.Content })
		else nil
	local back = square:FindFirstChild("Back")
	if back and back:IsA("GuiObject") then
		back.Visible = icon == nil
	end
end

-- A chip: a block plate in `color` with one centred outlined line on it. Returns the plate and the label.
local function chipPlate(root: ScreenGui, name: string, color: Color3, position: UDim2, size: Vector2, aspect: number, text: string): (Frame, TextLabel)
	local chip = Builder.blockPlate({
		parent = root,
		name = name,
		color = color,
		aspect = aspect,
		position = position,
		size = UDim2.fromScale(size.X, size.Y),
		anchor = Vector2.new(1, 0),
	})
	local label = Builder.label({
		parent = chip,
		name = "Text",
		text = text,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(chip),
	})
	return chip, label
end

-- The Scrap plate: a dark block plate (the board's) with the pixel Scrap cube and the rolling count.
local function buildScrapPill(root: ScreenGui)
	local pill = Builder.blockPlate({
		parent = root,
		name = "ScrapPill",
		color = Theme.Block.Trough,
		aspect = SCRAP_ASPECT,
		position = UDim2.fromScale(0.015, 0.025),
		size = UDim2.fromScale(0.3, 0.085),
	})
	scrapPill = pill
	local top = Builder.blockTop(pill)
	local icon = iconSquare(pill, UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.2, 0.6), Theme.Colors.Featured, top)
	setSquareIcon(icon, "Scrap")
	local number = Builder.label({
		parent = pill,
		name = "Amount",
		text = "0",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.3, 0.5),
		size = UDim2.fromScale(0.64, 0.66),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	setScrapValue = Builder.rolling(number)
end

local function buildClockChip(root: ScreenGui)
	local chip, label = chipPlate(
		root,
		"ClockChip",
		Theme.Colors.Featured,
		UDim2.fromScale(CLOCK_RIGHT, CLOCK_TOP),
		CLOCK_SIZE,
		CLOCK_ASPECT,
		Strings.HUD_DAY
	)
	clockChip = chip
	clockLabel = label
end

-- Biome chip under the clock chip: which part of the world the player is standing in.
local function buildBiomeChip(root: ScreenGui)
	local _, label = chipPlate(
		root,
		"BiomeChip",
		Theme.Colors.Select,
		UDim2.fromScale(0.985, 0.108),
		Vector2.new(0.2, 0.05),
		CHIP_ASPECT,
		Strings.HUD_BIOME:format(Strings.BIOME_Meadow)
	)
	biomeLabel = label
end

-- Meteor Shower countdown chip under the biome chip: "Shower in m:ss", purple, hidden until the
-- bootstrap feeds a countdown in (Config.ShowerWarnSeconds before a shower).
local function buildShowerChip(root: ScreenGui)
	local chip, label = chipPlate(
		root,
		"ShowerChip",
		Theme.Colors.Codex,
		UDim2.fromScale(0.985, 0.165),
		Vector2.new(0.2, 0.05),
		CHIP_ASPECT,
		Strings.SHOWER_CHIP:format(formatCountdown(0))
	)
	chip.Visible = false
	showerChip = chip
	showerLabel = label
end

-- A red notification block with a count on the button's top-right corner, hidden until SetBadge. `size` is its width as a
-- fraction of the button; a smaller button takes a bigger dot so its count stays readable.
local function addBadge(button: Frame, size: number)
	local badge = Builder.blockPlate({
		parent = button,
		name = "Badge",
		color = Theme.Colors.Close,
		aspect = 1,
		rows = BADGE_ROWS,
		cells = false,
		position = UDim2.fromScale(0.98, 0.02),
		size = UDim2.fromScale(size, size),
		anchor = Vector2.new(0.8, 0.2),
		zIndex = 5,
	})
	Builder.label({
		parent = badge,
		name = "Count",
		text = "",
		textSize = Theme.TextSize.Min,
		size = UDim2.fromScale(0.9, 0.9),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(badge),
	})
	badge.Visible = false
end

-- Left-edge icon stack: square buttons with a label beneath, as the hit sims lay them out. The face shows
-- the id's icon from the pack; while that icon is not uploaded it shows the MENU_GLYPH_<id> glyph.
local function buildMenuButton(root: ScreenGui, id: string, color: Color3, onClick: () -> ()): Frame
	local label = Builder.text("MENU_" .. id)
	local glyph = Builder.text("MENU_GLYPH_" .. id)
	local top = MENU_TOP + menuCount * MENU_SLOT
	menuCount += 1
	local slot = Builder.frame({
		parent = root,
		name = "Menu_" .. id,
		position = UDim2.fromScale(MENU_LEFT, top),
		size = UDim2.fromScale(Theme.Menu.SlotW, MENU_SLOT),
		aspect = Theme.Menu.Aspect,
	})
	local button = Builder.blockButton({
		parent = slot,
		name = "Button",
		text = if glyph == "MENU_GLYPH_" .. id then string.upper(string.sub(label, 1, 1)) else glyph,
		icon = id,
		color = color,
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, MENU_BUTTON / MENU_SLOT),
		anchor = Vector2.new(0.5, 0),
		textSize = Theme.TextSize.Title,
		aspect = 1,
		rows = Builder.blockButtonRows(MENU_BUTTON), -- its size is a fraction of the slot, so the rows come from its screen height
		hit = true, -- about 36 px at iPhone SE height: the 44 px floor
	}, onClick)
	Builder.label({
		parent = slot,
		name = "Label",
		text = label,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(1.3, 1 - MENU_BUTTON / MENU_SLOT),
		anchor = Vector2.new(0.5, 1),
	})
	addBadge(button, MENU_BADGE_SIZE)
	menuButtons[id] = button
	return button
end

-- Cumulative module weights for the default world, until the bootstrap calls SetShipTicks.
local function defaultTicks(): { number }
	local out: { number } = {}
	local acc = 0
	for _, def in ipairs(Modules.Worlds[DEFAULT_TICK_WORLD] or {}) do
		acc += def.weight
		table.insert(out, acc)
	end
	return out
end

-- Ship bar top centre: a dark block trough whose face fills cell-true in the Select blue (Builder.blockBar keeps the stepped
-- corners and draws the grout over the fill), milestone ticks, centred "Ship N%" text, and an invisible button over it all so a
-- tap opens the ship panel.
local function buildShipBar(root: ScreenGui)
	local trough = Builder.blockPlate({
		parent = root,
		name = "ShipBar",
		color = Theme.Block.Trough,
		aspect = CHIP_ASPECT,
		position = UDim2.fromScale(0.5, CLOCK_TOP + CENTER_SHIFT), -- the top row's y, shifted under the strip
		size = UDim2.fromScale(0.3, 0.075),
		anchor = Vector2.new(0.5, 0),
	})
	local setFill = Builder.blockBar(trough, Theme.Colors.Select)
	local value = Instance.new("NumberValue")
	value.Name = "Fill"
	value.Value = 0
	value.Changed:Connect(setFill)
	value.Parent = trough
	shipValue = value
	local innerPosition, innerSize = Builder.blockInner(trough)
	local top = Builder.blockTop(trough)
	shipTicks = Builder.frame({
		parent = trough,
		name = "Ticks",
		position = innerPosition,
		size = innerSize,
		zIndex = top,
	})
	shipLabel = Builder.label({
		parent = trough,
		name = "Text",
		text = Strings.HUD_SHIP:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = top + 1,
	})
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = top + 2
	tap.Parent = trough
	tap.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		if onShipTapped then
			onShipTapped()
		end
	end)
	Hud.SetShipTicks(defaultTicks())
end

-- "+N/min" under the Scrap pill; hidden while the camp earns nothing.
local function buildRateLine(root: ScreenGui)
	local label = Builder.label({
		parent = root,
		name = "Rate",
		text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(0)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.03, 0.115),
		size = UDim2.fromScale(0.3, 0.045),
		color = Theme.Colors.Confirm,
		xAlign = Enum.TextXAlignment.Left,
	})
	label.Visible = false
	rateLabel = label
end

-- "Luck xN.N" under the ship bar; hidden while luck is exactly 1.
local function buildLuckLine(root: ScreenGui)
	local label = Builder.label({
		parent = root,
		name = "Luck",
		text = Strings.HUD_LUCK:format(("%.1f"):format(1)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.105 + CENTER_SHIFT),
		size = UDim2.fromScale(0.3, 0.045),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Featured,
	})
	label.Visible = false
	luckLabel = label
end

-- Event banner in the luck line's slot under the ship bar (UI Playbook, "Event banner and compass"; the
-- board's event chip): a Codex-purple block plate with the event's pixel icon on the left, the event text
-- left-aligned, and a flat green block on the right for the luck multiplier. Hidden until SetEventBanner;
-- while it shows, the luck line stays hidden (the chip carries the number).
local function buildEventBanner(root: ScreenGui)
	local pill = Builder.blockPlate({
		parent = root,
		name = "EventBanner",
		color = Theme.Colors.Codex,
		aspect = BANNER_ASPECT,
		position = UDim2.fromScale(0.5, 0.105 + CENTER_SHIFT),
		size = UDim2.fromScale(0.4, 0.07),
		anchor = Vector2.new(0.5, 0),
	})
	pill.Visible = false
	banner = pill
	local top = Builder.blockTop(pill)
	-- the placeholder is a gold flat block (the purple of the old square would vanish on the purple plate)
	bannerIcon = iconSquare(pill, UDim2.fromScale(0.03, 0.5), UDim2.fromScale(0.1, 0.6), Theme.Colors.Featured, top)
	-- Two lines, per the Playbook: the event name bold on top, the time left smaller beneath it.
	bannerText = Builder.label({
		parent = pill,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(BANNER_TEXT_LEFT, BANNER_NAME_Y),
		size = UDim2.fromScale(BANNER_TEXT_WIDTH, BANNER_NAME_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	bannerSub = Builder.label({
		parent = pill,
		name = "Sub",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(BANNER_TEXT_LEFT, BANNER_SUB_Y),
		size = UDim2.fromScale(BANNER_TEXT_WIDTH, BANNER_SUB_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	local chip = Builder.blockPlate({
		parent = pill,
		name = "Chip",
		color = Theme.Colors.Confirm,
		aspect = BANNER_ASPECT * BANNER_CHIP.X / BANNER_CHIP.Y, -- its px shape on the banner, so the box does not move
		rows = BADGE_ROWS,
		cells = false,
		position = UDim2.fromScale(0.97, 0.5),
		size = UDim2.fromScale(BANNER_CHIP.X, BANNER_CHIP.Y),
		anchor = Vector2.new(1, 0.5),
		zIndex = top,
	})
	bannerChip = chip
	bannerChipLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(chip),
	})
end

-- Friend Boost chip under the luck line / event banner slot: "Friend Boost +N%", a dark block at 0 and
-- green above it; a tap opens the invite sheet (the bootstrap's callback).
local function buildFriendChip(root: ScreenGui)
	local chip = Builder.blockPlate({
		parent = root,
		name = "FriendChip",
		color = Theme.Block.Trough,
		aspect = FRIEND_CHIP_ASPECT,
		position = UDim2.fromScale(0.5, FRIEND_CHIP_TOP),
		size = UDim2.fromScale(FRIEND_CHIP_SIZE.X, FRIEND_CHIP_SIZE.Y),
		anchor = Vector2.new(0.5, 0),
	})
	friendChip = chip
	local top = Builder.blockTop(chip)
	friendLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.HUD_FRIEND_BOOST:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Rarity.Common,
		zIndex = top,
	})
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = top + 1
	tap.Parent = chip
	tap.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		Builder.pop(chip, 1.1)
		if onFriendChipTapped then
			onFriendChipTapped()
		end
	end)
end

-- The luck line shows by its own rule (luck is not exactly 1) unless the event banner has its slot.
local function applyLuckLine()
	local label = luckLabel
	if not label then
		return
	end
	local pill = banner
	label.Visible = luckShown and not (pill ~= nil and pill.Visible)
end

local function buildActionButton(root: ScreenGui)
	local button = Builder.blockButton({
		parent = root,
		name = "Action",
		text = Strings.ACTION_CATCH,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.975, 0.96),
		size = UDim2.fromScale(0.3, 0.13),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Title,
		aspect = ACTION_ASPECT,
		hit = true, -- the face is about 42 px tall at iPhone SE height once the one-cell lip is under it: the 44 px floor
	}, function()
		if onAction then
			onAction()
		end
	end)
	button.Visible = false
	actionButton = button
	actionFace = button:FindFirstChild("Face") :: TextButton
end

-- Top buttons (left of the clock chip) ----------------------------------------

-- The clock chip's width in screen Scale. Its aspect constraint derives the width from the height
-- (never past its Size bound), so the width in Scale depends on the screen's shape.
local function clockChipWidth(root: ScreenGui): number
	local screen = root.AbsoluteSize
	if screen.X <= 0 or screen.Y <= 0 then
		return CLOCK_SIZE.X
	end
	return math.min(CLOCK_SIZE.X, CLOCK_SIZE.Y * CLOCK_ASPECT * screen.Y / screen.X)
end

-- Places the top buttons in a row leftwards from the chip. Each is a square of TOP_BUTTON_H, so its
-- width in Scale is TOP_BUTTON_H * (screen height / screen width); anchored (1, 0), its x is its right edge.
-- The row stops short of the centre column: the ship bar (the clock chip's size, centred) and the compass
-- strip above it (CompassData.StripWidth) are in the way at 4:3, where the top buttons are as tall as the chip.
-- A button that would reach them goes in a column under the row's first button instead (below the clock chip's
-- left neighbour, where the biome chip and the radar are further right and the event banner is further left).
local function layoutTopButtons()
	local root = gui
	if not root then
		return
	end
	local screen = root.AbsoluteSize
	local ratio = if screen.X > 0 then screen.Y / screen.X else 1
	local buttonW = TOP_BUTTON_H * ratio
	local start = CLOCK_RIGHT - clockChipWidth(root) - TOP_GAP
	local limit = 0.5 + math.max(clockChipWidth(root), CompassData.StripWidth) / 2 + TOP_GAP
	local right = start
	local stacked = 0
	for _, button in ipairs(topButtons) do
		if not button.Visible then
			continue -- a hidden button leaves no gap
		end
		if right == start or right - buttonW >= limit then
			button.Position = UDim2.fromScale(right, CLOCK_TOP)
			right -= buttonW + TOP_GAP
		else
			stacked += 1
			button.Position = UDim2.fromScale(start, CLOCK_TOP + stacked * (TOP_BUTTON_H + TOP_GAP))
		end
	end
end

-- Public API -------------------------------------------------------------

function Hud.Build()
	if gui then
		return
	end
	local root = Builder.screen("HUD", 10)
	gui = root
	menuGui = Builder.screen("Menu", MENU_DISPLAY_ORDER)
	buildScrapPill(root)
	buildClockChip(root)
	buildBiomeChip(root)
	buildShowerChip(root)
	buildShipBar(root)
	buildRateLine(root)
	buildLuckLine(root)
	buildEventBanner(root)
	buildFriendChip(root)
	buildActionButton(root)
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTopButtons)
end

-- Ship completion 0..1: eases the fill and shows the whole percent.
function Hud.SetShip(percent01: number)
	local value, label = shipValue, shipLabel
	if not value or not label then
		return
	end
	local p = math.clamp(percent01, 0, 1)
	if shipTween then
		shipTween:Cancel()
	end
	local info = TweenInfo.new(SHIP_FILL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(value, info, { Value = p })
	shipTween = tween
	tween:Play()
	label.Text = Strings.HUD_SHIP:format(math.floor(p * 100))
end

-- Milestone tick marks (cumulative module weights, 0..1). The final mark sits at the bar's end and
-- is skipped, so the caller may pass Economy.milestones(world) as is.
function Hud.SetShipTicks(marks: { number })
	local holder = shipTicks
	if not holder then
		return
	end
	for _, child in ipairs(holder:GetChildren()) do
		child:Destroy()
	end
	for _, mark in ipairs(marks) do
		if mark > 0 and mark < 1 then
			Builder.frame({
				parent = holder,
				name = "Tick",
				position = UDim2.fromScale(mark, 0.5),
				size = UDim2.fromScale(TICK_WIDTH, 1),
				anchor = Vector2.new(0.5, 0.5),
				color = Theme.Colors.White,
				transparency = 0.45,
				zIndex = 3,
			})
		end
	end
end

function Hud.OnShipTapped(callback: () -> ())
	onShipTapped = callback
end

-- Scrap income per second; the line reads "+N/min" and hides when the camp earns nothing.
function Hud.SetRate(perSecond: number)
	local label = rateLabel
	if not label then
		return
	end
	if perSecond <= 0 then
		label.Visible = false
		return
	end
	label.Text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(perSecond * 60))
	label.Visible = true
end

-- The server's luck multiplier (LuckChanged), one decimal; the line hides while luck is exactly 1,
-- and stays hidden while the event banner holds its slot (the banner's chip carries the number).
function Hud.SetLuck(luck: number)
	local label = luckLabel
	if not label then
		return
	end
	luckShown = luck ~= 1
	if luckShown then
		-- Round half up to one decimal before formatting (1.25 must read x1.3, and %.1f would print 1.2).
		luck = math.floor(luck * 10 + 0.5) / 10
		label.Text = Strings.HUD_LUCK:format(("%.1f"):format(luck))
	end
	applyLuckLine()
end

-- The Friend Boost (FriendBoostChanged): `boost` is a fraction, shown as a whole percent. The chip
-- is dim at 0, green above it, and pops when the friend count grows.
function Hud.SetFriendBoost(count: number, boost: number)
	local chip, label = friendChip, friendLabel
	if not chip or not label then
		return
	end
	label.Text = Strings.HUD_FRIEND_BOOST:format(math.floor(boost * 100 + 0.5))
	local active = boost > 0
	local color = if active then Theme.Colors.Confirm else Theme.Block.Trough
	label.TextColor3 = if active then Theme.Colors.White else Theme.Rarity.Common
	Builder.setBlockColor(chip, color, TweenInfo.new(Theme.Tween.Open))
	if count > friendCountShown then
		Builder.pop(chip, 1.1)
	end
	friendCountShown = count
end

function Hud.OnFriendChipTapped(callback: () -> ())
	onFriendChipTapped = callback
end

-- The event banner in the luck line's slot: `text` is the event name (SHOWER_NOW), `subtitle` the
-- smaller line beneath it (the time left, SHOWER_LEFT formatted) and `chip` the green chip's text
-- (SHOWER_LUCK formatted); nil text hides the banner and gives the luck line its slot back. `iconKey` is an
-- Icons key for the square on the left; nil, or an icon not uploaded yet, leaves the gold placeholder.
-- On a banner too short for two lines at the 14 px floor (iPhone SE) the name and the subtitle take turns on one line, each
-- for Theme.Tween.BannerLine seconds; the bootstrap calls this on its poll, which moves the turn along.
function Hud.SetEventBanner(text: string?, subtitle: string?, chip: string?, iconKey: string?)
	local pill, label, sub = banner, bannerText, bannerSub
	if not pill or not label or not sub then
		return
	end
	if text then
		local square = bannerIcon
		if square and iconKey ~= bannerIconKey then
			bannerIconKey = iconKey
			setSquareIcon(square, iconKey)
		end
		local width = if chip then BANNER_TEXT_WIDTH else BANNER_TEXT_WIDTH_FULL
		local tall = pill.AbsoluteSize.Y
		local twoLines = subtitle ~= nil and (tall <= 0 or tall * BANNER_SUB_H >= Theme.TextSize.Min)
		if twoLines then
			label.Text = text
			sub.Text = subtitle or ""
		else
			local turn = Theme.Tween.BannerLine
			local showSub = subtitle ~= nil and os.clock() % (2 * turn) >= turn
			label.Text = if showSub then subtitle or text else text
		end
		sub.Visible = twoLines
		label.Size = UDim2.fromScale(width, if twoLines then BANNER_NAME_H else BANNER_ONE_H)
		label.Position = UDim2.fromScale(BANNER_TEXT_LEFT, if twoLines then BANNER_NAME_Y else BANNER_ONE_Y)
		sub.Size = UDim2.fromScale(width, BANNER_SUB_H)
		if bannerChip then
			bannerChip.Visible = chip ~= nil
		end
		if bannerChipLabel then
			bannerChipLabel.Text = chip or ""
		end
		if not pill.Visible then
			pill.Visible = true
			Builder.pop(pill, 1.1)
		end
	else
		pill.Visible = false
	end
	applyLuckLine()
end

-- Event countdown chip under the biome chip: seconds until the event, or nil to hide it. `format` is the
-- chip's string with one %s for the time (SHOWER_CHIP when nil; the Catch Rush passes RUSH_CHIP).
function Hud.SetEventCountdown(seconds: number?, format: string?)
	local chip, label = showerChip, showerLabel
	if not chip or not label then
		return
	end
	if seconds then
		label.Text = (format or Strings.SHOWER_CHIP):format(formatCountdown(seconds))
		if not chip.Visible then
			chip.Visible = true
			Builder.pop(chip, 1.1)
		end
	else
		chip.Visible = false
	end
end

-- Meteor Shower countdown chip under the biome chip: seconds until the shower, or nil to hide it.

function Hud.SetScrap(amount: number)
	if setScrapValue then
		setScrapValue(amount)
	end
	if amount > lastScrap then
		Builder.playSound(Sounds.ScrapTick)
	end
	lastScrap = amount
end

-- A gold outlined "+N" that pops at the action button (or bottom centre while it is hidden), flies to
-- the Scrap pill over Config.GainFlySeconds while shrinking a little, then fades and is destroyed.
-- Every call makes its own label, so several in flight never interfere. Pure presentation: the amount
-- is whatever the server granted.
function Hud.FlyGain(amount: number)
	local root, pill = gui, scrapPill
	if not root or not pill then
		return
	end
	local screen = root.AbsoluteSize
	if screen.X <= 0 or screen.Y <= 0 then
		return
	end
	local fromX, fromY = 0.5, FLY_FALLBACK_Y
	local button = actionButton
	if button and button.Visible then
		fromX, fromY = centreScale(root, button)
	end
	local toX, toY = centreScale(root, pill)

	local label = Builder.label({
		parent = root,
		name = "Gain",
		text = Strings.GAIN_FLY:format(Builder.formatNumber(amount)),
		textSize = Theme.TextSize.Title,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(fromX, fromY),
		size = UDim2.fromScale(FLY_SIZE.X, FLY_SIZE.Y),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = FLY_ZINDEX,
	})
	Builder.pop(label, 1.3)

	local factor = motionFactor()
	local flyInfo = TweenInfo.new(Config.GainFlySeconds * factor, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fly = TweenService:Create(label, flyInfo, {
		Position = UDim2.fromScale(toX, toY),
		Size = UDim2.fromScale(FLY_SIZE.X * FLY_SHRINK, FLY_SIZE.Y * FLY_SHRINK),
	})
	fly.Completed:Once(function()
		local fadeInfo = TweenInfo.new(FLY_FADE_SECONDS * factor, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
		end
		local fade = TweenService:Create(label, fadeInfo, { TextTransparency = 1 })
		fade.Completed:Once(function()
			label:Destroy()
		end)
		fade:Play()
	end)
	fly:Play()
end

-- Adds an entry to the left icon stack. Call after Hud.Build, once per screen, in display order.
function Hud.AddMenuButton(id: string, color: Color3, onClick: () -> ())
	local root = menuGui
	if not root or menuButtons[id] then
		return
	end
	buildMenuButton(root, id, color, onClick)
end

-- A square block button just left of the clock chip (then left of the previous one, or under the first once the row
-- would reach the ship bar and the compass), with the id's pixel icon as its face (the MENU_GLYPH_<id> glyph when the id has
-- no icon). It lives in the HUD gui, so it hides with SetVisible. Call after Hud.Build, once per id.
function Hud.AddTopButton(id: string, color: Color3, onClick: () -> ())
	local root = gui
	if not root or topButtonIds[id] then
		return
	end
	topButtonIds[id] = true
	local label = Builder.text("MENU_" .. id)
	local glyph = Builder.text("MENU_GLYPH_" .. id)
	local button = Builder.blockButton({
		parent = root,
		name = "Top_" .. id,
		text = if glyph == "MENU_GLYPH_" .. id then string.upper(string.sub(label, 1, 1)) else glyph,
		icon = id,
		color = color,
		position = UDim2.fromScale(CLOCK_RIGHT, CLOCK_TOP),
		size = UDim2.fromScale(CLOCK_SIZE.X, TOP_BUTTON_H),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		hit = true, -- about 28 px at iPhone SE height: the 44 px floor
	}, onClick)
	addBadge(button, TOP_BADGE_SIZE)
	table.insert(topButtons, button)
	topButtonById[id] = button
	layoutTopButtons()
end

-- Shows or hides a top button (a feature switched off in its data table hides its button entirely); the others close
-- up the gap. Unknown ids do nothing.
function Hud.SetTopButtonVisible(id: string, visible: boolean)
	local button = topButtonById[id]
	if not button or button.Visible == visible then
		return
	end
	button.Visible = visible
	layoutTopButtons()
end

-- The icon stack hides during a capture or a reveal (it sits above those dims) and shows otherwise.
function Hud.SetMenuVisible(visible: boolean)
	if menuGui and menuGui.Enabled ~= visible then
		menuGui.Enabled = visible
	end
end

-- Shows a red dot with a count on a menu button or a top button; 0 hides it.
function Hud.SetBadge(id: string, count: number)
	local button = menuButtons[id] or topButtonById[id]
	if not button then
		return
	end
	local badge = button:FindFirstChild("Badge")
	if not badge or not badge:IsA("Frame") then
		return
	end
	badge.Visible = count > 0
	local label = badge:FindFirstChild("Count")
	if label and label:IsA("TextLabel") then
		label.Text = if count > 0 then tostring(count) else ""
	end
	if count > 0 then
		Builder.pop(button, 1.15)
	end
end

function Hud.SetBiome(biome: string)
	if biomeLabel then
		biomeLabel.Text = Strings.HUD_BIOME:format(Builder.text("BIOME_" .. biome))
	end
end

-- The biome chip's text exactly as given: the bootstrap's words for a visit ("Mossy's home") in place of the biome's
-- name. SetBiome formats through the strings; this does not.
function Hud.SetBiomeLabel(text: string)
	if biomeLabel then
		biomeLabel.Text = text
	end
end

function Hud.SetClock(state: Types.ClockState)
	if not clockLabel or not clockChip then
		return
	end
	local phase = if state.isNight then Strings.HUD_NIGHT else Strings.HUD_DAY
	local weather = Builder.text("WEATHER_" .. state.weather)
	clockLabel.Text = Strings.HUD_CLOCK:format(phase, weather)
	local color = if state.isNight then Theme.Colors.Select else Theme.Colors.Featured
	Builder.setBlockColor(clockChip, color, TweenInfo.new(Theme.Tween.Open))
end

-- Show the contextual button with this text, or hide it with nil. It breathes while shown.
function Hud.SetAction(text: string?)
	local button, face = actionButton, actionFace
	if not button or not face then
		return
	end
	if text then
		face.Text = text
		if not button.Visible then
			button.Visible = true
			Builder.pop(button, 1.1)
			local scale = button:FindFirstChildOfClass("UIScale")
			if scale then
				task.delay(Theme.Tween.Open, function()
					if not button.Visible then
						return
					end
					local info = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
					local tween = TweenService:Create(scale, info, { Scale = Theme.Scale.Breathe })
					breathe = tween
					tween:Play()
				end)
			end
		end
	elseif button.Visible then
		button.Visible = false
		if breathe then
			breathe:Cancel()
			breathe = nil
		end
		local scale = button:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
end

function Hud.OnAction(callback: () -> ())
	onAction = callback
end

function Hud.SetVisible(visible: boolean)
	if gui then
		gui.Enabled = visible
	end
	if menuGui then
		menuGui.Enabled = visible
	end
end

return Hud
