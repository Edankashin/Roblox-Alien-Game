--!strict
-- StarterPlayerScripts.Client.UI.Reveal: the catch reveal ritual. Backdrop dims, the card scales in
-- with a Back ease, a radial burst spins behind it, the tier name shows in its colour, confetti for
-- Epic and above, "+N Scrap" floats up, "Tap anywhere" closes. Pure presentation of a server result.
-- The card's Shape area shows the species mesh (World.Models) turning in a ViewportFrame when one
-- exists, the placeholder colour-and-shape frame otherwise.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Builder = require(script.Parent.Builder)
local Models = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Models"))

local Reveal = {}

export type RevealInfo = {
	speciesName: string,
	speciesId: string?, -- the species row, for its mesh; without it the name is looked up in Species.List
	shape: string, -- placeholder shape name, shown on the card until real art exists
	color: Color3,
	tier: string,
	overlay: string, -- "None" hides the badge
	isNew: boolean,
	scrapGained: number,
	perfect: boolean?, -- the server scored a Perfect hit: show the Scrap multiplier line
}

local CONFETTI_COUNT = 20
local BURST_RAYS = 8
local VIEW_FOV = 40 -- the model viewport's camera
local VIEW_FIT = 1.15 -- camera distance margin over the model's bounding radius
local VIEW_DIRECTION = Vector3.new(-0.6, 0.45, -1) -- from the model's front-left, slightly above
local VIEW_SPIN = math.rad(30) -- radians per second while the reveal is open

local gui: ScreenGui? = nil
local card: Frame? = nil
local burst: Frame? = nil
local shapeBox: Frame? = nil
local shapeLabel: TextLabel? = nil
local viewBox: ViewportFrame? = nil
local viewCamera: Camera? = nil
local viewModel: Model? = nil
local spinConn: RBXScriptConnection? = nil
local spinAngle = 0
local speciesByName: { [string]: Types.SpeciesDef }? = nil
local nameLabel: TextLabel? = nil
local tierLabel: TextLabel? = nil
local overlayBadge: Frame? = nil
local overlayLabel: TextLabel? = nil
local newRibbon: Frame? = nil
local scrapLabel: TextLabel? = nil
local perfectLabel: TextLabel? = nil
local burstTween: Tween? = nil
local onClose: (() -> ())? = nil
local open = false

local function clearModel()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	if viewModel then
		viewModel:Destroy()
		viewModel = nil
	end
end

local function close()
	if not open then
		return
	end
	open = false
	local root = gui
	if burstTween then
		burstTween:Cancel()
		burstTween = nil
	end
	if card and root then
		Builder.close(card, function()
			if not open then
				clearModel()
				root.Enabled = false
			end
		end)
	elseif root then
		clearModel()
		root.Enabled = false
	end
	local callback = onClose
	onClose = nil
	if callback then
		callback()
	end
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Reveal", 30)
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
		close()
	end)

	-- Radial burst: thin rays in the tier colour, spun by a looping tween while the card is up.
	local rays = Builder.frame({
		parent = root,
		name = "Burst",
		position = UDim2.fromScale(0.5, 0.47),
		size = UDim2.fromScale(0.9, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = 2,
	})
	for i = 1, BURST_RAYS do
		local ray = Builder.frame({
			parent = rays,
			name = "Ray",
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.08, 1),
			anchor = Vector2.new(0.5, 0.5),
			color = Theme.Colors.White,
			transparency = 0.85,
			zIndex = 2,
		})
		ray.Rotation = (180 / BURST_RAYS) * (i - 1)
	end
	burst = rays

	local panel = Builder.frame({
		parent = root,
		name = "Card",
		position = UDim2.fromScale(0.5, 0.47),
		size = UDim2.fromScale(0.6, 0.56), -- ends at 0.75, clear of the Scrap line below
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel + 2,
		strokeColor = Theme.Rarity.Common,
		aspect = 0.8,
		zIndex = 3,
	})
	card = panel

	shapeBox = Builder.frame({
		parent = panel,
		name = "Shape",
		position = UDim2.fromScale(0.5, 0.34),
		size = UDim2.fromScale(0.56, 0.56),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Rarity.Common,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		aspect = 1,
		zIndex = 4,
	})
	shapeLabel = Builder.label({
		parent = shapeBox,
		name = "ShapeName",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.3),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	-- The mesh view, over the same square as the shape frame; only one of the two is visible at a time.
	local view = Instance.new("ViewportFrame")
	view.Name = "Model"
	view.BackgroundTransparency = 1
	view.BorderSizePixel = 0
	view.Position = UDim2.fromScale(0.5, 0.34)
	view.Size = UDim2.fromScale(0.56, 0.56)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Ambient = Builder.darker(Theme.Colors.White, 0.45) -- soft grey fill light
	view.LightColor = Theme.Colors.White
	view.LightDirection = Vector3.new(-1, -2, -1)
	view.ZIndex = 4
	view.Visible = false
	Builder.aspect(view, 1)
	view.Parent = panel
	local camera = Instance.new("Camera")
	camera.FieldOfView = VIEW_FOV
	camera.Parent = view
	view.CurrentCamera = camera
	viewBox = view
	viewCamera = camera
	nameLabel = Builder.label({
		parent = panel,
		name = "Species",
		text = "",
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.7),
		size = UDim2.fromScale(0.9, 0.12),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	tierLabel = Builder.label({
		parent = panel,
		name = "Tier",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.8),
		size = UDim2.fromScale(0.9, 0.08),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	overlayBadge = Builder.pill({
		parent = panel,
		name = "Overlay",
		position = UDim2.fromScale(0.96, 0.04),
		size = UDim2.fromScale(0.42, 0.09),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Codex,
		stroke = Theme.Stroke.Text,
		zIndex = 6,
	})
	overlayLabel = Builder.label({
		parent = overlayBadge,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 7,
	})
	-- Diagonal NEW! ribbon across the top-left corner.
	local ribbon = Builder.frame({
		parent = panel,
		name = "New",
		position = UDim2.fromScale(0.12, 0.08),
		size = UDim2.fromScale(0.5, 0.09),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Close,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		zIndex = 6,
	})
	ribbon.Rotation = -25
	Builder.gradient(ribbon, Theme.Colors.Close)
	newRibbon = ribbon
	Builder.label({
		parent = ribbon,
		name = "Text",
		text = Strings.CATCH_NEW,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 7,
	})
	scrapLabel = Builder.label({
		parent = root,
		name = "Scrap",
		text = "",
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.815),
		size = UDim2.fromScale(0.5, 0.08),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = 8,
	})
	-- Perfect bonus line under the Scrap line: gold outlined text, shown only for a Perfect catch.
	local bonus = Builder.label({
		parent = root,
		name = "PerfectBonus",
		text = Strings.CATCH_PERFECT_BONUS:format(Config.PerfectScrapMultiplier),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.885),
		size = UDim2.fromScale(0.4, 0.06),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = 8,
	})
	bonus.Visible = false
	perfectLabel = bonus
	Builder.label({
		parent = root,
		name = "Footer",
		text = Strings.REVEAL_TAP,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.95),
		size = UDim2.fromScale(0.5, 0.05),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
end

local function confetti(root: ScreenGui, tierColor: Color3)
	local palette = { tierColor, Theme.Colors.Featured, Theme.Colors.Confirm, Theme.Colors.Select, Theme.Colors.Close, Theme.Colors.White }
	local rng = Random.new()
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _ = 1, CONFETTI_COUNT do
		local piece = Builder.frame({
			parent = root,
			name = "Confetti",
			position = UDim2.fromScale(0.5, 0.47),
			size = UDim2.fromScale(0.012, 0.025),
			anchor = Vector2.new(0.5, 0.5),
			color = palette[rng:NextInteger(1, #palette)],
			zIndex = 9,
		})
		piece.Rotation = rng:NextNumber(0, 360)
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.18, 0.42)
		local target = UDim2.fromScale(0.5 + math.cos(angle) * distance, 0.47 + math.sin(angle) * distance * 1.4)
		local tween = TweenService:Create(piece, info, { Position = target, Rotation = piece.Rotation + rng:NextNumber(-360, 360), BackgroundTransparency = 1 })
		tween.Completed:Once(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

local function flyScrap(amount: number)
	local label = scrapLabel
	if not label then
		return
	end
	if amount <= 0 then
		label.Visible = false
		return
	end
	label.Text = Strings.REVEAL_SCRAP:format(Builder.formatNumber(amount))
	label.TextTransparency = 0
	label.Position = UDim2.fromScale(0.5, 0.8)
	label.Visible = true
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	task.delay(0.6, function()
		local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(label, info, { Position = UDim2.fromScale(0.5, 0.66), TextTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
	end)
end

-- Model view -------------------------------------------------------------

local function speciesFor(info: RevealInfo): Types.SpeciesDef?
	local id = info.speciesId
	if id then
		return Species.ById[id]
	end
	local byName = speciesByName
	if byName then
		return byName[info.speciesName]
	end
	local map: { [string]: Types.SpeciesDef } = {}
	for _, def in ipairs(Species.List) do
		map[def.name] = def
	end
	speciesByName = map
	return map[info.speciesName]
end

-- The model's pivot (its feet) sits on the viewport origin; the camera looks at its centre from the
-- front-left, slightly above, far enough back for the whole bounding box at this field of view.
local function frameCamera(camera: Camera, model: Model)
	local size = model:GetExtentsSize()
	local radius = math.max(size.X, size.Y, size.Z) / 2
	local distance = radius / math.tan(math.rad(VIEW_FOV) / 2) * VIEW_FIT
	local target = Vector3.new(0, size.Y / 2, 0)
	camera.CFrame = CFrame.lookAt(target + VIEW_DIRECTION.Unit * distance, target)
end

-- Shows the species mesh turning in the viewport when one exists, the placeholder shape frame otherwise.
local function showModel(def: Types.SpeciesDef?)
	clearModel()
	local view, camera = viewBox, viewCamera
	local model: Model? = nil
	if def and view and camera then
		model = Models.Clone(def, Config.ModelViewportScale)
	end
	if shapeBox then
		shapeBox.Visible = model == nil
	end
	if not view or not camera then
		return
	end
	view.Visible = model ~= nil
	if not model then
		return
	end
	spinAngle = 0
	model:PivotTo(CFrame.Angles(0, spinAngle, 0))
	model.Parent = view
	frameCamera(camera, model)
	viewModel = model
	spinConn = RunService.RenderStepped:Connect(function(dt: number)
		spinAngle = (spinAngle + dt * VIEW_SPIN) % (math.pi * 2)
		model:PivotTo(CFrame.Angles(0, spinAngle, 0))
	end)
end

-- Public API -------------------------------------------------------------

function Reveal.IsOpen(): boolean
	return open
end

function Reveal.Show(info: RevealInfo, onClosed: (() -> ())?)
	build()
	local root = gui
	local panel = card
	if not root or not panel then
		return
	end
	onClose = onClosed
	open = true

	local tierColor = Builder.tierColor(info.tier)
	local tierIndex = table.find(Tiers.Order, info.tier) or 1
	local epicIndex = table.find(Tiers.Order, "Epic") or 4

	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	if panelStroke then
		panelStroke.Color = tierColor
	end
	if shapeBox then
		shapeBox.BackgroundColor3 = info.color
	end
	if shapeLabel then
		shapeLabel.Text = Builder.text("SHAPE_" .. info.shape)
	end
	showModel(speciesFor(info))
	if nameLabel then
		nameLabel.Text = info.speciesName
	end
	if tierLabel then
		tierLabel.Text = Builder.text("TIER_" .. info.tier)
		tierLabel.TextColor3 = tierColor
	end
	if overlayBadge and overlayLabel then
		overlayBadge.Visible = info.overlay ~= "None"
		overlayLabel.Text = Builder.text("OVERLAY_" .. info.overlay)
	end
	if newRibbon then
		newRibbon.Visible = info.isNew
	end
	if burst then
		for _, ray in ipairs(burst:GetChildren()) do
			if ray:IsA("Frame") then
				ray.BackgroundColor3 = tierColor
			end
		end
		burst.Rotation = 0
		local spin = TweenService:Create(burst, TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		burstTween = spin
		spin:Play()
	end

	root.Enabled = true
	Builder.open(panel)
	Builder.playSound(Sounds.Reveal[info.tier] or Sounds.Reveal.Common)
	flyScrap(info.scrapGained)
	local bonus = perfectLabel
	if bonus then
		local perfect = info.perfect == true
		bonus.Visible = perfect
		if perfect then
			bonus.Text = Strings.CATCH_PERFECT_BONUS:format(Config.PerfectScrapMultiplier)
			Builder.pop(bonus)
		end
	end
	if tierIndex >= epicIndex then
		confetti(root, tierColor)
	end
end

function Reveal.Close()
	close()
end

return Reveal
