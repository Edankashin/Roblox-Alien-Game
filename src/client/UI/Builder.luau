--!strict
-- StarterPlayerScripts.Client.UI.Builder: the only place UI instances are created. Every screen
-- builds from these helpers so the look (Theme) is applied once and consistently: Scale-only
-- positions and sizes, Fredoka One, outlined text, chunky buttons with a lip, a click on every tap.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))

local Builder = {}

local EMPTY_SOUND = "rbxassetid://0"

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

function Builder.aspect(parent: GuiObject, ratio: number): UIAspectRatioConstraint
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio
	constraint.DominantAxis = Enum.DominantAxis.Height
	constraint.Parent = parent
	return constraint
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

-- A chunky block button: a darker lip underneath, a gradient face with a stroke, outlined white text.
-- Returns the container; the TextButton is its "Face" child. Press scales down and sinks the face.
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
	return container
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
