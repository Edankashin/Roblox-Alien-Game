--!strict
-- StarterPlayerScripts.Client.UI.Builder: the only place UI instances are created. Every screen
-- builds from these helpers so the look (Theme) is applied once and consistently: Scale-only
-- positions and sizes, Fredoka One, outlined text, chunky buttons with a lip and a gloss band, a click on every tap.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local BadgeFit = require(Shared:WaitForChild("BadgeFit"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))

local Builder = {}

local EMPTY_SOUND = "rbxassetid://0"
local BUTTON_ICON_SCALE = 0.7 -- a button's icon fills this fraction of its face, centred

export type FrameProps = {
	parent: Instance?,
	name: string?,
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	color: Color3?,
	transparency: number?,
	corner: number?, -- px radius from Theme.Corner; Theme.Corner.Pill means a full pill
	stroke: number?,
	strokeColor: Color3?,
	zIndex: number?,
	aspect: number?, -- width / height, keeps the shape across screens
	gloss: boolean?, -- true adds the Builder.gloss highlight band; off by default (frames and pills are plain containers)
}

export type LabelProps = {
	parent: Instance?,
	name: string?,
	text: string,
	textSize: number?, -- max px from Theme.TextSize; scales down to Theme.TextSize.Min
	color: Color3?,
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	stroke: number?, -- 0 for none
	strokeColor: Color3?,
	xAlign: Enum.TextXAlignment?,
	zIndex: number?,
	font: Enum.Font?,
}

export type ButtonProps = {
	parent: Instance?,
	name: string?,
	text: string,
	color: Color3,
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	textSize: number?,
	zIndex: number?,
	aspect: number?,
	icon: string?, -- an Icons key: shown on the face instead of `text` once its image is uploaded (id not 0)
	hit: boolean?, -- true adds an invisible hit area the face's size, grown to at least Theme.TapMin px each way and centred on it (the UI Playbook's 44 px floor for a small face)
}

export type RibbonProps = {
	parent: Instance?,
	name: string?,
	text: string,
	color: Color3,
	aspect: number, -- the holder's width over its height in px, so the swallowtail diamonds come out square
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	zIndex: number?,
}

export type SealProps = {
	parent: Instance?,
	name: string?,
	text: string,
	color: Color3,
	position: UDim2?,
	size: UDim2?, -- the caller makes it square (the seal draws squares inside it and keeps no aspect of its own)
	anchor: Vector2?,
	rotation: number?,
	zIndex: number?,
}

export type IconProps = {
	parent: Instance?,
	name: string?,
	key: string, -- an Icons key or a data id with an alias (Gear "Boots" -> SpeedBoots)
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	zIndex: number?,
}

export type TextBoxProps = {
	parent: Instance?,
	name: string?,
	placeholder: string,
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	textSize: number?, -- max px from Theme.TextSize; scales down to Theme.TextSize.Min
	zIndex: number?,
}

-- Strings lookup by key for dynamic names (tiers, weather). Falls back to the key so nothing is blank.
local stringsByKey: { [string]: string } = {}
for key, value in pairs(Strings) do
	stringsByKey[key] = value
end

function Builder.text(key: string): string
	return stringsByKey[key] or key
end

function Builder.darker(color: Color3, amount: number?): Color3
	return color:Lerp(Theme.Colors.Black, amount or Theme.Darken)
end

function Builder.lighter(color: Color3, amount: number?): Color3
	return color:Lerp(Theme.Colors.White, amount or Theme.Lighten)
end

function Builder.tierColor(tier: string): Color3
	local colors: { [string]: Color3 } = Theme.Rarity
	return colors[tier] or Theme.Rarity.Common
end

-- The tint an overlay's badge wears when its data row names one (`tint`, a Theme.Colors key: Launch Gold is gold), else nil.
function Builder.overlayTint(overlay: string): Color3?
	local row = Overlays.Overlays[overlay]
	local colors: { [string]: Color3 } = Theme.Colors
	return if row and row.tint then colors[row.tint] else nil
end

-- The colour of an overlay's badge: its tint, else the Codex purple every plain overlay wears.
function Builder.overlayColor(overlay: string): Color3
	return Builder.overlayTint(overlay) or Theme.Colors.Codex
end

-- Overlay badge fitting. The label in a badge is TextScaled at no less than the 14 px floor, so it wraps and cuts when it is
-- narrower than its text at that size ("Launch Gold" read "Launch" on the Reveal and "Launc" on an Aliens card). The names
-- are measured once with TextService at the floor size (Fredoka One, as drawn) and Shared/BadgeFit turns the widths into
-- Scale sizes against the parent's pixels; a screen asks for a fit and sets it, once per change of window.
Builder.BadgeTextFraction = 0.9 -- the label's width over its badge's (the UI Playbook's chip text fraction)
local BADGE_SLACK_PX = 2 -- rounding room on top of a measured width
local BADGE_FALLBACK_EM = 0.58 -- px per glyph per px of text size when TextService cannot answer (8.1 px at 14 px, the widest run on record)
local overlayNames: { [string]: BadgeFit.Name } = {}
local longestOverlay: BadgeFit.Name? = nil

local function floorTextPx(text: string): number
	local ok, width = pcall(function(): number
		return TextService:GetTextSize(text, Theme.TextSize.Min, Theme.Font, Vector2.new(10000, 10000)).X
	end)
	if ok then
		return width
	end
	return #text * Theme.TextSize.Min * BADGE_FALLBACK_EM
end

-- An overlay's name (strings key OVERLAY_<id>) as measured: the whole string and each word, in px at the floor size.
function Builder.overlayName(overlay: string): BadgeFit.Name
	local cached = overlayNames[overlay]
	if cached then
		return cached
	end
	local text = Builder.text("OVERLAY_" .. overlay)
	local words: { BadgeFit.Line } = {}
	for word in text:gmatch("%S+") do
		table.insert(words, { text = word, px = floorTextPx(word) })
	end
	local name: BadgeFit.Name = { whole = { text = text, px = floorTextPx(text) }, words = words }
	overlayNames[overlay] = name
	return name
end

-- The widest overlay name in data/Overlays (Order lists every overlay that shows a badge), measured once.
function Builder.longestOverlayName(): BadgeFit.Name
	local cached = longestOverlay
	if cached then
		return cached
	end
	local best: BadgeFit.Name? = nil
	for _, overlay in ipairs(Overlays.Order) do
		local name = Builder.overlayName(overlay)
		if best == nil or name.whole.px > best.whole.px then
			best = name
		end
	end
	local found = best or Builder.overlayName("None")
	longestOverlay = found
	return found
end

-- The fit parameters of a badge that is `minWidth` wide before it is fitted and at most `maxWidth` (and, on a card,
-- `besideMax` while it shares its row with the speed chip), as Scales of its parent.
function Builder.badgeParams(minWidth: number, maxWidth: number, besideMax: number?): BadgeFit.Params
	return {
		textFraction = Builder.BadgeTextFraction,
		slackPx = BADGE_SLACK_PX,
		minWidth = minWidth,
		maxWidth = maxWidth,
		besideMax = besideMax,
	}
end

function Builder.formatNumber(n: number): string
	local whole = tostring(math.floor(math.abs(n) + 0.5))
	local out = whole:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return if n < 0 then "-" .. out else out
end

function Builder.corner(parent: GuiObject, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = if radius >= Theme.Corner.Pill then UDim.new(0.5, 0) else UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function Builder.stroke(parent: GuiObject, thickness: number, color: Color3?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color or Theme.Colors.Outline
	stroke.ApplyStrokeMode = if parent:IsA("TextLabel") or parent:IsA("TextButton")
		then Enum.ApplyStrokeMode.Contextual
		else Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- Vertical gradient, lighter at the top, from a single base colour.
function Builder.gradient(parent: GuiObject, color: Color3): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Builder.lighter(color), color)
	gradient.Parent = parent
	return gradient
end

-- Finish ------------------------------------------------------------------

local GLOSS_FADE_AT = 0.7 -- where down the gloss band its transparency reaches EdgeAlpha; it is clear by the bottom

-- The corner radius a highlight on `target` takes: the given Theme.Corner px value, else the target's own
-- UICorner, else nil (square corners).
local function matchingRadius(target: GuiObject, px: number?): UDim?
	if px then
		return if px >= Theme.Corner.Pill then UDim.new(0.5, 0) else UDim.new(0, px)
	end
	local existing = target:FindFirstChildOfClass("UICorner")
	return if existing then existing.CornerRadius else nil
end

local function roundLike(frame: Frame, radius: UDim?)
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = radius
		corner.Parent = frame
	end
end

-- A decorative overlay frame filling `position`/`size` of `target`, one ZIndex above it, that never
-- catches input (Active false): a tap goes through to the button underneath.
local function overlay(target: GuiObject, name: string, color: Color3, position: UDim2, size: UDim2): Frame
	local band = Instance.new("Frame")
	band.Name = name
	band.Active = false
	band.BorderSizePixel = 0
	band.BackgroundColor3 = color
	band.BackgroundTransparency = 0 -- the UIGradient carries the transparency: it combines with the frame's own, so setting both would count it twice
	band.Position = position
	band.Size = size
	band.ZIndex = target.ZIndex + 1
	return band
end

-- A white highlight band across the top Theme.Gloss.Top of `target`, fading out downward (the glossy
-- cartoon finish). Its corners are `corner` (a Theme.Corner px value), else the target's own UICorner.
-- It is a child, so it moves and scales with the target. Anything else on a glossed frame needs a ZIndex
-- above the target's + 1, or the highlight washes over it. Returns the "Gloss" frame.
function Builder.gloss(target: GuiObject, corner: number?): Frame
	local band = overlay(target, "Gloss", Theme.Colors.White, UDim2.fromScale(0, 0), UDim2.fromScale(1, Theme.Gloss.Top))
	roundLike(band, matchingRadius(target, corner))
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, Theme.Gloss.Alpha),
		NumberSequenceKeypoint.new(GLOSS_FADE_AT, Theme.Gloss.EdgeAlpha),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = band
	band.Parent = target
	return band
end

-- A soft black inner shadow across the bottom Theme.Gloss.Shadow of `target`, clear at its top edge and
-- Theme.Gloss.ShadowAlpha transparent at the bottom, with the target's own corners. Returns the "InnerShadow" frame.

function Builder.aspect(parent: GuiObject, ratio: number): UIAspectRatioConstraint
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio
	constraint.DominantAxis = Enum.DominantAxis.Height
	constraint.Parent = parent
	return constraint
end

-- The right edge, in screen Scale, of the HUD's left icon column on a screen of this size (Theme.Menu): the column
-- sits above every panel (display order 25), so a panel or tray whose left edge is less than this plus Theme.Menu.Gap
-- has its first letters hidden under it. Wide screens give a slot Aspect * SlotH of the height; a tall narrow one only SlotW of the width.
function Builder.menuRight(screen: Vector2): number
	if screen.X <= 0 or screen.Y <= 0 then
		return Theme.Menu.Left + Theme.Menu.SlotW
	end
	return Theme.Menu.Left + math.min(Theme.Menu.SlotW, Theme.Menu.Aspect * Theme.Menu.SlotH * screen.Y / screen.X)
end

function Builder.screen(name: string, displayOrder: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = displayOrder
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Builder.frame(props: FrameProps): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.name or "Frame"
	frame.Position = props.position or UDim2.fromScale(0, 0)
	frame.Size = props.size or UDim2.fromScale(1, 1)
	frame.AnchorPoint = props.anchor or Vector2.zero
	frame.BorderSizePixel = 0
	frame.ZIndex = props.zIndex or 1
	if props.color then
		frame.BackgroundColor3 = props.color
		frame.BackgroundTransparency = props.transparency or 0
	else
		frame.BackgroundTransparency = 1
	end
	if props.corner then
		Builder.corner(frame, props.corner)
	end
	if props.stroke and props.stroke > 0 then
		Builder.stroke(frame, props.stroke, props.strokeColor)
	end
	if props.aspect then
		Builder.aspect(frame, props.aspect)
	end
	if props.gloss then
		Builder.gloss(frame, props.corner)
	end
	frame.Parent = props.parent
	return frame
end

function Builder.pill(props: FrameProps): Frame
	local copy = table.clone(props)
	copy.corner = Theme.Corner.Pill
	return Builder.frame(copy)
end

function Builder.label(props: LabelProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name or "Label"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Position = props.position or UDim2.fromScale(0, 0)
	label.Size = props.size or UDim2.fromScale(1, 1)
	label.AnchorPoint = props.anchor or Vector2.zero
	label.FontFace = Font.fromEnum(props.font or Theme.Font)
	label.Text = props.text
	label.TextColor3 = props.color or Theme.Colors.White
	label.TextScaled = true
	label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Center
	label.ZIndex = props.zIndex or 1
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = math.max(Theme.TextSize.Min, props.textSize or Theme.TextSize.Body)
	sizes.Parent = label
	local strokeWidth = if props.stroke ~= nil then props.stroke else Theme.Stroke.Text
	if strokeWidth > 0 then
		Builder.stroke(label, strokeWidth, props.strokeColor)
	end
	label.Parent = props.parent
	return label
end

-- The image asset id for an icon key (aliases first), or nil while it is unknown or not uploaded (id 0).
local function resolveIcon(key: string): number?
	local id: number? = Icons.Icons[Icons.Aliases[key] or key]
	if id == nil or id == 0 then
		return nil
	end
	return id
end

-- An icon from the pack as an ImageLabel, or nil (and nothing created) while its id is 0 or the key is
-- unknown: callers keep their text glyph or placeholder shape then, so the UI works with or without the pack.
function Builder.icon(props: IconProps): ImageLabel?
	local id = resolveIcon(props.key)
	if not id then
		return nil
	end
	local image = Instance.new("ImageLabel")
	image.Name = props.name or "Icon"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = "rbxassetid://" .. id
	image.ScaleType = Enum.ScaleType.Fit
	image.Position = props.position or UDim2.fromScale(0, 0)
	image.Size = props.size or UDim2.fromScale(1, 1)
	image.AnchorPoint = props.anchor or Vector2.zero
	image.ZIndex = props.zIndex or 1
	image.Parent = props.parent
	return image
end

-- A chunky block button: a darker lip underneath, a gradient face with a stroke and a gloss band, outlined
-- white text. Returns the container; the TextButton is its "Face" child. Press scales down and sinks the
-- face, and the gloss (a child of the face) goes with it.
-- With props.icon set and uploaded, the face shows the icon (centred, BUTTON_ICON_SCALE of the face, a child
-- of the face so it presses with it, above the gloss) and no text; otherwise it shows props.text.
function Builder.button(props: ButtonProps, onClick: () -> ()): Frame
	local container = Builder.frame({
		parent = props.parent,
		name = props.name or "Button",
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = props.zIndex,
		aspect = props.aspect,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = container

	local lipColor = Builder.darker(props.color)
	Builder.frame({
		parent = container,
		name = "Lip",
		color = lipColor,
		corner = Theme.Corner.Button,
		zIndex = props.zIndex,
	})

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AutoButtonColor = false
	face.BorderSizePixel = 0
	face.Position = UDim2.fromScale(0, 0)
	face.Size = UDim2.fromScale(1, 1 - Theme.ButtonLip)
	face.BackgroundColor3 = props.color
	face.FontFace = Font.fromEnum(Theme.Font)
	face.Text = props.text
	face.TextColor3 = Theme.Colors.White
	face.TextScaled = true
	face.ZIndex = (props.zIndex or 1) + 1
	Builder.corner(face, Theme.Corner.Button)
	local border = Builder.stroke(face, Theme.Stroke.Button, lipColor)
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Builder.stroke picks Contextual for text objects
	Builder.gradient(face, props.color)
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = props.textSize or Theme.TextSize.Label
	sizes.Parent = face
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = Theme.Stroke.Text
	textStroke.Color = Theme.Colors.Outline
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = face
	Builder.gloss(face, Theme.Corner.Button)
	if props.icon then
		local image = Builder.icon({
			parent = face,
			name = "Icon",
			key = props.icon,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(BUTTON_ICON_SCALE, BUTTON_ICON_SCALE),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = face.ZIndex + 2, -- above the gloss band (face + 1)
		})
		if image then
			face.Text = ""
		end
	end
	face.Parent = container

	local pressInfo = TweenInfo.new(Theme.Tween.Press, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function press()
		TweenService:Create(scale, pressInfo, { Scale = Theme.Scale.PressDown }):Play()
		TweenService:Create(face, pressInfo, { Position = UDim2.fromScale(0, Theme.ButtonLip) }):Play()
	end
	local function release()
		TweenService:Create(scale, pressInfo, { Scale = 1 }):Play()
		TweenService:Create(face, pressInfo, { Position = UDim2.fromScale(0, 0) }):Play()
	end
	face.MouseButton1Down:Connect(press)
	face.MouseButton1Up:Connect(release)
	face.MouseLeave:Connect(release)
	face.MouseEnter:Connect(function()
		TweenService:Create(scale, pressInfo, { Scale = Theme.Scale.Hover }):Play()
	end)
	face.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		onClick()
	end)
	if props.hit then
		-- A face under Theme.TapMin gets an invisible button over it: the face's own size, floored at TapMin px each way
		-- (UISizeConstraint grows it around its centre), a ZIndex above anything the face overlaps. It drives the same press,
		-- hover and click, so the face still looks pressed; the face itself never sees a tap.
		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.Text = ""
		hit.AutoButtonColor = false
		hit.BackgroundTransparency = 1
		hit.BorderSizePixel = 0
		hit.AnchorPoint = Vector2.new(0.5, 0.5)
		hit.Position = UDim2.fromScale(0.5, (1 - Theme.ButtonLip) / 2)
		hit.Size = UDim2.fromScale(1, 1 - Theme.ButtonLip)
		hit.ZIndex = face.ZIndex + 6
		local floor = Instance.new("UISizeConstraint")
		floor.MinSize = Vector2.new(Theme.TapMin, Theme.TapMin)
		floor.Parent = hit
		hit.Parent = container
		hit.MouseButton1Down:Connect(press)
		hit.MouseButton1Up:Connect(release)
		hit.MouseLeave:Connect(release)
		hit.MouseEnter:Connect(function()
			TweenService:Create(scale, pressInfo, { Scale = Theme.Scale.Hover }):Play()
		end)
		hit.Activated:Connect(function()
			Builder.playSound(Sounds.Click)
			onClick()
		end)
	end
	return container
end

-- A folded ribbon plate for a status word (BEST DEAL, NEW!): a navy-outlined plate in `color` with a gloss band, white outlined
-- text at the 14 px floor, and a darker diamond poking out under each end for the swallowtail. The holder is the size given
-- (`aspect` is its width over its height in px), the plate fills most of it (Theme.Ribbon), and nothing in it takes taps.
-- Returns the holder.
function Builder.ribbon(props: RibbonProps): Frame
	local z = props.zIndex or 1
	local holder = Builder.frame({
		parent = props.parent,
		name = props.name or "Ribbon",
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = z,
	})
	local dark = Builder.darker(props.color)
	for side = 0, 1 do
		local tail = Builder.frame({
			parent = holder,
			name = "Tail",
			position = UDim2.fromScale(0.05 + side * 0.9, 0.5 + Theme.Ribbon.Tail / 4),
			size = UDim2.fromScale(Theme.Ribbon.Tail / props.aspect, Theme.Ribbon.Tail),
			anchor = Vector2.new(0.5, 0.5),
			color = dark,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = z,
		})
		tail.Rotation = 45
	end
	local plate = Builder.frame({
		parent = holder,
		name = "Plate",
		position = UDim2.fromScale(0.05, 0),
		size = UDim2.fromScale(0.9, 1 - Theme.Ribbon.Tail / 4),
		color = Theme.Colors.White, -- the gradient is the colour (a gradient multiplies its frame's colour, so the frame is white)
		corner = Theme.Ribbon.Corner,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		gloss = true,
		zIndex = z + 1,
	})
	local tint = Instance.new("UIGradient")
	tint.Rotation = 90
	tint.Color = ColorSequence.new(Builder.lighter(props.color), props.color)
	tint.Parent = plate
	Builder.label({
		parent = plate,
		name = "Text",
		text = props.text,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.94, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = z + 3,
	})
	return holder
end

-- A spiky starburst seal for a value claim (BEST VALUE): Theme.Seal.Spikes squares turned evenly through a quarter turn make
-- twice that many times two points; a navy set a little larger under a set in `color` gives the outline without a stroke
-- (overlapping strokes would show lines through the burst). The label is white outlined text over the middle. The caller sizes the
-- holder square and may turn it (`rotation`); nothing in it takes taps. Returns the holder.
function Builder.seal(props: SealProps): Frame
	local z = props.zIndex or 1
	local holder = Builder.frame({
		parent = props.parent,
		name = props.name or "Seal",
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = z,
	})
	holder.Rotation = props.rotation or 0
	local spikes = Theme.Seal.Spikes
	local quarter = 90
	for layer = 0, 1 do
		local side = if layer == 0 then Theme.Seal.Ink else Theme.Seal.Fill
		for index = 0, spikes - 1 do
			local square = Builder.frame({
				parent = holder,
				name = if layer == 0 then "Ink" else "Fill",
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(side, side),
				anchor = Vector2.new(0.5, 0.5),
				color = if layer == 0 then Theme.Colors.Outline else props.color,
				zIndex = z + layer,
			})
			square.Rotation = index * quarter / spikes
		end
	end
	Builder.label({
		parent = holder,
		name = "Text",
		text = props.text,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(Theme.Seal.Text, Theme.Seal.Text * 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = z + 3,
	})
	return holder
end

-- Restyles a button made by Builder.button: the face, lip, border and gradient take a new colour, the face a new label, and
-- `enabled` decides whether its face takes taps (Active). ReleasePanel and AliensScreen grey a button this way and say why.
function Builder.restyleButton(container: Frame?, text: string, color: Color3, enabled: boolean)
	if not container then
		return
	end
	local dark = Builder.darker(color)
	local lip = container:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = dark
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.BackgroundColor3 = color
		face.Text = text
		face.Active = enabled
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.Thickness == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

-- A one-line input in the theme's look: panel-coloured box with a navy border, Fredoka text with the
-- no text stroke (navy on cream), left-aligned inside a scale padding. The text is kept when it gains focus (typing
-- edits it); the caller reads .Text and listens to FocusLost for Enter.
function Builder.textBox(props: TextBoxProps): TextBox
	local box = Instance.new("TextBox")
	box.Name = props.name or "TextBox"
	box.Position = props.position or UDim2.fromScale(0, 0)
	box.Size = props.size or UDim2.fromScale(1, 1)
	box.AnchorPoint = props.anchor or Vector2.zero
	box.BorderSizePixel = 0
	box.BackgroundColor3 = Theme.Colors.Panel
	box.ZIndex = props.zIndex or 1
	box.FontFace = Font.fromEnum(Theme.Font)
	box.Text = ""
	box.PlaceholderText = props.placeholder
	box.PlaceholderColor3 = Theme.Rarity.Common
	box.TextColor3 = Theme.Colors.Outline -- navy on the cream panel, no text stroke: an input field, not a title
	box.TextScaled = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.MultiLine = false
	box.ClipsDescendants = true
	Builder.corner(box, Theme.Corner.Button)
	local border = Builder.stroke(box, Theme.Stroke.Text, Theme.Colors.Outline)
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Builder.stroke picks Contextual for text objects
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = math.max(Theme.TextSize.Min, props.textSize or Theme.TextSize.Body)
	sizes.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = box
	box.Parent = props.parent
	return box
end

-- Sounds -----------------------------------------------------------------

local soundCache: { [string]: Sound } = {}
local uiGroup: SoundGroup? = nil

-- The SoundGroup every UI cue plays through, at Sounds.Volume.UI (the Ambience module owns its own).
local function soundGroup(): SoundGroup
	local existing = uiGroup
	if existing then
		return existing
	end
	local created = Instance.new("SoundGroup")
	created.Name = "UI"
	created.Volume = Sounds.Volume.UI
	created.Parent = SoundService
	uiGroup = created
	return created
end

-- Plays a UI sound by asset id. Placeholder ids (rbxassetid://0) are skipped silently.
function Builder.playSound(id: string)
	if id == "" or id == EMPTY_SOUND then
		return
	end
	local sound = soundCache[id]
	if not sound then
		local created = Instance.new("Sound")
		created.Name = "UI"
		created.SoundId = id
		created.SoundGroup = soundGroup()
		created.Parent = SoundService
		soundCache[id] = created
		sound = created
	end
	SoundService:PlayLocalSound(sound)
end

-- Whether `id` is an empty placeholder (nothing plays, playSound skips it).
function Builder.isSilent(id: string): boolean
	return id == "" or id == EMPTY_SOUND
end

-- Plays a one-shot by asset id as a 3D sound at `host` (a part; it follows the part): full volume within `minDistance` studs,
-- fading out by `maxDistance`. It plays through the same UI group as playSound, so the player's Sounds level applies, and
-- removes itself when it ends (at the latest after `maxSeconds`, for a sound that never loads). Answers whether it started
-- one; a placeholder id plays nothing.
function Builder.playSoundAt(id: string, host: BasePart, minDistance: number, maxDistance: number, maxSeconds: number): boolean
	if Builder.isSilent(id) then
		return false
	end
	local sound = Instance.new("Sound")
	sound.Name = "Positional"
	sound.SoundId = id
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = minDistance
	sound.RollOffMaxDistance = maxDistance
	sound.SoundGroup = soundGroup()
	sound.Parent = host
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, maxSeconds)
	sound:Play()
	return true
end

-- The player's Sounds level (Prefs applies it): the UI group's volume becomes Sounds.Volume.UI * scale.
function Builder.SetSoundVolume(scale: number)
	soundGroup().Volume = Sounds.Volume.UI * math.max(0, scale)
end

-- Motion -----------------------------------------------------------------

local function scaleOf(target: GuiObject): UIScale
	local existing = target:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Parent = target
	return scale
end

-- Window open: 0.85 -> 1 with a Back ease (Theme.Tween.Open).
function Builder.open(target: GuiObject)
	local scale = scaleOf(target)
	scale.Scale = 0.85
	target.Visible = true
	TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Window close: 1 -> 0.85 (Theme.Tween.Close), then hidden and onDone.
function Builder.close(target: GuiObject, onDone: (() -> ())?)
	local scale = scaleOf(target)
	local tween = TweenService:Create(scale, TweenInfo.new(Theme.Tween.Close, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
	tween.Completed:Once(function()
		target.Visible = false
		if onDone then
			onDone()
		end
	end)
	tween:Play()
end

-- A quick pop: scale to `peak` and spring back.
function Builder.pop(target: GuiObject, peak: number?)
	local scale = scaleOf(target)
	scale.Scale = peak or 1.3
	TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Horizontal shake around the current position, in Scale units.
function Builder.shake(target: GuiObject, amount: number?)
	local origin = target.Position
	local dx = amount or 0.012
	local step = TweenInfo.new(0.04, Enum.EasingStyle.Linear)
	task.spawn(function()
		for i = 1, 4 do
			local sign = if i % 2 == 0 then 1 else -1
			local tween = TweenService:Create(target, step, { Position = origin + UDim2.fromScale(dx * sign, 0) })
			tween:Play()
			tween.Completed:Wait()
		end
		TweenService:Create(target, step, { Position = origin }):Play()
	end)
end

local SHINE_ANGLE = 20 -- degrees the shine band leans
local SHINE_TALL = 2 -- band height as a multiple of the target's, so the lean never leaves a gap at the top or bottom
local SHINE_OVERSHOOT = 0.5 -- how far past each side (a fraction of the target's width) the band rests, fully hidden
local SHINE_LAYER = 3 -- shine ZIndex above the target's: over the gloss and an icon

-- Reduced Motion (the profile toggle or the system switch). Prefs requires Builder, so Builder reads it
-- lazily at call time instead of requiring it at load (a require cycle); false when it cannot be read.
local function reducedMotion(): boolean
	local module = script.Parent.Parent:FindFirstChild("Prefs")
	if not module or not module:IsA("ModuleScript") then
		return false
	end
	local ok, value = pcall(function(): boolean
		local prefs = require(module) :: any
		return prefs.ReducedMotion() == true
	end)
	return ok and value
end

-- A diagonal white band that sweeps left to right across `target` over Theme.Gloss.ShineSeconds, rests
-- Theme.Gloss.ShineEvery seconds, and repeats, for the one featured button on a screen. The band lives in a
-- "ShineClip" child frame that clips it to the target (and takes the target's corners). Does nothing while
-- Reduced Motion is on (re-read before every sweep). Runs until the target is destroyed or the returned
-- function is called, which also removes the clip.
function Builder.shine(target: GuiObject): () -> ()
	local clip = Instance.new("Frame")
	clip.Name = "ShineClip"
	clip.Active = false
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Position = UDim2.fromScale(0, 0)
	clip.Size = UDim2.fromScale(1, 1)
	clip.ZIndex = target.ZIndex + SHINE_LAYER
	roundLike(clip, matchingRadius(target, nil))

	local restX = UDim2.fromScale(-SHINE_OVERSHOOT, 0.5)
	local band = Instance.new("Frame")
	band.Name = "Shine"
	band.Active = false
	band.BorderSizePixel = 0
	band.BackgroundColor3 = Theme.Colors.White
	band.BackgroundTransparency = 0 -- the UIGradient carries the transparency (see overlay)
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = restX
	band.Size = UDim2.fromScale(Theme.Gloss.ShineWidth, SHINE_TALL)
	band.Rotation = SHINE_ANGLE
	band.ZIndex = clip.ZIndex
	local fade = Instance.new("UIGradient") -- clear at both edges, ShineAlpha in the middle
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, Theme.Gloss.ShineAlpha),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = band
	band.Parent = clip
	clip.Parent = target

	local stopped = false
	local sweep: Tween? = nil
	local function stop()
		if stopped then
			return
		end
		stopped = true
		if sweep then
			sweep:Cancel()
		end
		clip:Destroy()
	end
	target.Destroying:Once(stop)

	local info = TweenInfo.new(Theme.Gloss.ShineSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	task.spawn(function()
		while not stopped do
			if target:IsDescendantOf(game) and not reducedMotion() then
				band.Position = restX
				local tween = TweenService:Create(band, info, { Position = UDim2.fromScale(1 + SHINE_OVERSHOOT, 0.5) })
				sweep = tween
				tween:Play()
			end
			task.wait(Theme.Gloss.ShineSeconds + Theme.Gloss.ShineEvery)
		end
	end)
	return stop
end

-- Returns a setter that rolls the label's digits from the current value to the new one.
function Builder.rolling(label: TextLabel, format: ((number) -> string)?): (number) -> ()
	local value = Instance.new("NumberValue")
	value.Parent = label
	local fmt = format or Builder.formatNumber
	label.Text = fmt(0)
	value.Changed:Connect(function(v: number)
		label.Text = fmt(v)
	end)
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return function(target: number)
		TweenService:Create(value, info, { Value = target }):Play()
	end
end

return Builder
