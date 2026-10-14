--!strict
-- ReplicatedFirst.LoadingScreen: the game's own loading screen, in place of Roblox's grey one. A cold server loads
-- the 53 creature and prop meshes at boot (ServerScriptService.Server.Services.Models, up to
-- Config.ModelLoadTimeoutSeconds) and the client bootstrap then waits for the profile, so a joining player used to sit
-- on the default screen for several seconds. This shows a cream screen with a bouncing green alien and one outlined
-- line that counts the models as they arrive ("Loading aliens... N / M"), then fades out (0.4 s) when the client
-- bootstrap starts (StarterPlayerScripts.Client sets the player attribute ClientStarted in its start(), right after
-- State.Set). It also removes itself after Config.LoadingScreenMaxSeconds whatever happens, so a broken boot never
-- traps the player behind it. Pure presentation: it decides nothing.
--
-- ReplicatedFirst runs before ReplicatedStorage is guaranteed to exist, so this script depends on nothing in it: the
-- screen is built at once from the hardcoded locals below, and the title, the expected model count, the cap and the
-- strings are read from ReplicatedStorage.Shared only if it arrives in time (a background wait, never blocking the
-- first frame). Without it the screen shows no title, "Loading aliens..." in the English fallback below and the
-- built-in cap, and still works. Scale only for every Position and Size (UIStrokes and the text size cap are pixels).

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- The look. These mirror src/shared/Theme.luau (and the Mossbop row of src/shared/data/Species.luau) because this
-- script cannot require them; change them there and here together.
local FONT = Font.fromEnum(Enum.Font.FredokaOne) -- Theme.Font
local CREAM = Color3.fromHex("FFF4DC") -- Theme.Colors.Panel
local NAVY = Color3.fromHex("1B1F3B") -- Theme.Colors.Outline
local WHITE = Color3.new(1, 1, 1) -- Theme.Colors.White
local HEADING = Color3.fromHex("FFEF4A") -- Theme.Colors.Heading
local MOSSBOP_GREEN = Color3.fromHex("6BCB3F") -- Species Mossbop placeholder.color
local TEXT_STROKE = 2.5 -- Theme.Stroke.Text
local PANEL_STROKE = 4 -- Theme.Stroke.Panel
local MIN_TEXT = 14 -- Theme.TextSize.Min
local LABEL_TEXT = 30 -- a little over Theme.TextSize.Label (24): this is the one line on the screen
local TITLE_TEXT = 48 -- Theme.TextSize.Reveal

-- Timings and fallbacks that cannot live in data/Config because Config may not have arrived.
local FADE_SECONDS = 0.4 -- the fade-out
local POLL_SECONDS = 0.25 -- how often the model count, the cap and the started flag are checked
local BOUNCE_SECONDS = 0.45 -- one way up (the alien comes back down in the same time)
local SHARED_WAIT_SECONDS = 5 -- how long to wait for ReplicatedStorage.Shared before giving up on title and count
local CHILD_WAIT_SECONDS = 2 -- and for each module below it, once Shared is there
local FALLBACK_MAX_SECONDS = 25 -- the cap until Config.LoadingScreenMaxSeconds is read
local FALLBACK_MODELS_FOLDER = "Models" -- Config.ModelFolderName
local FALLBACK_PROPS_FOLDER = "Props" -- Config.PropsFolderName
local FALLBACK_ALIENS_LINE = "Loading aliens... %d / %d" -- strings.LOADING_ALIENS
local FALLBACK_PLAIN_LINE = "Loading aliens..." -- strings.LOADING_PLAIN
local STARTED_ATTRIBUTE = "ClientStarted" -- set on the LocalPlayer by StarterPlayerScripts.Client

local startedAt = os.clock()
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Whether the system's reduced-motion switch is on (false when it cannot be read: it is missing on some clients).
local function reducedMotion(): boolean
	local ok, value = pcall(function(): boolean
		return UserSettings():GetService("UserGameSettings").ReducedMotion
	end)
	return ok and value == true
end

-- Build -------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100 -- over every game screen (the HUD is 10, panels 20, toasts 40, the launch fade 50)
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local background = Instance.new("Frame")
background.Name = "Background"
background.Position = UDim2.fromScale(0, 0)
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = CREAM
background.BorderSizePixel = 0
background.Active = true -- swallows taps while it shows
background.Parent = gui

local function outline(parent: Instance, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = NAVY
	stroke.Parent = parent
end

local function round(frame: Frame)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
end

local function textLabel(name: string, position: UDim2, size: UDim2, color: Color3, maxText: number, strokeThickness: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextColor3 = color
	label.TextScaled = true
	label.Text = ""
	label.ZIndex = 2
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = MIN_TEXT
	sizes.MaxTextSize = maxText
	sizes.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = NAVY
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
	label.Parent = background
	return label
end

local title = textLabel("Title", UDim2.fromScale(0.5, 0.14), UDim2.fromScale(0.9, 0.14), HEADING, TITLE_TEXT, PANEL_STROKE)
local status = textLabel("Status", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.9, 0.09), WHITE, LABEL_TEXT, TEXT_STROKE)

-- The stage is a square (whatever the screen's shape) holding the alien, so everything inside it is plain Scale.
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, 0.47)
stage.Size = UDim2.fromScale(0.5, 0.42)
stage.BackgroundTransparency = 1
stage.Parent = background
local square = Instance.new("UIAspectRatioConstraint")
square.AspectRatio = 1
square.Parent = stage

local SHADOW_REST_SIZE = UDim2.fromScale(0.5, 0.09)
local SHADOW_AIR_SIZE = UDim2.fromScale(0.34, 0.06)
local SHADOW_REST_ALPHA = 0.7
local SHADOW_AIR_ALPHA = 0.88
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.fromScale(0.5, 0.92)
shadow.Size = SHADOW_REST_SIZE
shadow.BackgroundColor3 = NAVY
shadow.BackgroundTransparency = SHADOW_REST_ALPHA
shadow.BorderSizePixel = 0
shadow.Parent = stage
round(shadow)

-- The alien: a round Mossbop-green body with two eyes. Anchored at its bottom centre so the bounce is a height.
local BALL_REST = UDim2.fromScale(0.5, 0.92)
local BALL_PEAK = UDim2.fromScale(0.5, 0.64)
local ball = Instance.new("Frame")
ball.Name = "Alien"
ball.AnchorPoint = Vector2.new(0.5, 1)
ball.Position = BALL_REST
ball.Size = UDim2.fromScale(0.56, 0.56)
ball.BackgroundColor3 = MOSSBOP_GREEN
ball.BorderSizePixel = 0
ball.ZIndex = 2
ball.Parent = stage
round(ball)
outline(ball, PANEL_STROKE)

local shine = Instance.new("Frame")
shine.Name = "Shine"
shine.AnchorPoint = Vector2.new(0.5, 0.5)
shine.Position = UDim2.fromScale(0.28, 0.2)
shine.Size = UDim2.fromScale(0.2, 0.12)
shine.BackgroundColor3 = WHITE
shine.BackgroundTransparency = 0.55
shine.BorderSizePixel = 0
shine.Rotation = -30
shine.ZIndex = 3
shine.Parent = ball
round(shine)

for index, x in { 0.32, 0.68 } do
	local eye = Instance.new("Frame")
	eye.Name = "Eye" .. index
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(x, 0.45)
	eye.Size = UDim2.fromScale(0.24, 0.24)
	eye.BackgroundColor3 = WHITE
	eye.BorderSizePixel = 0
	eye.ZIndex = 3
	eye.Parent = ball
	round(eye)
	outline(eye, TEXT_STROKE)
	local pupil = Instance.new("Frame")
	pupil.Name = "Pupil"
	pupil.AnchorPoint = Vector2.new(0.5, 0.5)
	pupil.Position = UDim2.fromScale(0.55, 0.55)
	pupil.Size = UDim2.fromScale(0.5, 0.5)
	pupil.BackgroundColor3 = NAVY
	pupil.BorderSizePixel = 0
	pupil.ZIndex = 4
	pupil.Parent = eye
	round(pupil)
end

gui.Parent = playerGui

-- The bounce: up with a quad ease out and, reversed, down with the matching ease in, forever. Reduced motion keeps the
-- alien still.
if not reducedMotion() then
	local bounce = TweenInfo.new(BOUNCE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true)
	TweenService:Create(ball, bounce, { Position = BALL_PEAK }):Play()
	TweenService:Create(shadow, bounce, { Size = SHADOW_AIR_SIZE, BackgroundTransparency = SHADOW_AIR_ALPHA }):Play()
end

-- Shared data (arrives in the background) -----------------------------------

local maxSeconds = FALLBACK_MAX_SECONDS
local modelsFolderName = FALLBACK_MODELS_FOLDER
local propsFolderName = FALLBACK_PROPS_FOLDER
local alienLine = FALLBACK_ALIENS_LINE
local plainLine = FALLBACK_PLAIN_LINE
local expectedModels: number? = nil -- M: how many models the server will load; nil until known (or when it loads none)
local removing = false

-- The ModuleScript Shared.<path...>, waited for briefly, required under pcall; nil when it is missing or errors.
local function requireShared(shared: Instance, path: { string }): { [string]: any }?
	local node: Instance? = shared
	for _, name in path do
		node = if node then node:WaitForChild(name, CHILD_WAIT_SECONDS) else nil
	end
	if node and node:IsA("ModuleScript") then
		local ok, result = pcall(require, node)
		if ok and type(result) == "table" then
			return result :: { [string]: any }
		end
	end
	return nil
end

local function countKeys(map: any): number
	local count = 0
	if type(map) == "table" then
		for _ in pairs(map :: { [any]: any }) do
			count += 1
		end
	end
	return count
end

-- The models that have arrived: every non-Folder child of ReplicatedStorage.<Models> plus the non-Folder children of
-- <Models>.<Props> (the Props folder itself is not a model, so it never counts).
local function countModels(): number
	local models = ReplicatedStorage:FindFirstChild(modelsFolderName)
	if not models then
		return 0
	end
	local count = 0
	for _, child in models:GetChildren() do
		if not child:IsA("Folder") then
			count += 1
		end
	end
	local props = models:FindFirstChild(propsFolderName)
	if props then
		for _, child in props:GetChildren() do
			if not child:IsA("Folder") then
				count += 1
			end
		end
	end
	return count
end

local function refreshStatus()
	local total = expectedModels
	local text = if total and total > 0 then alienLine:format(math.min(countModels(), total), total) else plainLine
	if status.Text ~= text then
		status.Text = text
	end
end

task.spawn(function()
	local shared = ReplicatedStorage:WaitForChild("Shared", SHARED_WAIT_SECONDS)
	if not shared or removing then
		return
	end
	local config = requireShared(shared, { "data", "Config" })
	if config then
		if type(config.WorkingTitle) == "string" then
			title.Text = config.WorkingTitle
		end
		if type(config.LoadingScreenMaxSeconds) == "number" then
			maxSeconds = config.LoadingScreenMaxSeconds
		end
		if type(config.ModelFolderName) == "string" then
			modelsFolderName = config.ModelFolderName
		end
		if type(config.PropsFolderName) == "string" then
			propsFolderName = config.PropsFolderName
		end
	end
	-- The count only means something when the server loads models at boot (Config.LoadModelsAtBoot); otherwise the line
	-- stays plain.
	if not config or config.LoadModelsAtBoot ~= false then
		local assets = requireShared(shared, { "data", "ModelAssets" })
		local total = if assets then countKeys(assets.AssetIds) else 0
		if total > 0 then
			expectedModels = total
		end
	end
	local strings = requireShared(shared, { "strings", "en" })
	if strings then
		if type(strings.LOADING_ALIENS) == "string" then
			alienLine = strings.LOADING_ALIENS
		end
		if type(strings.LOADING_PLAIN) == "string" then
			plainLine = strings.LOADING_PLAIN
		end
	end
	if not removing then
		refreshStatus()
	end
end)

-- Remove ---------------------------------------------------------------------

-- Fades everything out over FADE_SECONDS and destroys the screen. Runs once.
local function remove()
	if removing then
		return
	end
	removing = true
	local info = TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function fade(instance: Instance, goal: { [string]: any })
		TweenService:Create(instance, info, goal):Play()
	end
	fade(background, { BackgroundTransparency = 1 })
	for _, node in background:GetDescendants() do
		if node:IsA("TextLabel") then
			fade(node, { TextTransparency = 1 })
		elseif node:IsA("Frame") then
			fade(node, { BackgroundTransparency = 1 })
		elseif node:IsA("UIStroke") then
			fade(node, { Transparency = 1 })
		end
	end
	background.Active = false
	task.delay(FADE_SECONDS, function()
		gui:Destroy()
	end)
end

player:GetAttributeChangedSignal(STARTED_ATTRIBUTE):Connect(function()
	if player:GetAttribute(STARTED_ATTRIBUTE) == true then
		remove()
	end
end)

-- The count, the cap and the started flag, polled (the folders fill in whatever order the loads finish).
refreshStatus()
while not removing do
	if player:GetAttribute(STARTED_ATTRIBUTE) == true or os.clock() - startedAt >= maxSeconds then
		remove()
		break
	end
	refreshStatus()
	task.wait(POLL_SECONDS)
end
