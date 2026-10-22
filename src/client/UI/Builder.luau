--!strict
-- StarterPlayerScripts.Client.UI.Builder: the only place UI instances are created. Every screen
-- builds from these helpers so the look (Theme) is applied once and consistently: Scale-only
-- positions and sizes, Fredoka One, outlined text, chunky buttons with a lip and a gloss band, a click on every tap.
-- The block-cell look (Decisions B44) is the "Block cells" section: blockPlate, blockButton, pixelIcon and their kin; the HUD is
-- built from them, and each other screen moves over in its own change.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TextService = game:GetService("TextService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local BadgeFit = require(Shared:WaitForChild("BadgeFit"))
local BlockMath = require(Shared:WaitForChild("BlockMath"))
local PixelIcons = require(Shared:WaitForChild("data"):WaitForChild("PixelIcons"))
local StrokeMath = require(Shared:WaitForChild("StrokeMath"))
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
	rows: number?, -- Builder.blockButton only: the face's cell rows (default from size.Y as a Scale of the screen, less the one-cell lip)
	cells: boolean?, -- Builder.blockButton only: false draws the face as a flat block (a button repeated down a list: UI Playbook "Frames")
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

export type BlockProps = {
	parent: Instance?,
	name: string?,
	color: Color3, -- the face colour; the shading is white and black overlays, so Builder.setBlockColor recolours it
	aspect: number?, -- the plate's width over its height in px: the plate keeps it, so its cells stay square. Nil makes a fitted
	-- plate: no aspect constraint, it takes the box its Size gives (a row in a list, a band as wide as the screen) and draws the
	-- whole number of columns nearest square cells for the box it measures, again when that box changes shape
	rows: number?, -- cell rows across the face; default from size.Y (Builder.blockRows), so a cell is about Theme.Block.Cell of the screen
	-- (a fitted plate with no rows picks them once from its measured height, again when the screen changes)
	cells: boolean?, -- false: a flat block (ink, face and stepped corners, no bands, grout or jitter), for a badge or an icon square
	edges: boolean?, -- with cells false: an edged block, the flat block plus the C3 lit top row and shaded edges (no grout, no
	-- jitter): a card repeated down a list or across a grid, so it reads as a block at eight frames, not fifty (UI Playbook "Frames")
	position: UDim2?,
	size: UDim2?,
	anchor: Vector2?,
	zIndex: number?,
	seed: number?, -- the jitter hash's seed (Theme.Block.Seed by default); a neighbour can take another so two plates differ
	ink: Color3?, -- the border colour (the navy Outline by default)
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

-- Strokes ------------------------------------------------------------------
-- UIStroke.Thickness is pixels and takes no Scale, so Builder.stroke sizes it from the screen height (Shared/StrokeMath, the
-- numbers in Theme.Stroke): the thickness a caller passes (Theme.Stroke.Text, Button, Panel...) is its pixels at
-- Theme.Stroke.ReferenceHeight. Each stroke carries that reference as the STROKE_PX attribute and a tag, and one listener on the
-- camera's ViewportSize sets every tagged stroke again when the window changes (a rotation, a resize, an emulator switch).
-- A caller that compares a stroke's thickness reads Builder.strokePx, not .Thickness, which is a scaled number.

local STROKE_TAG = "ScaledStroke"
local STROKE_PX = "StrokePx"
local STROKE_SCALE: StrokeMath.Params = {
	referenceHeight = Theme.Stroke.ReferenceHeight,
	minScale = Theme.Stroke.MinScale,
	maxScale = Theme.Stroke.MaxScale,
}
local strokeWatching = false

local function viewportHeight(): number
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize.Y else 0
end

-- The thickness in px for a stroke that is `referencePx` thick at the reference height, on this screen.
function Builder.strokeThickness(referencePx: number): number
	return StrokeMath.Thickness(referencePx, viewportHeight(), STROKE_SCALE)
end

local function resizeStrokes()
	for _, instance in ipairs(CollectionService:GetTagged(STROKE_TAG)) do
		local referencePx = instance:GetAttribute(STROKE_PX)
		if instance:IsA("UIStroke") and type(referencePx) == "number" then
			instance.Thickness = Builder.strokeThickness(referencePx)
		end
	end
end

-- Connects the one ViewportSize listener, and follows the camera when Workspace swaps it (a respawn or a cutscene camera).
local function watchViewport()
	if strokeWatching then
		return
	end
	strokeWatching = true
	local viewportConnection: RBXScriptConnection? = nil
	local function follow()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeStrokes)
		end
		resizeStrokes()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(follow)
	follow()
end

-- The pixels a stroke was asked for (its thickness at the reference height): the attribute Builder.stroke wrote, else the
-- Thickness of a stroke Builder did not make.
function Builder.strokePx(stroke: UIStroke): number
	local referencePx = stroke:GetAttribute(STROKE_PX)
	return if type(referencePx) == "number" then referencePx else stroke.Thickness
end

-- Gives a stroke a new thickness, in px at the reference height (a selected card's thicker ring): the attribute the viewport
-- listener reads moves with it, so a resize keeps the new value. Screens call this, never `stroke.Thickness = ...`.
function Builder.setStrokePx(stroke: UIStroke, referencePx: number)
	CollectionService:AddTag(stroke, STROKE_TAG)
	stroke:SetAttribute(STROKE_PX, referencePx)
	stroke.Thickness = Builder.strokeThickness(referencePx)
end

-- Outlines `parent`: round the text of a TextLabel or TextButton (Contextual), else its border. `mode` picks the other one
-- (a button's border and an input's border are Border strokes on text objects). The join is Theme.Stroke.TextJoin on a text
-- outline and Theme.Stroke.ShapeJoin on a border.
function Builder.stroke(parent: GuiObject, thickness: number, color: Color3?, mode: Enum.ApplyStrokeMode?): UIStroke
	local isText = parent:IsA("TextLabel") or parent:IsA("TextButton")
	local applied = mode or (if isText then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Colors.Outline
	stroke.ApplyStrokeMode = applied
	stroke.LineJoinMode = if isText and applied == Enum.ApplyStrokeMode.Contextual then Theme.Stroke.TextJoin else Theme.Stroke.ShapeJoin
	Builder.setStrokePx(stroke, thickness)
	watchViewport()
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
	Builder.stroke(face, Theme.Stroke.Button, lipColor, Enum.ApplyStrokeMode.Border) -- the border; the text outline follows below
	Builder.gradient(face, props.color)
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = props.textSize or Theme.TextSize.Label
	sizes.Parent = face
	Builder.stroke(face, Theme.Stroke.Text, Theme.Colors.Outline)
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

-- A folded ribbon for a status word (BEST DEAL, NEW!), in block cells (UI Playbook "Screens after the HUD", the Shop): a flat block
-- plate in `color` with white outlined text at the 14 px floor, over a darker flat square at each end dropped below it for the
-- folded tail. The holder is the size given (`aspect` is its width over its height in px), the plate fills most of it
-- (Theme.Ribbon), and nothing in it takes taps. Returns the holder.
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
	local plateH = 1 - Theme.Ribbon.Tail / 4
	for side = 0, 1 do
		Builder.blockPlate({
			parent = holder,
			name = "Tail",
			color = dark,
			aspect = 1,
			rows = Theme.Block.MinRows,
			cells = false,
			position = UDim2.fromScale(0.05 + side * 0.9, 0.5 + Theme.Ribbon.Tail / 4),
			size = UDim2.fromScale(Theme.Ribbon.Tail / props.aspect, Theme.Ribbon.Tail),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = z,
		})
	end
	local plate = Builder.blockPlate({
		parent = holder,
		name = "Plate",
		color = props.color,
		aspect = 0.9 * props.aspect / plateH,
		rows = Theme.Block.MinRows,
		cells = false,
		position = UDim2.fromScale(0.05, 0),
		size = UDim2.fromScale(0.9, plateH),
		zIndex = z + Theme.Block.Layer.Fill + 1, -- over both tails' ink and face
	})
	Builder.label({
		parent = plate,
		name = "Text",
		text = props.text,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.94, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(plate),
	})
	return holder
end

-- The stepped pixel octagon on an 8 by 8 grid (Theme.Block.PixelGrid) as overlapping bars { x, y, w, h }: the ink, then the colour
-- one unit inside it all round (the ink keeps one thickness round every step, like the compass diamond); a thick ring insets the
-- colour two units (a plus of two bars; the third bar hides).
local OCTAGON_INK = { { 2, 0, 4, 8 }, { 1, 1, 6, 6 }, { 0, 2, 8, 4 } }
local OCTAGON_FILL = { { 3, 1, 2, 6 }, { 2, 2, 4, 4 }, { 1, 3, 6, 2 } }
local OCTAGON_THICK = { { 3, 2, 2, 4 }, { 2, 3, 4, 2 }, { 4, 4, 0, 0 } }

-- A pixel octagon: the round thing of a block screen (a seal, a planet, the Star Chart's star and glow, a ready dot), frames only.
export type OctagonProps = {
	parent: Instance?,
	name: string?,
	color: Color3, -- the face
	ink: Color3?, -- the ring (navy by default)
	position: UDim2?,
	size: UDim2?, -- the holder keeps a 1:1 aspect inside it
	anchor: Vector2?,
	zIndex: number?, -- the ink takes this, the face one more; content goes at two more (Builder.octagonTop)
}
export type Octagon = { holder: Frame, ink: { Frame }, fill: { Frame } }

local function octagonRect(frame: Frame, bar: { number })
	local grid = Theme.Block.PixelGrid
	frame.Position = UDim2.fromScale(bar[1] / grid, bar[2] / grid)
	frame.Size = UDim2.fromScale(bar[3] / grid, bar[4] / grid)
	frame.Visible = bar[3] > 0 and bar[4] > 0
end

-- Builds a pixel octagon in a square holder; nothing in it takes taps. Returns its holder and its bars (for paintOctagon).
function Builder.pixelOctagon(props: OctagonProps): Octagon
	local z = props.zIndex or 1
	local holder = Builder.frame({
		name = props.name or "Octagon",
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		aspect = 1,
		zIndex = z,
	})
	local out: Octagon = { holder = holder, ink = {}, fill = {} }
	for layer, bars in ipairs({ OCTAGON_INK, OCTAGON_FILL }) do
		for _, bar in ipairs(bars) do
			local frame = Builder.frame({
				parent = holder,
				name = if layer == 1 then "Ink" else "Fill",
				color = if layer == 1 then props.ink or Theme.Colors.Outline else props.color,
				zIndex = z + layer - 1,
			})
			octagonRect(frame, bar)
			table.insert(if layer == 1 then out.ink else out.fill, frame)
		end
	end
	holder.Parent = props.parent
	return out
end

-- The ZIndex content on a pixel octagon takes (a planet's number, a seal's word).
function Builder.octagonTop(octagon: Octagon): number
	return octagon.holder.ZIndex + 2
end

-- Repaints a pixel octagon: its face and ring colours and see-through, and whether the ring is thick (two units: a selected
-- planet).
function Builder.paintOctagon(octagon: Octagon, fill: Color3, fillAlpha: number, ink: Color3, inkAlpha: number, thick: boolean)
	for index, frame in ipairs(octagon.fill) do
		frame.BackgroundColor3 = fill
		frame.BackgroundTransparency = fillAlpha
		octagonRect(frame, (if thick then OCTAGON_THICK else OCTAGON_FILL)[index])
	end
	for _, frame in ipairs(octagon.ink) do
		frame.BackgroundColor3 = ink
		frame.BackgroundTransparency = inkAlpha
	end
end

-- A seal for a value claim (BEST VALUE), in block cells: a pixel octagon in `color` inside a navy ink, frames only (no stroke, no
-- turned squares). The label is white outlined text over the middle. The caller sizes the holder square and may turn it
-- (`rotation`, the stamp's tilt); nothing in it takes taps. Returns the holder.
function Builder.seal(props: SealProps): Frame
	local octagon = Builder.pixelOctagon({
		parent = props.parent,
		name = props.name or "Seal",
		color = props.color,
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = props.zIndex,
	})
	local holder = octagon.holder
	holder.Rotation = props.rotation or 0
	Builder.label({
		parent = holder,
		name = "Text",
		text = props.text,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(Theme.Seal.Text, Theme.Seal.Text * 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.octagonTop(octagon),
	})
	return holder
end

-- Recolours a block button's face and lip, keeping its text and whether it takes taps (a Shop tab going dark when another is
-- active, a Settings level button turning green): the block twin of the screens' old in-place recolour.
function Builder.recolorBlockButton(container: Instance?, color: Color3)
	if not container then
		return
	end
	local plate, lip = container:FindFirstChild("Plate"), container:FindFirstChild("Lip")
	if plate then
		Builder.setBlockColor(plate, color)
	end
	if lip then
		Builder.setBlockColor(lip, Builder.darker(color))
	end
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
			if child:IsA("UIStroke") and Builder.strokePx(child) == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

-- Block cells ------------------------------------------------------------------
-- The block-cell look (UI Playbook "Block cells", Decisions B44): every plate and button is a whole number of square cells with
-- its corner cells cut (a stepped pixel corner), a navy ink border, a lit top row, darker side and bottom cells, a grout line on
-- each cell and a few cells a shade off. Frames only (no image to upload, nothing at an id of 0), Scale only (Shared/BlockMath
-- gives every rectangle as a fraction of the plate, and the plate keeps its aspect so the cells stay square), and the shading is
-- white and black overlays, so a plate recolours by its "Fill" frames alone (Builder.setBlockColor). No gradient, no gloss, no
-- round corner on a block. Inside a plate the layers are Theme.Block.Layer steps above the plate's ZIndex: content goes at
-- Builder.blockTop(plate) or higher.

local BLOCK_ASPECT = "BlockAspect" -- attributes a plate carries so a later call (blockBar, blockInner) can rebuild its grid
local BLOCK_ROWS = "BlockRows"
local BLOCK_COLS = "BlockCols"
local BLOCK_COLOR = "BlockColor" -- the face colour now (setBlockColor moves it), which a fitted plate's redraw keeps
local BLOCK_INK = "BlockInk" -- and the ink colour (setBlockInk)
local BLOCK_FADE = "BlockFade" -- and the fade (setBlockFade)
local FIT_RESHAPE = 0.01 -- a fitted plate whose aspect moves more than this (not a uniform scale) picks its rows again
local BLOCK_ICON_SCALE = 0.8 -- a block button's icon, as a fraction of its face's padded box (about 0.6 of the face's height)
local BLOCK_TEXT_PAD_X = 0.5 -- a block button's text keeps this many cells clear of the ink at each side
local BLOCK_TEXT_PAD_Y = 0.25 -- and this many at the top and bottom

-- The ZIndex content on a block plate takes: above its ink, face, bar and cell overlays.
function Builder.blockTop(plate: GuiObject): number
	return plate.ZIndex + Theme.Block.Layer.Content
end

-- The cell rows of a plate `height` tall, as a Scale of the screen height: a cell is then about `cell` of the screen
-- (Theme.Block.Cell by default; a modal panel passes Theme.Block.PanelCell, the density rule for big plates).
function Builder.blockRows(height: number, cell: number?): number
	return BlockMath.Rows(height, cell or Theme.Block.Cell, Theme.Block.Ink, Theme.Block.MinRows)
end

-- The face rows of a block button `height` tall (a Scale of the screen height): one cell of it is the lip.
function Builder.blockButtonRows(height: number): number
	return Builder.blockRows(height - Theme.Block.Cell)
end

local function blockGrid(plate: Instance): BlockMath.Grid?
	local aspect, rows = plate:GetAttribute(BLOCK_ASPECT), plate:GetAttribute(BLOCK_ROWS)
	if type(aspect) ~= "number" or type(rows) ~= "number" then
		return nil
	end
	return BlockMath.Grid(aspect, rows, Theme.Block.Ink)
end

-- One rectangle of a plate (fractions of it) as a frame that never takes input.
local function rectFrame(parent: Instance, name: string, rect: BlockMath.Rect, color: Color3, transparency: number, z: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Active = false
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Position = UDim2.fromScale(rect.x, rect.y)
	frame.Size = UDim2.fromScale(rect.w, rect.h)
	frame.ZIndex = z
	frame.Parent = parent
	return frame
end

-- What a plate drew (its ink, face and cell overlays), so a fitted plate can clear and redraw them without touching the content
-- a screen put in it, and what to run after a redraw (a bar re-placing its fill, a button its padding). Weak keys: a destroyed
-- plate drops out.
local drawnParts: { [Instance]: { Frame } } = setmetatable({}, { __mode = "k" }) :: any
local redrawHooks: { [Instance]: { () -> () } } = setmetatable({}, { __mode = "k" }) :: any

local function onRedraw(plate: Instance, hook: () -> ())
	local hooks = redrawHooks[plate]
	if not hooks then
		hooks = {}
		redrawHooks[plate] = hooks
	end
	table.insert(hooks, hook)
end

-- The grid a block plate drew last, or nil for a frame that is not a block plate: a screen that places its own pieces on a
-- plate's cells (the capture bar's zones, trail and marker) reads it. A fitted plate can redraw; Builder.onBlockRedraw hears it.
function Builder.blockGrid(plate: Instance): BlockMath.Grid?
	return blockGrid(plate)
end

-- Runs `hook` after every redraw of a fitted plate (its columns or rows changed), so pieces placed on its cells follow.
function Builder.onBlockRedraw(plate: Instance, hook: () -> ())
	onRedraw(plate, hook)
end

-- Draws a plate's grid: the ink border and the face as two overlapping bars each (the cut corners), then, with `cells`, the lit
-- top row and the shaded side and bottom cells (three cells or more both ways), the grout on every cell and the jittered cells.
-- The face, the ink and the fade come from the plate's attributes (setBlockColor, setBlockInk and setBlockFade keep them), so a
-- redraw keeps a recolour.
local function drawGrid(plate: Frame, grid: BlockMath.Grid, cells: boolean, edges: boolean, seed: number)
	local old = drawnParts[plate]
	if old then
		for _, part in ipairs(old) do
			part:Destroy()
		end
	end
	local parts: { Frame } = {}
	drawnParts[plate] = parts
	local z = plate.ZIndex
	local layers = Theme.Block.Layer
	local color, inkColor, fadeBy = plate:GetAttribute(BLOCK_COLOR), plate:GetAttribute(BLOCK_INK), plate:GetAttribute(BLOCK_FADE)
	local face: Color3 = if typeof(color) == "Color3" then color else Theme.Colors.Panel
	local ink: Color3 = if typeof(inkColor) == "Color3" then inkColor else Theme.Colors.Outline
	local fade: number = if type(fadeBy) == "number" then fadeBy else 0
	if cells and not BlockMath.WithinBudget(grid, Theme.Block.MaxCells) then
		cells, edges = false, true -- no screen makes a grid this big; draw it edged rather than spend seconds on its cells
	end
	local function add(name: string, rect: BlockMath.Rect, shade: Color3, transparency: number, layer: number)
		table.insert(parts, rectFrame(plate, name, rect, shade, 1 - (1 - transparency) * (1 - fade), z + layer))
	end
	for _, rect in ipairs(BlockMath.Shape(grid, 0, 0)) do
		add("Ink", rect, ink, 0, layers.Ink)
	end
	for _, rect in ipairs(BlockMath.Face(grid)) do
		add("Fill", rect, face, 0, layers.Fill)
	end
	if cells or edges then
		local bands = BlockMath.Bands(grid)
		if bands.top then
			add("Lit", bands.top, Theme.Colors.White, Theme.Block.TopAlpha, layers.Cells)
		end
		for _, rect in ipairs({ bands.bottom, bands.left, bands.right }) do
			if rect then
				add("Edge", rect, Theme.Colors.Black, Theme.Block.EdgeAlpha, layers.Cells)
			end
		end
	end
	if cells then
		for _, rect in ipairs(BlockMath.GroutCached(grid, Theme.Block.Grout)) do
			add("Grout", rect, Theme.Colors.Black, Theme.Block.GroutAlpha, layers.Cells)
		end
		for _, cell in ipairs(BlockMath.JitteredCached(grid, seed)) do
			local shade = if cell.level > 0 then Theme.Colors.White else Theme.Colors.Black
			add("Jitter", BlockMath.Cell(grid, cell.col, cell.row), shade, Theme.Block.JitterAlpha, layers.Cells)
		end
	end
	plate:SetAttribute(BLOCK_ROWS, grid.rows)
	plate:SetAttribute(BLOCK_COLS, grid.cols)
	local hooks = redrawHooks[plate]
	if hooks then
		for _, hook in ipairs(hooks) do
			hook()
		end
	end
end

-- A fitted plate follows its box: it measures its px size, keeps `rows` (or picks them from its height as a share of the screen,
-- again when the screen height or the box's shape changes) and redraws only when the rows or the whole number of columns nearest
-- square cells change. A UIScale tween (a panel opening) scales both sides alike, so it never re-picks or redraws; a rotation, a
-- resize or a column growing shorter may. Before it is measured it draws from a guess (its Size as a share of the screen), so it
-- is never blank for a frame.
-- The fitted plates' measurements wait in one queue and run in batches of Theme.Block.FitBudget seconds a frame, yielding between
-- batches: a screen that builds or resizes a hundred fitted plates at once (the HUD at start, while the server loads) spreads
-- their redraws over a few frames instead of running them all in one go (Studio 2026-10-22: "Script timeout: exhausted allowed
-- execution time" in fitPlate's measure, then draw). Every plate drew its guess when it was built, so nothing is blank meanwhile.
local fitQueue: { () -> () } = {}
local fitQueued: { [() -> ()]: boolean } = {}
local fitDraining = false

local function drainFits()
	local started = os.clock()
	local head = 1
	while head <= #fitQueue do
		local measure = fitQueue[head]
		head += 1
		fitQueued[measure] = nil -- a change from here on queues it again
		local ok, problem = pcall(function(): string?
			measure()
			return nil
		end)
		if not ok then
			warn("[Builder] a fitted plate's measure failed: " .. tostring(problem))
		end
		if head <= #fitQueue and os.clock() - started > Theme.Block.FitBudget then
			task.wait() -- the rest wait a frame
			started = os.clock()
		end
	end
	table.clear(fitQueue)
	fitDraining = false
end

local function scheduleFit(measure: () -> ())
	if fitQueued[measure] then
		return
	end
	fitQueued[measure] = true
	table.insert(fitQueue, measure)
	if not fitDraining then
		fitDraining = true
		task.defer(drainFits)
	end
end

-- The height of the screen a plate is on: its ScreenGui's (Builder.screen ignores the inset, so it is the whole viewport, and it
-- is laid out with the plate, so the two always agree), else the camera's viewport.
local function screenHeight(plate: Instance): number
	local gui = plate:FindFirstAncestorWhichIsA("ScreenGui")
	if gui and gui.AbsoluteSize.Y > 0 then
		return gui.AbsoluteSize.Y
	end
	return viewportHeight()
end

local function fitPlate(plate: Frame, size: UDim2, rows: number?, draw: (number, number) -> ())
	local camera = workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else Vector2.new(16, 9)
	local guessRows = rows or Builder.blockRows(size.Y.Scale)
	local guessAspect = if size.Y.Scale > 0 and screen.Y > 0 then (size.X.Scale * screen.X) / (size.Y.Scale * screen.Y) else 1
	local shownRows, shownCols = guessRows, BlockMath.Grid(guessAspect, guessRows, Theme.Block.Ink).cols
	local pickedRows: number? = rows
	local pickedFor, pickedAspect = 0, 0
	draw(guessAspect, guessRows)
	local function measure()
		local box = plate.AbsoluteSize
		if box.X <= 0 or box.Y <= 0 then
			return
		end
		local height = screenHeight(plate)
		local aspect = box.X / box.Y
		local want = pickedRows
		local reshaped = pickedAspect <= 0 or math.abs(aspect / pickedAspect - 1) > FIT_RESHAPE
		if rows == nil and (want == nil or pickedFor ~= height or reshaped) then
			-- 0: not a screen's measurement yet (a 1 px viewport at start); keep what is drawn until a real one comes
			local fresh = BlockMath.ScreenRows(box.Y, height, Theme.Block.Cell, Theme.Block.Ink, Theme.Block.MinRows, 0)
			if fresh <= 0 then
				return
			end
			want = fresh
			pickedRows, pickedFor, pickedAspect = want, height, aspect
		end
		local wantRows = want or guessRows
		local cols = BlockMath.Grid(aspect, wantRows, Theme.Block.Ink).cols
		if cols ~= shownCols or wantRows ~= shownRows then
			shownRows, shownCols = wantRows, cols
			draw(aspect, wantRows)
		end
	end
	plate:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scheduleFit(measure)
	end)
	scheduleFit(measure)
end

-- A block plate (UI Playbook "Block cells"): ink, face and, unless `cells` is false, the C3 bands, the grout and the C2 jitter
-- (BlockMath.Level: 1 in 8 a shade down, 1 in 8 a shade up). With `aspect` the plate keeps that shape (a UIAspectRatioConstraint)
-- and its grid is fixed; without it the plate is fitted (fitPlate) to whatever box its Size gives. Returns the plate, a
-- transparent frame; put labels and icons in it at Builder.blockTop(plate), and never a UIListLayout (it would stack the cells).
function Builder.blockPlate(props: BlockProps): Frame
	local size = props.size or UDim2.fromScale(1, 1)
	local plate = Builder.frame({
		name = props.name or "Plate",
		position = props.position,
		size = size,
		anchor = props.anchor,
		zIndex = props.zIndex or 1,
		aspect = props.aspect,
	})
	plate:SetAttribute(BLOCK_COLOR, props.color)
	plate:SetAttribute(BLOCK_INK, props.ink or Theme.Colors.Outline)
	local cells = props.cells ~= false
	local edges = props.edges == true
	local seed = props.seed or Theme.Block.Seed
	local function draw(aspect: number, rows: number)
		plate:SetAttribute(BLOCK_ASPECT, aspect)
		drawGrid(plate, BlockMath.Grid(aspect, rows, Theme.Block.Ink), cells, edges, seed)
	end
	local aspect = props.aspect
	if aspect then
		draw(aspect, props.rows or Builder.blockRows(size.Y.Scale))
	else
		fitPlate(plate, size, props.rows, draw)
	end
	plate.Parent = props.parent
	return plate
end

-- Gives a plate (or a block button's Plate or Lip) a new face colour, at once or over `info`.
function Builder.setBlockColor(plate: Instance, color: Color3, info: TweenInfo?)
	plate:SetAttribute(BLOCK_COLOR, color)
	for _, part in ipairs(drawnParts[plate] or {}) do
		if part.Name == "Fill" then
			if info then
				TweenService:Create(part, info, { BackgroundColor3 = color }):Play()
			else
				part.BackgroundColor3 = color
			end
		end
	end
end

-- Gives a plate a new ink colour: a species icon's ring in its tier's colour (the rarity colours stay the rarity colours).
function Builder.setBlockInk(plate: Instance, color: Color3)
	plate:SetAttribute(BLOCK_INK, color)
	for _, part in ipairs(drawnParts[plate] or {}) do
		if part.Name == "Ink" then
			part.BackgroundColor3 = color
		end
	end
end

-- Fades a whole plate by `transparency` (0 as drawn, 1 gone): each of its frames keeps its own share of see-through (a lit row
-- stays lighter than the face), so a dimmed row reads as the same block, fainter. Its content (labels, icons) fades on its own.
function Builder.setBlockFade(plate: Instance, transparency: number)
	plate:SetAttribute(BLOCK_FADE, transparency)
	local base: { [string]: number } = {
		Lit = Theme.Block.TopAlpha,
		Edge = Theme.Block.EdgeAlpha,
		Grout = Theme.Block.GroutAlpha,
		Jitter = Theme.Block.JitterAlpha,
	}
	for _, part in ipairs(drawnParts[plate] or {}) do
		part.BackgroundTransparency = 1 - (1 - (base[part.Name] or 0)) * (1 - transparency)
	end
end

-- The face's inner box of a plate (inside the ink, corners included) as a Position and a Size of the plate: a progress bar's span,
-- a row of tick marks. The whole plate when it is not a block plate.
function Builder.blockInner(plate: Instance): (UDim2, UDim2)
	local grid = blockGrid(plate)
	if not grid then
		return UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
	end
	local inner = BlockMath.Inner(grid)
	return UDim2.fromScale(inner.x, inner.y), UDim2.fromScale(inner.w, inner.h)
end

-- A progress fill in `color` across a plate's face from the left, under its cell overlays (so the fill shows the cells too) and
-- inside its stepped corners. Returns a setter for the fill, 0 to 1; it starts empty.
function Builder.blockBar(plate: Frame, color: Color3): (number) -> ()
	local first = blockGrid(plate)
	if not first then
		return function(_p: number) end
	end
	local bars: { Frame } = {}
	for index, rect in ipairs(BlockMath.Fill(first, 0)) do
		local bar = rectFrame(plate, "Bar", rect, color, 0, plate.ZIndex + Theme.Block.Layer.Bar)
		bar.Visible = false
		bars[index] = bar
	end
	local shown = 0
	local function set(p: number)
		shown = p
		local grid = blockGrid(plate) or first
		for index, rect in ipairs(BlockMath.Fill(grid, p)) do
			local bar = bars[index]
			if bar then
				bar.Position = UDim2.fromScale(rect.x, rect.y)
				bar.Size = UDim2.fromScale(rect.w, rect.h)
				bar.Visible = rect.w > 0
			end
		end
	end
	onRedraw(plate, function()
		set(shown)
	end)
	return set
end

-- A pixel icon from data/PixelIcons (an 8 by 8 drawing, or the finer grid its key names) as frames in a square holder, or nil (nothing created) when the key has
-- none. The holder keeps a 1:1 aspect inside the size given; nothing in it takes taps.
function Builder.pixelIcon(props: IconProps): Frame?
	local key = if PixelIcons.Icons[props.key] then props.key else Icons.Aliases[props.key] or ""
	local pixels = PixelIcons.Icons[key]
	if not pixels then
		return nil
	end
	local z = props.zIndex or 1
	local holder = Builder.frame({
		name = props.name or "PixelIcon",
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = z,
		aspect = 1,
	})
	local grid = PixelIcons.GridOf(key) -- 8 by 8 unless the icon names a finer grid (the Menu's 16 by 16 icons)
	local colors: { [string]: Color3 } = Theme.Colors
	for index, pixel in ipairs(pixels) do
		local colorKey = pixel[5] :: string
		local rect: BlockMath.Rect = {
			x = (pixel[1] :: number) / grid,
			y = (pixel[2] :: number) / grid,
			w = (pixel[3] :: number) / grid,
			h = (pixel[4] :: number) / grid,
		}
		rectFrame(holder, "Pixel", rect, colors[colorKey] or Theme.Hex(colorKey), 0, z + index)
	end
	holder.Parent = props.parent
	return holder
end

-- The icon a block surface shows for a key: the pixel icon first while data/PixelIcons.PreferOverPack is on (one look, B44), else
-- the uploaded pack image; the other one when the first has nothing. Nil when neither exists (the caller keeps its glyph).
function Builder.blockIcon(props: IconProps): GuiObject?
	local pixel: GuiObject? = nil
	local image: GuiObject? = nil
	if PixelIcons.PreferOverPack then
		pixel = Builder.pixelIcon(props)
		if pixel then
			return pixel
		end
		image = Builder.icon(props)
		return image
	end
	image = Builder.icon(props)
	if image then
		return image
	end
	pixel = Builder.pixelIcon(props)
	return pixel
end

-- A chunky block button: a block plate face over a lip one cell deep in the colour darkened (a flat block, so the button reads as
-- a block standing on its own shadow), outlined white text or a pixel icon on the face. A press sinks the face exactly one cell
-- onto the lip (no squash: blocks do not squash); a hover on a mouse grows it to Theme.Block.Hover. Every tap clicks. `hit` adds
-- the invisible 44 px area as on Builder.button. Returns the container; "Face" is the TextButton (set its Text), "Plate" and "Lip"
-- the plates (Builder.restyleBlockButton recolours them). With no `aspect` the button is fitted (its plates fit the box a row or a
-- list gives it; pass `rows` when its size is a fraction of something other than the screen); `cells = false` makes its face flat.
function Builder.blockButton(props: ButtonProps, onClick: () -> ()): Frame
	local aspect = props.aspect -- nil: a fitted button (its plates fit the box a list or a parent frame gives it)
	local size = props.size or UDim2.fromScale(1, 1)
	local rows = props.rows or Builder.blockButtonRows(size.Y.Scale)
	local lip, faceAspect = BlockMath.Lip(aspect or 1, rows, Theme.Block.Ink)
	local z = props.zIndex or 1
	local container = Builder.frame({
		parent = props.parent,
		name = props.name or "Button",
		position = props.position,
		size = size,
		anchor = props.anchor,
		zIndex = z,
		aspect = aspect,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = container
	Builder.blockPlate({
		parent = container,
		name = "Lip",
		color = Builder.darker(props.color),
		aspect = aspect,
		rows = rows + 1,
		cells = false,
		zIndex = z,
	})
	local plate = Builder.blockPlate({
		parent = container,
		name = "Plate",
		color = props.color,
		aspect = if aspect then faceAspect else nil,
		rows = rows,
		cells = props.cells,
		size = UDim2.fromScale(1, 1 - lip),
		zIndex = z + 1,
	})
	local grid = blockGrid(plate) or BlockMath.Grid(faceAspect, rows, Theme.Block.Ink)

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AutoButtonColor = false
	face.BackgroundTransparency = 1
	face.BorderSizePixel = 0
	face.Position = UDim2.fromScale(0, 0)
	face.Size = UDim2.fromScale(1, 1 - lip)
	face.FontFace = Font.fromEnum(Theme.Font)
	face.Text = props.text
	face.TextColor3 = Theme.Colors.White
	face.TextScaled = true
	face.ZIndex = z + 2 -- over the Plate sibling and all of its layers
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = props.textSize or Theme.TextSize.Label
	sizes.Parent = face
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(grid.inkX + BLOCK_TEXT_PAD_X * grid.cellX, 0)
	padding.PaddingRight = UDim.new(grid.inkX + BLOCK_TEXT_PAD_X * grid.cellX, 0)
	padding.PaddingTop = UDim.new(grid.inkY + BLOCK_TEXT_PAD_Y * grid.cellY, 0)
	padding.PaddingBottom = UDim.new(grid.inkY + BLOCK_TEXT_PAD_Y * grid.cellY, 0)
	padding.Parent = face
	if not aspect then
		onRedraw(plate, function() -- a fitted face's columns can change: keep the text half a cell clear of the ink
			local now = blockGrid(plate)
			if now then
				padding.PaddingLeft = UDim.new(now.inkX + BLOCK_TEXT_PAD_X * now.cellX, 0)
				padding.PaddingRight = UDim.new(now.inkX + BLOCK_TEXT_PAD_X * now.cellX, 0)
			end
		end)
	end
	Builder.stroke(face, Theme.Stroke.Text, Theme.Colors.Outline)
	if props.icon then
		local image = Builder.blockIcon({
			parent = face,
			name = "Icon",
			key = props.icon,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(BLOCK_ICON_SCALE, BLOCK_ICON_SCALE),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = face.ZIndex + 1,
		})
		if image then
			face.Text = ""
		end
	end
	face.Parent = container

	local pressInfo = TweenInfo.new(Theme.Tween.Press, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function sink(y: number)
		TweenService:Create(plate, pressInfo, { Position = UDim2.fromScale(0, y) }):Play()
		TweenService:Create(face, pressInfo, { Position = UDim2.fromScale(0, y) }):Play()
	end
	local function press()
		sink(lip)
	end
	local function release()
		TweenService:Create(scale, pressInfo, { Scale = 1 }):Play()
		sink(0)
	end
	local function hover()
		TweenService:Create(scale, pressInfo, { Scale = Theme.Block.Hover }):Play()
	end
	face.MouseButton1Down:Connect(press)
	face.MouseButton1Up:Connect(release)
	face.MouseLeave:Connect(release)
	face.MouseEnter:Connect(hover)
	face.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		onClick()
	end)
	if props.hit then
		-- As on Builder.button: an invisible button the face's size, floored at Theme.TapMin px each way around its centre.
		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.Text = ""
		hit.AutoButtonColor = false
		hit.BackgroundTransparency = 1
		hit.BorderSizePixel = 0
		hit.AnchorPoint = Vector2.new(0.5, 0.5)
		hit.Position = UDim2.fromScale(0.5, (1 - lip) / 2)
		hit.Size = UDim2.fromScale(1, 1 - lip)
		hit.ZIndex = face.ZIndex + 6
		local floor = Instance.new("UISizeConstraint")
		floor.MinSize = Vector2.new(Theme.TapMin, Theme.TapMin)
		floor.Parent = hit
		hit.Parent = container
		hit.MouseButton1Down:Connect(press)
		hit.MouseButton1Up:Connect(release)
		hit.MouseLeave:Connect(release)
		hit.MouseEnter:Connect(hover)
		hit.Activated:Connect(function()
			Builder.playSound(Sounds.Click)
			onClick()
		end)
	end
	return container
end

-- Restyles a block button: the face and the lip take a new colour, the face a new label (kept blank while it shows an icon), and
-- `enabled` decides whether it takes taps. The block twin of Builder.restyleButton, for the screens rebuilt in block cells.
function Builder.restyleBlockButton(container: Frame?, text: string, color: Color3, enabled: boolean)
	if not container then
		return
	end
	local plate, lip = container:FindFirstChild("Plate"), container:FindFirstChild("Lip")
	if plate then
		Builder.setBlockColor(plate, color)
	end
	if lip then
		Builder.setBlockColor(lip, Builder.darker(color))
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = if face:FindFirstChild("Icon") then "" else text
		face.Active = enabled
	end
end

local HEADER_SIZE = Vector2.new(0.42, 0.11) -- a panel's header tab, of the panel, straddling its top edge
local CLOSE_POSITION = UDim2.fromScale(0.985, 0.015) -- a panel's close button: top right, anchored at its top right corner
local CLOSE_SIZE = Vector2.new(0.11, 0.14)

-- The rows of a modal panel `height` tall (a Scale of the screen height): the panel cell, Theme.Block.PanelCell (the UI Playbook's
-- density rule: a big plate takes cells twice the HUD's, as the world's cell is twice a creature's, so a panel is about 19 rows).
function Builder.blockPanelRows(height: number): number
	return Builder.blockRows(height, Theme.Block.PanelCell)
end

-- The header tab a block panel wears straddling its top edge: a block plate in `color`, `size` of the panel (HEADER_SIZE by
-- default), three rows of cells, its shape from the panel's `panelAspect` so the cells stay square, the title in white outlined
-- Title text on top. Returns the tab and the title label.
function Builder.blockHeader(
	panel: Frame,
	panelAspect: number,
	title: string,
	color: Color3,
	size: Vector2?,
	position: UDim2?,
	zIndex: number?
): (Frame, TextLabel)
	local box = size or HEADER_SIZE
	local tab = Builder.blockPlate({
		parent = panel,
		name = "Header",
		color = color,
		aspect = box.X * panelAspect / box.Y,
		rows = Theme.Block.MinRows,
		position = position or UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(box.X, box.Y),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = zIndex or Builder.blockTop(panel),
	})
	local label = Builder.label({
		parent = tab,
		name = "Title",
		text = title,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.72),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(tab),
	})
	return tab, label
end

-- The red close button a block panel wears at its top right: a square block button with the close glyph and the 44 px hit area.
-- `panelHeight` is the panel's height as a Scale of the screen (its rows come from it); position and size default to the
-- panels' common slot.
function Builder.blockClose(panel: Frame, panelHeight: number, onClose: () -> (), position: UDim2?, size: Vector2?, zIndex: number?): Frame
	local box = size or CLOSE_SIZE
	return Builder.blockButton({
		parent = panel,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = position or CLOSE_POSITION,
		size = UDim2.fromScale(box.X, box.Y),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		rows = Builder.blockButtonRows(box.Y * panelHeight),
		hit = true,
		zIndex = zIndex or Builder.blockTop(panel),
	}, onClose)
end

-- A one-line input in the theme's look: panel-coloured box with a navy ink, Fredoka text with the
-- no text stroke (navy on cream), left-aligned inside a scale padding. The text is kept when it gains focus (typing
-- edits it); the caller reads .Text and listens to FocusLost for Enter.
-- In block cells (the Settings change): the box sits in a fitted flat block plate in the panel cream with the navy ink (the
-- plate takes the position, size and anchor; the box fills its face, clear, so it is the plate that shows). The box's Parent is
-- that plate; a caller reads .Text and FocusLost as before.
function Builder.textBox(props: TextBoxProps): TextBox
	local holder = Builder.blockPlate({
		parent = props.parent,
		name = (props.name or "TextBox") .. "Plate",
		color = Theme.Colors.Panel,
		rows = Theme.Block.MinRows,
		cells = false,
		position = props.position,
		size = props.size,
		anchor = props.anchor,
		zIndex = props.zIndex,
	})
	local box = Instance.new("TextBox")
	box.Name = props.name or "TextBox"
	box.Position, box.Size = Builder.blockInner(holder)
	box.BorderSizePixel = 0
	box.BackgroundTransparency = 1
	box.ZIndex = Builder.blockTop(holder)
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
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = Theme.TextSize.Min
	sizes.MaxTextSize = math.max(Theme.TextSize.Min, props.textSize or Theme.TextSize.Body)
	sizes.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0) -- no top or bottom padding: the plate's ink is the margin, and the 14 px floor fits
	padding.Parent = box
	box.Parent = holder
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
	local block = blockGrid(target)
	if block then
		-- A block plate has no round corner to match: the sweep stays inside its face's wide bar (between the cut corner cells),
		-- under the plate's content layer.
		local wide = BlockMath.Face(block)[1]
		clip.Position = UDim2.fromScale(wide.x, wide.y)
		clip.Size = UDim2.fromScale(wide.w, wide.h)
		clip.ZIndex = target.ZIndex + Theme.Block.Layer.Cells
	end

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
