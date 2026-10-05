--!strict
-- StarterPlayerScripts.Client: the client bootstrap. Waits for the profile, mirrors it in State, builds
-- the HUD, starts the world renderers (wild aliens, the player's own camp, material nodes) and runs
-- the capture flow: nearest alien -> CaptureStart -> CaptureBar taps -> CaptureHit results -> Reveal.
-- The contextual button shows one verb at a time: Catch!, Collect, Build or Launch. The client only
-- draws and reports tap times and ids; every outcome is the server's.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Economy = require(Shared:WaitForChild("Economy"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local State = require(script:WaitForChild("State"))
local Builder = require(script:WaitForChild("UI"):WaitForChild("Builder"))
local Hud = require(script:WaitForChild("UI"):WaitForChild("Hud"))
local CaptureBar = require(script:WaitForChild("UI"):WaitForChild("CaptureBar"))
local Reveal = require(script:WaitForChild("UI"):WaitForChild("Reveal"))
local Toast = require(script:WaitForChild("UI"):WaitForChild("Toast"))
local Screens = require(script:WaitForChild("UI"):WaitForChild("Screens"))
local ShipScreen = require(script:WaitForChild("UI"):WaitForChild("ShipScreen"))
local ShopScreen = require(script:WaitForChild("UI"):WaitForChild("ShopScreen"))
local AliensScreen = require(script:WaitForChild("UI"):WaitForChild("AliensScreen"))
local CodexScreen = require(script:WaitForChild("UI"):WaitForChild("CodexScreen"))
local NearbyPanel = require(script:WaitForChild("UI"):WaitForChild("NearbyPanel"))
local WildRenderer = require(script:WaitForChild("World"):WaitForChild("WildRenderer"))
local CampRenderer = require(script:WaitForChild("World"):WaitForChild("CampRenderer"))
local NodeRenderer = require(script:WaitForChild("World"):WaitForChild("NodeRenderer"))
local PeddlerRenderer = require(script:WaitForChild("World"):WaitForChild("PeddlerRenderer"))
local PeddlerScreen = require(script:WaitForChild("UI"):WaitForChild("PeddlerScreen"))
local PowerUpBar = require(script:WaitForChild("UI"):WaitForChild("PowerUpBar"))
local QuestsScreen = require(script:WaitForChild("UI"):WaitForChild("QuestsScreen"))
local TutorialHint = require(script:WaitForChild("UI"):WaitForChild("TutorialHint"))
local GiftsScreen = require(script:WaitForChild("UI"):WaitForChild("GiftsScreen"))
local LandmarkRenderer = require(script:WaitForChild("World"):WaitForChild("LandmarkRenderer"))
local Quests = require(Shared:WaitForChild("data"):WaitForChild("Quests"))

local ACTION_POLL_SECONDS = 0.1 -- how often the contextual button re-decides its verb
local TOAST_TOP_WITH_PANEL = 0.03 -- with a panel open, toasts sit over the dimmed HUD row instead of the panel's header
local TOAST_TOP_WITH_BANNER = 0.19 -- while the event banner has the luck line's slot, toasts stack beneath it
local SHIP_POLL_SECONDS = 0.5 -- how often the ship bar extrapolates assembly progress
local PROFILE_PULL_SECONDS = 1 -- retry interval while the server is still loading the profile
local BIOME_POLL_SECONDS = 0.5 -- how often the biome chip re-reads the player's position
local SHOWER_POLL_SECONDS = 1 -- the shower chip and banner count down between server pushes

local localPlayer = Players.LocalPlayer
local started = false
local inCapture = false
local captureToken: string? = nil
local collecting = false

type Action = "Catch" | "Collect" | "Build" | "Launch" | "Trade" | "Horn"
local currentAction: Action? = nil
local ACTION_TEXT: { [string]: string } = {
	Catch = Strings.ACTION_CATCH,
	Collect = Strings.ACTION_COLLECT,
	Build = Strings.ACTION_BUILD,
	Launch = Strings.ACTION_LAUNCH,
	Trade = Strings.ACTION_TRADE,
	Horn = Strings.ACTION_HORN,
}
local soundHorn = Net.func("SoundHorn")
local horning = false

local captureStart = Net.func("CaptureStart")
local captureHit = Net.func("CaptureHit")
local captureCancel = Net.event("CaptureCancel")
local collectMaterial = Net.func("CollectMaterial")

-- A catch in progress or a modal screen blocks every other action.
local function modalOpen(): boolean
	return inCapture or Reveal.IsOpen() or Screens.IsAnyOpen()
end

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
		State.ApplyCatch(species, result.overlay or "None")
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
			perfect = result.perfect == true,
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
	if modalOpen() then
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

-- Materials ---------------------------------------------------------------

-- Asks the server for the nearest available node. Returns true when a request went out.
local function tryCollectNearest(): boolean
	if collecting then
		return false
	end
	local part = NodeRenderer.Nearest(Config.MaterialInteractDistance)
	if not part then
		return false
	end
	local nodeId = NodeRenderer.NodeIdOf(part)
	if not nodeId then
		return false
	end
	collecting = true
	task.spawn(function()
		local ok, reason = collectMaterial:InvokeServer(nodeId)
		collecting = false
		if ok == true then
			return -- the server's MaterialCollected push shows the toast
		end
		if reason == "Taken" then
			Toast.Show(Strings.TOAST_NODE_EMPTY, Theme.Colors.Close)
		else
			print(("[%s] collect refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
	return true
end

-- Ship --------------------------------------------------------------------

local function refreshShip()
	if not State.Has() then
		return
	end
	local profile = State.Get()
	Hud.SetShip(Economy.shipPercent(profile, profile.world.current, State.Now()))
end

-- Biome chip ----------------------------------------------------------------

local currentBiome: Types.Biome? = nil

local function refreshBiome()
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local biome: Types.Biome = Biomes.At(root.Position) -- annotated: the checker widens singleton unions
	if biome ~= currentBiome then
		currentBiome = biome
		Hud.SetBiome(biome)
		State.SetBiome(biome)
	end
end

local function shipComplete(): boolean
	local profile = State.Get()
	return Economy.activeModuleIndex(profile, profile.world.current) == nil
end

-- Contextual action ---------------------------------------------------------

-- One verb at a time: of the targets in reach (a wild alien, a material node, the ship), the nearest wins,
-- so standing next to a node beside an alien still offers Collect.
local function decideAction(): Action?
	if modalOpen() or not State.Has() then
		return nil
	end
	local best: Action? = nil
	local bestDistance = math.huge
	-- Nearest returns the cap as the distance when nothing is in range, so the part decides, not the number.
	local wildPart, wildDistance = WildRenderer.Nearest(Config.CaptureInteractDistance)
	if wildPart then
		best, bestDistance = "Catch", wildDistance
	end
	local nodePart, nodeDistance = NodeRenderer.Nearest(Config.MaterialInteractDistance)
	if nodePart and nodeDistance < bestDistance then
		best, bestDistance = "Collect", nodeDistance
	end
	local shipDistance = CampRenderer.DistanceToShip()
	if shipDistance <= Config.CampInteractDistance and shipDistance < bestDistance then
		best, bestDistance = if shipComplete() then "Launch" else "Build", shipDistance
	end
	local peddlerDistance = PeddlerRenderer.DistanceToShip()
	if peddlerDistance <= Config.PeddlerInteractDistance and peddlerDistance < bestDistance then
		best, bestDistance = "Trade", peddlerDistance
	end
	-- The horn is offered at the shrine whenever the player holds it; the server judges night and step.
	local shrineDistance = LandmarkRenderer.DistanceTo("Shrine")
	if shrineDistance <= Config.ShrineInteractDistance and shrineDistance < bestDistance and (State.Get().inventory.items[Quests.HornItem] or 0) > 0 then
		best = "Horn"
	end
	return best
end

local function performAction()
	local action = currentAction
	if action == "Catch" then
		tryCatchNearest()
	elseif action == "Collect" then
		tryCollectNearest()
	elseif action == "Build" then
		Screens.Open("Ship")
	elseif action == "Launch" then
		-- Launching arrives with World 2; the complete ship is the milestone for now.
		Toast.Show(Strings.SHIP_COMPLETE, Theme.Colors.Featured)
	elseif action == "Trade" then
		Screens.Open("Peddler")
	elseif action == "Horn" and not horning then
		horning = true
		task.spawn(function()
			local ok, reason = soundHorn:InvokeServer()
			horning = false
			if ok == true then
				return -- WardenSummoned carries the toast
			elseif reason == "NotNight" then
				Toast.Show(Strings.TOAST_HORN_NOT_NIGHT, Theme.Colors.Select)
			elseif reason == "TooFar" then
				Toast.Show(Strings.TOAST_HORN_TOO_FAR, Theme.Colors.Select)
			elseif reason == "Cooldown" then
				Toast.Show(Strings.TOAST_HORN_COOLDOWN, Theme.Colors.Select)
			else
				print(("[%s] horn refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			end
		end)
	end
end

-- Server pushes that only need a toast ----------------------------------------
-- Each wait runs in its own thread so a remote the server has not created yet never blocks the boot.

local function connectToasts()
	task.spawn(function()
		Net.event("MaterialCollected").OnClientEvent:Connect(function(material: string, count: number)
			Toast.Show(Strings.TOAST_MATERIAL:format(count, Builder.text("MATERIAL_" .. material)), Theme.Colors.Featured)
		end)
	end)
	task.spawn(function()
		Net.event("ModuleCompleted").OnClientEvent:Connect(function(worldId: number, moduleId: string)
			Toast.Show(Strings.TOAST_MODULE_DONE:format(Builder.text("MODULE_" .. moduleId)), Theme.Colors.Confirm)
			local def = Economy.moduleDef(worldId, moduleId)
			if def and def.unlocksSlots then
				Toast.Show(Strings.TOAST_SLOT_UNLOCKED:format(def.unlocksSlots), Theme.Colors.Featured)
			end
		end)
	end)
	-- Server-wide catch banners for rare finds, in the tier's colour.
	task.spawn(function()
		Net.event("Announcement").OnClientEvent:Connect(function(note: Types.Announcement)
			local def = Species.ById[note.species]
			local speciesName = if def then def.name else note.species
			local text = if note.overlay ~= "None"
				then Strings.ANNOUNCE_CATCH_OVERLAY:format(note.playerName, Builder.text("OVERLAY_A_" .. note.overlay), Builder.text("TIER_" .. note.tier), speciesName)
				else Strings.ANNOUNCE_CATCH:format(note.playerName, Builder.text("TIER_A_" .. note.tier), speciesName)
			Toast.Banner(text, Builder.tierColor(note.tier), Config.AnnounceSeconds)
		end)
	end)
	task.spawn(function()
		Net.event("WardenSummoned").OnClientEvent:Connect(function()
			Toast.Banner(Strings.TOAST_WARDEN_AWAKE, Builder.tierColor("Legendary"), Config.AnnounceSeconds)
		end)
	end)
	task.spawn(function()
		Net.event("WardenRetreated").OnClientEvent:Connect(function()
			Toast.Show(Strings.TOAST_WARDEN_RETREAT, Builder.tierColor("Legendary"))
		end)
	end)
	-- The offline settlement is claimed rather than pushed, so it is never missed on a slow boot.
	task.spawn(function()
		local raw = Net.func("ClaimOfflineSummary"):InvokeServer()
		local summary = raw :: Types.OfflineSummary?
		if not summary then
			return
		end
		Toast.Show(Strings.OFFLINE_TITLE, Theme.Colors.Featured)
		if summary.scrap > 0 then
			Toast.Show(Strings.OFFLINE_BODY:format(Builder.formatNumber(summary.scrap)), Theme.Colors.Featured)
		end
		for _, moduleId in ipairs(summary.completedModules) do
			Toast.Show(Strings.OFFLINE_MODULES:format(Builder.text("MODULE_" .. moduleId)), Theme.Colors.Confirm)
		end
	end)
end

-- Boot ---------------------------------------------------------------------

local function start(profile: Types.Profile)
	if started then
		return
	end
	started = true

	State.Set(profile)
	State.Start()

	-- The default chat window sits top-left over the Scrap pill and the menu stack; move it bottom-left.
	local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if chatWindow then
		chatWindow.HorizontalAlignment = Enum.HorizontalAlignment.Left
		chatWindow.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	Hud.Build()
	Hud.SetScrap(profile.scrap)
	Hud.SetShipTicks(Economy.milestones(profile.world.current))
	Hud.SetRate(State.GetRate().ratePerSecond)
	refreshShip()
	Hud.OnAction(performAction)
	Hud.OnShipTapped(function()
		if not inCapture and not Reveal.IsOpen() then
			Screens.Toggle("Ship")
		end
	end)

	-- Modal screens: one open at a time, each behind a left-edge menu button.
	Screens.Register("Ship", ShipScreen)
	Screens.Register("Shop", ShopScreen)
	Screens.Register("Peddler", PeddlerScreen)
	Screens.Register("Quests", QuestsScreen)
	Screens.Register("Gifts", GiftsScreen)
	-- An egg from the Peddler hatches through the same reveal as a wild catch.
	PeddlerScreen.OnGrant(function(grant: Types.GrantResult)
		local def = Species.ById[grant.species]
		WildRenderer.MarkKnown(grant.species)
		State.ApplyCatch(grant.species, grant.overlay)
		Screens.CloseAll()
		Reveal.Show({
			speciesName = if def then def.name else grant.species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(grant.tier),
			tier = grant.tier,
			overlay = grant.overlay,
			isNew = grant.isNew,
			scrapGained = grant.scrapGained,
			perfect = false,
		})
	end)
	PeddlerRenderer.Start()
	PowerUpBar.Build()
	State.OnChanged("luck", function()
		Hud.SetLuck(State.GetLuck())
	end)
	Hud.SetLuck(State.GetLuck())
	Screens.Register("Aliens", AliensScreen)
	Screens.Register("Codex", CodexScreen)
	local function menu(name: string)
		return function()
			if not inCapture and not Reveal.IsOpen() then
				Screens.Toggle(name)
			end
		end
	end
	Hud.AddMenuButton("Shop", Theme.Colors.Confirm, menu("Shop"))
	Hud.AddMenuButton("Aliens", Theme.Colors.Featured, menu("Aliens"))
	Hud.AddMenuButton("Codex", Theme.Colors.Codex, menu("Codex"))
	Hud.AddMenuButton("Ship", Theme.Colors.Select, menu("Ship"))
	Hud.AddMenuButton("Quests", Theme.Colors.Heading, menu("Quests"))
	Hud.AddMenuButton("Gifts", Theme.Colors.Close, menu("Gifts"))
	-- A gift egg hatches through the same reveal as a wild catch.
	GiftsScreen.OnGrant(function(grant: Types.GrantResult)
		local def = Species.ById[grant.species]
		WildRenderer.MarkKnown(grant.species)
		State.ApplyCatch(grant.species, grant.overlay)
		Screens.CloseAll()
		Reveal.Show({
			speciesName = if def then def.name else grant.species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(grant.tier),
			tier = grant.tier,
			overlay = grant.overlay,
			isNew = grant.isNew,
			scrapGained = grant.scrapGained,
			perfect = false,
		})
	end)
	-- Unclaimed gifts show as a badge on the menu.
	local function refreshGiftBadge()
		local gifts = State.GetGifts()
		local waiting = 0
		for day = 1, math.min(gifts.daysPlayed, 7) do
			if not gifts.claimed[tostring(day)] then
				waiting += 1
			end
		end
		Hud.SetBadge("Gifts", waiting)
	end
	State.OnChanged("gifts", refreshGiftBadge)

	-- Meteor Shower: countdown chip before, event banner with the luck chip during, toasts at the edges.
	local showerWasActive = false
	local function refreshShower()
		local shower, elapsed = State.GetShower()
		if shower.active then
			local left = math.ceil(math.max(0, shower.secondsLeft - elapsed)) -- whole seconds: %d refuses a fraction
			local minutes, seconds = left // 60, left % 60
			local timeText = if minutes > 0 then Strings.TIME_MS:format(minutes, seconds) else Strings.TIME_S:format(seconds)
			Hud.SetEventBanner(Strings.SHOWER_NOW, Strings.SHOWER_LEFT:format(timeText), Strings.SHOWER_LUCK:format(("%.1f"):format(State.GetLuck())))
			Hud.SetShowerCountdown(nil)
			if not showerWasActive then
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds)
			end
			showerWasActive = true
			return
		end
		Hud.SetEventBanner(nil, nil, nil)
		if showerWasActive then
			Toast.Show(Strings.SHOWER_OVER, Theme.Colors.Codex)
		end
		showerWasActive = false
		local nextIn = math.max(0, shower.nextInSeconds - elapsed)
		if shower.nextInSeconds > 0 and nextIn <= Config.ShowerWarnSeconds then
			Hud.SetShowerCountdown(nextIn)
		else
			Hud.SetShowerCountdown(nil)
		end
	end
	State.OnChanged("shower", refreshShower)
	State.OnChanged("luck", refreshShower)
	-- A late joiner missed the last ShowerChanged push; the answer seeds State unless a push beat it.
	task.spawn(function()
		local raw = Net.func("GetShower"):InvokeServer()
		local state = raw :: Types.ShowerState?
		if state then
			State.SeedShower(state)
		end
	end)
	LandmarkRenderer.Start()
	TutorialHint.Start()

	-- Field Notes: a badge and a toast when the current step's objectives are all met; cleared on claim.
	local function currentStepComplete(): (boolean, string?)
		local profile = State.Get()
		local chain = Quests.FieldNotes[profile.world.current]
		if not chain then
			return false, nil
		end
		local index = profile.quests.fieldNotes[tostring(profile.world.current)] or 1
		local step = chain[index]
		if not step then
			return false, nil
		end
		for _, objective in ipairs(step.objectives) do
			if (profile.quests.progress[objective.id] or 0) < objective.count then
				return false, step.id
			end
		end
		return true, step.id
	end
	local announcedStep: string? = nil
	State.OnChanged("quests", function()
		local complete, stepId = currentStepComplete()
		Hud.SetBadge("Quests", if complete then 1 else 0)
		if complete and stepId and announcedStep ~= stepId then
			announcedStep = stepId
			Toast.Show(Strings.TOAST_QUEST_STEP_DONE:format(Builder.text("FN_" .. stepId .. "_TITLE")), Theme.Colors.Featured)
		elseif not complete then
			announcedStep = nil
		end
	end)
	NearbyPanel.Start()

	local known: { [string]: boolean } = {}
	for species, entry in pairs(profile.codex) do
		if entry.count > 0 then
			known[species] = true
		end
	end
	WildRenderer.Start(known)
	CampRenderer.Start()
	NodeRenderer.Start()

	State.OnChanged("scrap", function()
		Hud.SetScrap(State.Get().scrap)
	end)
	State.OnChanged("rate", function()
		Hud.SetRate(State.GetRate().ratePerSecond)
		refreshShip()
	end)
	State.OnChanged("modules", refreshShip)

	-- The world's special weather gets a banner naming its signature alien when it starts.
	local lastWeather: string? = nil
	local function onClock(state: Types.ClockState)
		Hud.SetClock(state)
		State.SetClock(state)
		local world = Worlds[State.Get().world.current]
		if world and state.weather == world.weather.special.id and lastWeather ~= nil and lastWeather ~= state.weather then
			local def = Species.ById[world.weather.special.speciesId]
			local text = Strings.WEATHER_SPECIAL_BANNER:format(Builder.text("WEATHER_" .. state.weather), if def then def.name else world.weather.special.speciesId)
			Toast.Banner(text, if def then Builder.tierColor(def.tier) else Theme.Colors.Select, Config.AnnounceSeconds)
		end
		lastWeather = state.weather
	end
	Net.event("ClockChanged").OnClientEvent:Connect(onClock)
	task.spawn(function()
		local state = Net.func("GetClock"):InvokeServer() :: Types.ClockState?
		if state then
			onClock(state)
		end
	end)
	connectToasts()

	-- Contextual button and ship bar polls.
	local actionAccumulator = 0
	local shipAccumulator = 0
	local biomeAccumulator = 0
	local showerAccumulator = 0
	RunService.Heartbeat:Connect(function(dt: number)
		actionAccumulator += dt
		shipAccumulator += dt
		biomeAccumulator += dt
		showerAccumulator += dt
		if showerAccumulator >= SHOWER_POLL_SECONDS then
			showerAccumulator = 0
			refreshShower()
		end
		if shipAccumulator >= SHIP_POLL_SECONDS then
			shipAccumulator = 0
			refreshShip()
		end
		if biomeAccumulator >= BIOME_POLL_SECONDS then
			biomeAccumulator = 0
			refreshBiome()
		end
		if actionAccumulator < ACTION_POLL_SECONDS then
			return
		end
		actionAccumulator = 0
		local action: Action? = decideAction() -- annotated: the checker widens singleton unions otherwise
		currentAction = action
		Hud.SetAction(if action then ACTION_TEXT[action] else nil)
		Hud.SetMenuVisible(not inCapture and not Reveal.IsOpen())
		PowerUpBar.SetVisible(not inCapture and not Reveal.IsOpen()) -- it shares the lower third with the capture bar
		TutorialHint.SetVisible(not inCapture and not Reveal.IsOpen() and not Screens.IsAnyOpen())
		Toast.SetTop(if Screens.IsAnyOpen() then TOAST_TOP_WITH_PANEL elseif State.GetShower().active then TOAST_TOP_WITH_BANNER else nil)
	end)

	-- Space / gamepad A start a catch on the nearest alien (the CaptureBar rebinds these while open).
	-- Sunk only when a catch starts, so Space still jumps when nothing is in reach.
	ContextActionService:BindAction("StartCapture", function(_name: string, state: Enum.UserInputState, _input: InputObject)
		if state == Enum.UserInputState.Begin and not modalOpen() then
			if tryCatchNearest() then
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	-- Tapping or clicking an alien itself also starts a catch when it is in reach.
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or modalOpen() then
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
	-- Real saves can take seconds (or a retry while another server releases the lock), so keep asking.
	while not started do
		local profile = Net.func("GetProfile"):InvokeServer() :: Types.Profile?
		if profile then
			start(profile)
			return
		end
		task.wait(PROFILE_PULL_SECONDS)
	end
end)

print(("[%s] client started"):format(Config.WorkingTitle))
