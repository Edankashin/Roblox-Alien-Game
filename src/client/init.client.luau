--!strict
-- StarterPlayerScripts.Client: the client bootstrap. Waits for the profile, builds the HUD, starts the
-- wild-alien renderer, and runs the capture flow: nearest alien -> CaptureStart -> CaptureBar taps ->
-- CaptureHit results -> Reveal. The client only draws and reports tap times; every outcome is the server's.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script:WaitForChild("UI"):WaitForChild("Builder"))
local Hud = require(script:WaitForChild("UI"):WaitForChild("Hud"))
local CaptureBar = require(script:WaitForChild("UI"):WaitForChild("CaptureBar"))
local Reveal = require(script:WaitForChild("UI"):WaitForChild("Reveal"))
local WildRenderer = require(script:WaitForChild("World"):WaitForChild("WildRenderer"))

local localPlayer = Players.LocalPlayer
local started = false
local inCapture = false
local captureToken: string? = nil

local captureStart = Net.func("CaptureStart")
local captureHit = Net.func("CaptureHit")
local captureCancel = Net.event("CaptureCancel")

-- Capture flow ------------------------------------------------------------

local function finishCapture()
	inCapture = false
	captureToken = nil
	CaptureBar.End()
end

local function onCaught(result: Types.CaptureHitResult)
	local species = result.species or ""
	local def = Species.ById[species]
	if species ~= "" then
		WildRenderer.MarkKnown(species)
	end
	if result.scrap then
		Hud.SetScrap(result.scrap)
	end
	task.delay(0.6, function()
		finishCapture()
		Reveal.Show({
			speciesName = if def then def.name else species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(result.tier or "Common"),
			tier = result.tier or "Common",
			overlay = result.overlay or "None",
			isNew = result.isNew == true,
			scrapGained = result.scrapGained or 0,
		})
	end)
end

local function sendTap(tapTime: number)
	local token = captureToken
	if not token then
		return
	end
	task.spawn(function()
		local raw = captureHit:InvokeServer(token, tapTime)
		if not inCapture or captureToken ~= token then
			return
		end
		local result = raw :: Types.CaptureHitResult?
		if not result then
			-- the server dropped the encounter (timeout or despawn)
			finishCapture()
			return
		end
		CaptureBar.ApplyResult(result)
		if result.outcome == "Caught" then
			onCaught(result)
		elseif result.outcome == "Fled" then
			task.delay(0.9, finishCapture)
		end
	end)
end

local function beginCapture(part: Part)
	if inCapture or Reveal.IsOpen() then
		return
	end
	local spawnId = part:GetAttribute("SpawnId")
	if type(spawnId) ~= "string" then
		return
	end
	inCapture = true
	Hud.SetAction(nil)
	-- Own thread: InvokeServer yields, and callers are input callbacks.
	task.spawn(function()
		local raw, reason = captureStart:InvokeServer(spawnId)
		local start = raw :: Types.CaptureStartResult?
		if not start then
			inCapture = false
			print(("[%s] capture refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			return
		end
		captureToken = start.token
		local def = Species.ById[start.species]
		CaptureBar.Begin({
			speciesName = if def then def.name else start.species,
			tierName = Builder.text("TIER_" .. start.tier),
			tierColor = Builder.tierColor(start.tier),
			params = start,
			onTap = sendTap,
		})
	end)
end

-- Returns true when a catch was started.
local function tryCatchNearest(): boolean
	local part = WildRenderer.Nearest(Config.CaptureInteractDistance)
	if part then
		beginCapture(part)
		return true
	end
	return false
end

-- Boot ---------------------------------------------------------------------

local function start(profile: Types.Profile)
	if started then
		return
	end
	started = true

	Hud.Build()
	Hud.SetScrap(profile.scrap)
	Hud.OnAction(function()
		tryCatchNearest()
	end)

	local known: { [string]: boolean } = {}
	for species, entry in pairs(profile.codex) do
		if entry.count > 0 then
			known[species] = true
		end
	end
	WildRenderer.Start(known)

	Net.event("ScrapChanged").OnClientEvent:Connect(function(scrap: number)
		Hud.SetScrap(scrap)
	end)
	Net.event("ClockChanged").OnClientEvent:Connect(function(state: Types.ClockState)
		Hud.SetClock(state)
	end)
	task.spawn(function()
		local state = Net.func("GetClock"):InvokeServer() :: Types.ClockState?
		if state then
			Hud.SetClock(state)
		end
	end)

	-- Contextual button: Catch! while a wild alien is in reach and nothing modal is up.
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < 0.1 then
			return
		end
		accumulator = 0
		if inCapture or Reveal.IsOpen() then
			Hud.SetAction(nil)
			return
		end
		local part = WildRenderer.Nearest(Config.CaptureInteractDistance)
		Hud.SetAction(if part then Strings.ACTION_CATCH else nil)
	end)

	-- Space / gamepad A start a catch on the nearest alien (the CaptureBar rebinds these while open).
	-- Sunk only when a catch starts, so Space still jumps when nothing is in reach.
	ContextActionService:BindAction("StartCapture", function(_name: string, state: Enum.UserInputState, _input: InputObject)
		if state == Enum.UserInputState.Begin and not inCapture and not Reveal.IsOpen() then
			if tryCatchNearest() then
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	-- Tapping or clicking an alien itself also starts a catch when it is in reach.
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or inCapture or Reveal.IsOpen() then
			return
		end
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		local part = WildRenderer.PartAtScreenPoint(input.Position.X, input.Position.Y)
		if not part then
			return
		end
		local character = localPlayer.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") and (root.Position - part.Position).Magnitude <= Config.CaptureInteractDistance then
			beginCapture(part)
		end
	end)

	-- If the character dies mid-catch, release the server-side encounter so the alien is not stuck "Taken".
	localPlayer.CharacterAdded:Connect(function()
		if inCapture then
			captureCancel:FireServer()
			finishCapture()
		end
	end)

	local alienCount = 0
	for _ in pairs(profile.aliens) do
		alienCount += 1
	end
	print(("[%s] client: profile loaded. scrap=%d aliens=%d world=%d"):format(Config.WorkingTitle, profile.scrap, alienCount, profile.world.current))
end

-- The profile can arrive either way: pushed when it loads, or pulled if it loaded before this script ran.
Net.event("ProfileLoaded").OnClientEvent:Connect(function(profile: Types.Profile)
	start(profile)
end)
task.spawn(function()
	local profile = Net.func("GetProfile"):InvokeServer() :: Types.Profile?
	if profile then
		start(profile)
	end
end)

print(("[%s] client started"):format(Config.WorkingTitle))
