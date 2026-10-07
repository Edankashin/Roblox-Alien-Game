--!strict
-- StarterPlayerScripts.Client.UI.Reveal: the catch reveal ritual. Backdrop dims, the card scales in
-- with a Back ease, a radial burst spins behind it, the tier name shows in its colour, confetti for
-- Epic and above, "+N Scrap" floats up, "Tap anywhere" closes. Pure presentation of a server result.
-- A size band that names itself (data/Sizes label: Tiny, Big, HUGE) stamps "HUGE Zorp!" in the Featured
-- colour above the species name with its Scrap multiplier beneath the tier, and pops the card by the
-- band's revealPop (no pop under Reduced Motion).
-- The card's Shape area shows the species mesh (World.Models) turning in a ViewportFrame when one
-- exists, the placeholder colour-and-shape frame otherwise.
-- Sprites (Icons.Particles, id 0 = not uploaded, then nothing changes): a Shine sunburst turns behind the
-- card in the tier colour (still under Reduced Motion), and the confetti pieces wear the Confetti sprite.
-- A Perfect catch (info.perfect, not under Reduced Motion) also flashes the screen white for
-- Config.VfxPerfectFlashSeconds; the flash takes no input.
-- A grant that carries overflowScrap (the storage cap was full, data/Storage: the alien turned into Scrap and no
-- record was added) wears a red "Storage full: turned into N Scrap" ribbon above the card, and closing the Reveal
-- toasts the hint to release or fuse aliens to keep new catches.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local Prefs = require(script.Parent.Parent.Prefs)
local Models = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Models"))
local MusicDirector = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("MusicDirector"))

local Reveal = {}

export type RevealInfo = {
	speciesName: string,
	speciesId: string?, -- the species row, for its mesh; without it the name is looked up in Species.List
	shape: string, -- placeholder shape name, shown on the card until real art exists
	color: Color3,
	tier: string,
	overlay: string, -- "None" hides the badge
	size: string, -- the size band id (data/Sizes); the labelled bands get the stamp and the pop
	isNew: boolean,
	scrapGained: number,
	perfect: boolean?, -- the server scored a Perfect hit: show the Scrap multiplier line
	overflowScrap: number?, -- the storage cap was full: the alien turned into this much Scrap (already in scrapGained)
}

local CONFETTI_COUNT = 20
local BURST_RAYS = 8
local VIEW_FOV = 40 -- the model viewport's camera
local VIEW_FIT = 1.15 -- camera distance margin over the model's bounding radius
local VIEW_DIRECTION = Vector3.new(-0.6, 0.45, -1) -- from the model's front-left, slightly above
local VIEW_SPIN = math.rad(30) -- radians per second while the reveal is open
-- Card layout (fractions of the card's height): the species and tier lines drop a little under a size
-- stamp, which takes the gap between the model and the name.
local NAME_Y = 0.7
local TIER_Y = 0.8
local NAME_Y_STAMPED = 0.745
local TIER_Y_STAMPED = 0.845
local STAMP_Y = 0.655
local STAMP_SCRAP_Y = 0.945 -- of the screen, on the root like the Scrap (0.815) and Perfect (0.885) lines, under both
local STAMP_PEAK = 1.5 -- the stamp slams in from this scale
local CARD_ASPECT = 0.8 -- the card's width over height
local CARD_POSITION = UDim2.fromScale(0.5, 0.47)
local CARD_SIZE = UDim2.fromScale(0.6, 0.56) -- ends at 0.75, clear of the Scrap line below
local RAYS_WIDTH = 1.6 -- the sunburst sprite's width, in card widths
local RAYS_TRANSPARENCY = 0.35
local FLASH_START = 0.15 -- the Perfect flash's starting transparency; it fades from here to 1
local FLASH_LAYER = 10 -- its ZIndex: over the card, the text lines (8) and the confetti (9)
local TIER_LABEL_W = 0.9 -- the tier label's width, of the card
local TIER_H = 0.08 -- its height, of the card; the rarity badge beside it is this tall and square
local TIER_ICON_GAP = 0.015 -- of the card's width, between the badge and the tier text
local STORAGE_Y = 0.09 -- the storage-full ribbon, of the screen: centred above the card (which starts at 0.19)
local STORAGE_W = 0.7
local STORAGE_H = 0.09

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
local tierBadge: ImageLabel? = nil -- the rarity badge left of the tier text; absent while its image is not uploaded
local stampLabel: TextLabel? = nil
local stampScrapLabel: TextLabel? = nil
local overlayBadge: Frame? = nil
local overlayLabel: TextLabel? = nil
local newRibbon: Frame? = nil
local scrapLabel: TextLabel? = nil
local storageRibbon: Frame? = nil -- the "Storage full" ribbon above the card
local storageLabel: TextLabel? = nil
local storageHint = false -- the Reveal on screen was a storage overflow: close toasts the hint
local perfectLabel: TextLabel? = nil
local burstTween: Tween? = nil
local raysFrame: Frame? = nil -- holds the sunburst sprite; made by Show, destroyed with the close
local raysTween: Tween? = nil
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

-- Seats the rarity badge just left of the tier text, on the label's own line. The text is centred in its
-- label, so the badge's right edge sits half the text's share of the label (TextBounds over the label's
-- width, both in the same scaled pixels) plus a gap left of the centre line. Until the text is measured it
-- sits at the label's left edge instead, clear of the text. Called when the label moves (the size stamp)
-- and whenever the text is re-measured, so the badge follows the label.
local function placeTierBadge()
	local badge, label = tierBadge, tierLabel
	if not badge or not label then
		return
	end
	local labelWidth = label.AbsoluteSize.X
	local share = if labelWidth > 0 and label.TextBounds.X > 0 then math.min(1, label.TextBounds.X / labelWidth) else 1
	badge.Position = UDim2.fromScale(0.5 - TIER_LABEL_W * share / 2 - TIER_ICON_GAP, label.Position.Y.Scale)
end

-- Stops the sunburst's turning; the sprite stays until clearRays.
local function stopRays()
	if raysTween then
		raysTween:Cancel()
		raysTween = nil
	end
end

local function clearRays()
	stopRays()
	if raysFrame then
		raysFrame:Destroy()
		raysFrame = nil
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
	stopRays()
	if card and root then
		Builder.close(card, function()
			if not open then
				clearModel()
				clearRays()
				root.Enabled = false
			end
		end)
	elseif root then
		clearModel()
		clearRays()
		root.Enabled = false
	end
	local callback = onClose
	onClose = nil
	if callback then
		callback()
	end
	if storageHint then
		storageHint = false
		Toast.Show(Strings.TOAST_STORAGE_FULL_HINT, Theme.Colors.Close)
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
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel + 2,
		strokeColor = Theme.Rarity.Common,
		aspect = CARD_ASPECT,
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
		position = UDim2.fromScale(0.5, NAME_Y),
		size = UDim2.fromScale(0.9, 0.12),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	local tier = Builder.label({
		parent = panel,
		name = "Tier",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, TIER_Y),
		size = UDim2.fromScale(TIER_LABEL_W, TIER_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	tierLabel = tier
	tier:GetPropertyChangedSignal("TextBounds"):Connect(placeTierBadge)
	tier:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeTierBadge)
	-- Size stamp (shown only for the bands that name themselves): the band and the species in gold over
	-- the model's foot, then the Scrap multiplier small beneath the tier.
	local stamp = Builder.label({
		parent = panel,
		name = "SizeStamp",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, STAMP_Y),
		size = UDim2.fromScale(0.94, 0.07),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = 6,
	})
	stamp.Visible = false
	stampLabel = stamp
	local stampScrap = Builder.label({
		parent = root,
		name = "SizeScrap",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, STAMP_SCRAP_Y),
		size = UDim2.fromScale(0.5, 0.05),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = 8,
	})
	stampScrap.Visible = false
	stampScrapLabel = stampScrap
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
	-- Storage-full ribbon (shown only for a grant that overflowed the cap): a red pill above the card.
	local storage = Builder.pill({
		parent = root,
		name = "StorageFull",
		position = UDim2.fromScale(0.5, STORAGE_Y),
		size = UDim2.fromScale(STORAGE_W, STORAGE_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Close,
		stroke = Theme.Stroke.Text,
		zIndex = 8,
	})
	Builder.gradient(storage, Theme.Colors.Close)
	storage.Visible = false
	storageRibbon = storage
	storageLabel = Builder.label({
		parent = storage,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.92, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 9,
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

-- The sunburst sprite (Icons.Particles.Shine) behind the card, built per reveal: a square in the tier
-- colour, RAYS_WIDTH card widths wide, turning once per Config.VfxRevealRaysSeconds (still under Reduced
-- Motion). Nothing is made while the sprite is not uploaded. Layered under the card, over the dim.
local function showRays(root: ScreenGui, tierColor: Color3)
	clearRays()
	local sprite = Icons.Particles.Shine
	if sprite == 0 then
		return
	end
	-- A holder with the card's own place, size and shape, so the sprite is sized in card widths with Scale only.
	local holder = Builder.frame({
		parent = root,
		name = "Sunburst",
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		aspect = CARD_ASPECT,
		zIndex = 2,
	})
	local image = Instance.new("ImageLabel")
	image.Name = "Rays"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = "rbxassetid://" .. sprite
	image.ImageColor3 = tierColor
	image.ImageTransparency = RAYS_TRANSPARENCY
	image.ScaleType = Enum.ScaleType.Fit
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(RAYS_WIDTH, RAYS_WIDTH * CARD_ASPECT) -- the holder is CARD_ASPECT wide per tall: this is square
	image.ZIndex = 2
	image.Parent = holder
	raysFrame = holder
	if not Prefs.ReducedMotion() then
		local spin = TweenService:Create(image, TweenInfo.new(Config.VfxRevealRaysSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		raysTween = spin
		spin:Play()
	end
end

-- One confetti piece at the card's centre: the Confetti sprite (Icons.Particles) when it is uploaded,
-- a plain frame otherwise. Also returns the property that fades it.
local function confettiPiece(root: ScreenGui, color: Color3, sprite: number): (GuiObject, string)
	if sprite ~= 0 then
		local image = Instance.new("ImageLabel")
		image.Name = "Confetti"
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Image = "rbxassetid://" .. sprite
		image.ImageColor3 = color
		image.ScaleType = Enum.ScaleType.Fit
		image.Position = UDim2.fromScale(0.5, 0.47)
		image.Size = UDim2.fromScale(0.012, 0.025)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ZIndex = 9
		image.Parent = root
		return image, "ImageTransparency"
	end
	local piece = Builder.frame({
		parent = root,
		name = "Confetti",
		position = UDim2.fromScale(0.5, 0.47),
		size = UDim2.fromScale(0.012, 0.025),
		anchor = Vector2.new(0.5, 0.5),
		color = color,
		zIndex = 9,
	})
	return piece, "BackgroundTransparency"
end

local function confetti(root: ScreenGui, tierColor: Color3)
	local palette = { tierColor, Theme.Colors.Featured, Theme.Colors.Confirm, Theme.Colors.Select, Theme.Colors.Close, Theme.Colors.White }
	local rng = Random.new()
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local sprite = Icons.Particles.Confetti
	for _ = 1, CONFETTI_COUNT do
		local piece, fade = confettiPiece(root, palette[rng:NextInteger(1, #palette)], sprite)
		piece.Rotation = rng:NextNumber(0, 360)
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.18, 0.42)
		local target = UDim2.fromScale(0.5 + math.cos(angle) * distance, 0.47 + math.sin(angle) * distance * 1.4)
		local tween = TweenService:Create(piece, info, { Position = target, Rotation = piece.Rotation + rng:NextNumber(-360, 360), [fade] = 1 })
		tween.Completed:Once(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

-- The white flash of a Perfect catch: a full-screen frame over everything on the reveal, fading out and
-- then removed. A plain Frame that is not Active, so it takes no input and the tap that closes still lands.
local function perfectFlash(root: ScreenGui)
	local flash = Builder.frame({
		parent = root,
		name = "PerfectFlash",
		color = Theme.Colors.White,
		transparency = FLASH_START,
		zIndex = FLASH_LAYER,
	})
	flash.Active = false
	local tween = TweenService:Create(flash, TweenInfo.new(Config.VfxPerfectFlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		flash:Destroy()
	end)
	tween:Play()
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

-- Size stamp --------------------------------------------------------------

-- A whole multiplier prints bare ("2"), a fractional one with its decimals trimmed ("1.5", "1.25").
local function formatMultiplier(multiplier: number): string
	if multiplier == math.floor(multiplier) then
		return tostring(math.floor(multiplier))
	end
	return (string.format("%.2f", multiplier):gsub("0+$", ""))
end

-- Shows or hides the size stamp for a band, and moves the name and tier lines to suit. A band without
-- a label (Normal, Small) leaves the card exactly as it was.
local function showStamp(info: RevealInfo, band: Sizes.Band)
	local stamp, stampScrap = stampLabel, stampScrapLabel
	local stamped = band.label
	if nameLabel then
		nameLabel.Position = UDim2.fromScale(0.5, if stamped then NAME_Y_STAMPED else NAME_Y)
	end
	if tierLabel then
		tierLabel.Position = UDim2.fromScale(0.5, if stamped then TIER_Y_STAMPED else TIER_Y)
		placeTierBadge()
	end
	if stamp then
		stamp.Visible = stamped
		if stamped then
			stamp.Text = if band.scrapMultiplier ~= 1
				then Strings.REVEAL_SIZE_SCRAP:format(Builder.text("SIZE_" .. band.id), info.speciesName, formatMultiplier(band.scrapMultiplier))
				else Strings.REVEAL_SIZE:format(Builder.text("SIZE_" .. band.id), info.speciesName)
			local scale = stamp:FindFirstChildOfClass("UIScale")
			if Prefs.ReducedMotion() then
				if scale then
					scale.Scale = 1
				end
			else
				Builder.pop(stamp, STAMP_PEAK)
			end
		end
	end
	if stampScrap then
		local bonus = stamped and band.scrapMultiplier ~= 1
		stampScrap.Visible = bonus
		if bonus then
			stampScrap.Text = "" -- the multiplier rides on the stamp line; the root's Scrap, Perfect and Tap lines keep their slots
		end
	end
end

-- The card's pop-in for a band with its own revealPop: up from the usual start to `peak` times the
-- resting size with the Back ease, then settling to 1. Normal (1) keeps the plain open.
local function popCard(panel: GuiObject, peak: number)
	local scale = panel:FindFirstChildOfClass("UIScale")
	if not scale then
		return
	end
	scale.Scale = 0.85
	local rise = TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = peak })
	rise.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed and open then
			TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end)
	rise:Play()
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
	local band = Sizes.ById[info.size] or Sizes.ById[Sizes.Default]
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
	-- The rarity badge (key = the tier) beside the tier text, rebuilt per reveal; showStamp seats it.
	if tierBadge then
		tierBadge:Destroy()
		tierBadge = nil
	end
	tierBadge = Builder.icon({
		parent = panel,
		name = "TierBadge",
		key = info.tier,
		size = UDim2.fromScale(TIER_H / CARD_ASPECT, TIER_H),
		anchor = Vector2.new(1, 0.5),
		zIndex = 4,
	})
	showStamp(info, band)
	if overlayBadge and overlayLabel then
		overlayBadge.Visible = info.overlay ~= "None"
		overlayLabel.Text = Builder.text("OVERLAY_" .. info.overlay)
	end
	if newRibbon then
		newRibbon.Visible = info.isNew
	end
	local overflow = info.overflowScrap
	storageHint = overflow ~= nil
	if storageRibbon and storageLabel then
		storageRibbon.Visible = overflow ~= nil
		if overflow ~= nil then
			storageLabel.Text = Strings.REVEAL_STORAGE_FULL:format(Builder.formatNumber(overflow))
			if not Prefs.ReducedMotion() then
				Builder.pop(storageRibbon, 1.15)
			end
		end
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
	showRays(root, tierColor)

	root.Enabled = true
	Builder.open(panel)
	if band.revealPop ~= 1 and not Prefs.ReducedMotion() then
		popCard(panel, band.revealPop)
	end
	-- The tier's stinger plays through the music director, which ducks the bed for its length (data/Music Ducking).
	MusicDirector.Stinger(if Sounds.Reveal[info.tier] ~= nil then "Reveal." .. info.tier else "Reveal.Common")
	flyScrap(info.scrapGained)
	local bonus = perfectLabel
	if bonus then
		local perfect = info.perfect == true
		bonus.Visible = perfect
		if perfect then
			bonus.Text = Strings.CATCH_PERFECT_BONUS:format(Config.PerfectScrapMultiplier)
			Builder.pop(bonus)
			if not Prefs.ReducedMotion() then
				perfectFlash(root)
			end
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
