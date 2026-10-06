--!strict
-- StarterPlayerScripts.Client: the client bootstrap. Waits for the profile, mirrors it in State, builds
-- the HUD, starts the world renderers (wild aliens, the player's own camp, material nodes) and runs
-- the capture flow: nearest alien -> CaptureStart -> CaptureBar taps -> CaptureHit results -> Reveal.
-- The contextual button shows one verb at a time: Catch!, Collect, Build or Launch. The client only
-- draws and reports tap times and ids; every outcome is the server's.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService = game:GetService("TextChatService")
local SocialService = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Economy = require(Shared:WaitForChild("Economy"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Place = require(Shared:WaitForChild("Place"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local HomeBuild = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local HomeData = require(Shared:WaitForChild("data"):WaitForChild("Home"))
local VisitingData = require(Shared:WaitForChild("data"):WaitForChild("Visiting"))
local CatchRush = require(Shared:WaitForChild("data"):WaitForChild("CatchRush"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local GrowthData = require(Shared:WaitForChild("data"):WaitForChild("Growth"))
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
local BuildScreen = require(script:WaitForChild("UI"):WaitForChild("BuildScreen"))
local MailScreen = require(script:WaitForChild("UI"):WaitForChild("MailScreen"))
local VisitScreen = require(script:WaitForChild("UI"):WaitForChild("VisitScreen"))
local NearbyPanel = require(script:WaitForChild("UI"):WaitForChild("NearbyPanel"))
local WildRenderer = require(script:WaitForChild("World"):WaitForChild("WildRenderer"))
local CampRenderer = require(script:WaitForChild("World"):WaitForChild("CampRenderer"))
local HomeRenderer = require(script:WaitForChild("World"):WaitForChild("HomeRenderer"))
local HangarRenderer = require(script:WaitForChild("World"):WaitForChild("HangarRenderer"))
local CompanionRenderer = require(script:WaitForChild("World"):WaitForChild("CompanionRenderer"))
local SightingRenderer = require(script:WaitForChild("World"):WaitForChild("SightingRenderer"))
local NodeRenderer = require(script:WaitForChild("World"):WaitForChild("NodeRenderer"))
local PeddlerRenderer = require(script:WaitForChild("World"):WaitForChild("PeddlerRenderer"))
local PeddlerScreen = require(script:WaitForChild("UI"):WaitForChild("PeddlerScreen"))
local PowerUpBar = require(script:WaitForChild("UI"):WaitForChild("PowerUpBar"))
local QuestsScreen = require(script:WaitForChild("UI"):WaitForChild("QuestsScreen"))
local TutorialHint = require(script:WaitForChild("UI"):WaitForChild("TutorialHint"))
local GiftsScreen = require(script:WaitForChild("UI"):WaitForChild("GiftsScreen"))
local NotifyCard = require(script:WaitForChild("UI"):WaitForChild("NotifyCard"))
local Radar = require(script:WaitForChild("UI"):WaitForChild("Radar"))
local Compass = require(script:WaitForChild("UI"):WaitForChild("Compass"))
local Waypoint = require(script:WaitForChild("World"):WaitForChild("Waypoint"))
local TutorialData = require(Shared:WaitForChild("data"):WaitForChild("Tutorial"))
local RadarData = require(Shared:WaitForChild("data"):WaitForChild("Radar"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Vfx = require(script:WaitForChild("World"):WaitForChild("Vfx"))
local Ambience = require(script:WaitForChild("World"):WaitForChild("Ambience"))
local LightingDirector = require(script:WaitForChild("World"):WaitForChild("LightingDirector"))
local WeatherFx = require(script:WaitForChild("World"):WaitForChild("WeatherFx"))
local CameraDirector = require(script:WaitForChild("World"):WaitForChild("CameraDirector"))
local LaunchSequence = require(script:WaitForChild("World"):WaitForChild("LaunchSequence"))
local Prefs = require(script:WaitForChild("Prefs"))
local SettingsScreen = require(script:WaitForChild("UI"):WaitForChild("SettingsScreen"))
local StarChartScreen = require(script:WaitForChild("UI"):WaitForChild("StarChartScreen"))
local LeaderboardScreen = require(script:WaitForChild("UI"):WaitForChild("LeaderboardScreen"))
local LandmarkRenderer = require(script:WaitForChild("World"):WaitForChild("LandmarkRenderer"))
local Quests = require(Shared:WaitForChild("data"):WaitForChild("Quests"))
local Social = require(Shared:WaitForChild("data"):WaitForChild("Social"))
local Weekly = require(Shared:WaitForChild("data"):WaitForChild("Weekly"))
local WeeklyMath = require(Shared:WaitForChild("WeeklyMath"))

local ACTION_POLL_SECONDS = 0.1 -- how often the contextual button re-decides its verb
local TOAST_TOP_WITH_PANEL = 0.03 -- with a panel open, toasts sit over the dimmed HUD row instead of the panel's header
local TOAST_TOP_WITH_BANNER = 0.29 -- with or without the event banner the centre column ends at the Friend Boost chip (0.281), so toasts start under it (Studio 2026-10-06: a shower toast covered the chip at 0.235)
local SHIP_POLL_SECONDS = 0.5 -- how often the ship bar extrapolates assembly progress
local PROFILE_PULL_SECONDS = 1 -- retry interval while the server is still loading the profile
local BIOME_POLL_SECONDS = 0.5 -- how often the biome chip re-reads the player's position
local SHOWER_POLL_SECONDS = 1 -- the shower chip and banner count down between server pushes
local SECONDS_PER_HOUR = 3600 -- unit conversions for the weekly banner's "Nd Nh" time left
local SECONDS_PER_DAY = 86400

local localPlayer = Players.LocalPlayer
local started = false
local inCapture = false
local captureToken: string? = nil
local collecting = false
local radarTarget: Part? = nil -- the wild part a tapped radar blip marked with the waypoint
local capturePart: Part? = nil -- the wild part the current catch is for
local capturePosition: Vector3? = nil -- where it stood when the catch began: the server removes the part before the result lands, so the burst plays here
local cinematic = false -- the crash-landing opener is running: the HUD, hint and radar stay hidden
local radarTier = 0 -- the radar tier the server says the player holds (gear.radar), mirrored for the Nearby column
local RADAR_MK2_TIER: number = (RadarData :: any).Mk2.Tier -- data/Radar: the tier from which the Nearby column lists what is not out now

-- The Nearby column shows without a radar (the free list) and from Radar Mk2 up (the compact "not now" list
-- under the disc, only while the disc itself shows); Mk1 has the disc alone. Never during a cinematic.
local function nearbyShows(): boolean
	if cinematic then
		return false
	end
	if radarTier < 1 then
		return true
	end
	return radarTier >= RADAR_MK2_TIER and Radar.IsShown()
end

type Action = "Catch" | "Collect" | "Build" | "Launch" | "Trade" | "Horn" | "Heater" | "Decorate" | "Spin" | "Mail" | "Wave"
local currentAction: Action? = nil
local ACTION_TEXT: { [string]: string } = {
	Catch = Strings.ACTION_CATCH,
	Collect = Strings.ACTION_COLLECT,
	Build = Strings.ACTION_BUILD,
	Launch = Strings.ACTION_LAUNCH,
	Trade = Strings.ACTION_TRADE,
	Horn = Strings.ACTION_HORN,
	Heater = Strings.ACTION_HEATER,
	Decorate = Strings.ACTION_DECORATE,
	Spin = Strings.ACTION_SPIN,
	Mail = Strings.ACTION_MAIL,
	Wave = Strings.ACTION_WAVE,
}
local soundHorn = Net.func("SoundHorn")
local horning = false
local placeHeater = Net.func("PlaceHeater")
local placingHeater = false -- one PlaceHeater request in flight at a time
local BLIZZARD = "Blizzard" -- the Frostbyte world's rule and the special weather it names

local captureStart = Net.func("CaptureStart")
local captureHit = Net.func("CaptureHit")
local captureCancel = Net.event("CaptureCancel")
local collectMaterial = Net.func("CollectMaterial")

-- The Heater rule is live: the player's world runs the Blizzard rule and the blizzard is on right now
-- (State.GetConditions mirrors the server clock).
local function blizzardActive(): boolean
	if not State.Has() then
		return false
	end
	local world = Worlds[State.Get().world.current]
	if not world or world.rule ~= BLIZZARD then
		return false
	end
	for _, condition in ipairs(State.GetConditions()) do
		if condition == BLIZZARD then
			return true
		end
	end
	return false
end

-- A catch in progress or a modal screen blocks every other action.
local function modalOpen(): boolean
	return inCapture or Reveal.IsOpen() or Screens.IsAnyOpen()
end

-- The tutorial is still running: this place is the tutorial's world and its last step is not behind
-- the player yet. The five-minute script holds the server-wide event banners while this is true.
local function tutorialActive(): boolean
	return Place.WorldId() == TutorialData.World and State.GetTutorial() <= #TutorialData.Steps
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
	local tierColor = Builder.tierColor(result.tier or "Common")
	local target = capturePart
	-- The Caught result carries no size field; the band is the one the server wrote on the spawn part
	-- (the same roll the catch Scrap used), read before the part is gone.
	local sizeAttribute = if target then target:GetAttribute("Size") else nil
	local sizeId = if type(sizeAttribute) == "string" then sizeAttribute else Sizes.Default
	local at = if target and target.Parent then target.Position else capturePosition
	if at then
		Vfx.CatchBurst(at, tierColor)
	end
	if (result.scrapGained or 0) > 0 then
		Hud.FlyGain(result.scrapGained or 0)
	end
	task.delay(0.6, function()
		finishCapture()
		Reveal.Show({
			speciesId = species,
			speciesName = if def then def.name else species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(result.tier or "Common"),
			tier = result.tier or "Common",
			overlay = result.overlay or "None",
			size = sizeId,
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
	capturePart = part
	capturePosition = part.Position
	CameraDirector.Cancel() -- a catch takes priority over any camera moment
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

-- The chip's words: the biome's name, or at home while visiting whose home it is (milestone 42e). Called when the
-- biome changes and when the view does; with no biome read yet and no view it leaves the chip as it is.
local function applyBiomeChip()
	local view = State.GetHomeView()
	local biome = currentBiome
	if view ~= nil and Place.IsHome() then
		Hud.SetBiomeLabel(Strings.HUD_VISITING_CHIP:format(view.ownerName))
	elseif biome ~= nil then
		Hud.SetBiome(biome)
	end
end

local function refreshBiome()
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local biome: Types.Biome = Biomes.At(root.Position) -- annotated: the checker widens singleton unions
	if biome ~= currentBiome then
		currentBiome = biome
		applyBiomeChip()
		State.SetBiome(biome)
	end
end

local function shipComplete(): boolean
	local profile = State.Get()
	return Economy.activeModuleIndex(profile, profile.world.current) == nil
end

-- Contextual action ---------------------------------------------------------

-- Flat (X and Z) studs from the local character to one of the home world builder's placeholder parts under
-- Workspace.World (the Kiosk, the Mailbox); math.huge while the part or the character is missing.
local function homePartDistance(name: string): number
	local world = Workspace:FindFirstChild("World")
	local part = if world then world:FindFirstChild(name) else nil
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not part or not part:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return math.huge
	end
	local dx, dz = root.Position.X - part.Position.X, root.Position.Z - part.Position.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Where the local character's root is, or nil while it has none.
local function localRootPosition(): Vector3?
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

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
		-- At home the ship has no modules (so it reads complete) and the server refuses a launch from there:
		-- it offers Build, which opens the Ship panel and its Star Chart button.
		best, bestDistance = if shipComplete() and not Place.IsHome() then "Launch" else "Build", shipDistance
	end
	local peddlerDistance = PeddlerRenderer.DistanceToShip()
	if peddlerDistance <= Config.PeddlerInteractDistance and peddlerDistance < bestDistance then
		best, bestDistance = "Trade", peddlerDistance
	end
	-- At home the plot offers Decorate (the Build tray) from within DecorateInteractDistance of its centre.
	if Place.IsHome() then
		-- A guest at someone else's home (milestone 42e) neither decorates their plot nor opens their mailbox:
		-- Decorate and Mail are the owner's, Spin (the player's own wheel) and Wave are the guest's.
		local visiting = State.IsVisiting()
		if not visiting then
			local plotDistance = HomeRenderer.PlotDistance()
			if plotDistance <= HomeBuild.DecorateInteractDistance and plotDistance < bestDistance then
				best, bestDistance = "Decorate", plotDistance
			end
		end
		-- The kiosk offers the spin wheel and the mailbox the letters (42d), each from its own interact distance.
		local kioskDistance = homePartDistance("Kiosk")
		if kioskDistance <= HomeData.KioskInteractDistance and kioskDistance < bestDistance then
			best, bestDistance = "Spin", kioskDistance
		end
		if not visiting then
			local mailboxDistance = homePartDistance("Mailbox")
			if mailboxDistance <= HomeData.MailboxInteractDistance and mailboxDistance < bestDistance then
				best, bestDistance = "Mail", mailboxDistance
			end
		else
			-- The displayed alien nearest the player waves back from within WaveInteractDistance.
			local at = localRootPosition()
			if at then
				local uid, waveDistance = HomeRenderer.NearestDisplayed(at)
				if uid ~= nil and waveDistance <= VisitingData.WaveInteractDistance and waveDistance < bestDistance then
					best, bestDistance = "Wave", waveDistance
				end
			end
		end
	end
	-- The horn is offered at the shrine whenever the player holds it; the server judges night and step.
	local shrineDistance = LandmarkRenderer.DistanceTo("Shrine")
	if shrineDistance <= Config.ShrineInteractDistance and shrineDistance < bestDistance and (State.Get().inventory.items[Quests.HornItem] or 0) > 0 then
		best = "Horn"
	end
	-- The Heater is the lowest priority: offered during a blizzard only when nothing else is in reach.
	if best == nil and blizzardActive() then
		best = "Heater"
	end
	return best
end

local launching = false -- one Launch request in flight at a time
local flying = false -- a Star Chart Fly's fade is under way
local waving = false -- one Wave request in flight at a time

-- Waves at the displayed alien nearest the player (milestone 42e). The target is read again here, not taken from
-- the poll, so a tap a moment after the alien wandered off waves at nothing instead of at the wrong one. The server
-- judges everything (who is visiting, what is on display, one wave per alien, the day's cap) and pays both sides.
local function tryWave()
	local view = State.GetHomeView()
	local at = localRootPosition()
	if waving or view == nil or at == nil then
		return
	end
	local uid, distance = HomeRenderer.NearestDisplayed(at)
	if uid == nil or distance > VisitingData.WaveInteractDistance then
		return
	end
	local target: string = uid
	local ownerName = view.ownerName
	local before = HomeRenderer.DisplayedPosition(target)
	waving = true
	task.spawn(function()
		local called, ok, reason, species, scrap = pcall(function(): (any, any, any, any)
			return Net.func("Wave"):InvokeServer(target)
		end)
		waving = false
		if not called then
			print(("[%s] Wave failed: %s"):format(Config.WorkingTitle, tostring(ok)))
			return
		end
		if ok == true then
			local speciesId = if type(species) == "string" then species else ""
			local def = Species.ById[speciesId]
			local paid = if type(scrap) == "number" then scrap else 0
			Builder.playSound(Sounds.GiftClaim)
			Toast.Show(Strings.TOAST_WAVE_SENT:format(ownerName, if def then def.name else speciesId, Builder.formatNumber(paid)), Theme.Colors.Confirm)
			local where = HomeRenderer.DisplayedPosition(target) or before
			if where then
				Vfx.CatchBurst(where, Theme.Colors.Featured)
			end
		elseif reason == "Again" then
			Toast.Show(Strings.TOAST_WAVE_AGAIN, Theme.Colors.Select)
		elseif reason == "Cap" then
			Toast.Show(Strings.TOAST_WAVE_CAP, Theme.Colors.Featured)
		elseif reason ~= "NotVisiting" and reason ~= "NotDisplayed" and reason ~= "RateLimited" then
			print(("[%s] Wave refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
		-- NotVisiting and NotDisplayed are silent: the next poll decides the verb again from what is drawn now.
	end)
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
		-- The server judges the ship, the world and the next place; an accepted launch comes back as the
		-- Launched event, which plays the sequence. One request in flight at a time.
		if launching or LaunchSequence.IsPlaying() then
			return
		end
		launching = true
		task.spawn(function()
			local ok, reason = Net.func("Launch"):InvokeServer()
			launching = false
			if ok == true then
				return -- Launched carries the sequence
			elseif reason == "NotComplete" then
				Toast.Show(Strings.TOAST_LAUNCH_NOT_READY, Theme.Colors.Select)
			elseif reason == "NoNextWorld" then
				Toast.Show(Strings.TOAST_LAUNCH_LAST_WORLD, Theme.Colors.Featured)
			elseif reason == "WrongWorld" then
				Toast.Show(Strings.TOAST_LAUNCH_WRONG_WORLD, Theme.Colors.Close)
			elseif reason == "Busy" then
				return -- a launch is already under way
			else
				print(("[%s] launch refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			end
		end)
	elseif action == "Trade" then
		Screens.Open("Peddler")
	elseif action == "Decorate" then
		Screens.Open("Build")
	elseif action == "Spin" then
		Screens.Open("Gifts") -- the wheel is the Gifts screen's middle column; there is no tab to pick
	elseif action == "Mail" then
		Screens.Open("Mail")
	elseif action == "Wave" then
		tryWave()
	elseif action == "Horn" and not horning then
		horning = true
		task.spawn(function()
			local ok, reason = soundHorn:InvokeServer()
			horning = false
			if ok == true then
				Builder.playSound(Sounds.HornCall)
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
	elseif action == "Heater" and not placingHeater then
		placingHeater = true
		task.spawn(function()
			local ok, reason = placeHeater:InvokeServer()
			placingHeater = false
			if ok == true then
				Toast.Show(Strings.TOAST_HEATER_PLACED:format(Config.HeaterSeconds), Theme.Colors.Featured)
			elseif reason == "NotEnoughScrap" then
				Toast.Show(Strings.TOAST_HEATER_NOT_ENOUGH:format(Builder.formatNumber(Config.HeaterScrap)), Theme.Colors.Close)
			elseif reason == "Limit" then
				Toast.Show(Strings.TOAST_HEATER_LIMIT, Theme.Colors.Select)
			elseif reason == "NoBlizzard" then
				Toast.Show(Strings.TOAST_HEATER_NO_BLIZZARD, Theme.Colors.Select)
			else
				print(("[%s] heater refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			end
		end)
	end
end

-- Server pushes that only need a toast ----------------------------------------
-- Each wait runs in its own thread so a remote the server has not created yet never blocks the boot.

local friendBoostSeen = false -- the first FriendBoostChanged after joining is only the starting state
local invitePending = false

-- The Friend Boost chip's tap: the native invite sheet when the platform allows it, otherwise a toast
-- (the Gifts screen's invite button does the same).
local function onFriendChipTap()
	if invitePending then
		return
	end
	invitePending = true
	task.spawn(function()
		local askedOk, canInvite = pcall(function()
			return SocialService:CanSendGameInviteAsync(localPlayer)
		end)
		local prompted = false
		if askedOk and canInvite == true then
			prompted = pcall(function()
				SocialService:PromptGameInvite(localPlayer)
			end)
		end
		if not prompted then
			Toast.Show(Strings.TOAST_INVITE_UNAVAILABLE, Theme.Rarity.Common)
		end
		invitePending = false
	end)
end

-- The display name of an owned alien from the profile mirror (its species name, or the species id when the
-- species has no def); nil when the mirror does not hold it, so a toast never names nothing.
local function alienName(uid: string): string?
	if not State.Has() then
		return nil
	end
	local record = State.Get().aliens[uid]
	if not record then
		return nil
	end
	local def = Species.ById[record.species]
	return if def then def.name else record.species
end

local function connectToasts()
	-- Friends joined or left this server: the server sends the count and the boost (a fraction), and the
	-- arriving friend's name when one just joined.
	task.spawn(function()
		Net.event("FriendBoostChanged").OnClientEvent:Connect(function(count: number, boost: number, arrivedName: string?)
			State.SetFriends(count, boost)
			Hud.SetFriendBoost(count, boost)
			local percent = math.floor(boost * 100 + 0.5)
			local first = not friendBoostSeen
			friendBoostSeen = true
			if arrivedName then
				Toast.Show(Strings.TOAST_FRIEND_JOINED:format(arrivedName, percent), Theme.Colors.Confirm)
			elseif not (first and count == 0) then
				Toast.Show(Strings.TOAST_FRIEND_LEFT:format(percent), Theme.Colors.Select)
			end
		end)
	end)
	task.spawn(function()
		Net.event("MaterialCollected").OnClientEvent:Connect(function(material: string, count: number)
			Toast.Show(Strings.TOAST_MATERIAL:format(count, Builder.text("MATERIAL_" .. material)), Theme.Colors.Featured, material)
		end)
	end)
	task.spawn(function()
		Net.event("ModuleCompleted").OnClientEvent:Connect(function(worldId: number, moduleId: string)
			Builder.playSound(Sounds.ModuleComplete)
			Vfx.ModuleBurst(CampRenderer.ShipPosition(), Theme.Colors.Confirm)
			if not modalOpen() and not cinematic then
				CameraDirector.PanTo(CampRenderer.ShipPosition())
			end
			Toast.Show(Strings.TOAST_MODULE_DONE:format(Builder.text("MODULE_" .. moduleId)), Theme.Colors.Confirm)
			local def = Economy.moduleDef(worldId, moduleId)
			if def and def.unlocksSlots then
				Toast.Show(Strings.TOAST_SLOT_UNLOCKED:format(def.unlocksSlots), Theme.Colors.Featured)
			end
		end)
	end)
	-- The server accepted a launch: the lift-off plays with the HUD hidden, like the crash opener. With
	-- a live place the server teleports the player before the sequence ends; otherwise the camp returns.
	task.spawn(function()
		Net.event("Launched").OnClientEvent:Connect(function(nextWorldId: number, placeLive: boolean)
			if LaunchSequence.IsPlaying() then
				return
			end
			cinematic = true
			Hud.SetVisible(false)
			LaunchSequence.Play(nextWorldId, placeLive, function()
				cinematic = false
				Hud.SetVisible(true)
			end)
		end)
	end)
	-- The first launch opened the home planet (the server fires this once, right after Launched and the
	-- mirror pushes): the toast waits for the lift-off (and its own toast) to finish. IsPlaying always ends,
	-- by onDone or by the sequence's safety net.
	task.spawn(function()
		Net.event("HomeUnlocked").OnClientEvent:Connect(function()
			task.spawn(function()
				while LaunchSequence.IsPlaying() do
					task.wait(Config.BannerDeferSeconds)
				end
				Toast.Show(Strings.TOAST_HOME_UNLOCKED, Theme.Colors.Featured)
			end)
		end)
	end)
	-- Habitats (milestone 42c): the Scrap the displayed aliens earned while the player was away is paid when they
	-- arrive home, and the server says how much. A settle while the player is in comes as the HabitatIncome event; the
	-- one that ran while the profile loaded fired before this listener existed, so once the profile is in, one
	-- ClaimHabitatIncome call asks for it (0 when there was none; the server clears it once answered).
	task.spawn(function()
		local function toastIncome(paid: any)
			if type(paid) == "number" and paid > 0 then
				Toast.Show(Strings.TOAST_HABITAT_INCOME:format(Builder.formatNumber(paid)), Theme.Colors.Confirm)
			end
		end
		Net.event("HabitatIncome").OnClientEvent:Connect(toastIncome)
		while not State.Has() do
			task.wait(ACTION_POLL_SECONDS)
		end
		local called, paid = pcall(function(): any
			return Net.func("ClaimHabitatIncome"):InvokeServer()
		end)
		if called then
			toastIncome(paid)
		end
	end)
	-- A letter arrived from the developer panel (milestone 42d): every client is told once, wherever it is; the
	-- letters themselves come by MailChanged into the mirror.
	task.spawn(function()
		Net.event("MailArrived").OnClientEvent:Connect(function()
			Toast.Show(Strings.TOAST_MAIL_NEW, Theme.Colors.Featured)
		end)
	end)
	-- Visiting (milestone 42e), the owner's side: someone started viewing this home, or waved at one of its displayed
	-- aliens. The Visitor Book is not pushed, so a visitor's arrival also asks the server for it again (the Mail screen
	-- reads the mirror).
	task.spawn(function()
		Net.event("VisitorArrived").OnClientEvent:Connect(function(name: string)
			Toast.Show(Strings.TOAST_VISITOR_ARRIVED:format(tostring(name)), Theme.Colors.Select)
			State.RefreshVisitors()
		end)
	end)
	task.spawn(function()
		Net.event("WaveReceived").OnClientEvent:Connect(function(name: string, species: string, scrap: number)
			local def = Species.ById[species]
			Toast.Show(Strings.TOAST_WAVE_GOT:format(tostring(name), if def then def.name else tostring(species), Builder.formatNumber(scrap)), Theme.Colors.Featured)
		end)
	end)
	-- The outposts table the server holds (a collect, an upgrade, a launch that opens one) replaces the mirror's.
	task.spawn(function()
		Net.event("OutpostsChanged").OnClientEvent:Connect(function(outposts: { [string]: Types.OutpostState })
			State.SetOutposts(outposts)
		end)
	end)
	-- The server accepted a Fly from the Star Chart: the screens close, the banner names the world and the
	-- screen fades to black over Config.FlyTeleportDelaySeconds. With a live place the server teleports
	-- then; without one the fade lifts again, the mirror already moved to the new world by the WorldChanged
	-- and ModulesChanged pushes, exactly as after a non-live Launch.
	task.spawn(function()
		Net.event("Flew").OnClientEvent:Connect(function(worldId: number, placeLive: boolean)
			if flying or LaunchSequence.IsPlaying() then
				return
			end
			flying = true
			cinematic = true
			Hud.SetVisible(false)
			Screens.CloseAll()
			local worldKey = "WORLD_" .. tostring(worldId)
			local worldDef = Worlds[worldId]
			local name = if Builder.text(worldKey) ~= worldKey then Builder.text(worldKey) elseif worldDef then worldDef.name else worldKey
			Toast.Banner(Strings.FLY_LINE:format(name), Theme.Colors.Select, Config.FlyTeleportDelaySeconds)
			local function lift(afterwards: (() -> ())?)
				LaunchSequence.Fade(Config.FlyTeleportDelaySeconds, false, function()
					flying = false
					cinematic = false
					Hud.SetVisible(true)
					if afterwards then
						afterwards()
					end
				end)
			end
			LaunchSequence.Fade(Config.FlyTeleportDelaySeconds, true, function()
				if placeLive then
					-- The teleport takes over from here; should it never come, lift the fade rather than leave
					-- the player in the dark.
					task.delay(Config.TeleportGraceSeconds, function()
						if flying then
							lift(nil)
						end
					end)
				else
					lift(function()
						Toast.Show(Strings.TOAST_FLY_NOT_LIVE:format(name), Theme.Colors.Featured)
					end)
				end
			end)
		end)
	end)
	-- Server-wide banners: a rare find in the tier's colour, or the Catch Rush winner in the Featured gold.
	task.spawn(function()
		Net.event("Announcement").OnClientEvent:Connect(function(note: Types.Announcement)
			local text: string
			local color: Color3
			if note.kind == "rush" then
				text = Strings.ANNOUNCE_RUSH:format(note.playerName, note.catches or 0)
				color = Theme.Colors.Featured
			elseif note.kind == "notice" then
				-- A line from the team (the developer panel), shown as typed in the Codex purple.
				text = Strings.ANNOUNCE_NOTICE:format(note.text or "")
				color = Theme.Colors.Codex
			else
				local def = Species.ById[note.species]
				local speciesName = if def then def.name else note.species
				text = if note.overlay ~= "None"
					then Strings.ANNOUNCE_CATCH_OVERLAY:format(note.playerName, Builder.text("OVERLAY_A_" .. note.overlay), Builder.text("TIER_" .. note.tier), speciesName)
					else Strings.ANNOUNCE_CATCH:format(note.playerName, Builder.text("TIER_A_" .. note.tier), speciesName)
				color = Builder.tierColor(note.tier)
			end
			-- The Reveal owns the screen while it is up (its NEW ribbon sits where the banner lands): wait for it.
			task.spawn(function()
				local waited = 0
				while Reveal.IsOpen() and waited < Config.AnnounceSeconds do
					task.wait(Config.BannerDeferSeconds)
					waited += Config.BannerDeferSeconds
				end
				Toast.Banner(text, color, Config.AnnounceSeconds)
			end)
		end)
	end)
	-- The player's own Catch Rush result: placed and paid (rank 1 to TopCount), paid for taking part (past
	-- it) or nothing to show (rank 0, which the tutorial hold also keeps quiet).
	task.spawn(function()
		Net.event("CatchRushResult").OnClientEvent:Connect(function(result: Types.CatchRushResult)
			local rewardText = GiftsScreen.RewardText(result.rewards)
			if result.rank >= 1 and result.rank <= CatchRush.TopCount then
				local text = if result.catches == 1
					then Strings.RUSH_RESULT_ONE:format(result.rank, rewardText)
					else Strings.RUSH_RESULT:format(result.rank, result.catches, rewardText)
				Toast.Show(text, Theme.Colors.Featured)
			elseif result.rank > CatchRush.TopCount then
				local text = if result.catches == 1
					then Strings.RUSH_PART_ONE:format(rewardText)
					else Strings.RUSH_PART:format(result.catches, rewardText)
				Toast.Show(text, Theme.Colors.Featured)
			elseif not (TutorialData.Script.HoldEventBannersWhileActive and tutorialActive()) then
				Toast.Show(Strings.RUSH_NONE, Theme.Colors.Select)
			end
		end)
	end)
	task.spawn(function()
		-- An alien granted outside a catch (the Starter Pack's Rare) gets the same reveal as a catch.
		Net.event("AlienGranted").OnClientEvent:Connect(function(grant: Types.GrantResult)
			local def = Species.ById[grant.species]
			WildRenderer.MarkKnown(grant.species)
			State.ApplyCatch(grant.species, grant.overlay)
			Screens.CloseAll()
			Reveal.Show({
				speciesId = grant.species,
				speciesName = if def then def.name else grant.species,
				shape = if def then def.placeholder.shape else "Ball",
				color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(grant.tier),
				tier = grant.tier,
				overlay = grant.overlay,
				size = grant.size,
				isNew = grant.isNew,
				scrapGained = grant.scrapGained,
				perfect = false,
			})
		end)
	end)
	task.spawn(function()
		Net.event("WardenSummoned").OnClientEvent:Connect(function()
			Builder.playSound(Sounds.WardenAppear)
			Toast.Banner(Strings.TOAST_WARDEN_AWAKE, Builder.tierColor("Legendary"), Config.AnnounceSeconds)
		end)
	end)
	task.spawn(function()
		Net.event("WardenRetreated").OnClientEvent:Connect(function()
			Toast.Show(Strings.TOAST_WARDEN_RETREAT, Builder.tierColor("Legendary"))
		end)
	end)
	-- The Warden's sighting: a banner when it starts to cross the land and a toast when it has wandered off (the
	-- renderer draws it either way; the tutorial hold keeps both quiet). `sightingActive` is nil only while the
	-- one GetSighting call for a late joiner is in flight: a push that lands first seeds it without a banner, and
	-- an answer or a failure seeds it otherwise, so a sighting already running at join time never banners.
	task.spawn(function()
		local sightingActive: boolean? = nil
		local sightingSpecies = "" -- the last Warden species seen running, for the "wandered off" toast
		local function sightingName(species: string): string
			local def = Species.ById[species]
			return if def then def.name else species
		end
		Net.event("SightingChanged").OnClientEvent:Connect(function(state: Types.SightingState)
			local was = sightingActive
			sightingActive = state.active
			if state.active then
				sightingSpecies = state.species
			end
			if was == nil or was == state.active then
				return
			end
			if TutorialData.Script.HoldEventBannersWhileActive and tutorialActive() then
				return
			end
			if state.active then
				local def = Species.ById[state.species]
				Builder.playSound(Sounds.WardenAppear)
				Toast.Banner(
					Strings.SIGHTING_BANNER:format(sightingName(state.species)),
					Builder.tierColor(if def then def.tier else "Common"),
					Config.AnnounceSeconds
				)
			else
				local species = if Species.ById[state.species] then state.species else sightingSpecies
				Toast.Show(Strings.SIGHTING_OVER:format(sightingName(species)), Theme.Rarity.Common)
			end
		end)
		local ok, answer = pcall(function()
			return Net.func("GetSighting"):InvokeServer()
		end)
		if sightingActive ~= nil then
			return
		end
		local seed = if ok and type(answer) == "table" then answer :: Types.SightingState else nil
		sightingActive = if seed then seed.active else false
		if seed and seed.active then
			sightingSpecies = seed.species
		end
	end)
	-- The group gift's state: the server pushes it whenever membership or the claim changes.
	task.spawn(function()
		Net.event("SocialChanged").OnClientEvent:Connect(function(snapshot: GiftsScreen.SocialSnapshot)
			GiftsScreen.SetSocial(snapshot)
		end)
	end)
	-- The daily and weekly quest sets: dealt, progressed, claimed and rerolled on the server, mirrored into State.
	task.spawn(function()
		Net.event("DailyQuestsChanged").OnClientEvent:Connect(function(snapshot: State.DailyQuestsSnapshot)
			State.SetDailyQuests(snapshot)
		end)
	end)
	-- The weekly board: the server pushes it when it refreshes; the Ranks screen draws it while open.
	task.spawn(function()
		Net.event("LeaderboardChanged").OnClientEvent:Connect(function(payload: LeaderboardScreen.Payload)
			LeaderboardScreen.SetPayload(payload)
		end)
	end)
	-- A referral paid out (the invitee on joining through a link, the inviter per friend): a toast naming the reward.
	task.spawn(function()
		Net.event("ReferralGranted").OnClientEvent:Connect(function(role: string)
			if role == "invitee" then
				Builder.playSound(Sounds.GiftClaim)
				Toast.Show(Strings.TOAST_REFERRAL_INVITEE:format(GiftsScreen.RewardText(Social.ReferralInvitee)), Theme.Colors.Featured)
			elseif role == "inviter" then
				Builder.playSound(Sounds.GiftClaim)
				Toast.Show(Strings.TOAST_REFERRAL_INVITER:format(GiftsScreen.RewardText(Social.ReferralInviter)), Theme.Colors.Featured)
			end
		end)
	end)
	-- The server says it is time to ask about notifications; the card waits for a clear screen (never over a
	-- catch, a reveal, a launch or fly sequence, the crash opener or an open panel).
	task.spawn(function()
		Net.event("NotifyAsk").OnClientEvent:Connect(function()
			NotifyCard.Show(function()
				return not inCapture and not Reveal.IsOpen() and not LaunchSequence.IsPlaying() and not flying and not cinematic and not Screens.IsAnyOpen()
			end)
		end)
	end)
	-- An alien crossed a growth stage while working: a toast naming it, and its camp worker pops at the new size.
	task.spawn(function()
		Net.event("AlienGrew").OnClientEvent:Connect(function(uid: string, stageId: string)
			if type(uid) ~= "string" or type(stageId) ~= "string" then
				return
			end
			local name = alienName(uid)
			if name then
				Toast.Show(Strings.TOAST_ALIEN_GREW:format(name, Builder.text("STAGE_" .. stageId)), Theme.Colors.Featured)
			end
			CampRenderer.Grew(uid)
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
		-- Aliens that grew while away: one line with the count, then the first few by name.
		local grown = summary.grown
		if grown and #grown > 0 then
			Toast.Show(Strings.OFFLINE_GREW:format(#grown), Theme.Colors.Featured)
			for index, entry in ipairs(grown) do
				if index > GrowthData.GrewToastMax then
					break
				end
				local name = if type(entry.uid) == "string" and type(entry.stage) == "string" then alienName(entry.uid) else nil
				if name then
					Toast.Show(Strings.TOAST_ALIEN_GREW:format(name, Builder.text("STAGE_" .. entry.stage)), Theme.Colors.Featured)
				end
			end
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
	Prefs.Start() -- applies volumes, motion and silhouette preferences before anything plays or renders

	-- The default chat window sits top-left over the Scrap pill and the menu stack; move it bottom-left.
	local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if chatWindow then
		chatWindow.HorizontalAlignment = Enum.HorizontalAlignment.Left
		chatWindow.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	Hud.Build()
	Hud.SetScrap(profile.scrap)
	Hud.SetShipTicks(Economy.milestones(profile.world.current))
	State.OnChanged("world", function()
		Hud.SetShipTicks(Economy.milestones(State.Get().world.current))
		refreshShip()
		Screens.CloseAll()
	end)
	-- Visiting (milestone 42e): State fires "visit" for every HomeView push and the boot pull. A view of a new owner
	-- welcomes the visitor and closes the screens (the Visit screen or Star Chart that asked); a cleared view that
	-- was set says the visitor is home again; a refresh of the same home is silent. The biome chip follows the view.
	local viewedOwner: number? = nil
	local function onVisit()
		local view = State.GetHomeView()
		local owner = if view then view.ownerId else nil
		if owner ~= viewedOwner then
			if view then
				Toast.Show(Strings.TOAST_VISIT_WELCOME:format(view.ownerName), Theme.Colors.Confirm)
			elseif viewedOwner ~= nil then
				Toast.Show(Strings.TOAST_VISIT_RETURN, Theme.Colors.Select)
			end
			Screens.CloseAll()
			viewedOwner = owner
		end
		applyBiomeChip()
	end
	State.OnChanged("visit", onVisit)
	onVisit() -- a view that landed before this listener (a teleported visitor's first pull) is welcomed too
	Hud.SetRate(State.GetRate().ratePerSecond)
	refreshShip()
	Hud.OnAction(performAction)
	Hud.OnFriendChipTapped(onFriendChipTap)
	Hud.OnShipTapped(function()
		if not inCapture and not Reveal.IsOpen() then
			Screens.Toggle("Ship")
		end
	end)

	-- Modal screens: one open at a time, each behind a left-edge menu button.
	Toast.SetPanelProbe(Screens.IsAnyOpen) -- banners drop to the bottom slot while a panel is open
	Screens.Register("Ship", ShipScreen)
	Screens.Register("Shop", ShopScreen)
	Screens.Register("Peddler", PeddlerScreen)
	Screens.Register("Quests", QuestsScreen)
	Screens.Register("Gifts", GiftsScreen)
	Screens.Register("Settings", SettingsScreen)
	Screens.Register("StarChart", StarChartScreen)
	Screens.Register("Ranks", LeaderboardScreen)
	Screens.Register("Build", BuildScreen)
	Screens.Register("Mail", MailScreen)
	Screens.Register("Visit", VisitScreen)
	-- An egg from the Peddler hatches through the same reveal as a wild catch.
	PeddlerScreen.OnGrant(function(grant: Types.GrantResult)
		local def = Species.ById[grant.species]
		WildRenderer.MarkKnown(grant.species)
		State.ApplyCatch(grant.species, grant.overlay)
		Screens.CloseAll()
		Reveal.Show({
			speciesId = grant.species,
			speciesName = if def then def.name else grant.species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(grant.tier),
			tier = grant.tier,
			overlay = grant.overlay,
			size = grant.size,
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
	Hud.AddTopButton("Settings", Theme.Colors.Select, menu("Settings"))
	-- Top buttons stack leftwards from the clock in the order added, so Settings (first) stays rightmost.
	Hud.AddTopButton("Ranks", Theme.Colors.Featured, menu("Ranks"))
	-- A gift egg hatches through the same reveal as a wild catch.
	GiftsScreen.OnGrant(function(grant: Types.GrantResult)
		local def = Species.ById[grant.species]
		WildRenderer.MarkKnown(grant.species)
		State.ApplyCatch(grant.species, grant.overlay)
		Screens.CloseAll()
		Reveal.Show({
			speciesId = grant.species,
			speciesName = if def then def.name else grant.species,
			shape = if def then def.placeholder.shape else "Ball",
			color = if def then Color3.fromHex(def.placeholder.color) else Builder.tierColor(grant.tier),
			tier = grant.tier,
			overlay = grant.overlay,
			size = grant.size,
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

	-- The five-minute script's payoff: when the step named by TutorialData.Script.GiftPopAfterStep falls
	-- behind the player and the day-1 gift is unclaimed, the Gifts screen opens by itself, once a session.
	-- It waits out the module-complete camera pan and any open panel, and gives up quietly after
	-- Script.GiftPopWaitSeconds: the menu badge still shows the gift.
	local giftPopStep: number? = nil
	for index, step in ipairs(TutorialData.Steps) do
		if step.id == TutorialData.Script.GiftPopAfterStep then
			giftPopStep = index
			break
		end
	end
	local giftPopSpawned = false
	local lastTutorialStep = State.GetTutorial() -- seeded now that the profile is live
	local function welcomeGiftWaiting(): boolean
		local gifts = State.GetGifts()
		return gifts.daysPlayed >= 1 and not gifts.claimed["1"]
	end
	State.OnChanged("tutorial", function()
		local step = State.GetTutorial()
		local previous = lastTutorialStep
		lastTutorialStep = step
		local popAfter = giftPopStep
		if giftPopSpawned or not popAfter or previous ~= popAfter or step <= popAfter or not welcomeGiftWaiting() then
			return
		end
		giftPopSpawned = true
		task.spawn(function()
			local poll = TutorialData.Script.GiftPopPollSeconds
			local deadline = os.clock() + TutorialData.Script.GiftPopWaitSeconds
			-- Poll first, then test: a ModuleCompleted that lands just after this push still gets to start its pan.
			repeat
				task.wait(poll)
				if not CameraDirector.IsBusy() and not modalOpen() and not cinematic then
					if welcomeGiftWaiting() then -- it may have been claimed from the menu meanwhile
						-- The screen is the message: a toast covered its header and a banner its bottom row.
						Screens.Open("Gifts")
					end
					return
				end
			until os.clock() >= deadline
		end)
	end)

	-- Event banner slot: the Meteor Shower first, then the Catch Rush, then a server luck someone bought.
	-- Meteor Shower: countdown chip before, event banner with the luck chip during, toasts at the edges; the
	-- Catch Rush: its own countdown chip (only when no shower's is due), banner with the score during, toasts
	-- at the edges. While the tutorial runs (data/Tutorial Script.HoldEventBannersWhileActive) the banner, the chip, the
	-- countdown and the horn wait; the shower itself (sky streaks, luck) is real and runs as ever. The
	-- Catch Rush is held the same way and, if a shower runs when it starts, waits for the slot too.
	local showerWasActive = false
	local showerBannerHeld = false -- a shower began under the hold, so its banner is still owed
	local rushWasActive = false
	local rushBannerHeld = false -- a rush began under the hold or a shower, so its banner is still owed
	-- "1m 5s" / "40s" for a banner's time left, in whole seconds: %d refuses a fraction.
	local function timeLeftText(seconds: number): string
		local left = math.ceil(math.max(0, seconds))
		local minutes = left // 60
		return if minutes > 0 then Strings.TIME_MS:format(minutes, left % 60) else Strings.TIME_S:format(left)
	end
	local function eventBannersHeld(): boolean
		return TutorialData.Script.HoldEventBannersWhileActive and tutorialActive()
	end
	-- The Alien of the Week at the server's clock and shift (nil when the rotation is empty), its display name, the
	-- "Nd Nh" time left and the weather chip's text (nil when the week keeps the usual weather).
	local function weeklyCurrent(): WeeklyMath.Current?
		return WeeklyMath.Current(workspace:GetServerTimeNow(), State.GetWeeklyOffset())
	end
	local function weeklyName(current: WeeklyMath.Current): string
		local def = Species.ById[current.drop.species]
		return if def then def.name else current.drop.species
	end
	local function weeklyLeftText(current: WeeklyMath.Current): string
		local left = math.max(0, math.floor(current.secondsLeft))
		return Strings.TIME_DH:format(left // SECONDS_PER_DAY, (left % SECONDS_PER_DAY) // SECONDS_PER_HOUR)
	end
	local function weeklyWeather(current: WeeklyMath.Current): string?
		local weather = current.drop.weather
		return if weather then Builder.text("WEATHER_" .. weather) else nil
	end
	local function refreshEventBanner()
		local shower, elapsed = State.GetShower()
		local rushState, rushElapsed = State.GetRush()
		local held = eventBannersHeld()
		-- The rush's edges first (a toast at the start and at the end); the banner slot below still goes to
		-- a running shower, which keeps priority when both are up.
		if rushState.active then
			if held or shower.active then
				if not rushWasActive then
					rushBannerHeld = true -- it began unseen; announced when the slot frees
				end
			else
				if not rushWasActive or rushBannerHeld then
					Toast.Banner(Strings.RUSH_NOW, Theme.Colors.Featured, Config.AnnounceSeconds)
				end
				rushBannerHeld = false
			end
			rushWasActive = true
		else
			-- No goodbye toast here: every player gets a CatchRushResult toast at the end (ranked, paid for taking
			-- part, or "catch one next time"), and two toasts at once read as a bug.
			rushWasActive = false
			rushBannerHeld = false
		end
		if shower.active then
			if held then
				if not showerWasActive then
					Vfx.SetShowerSky(true)
				end
				showerWasActive = true
				showerBannerHeld = true
				Hud.SetEventBanner(nil, nil, nil)
				Hud.SetEventCountdown(nil)
				return
			end
			Hud.SetEventBanner(Strings.SHOWER_NOW, Strings.SHOWER_LEFT:format(timeLeftText(shower.secondsLeft - elapsed)), Strings.SHOWER_LUCK:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)), "Shower")
			Hud.SetEventCountdown(nil)
			if not showerWasActive then
				Builder.playSound(Sounds.ShowerHorn)
				Vfx.SetShowerSky(true)
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds)
			elseif showerBannerHeld then
				-- The hold just lifted mid-shower: the banner it kept back shows now, without the horn.
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds)
			end
			showerBannerHeld = false
			showerWasActive = true
			return
		end
		if showerWasActive then
			Vfx.SetShowerSky(false)
			if not showerBannerHeld then -- a shower the player never saw announced needs no goodbye
				Toast.Show(Strings.SHOWER_OVER, Theme.Colors.Codex)
			end
		end
		showerWasActive = false
		showerBannerHeld = false
		if held then
			Hud.SetEventBanner(nil, nil, nil)
			Hud.SetEventCountdown(nil)
			return
		end
		-- No shower: a running Catch Rush takes the banner slot, else server luck someone bought.
		local luckState, luckElapsed = State.GetServerLuck()
		if rushState.active then
			local own = 0
			for _, row in ipairs(rushState.rows) do
				if row.userId == localPlayer.UserId then
					own = row.catches
				end
			end
			local top = if rushState.rows[1] then rushState.rows[1].catches else 0
			-- no icon for the rush yet: the banner shows its placeholder square
			Hud.SetEventBanner(Strings.RUSH_NOW, Strings.RUSH_LEFT:format(timeLeftText(rushState.secondsLeft - rushElapsed)), Strings.RUSH_SCORE:format(own, top), nil)
		elseif luckState and luckState.secondsLeft - luckElapsed > 0 then
			local timeText = timeLeftText(luckState.secondsLeft - luckElapsed)
			local multiplier = ("%d"):format(1 + luckState.bonus)
			-- no icon for server luck yet: the banner shows its placeholder square
			Hud.SetEventBanner(Strings.SERVERLUCK_BANNER:format(multiplier), Strings.SERVERLUCK_LEFT:format(timeText), Strings.SERVERLUCK_CHIP:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)))
		else
			-- Nothing else claims the slot: the Alien of the Week, for as long as data/Weekly BannerDays says.
			local current = weeklyCurrent()
			if current and current.secondsLeft <= Weekly.BannerDays * SECONDS_PER_DAY then
				local weather = weeklyWeather(current)
				-- The title is the fixed line (a name there clipped at phone width); the species goes under it, with its
				-- world named when the drop is on another world, so a player on World 1 knows where to fly.
				-- The subtitle keeps the species and the time (a world name there wrapped and clipped at phone width); when
				-- the drop is on another world the chip shows nothing (a world name in it wrapped and clipped too; the
				-- subtitle's species line already names the world) and the week's weather, which only that world has, stays off it.
				local dropWorld = Worlds[current.drop.worldId]
				local elsewhere = current.drop.worldId ~= Place.WorldId() and dropWorld ~= nil
				local subtitle = Strings.WEEKLY_LEFT:format(weeklyName(current), weeklyLeftText(current))
				local chip = if elsewhere then nil elseif weather then Strings.WEEKLY_CHIP:format(weather) else nil
				Hud.SetEventBanner(Strings.WEEKLY_BANNER, subtitle, chip, nil)
			else
				Hud.SetEventBanner(nil, nil, nil)
			end
		end
		-- The countdown chip: the shower's when one is due, else the rush's (never while the rush runs).
		local nextIn = math.max(0, shower.nextInSeconds - elapsed)
		local rushNextIn = math.max(0, rushState.nextInSeconds - rushElapsed)
		if shower.nextInSeconds > 0 and nextIn > 0 and nextIn <= Config.ShowerWarnSeconds then
			Hud.SetEventCountdown(nextIn)
		elseif not Place.IsHome() and not rushState.active and rushState.nextInSeconds > 0 and rushNextIn <= CatchRush.WarnSeconds then
			Hud.SetEventCountdown(rushNextIn, Strings.RUSH_CHIP) -- never at home, where no rush runs
		else
			Hud.SetEventCountdown(nil)
		end
	end
	State.OnChanged("shower", refreshEventBanner)
	State.OnChanged("rush", refreshEventBanner)
	State.OnChanged("luck", refreshEventBanner)
	State.OnChanged("tutorial", refreshEventBanner) -- the hold lifts the moment the last step completes
	State.OnChanged("clock", refreshEventBanner) -- the clock push keeps the weekly line's hours honest
	-- The Alien of the Week announces itself once per week (and per Studio shift): at join, once the server has
	-- said which week it is, then on every flip it pushes. The key keeps a repeat push from announcing twice, and
	-- the tutorial hold keeps it back until the last step (the "tutorial" topic retries it).
	local weeklyAnnounced: string? = nil
	local function announceWeekly()
		if not State.HasWeekly() or eventBannersHeld() then
			return
		end
		local current = weeklyCurrent()
		if not current then
			return
		end
		local key = current.weekId .. ":" .. current.drop.species
		if key == weeklyAnnounced then
			return
		end
		weeklyAnnounced = key
		local name = weeklyName(current)
		local weather = weeklyWeather(current)
		Toast.Banner(if weather then Strings.WEEKLY_NOW_WEATHER:format(name, weather) else Strings.WEEKLY_NOW:format(name), Theme.Colors.Codex, Config.AnnounceSeconds)
	end
	State.OnChanged("weekly", function()
		announceWeekly()
		refreshEventBanner()
	end)
	State.OnChanged("tutorial", announceWeekly)
	announceWeekly() -- the server's answer may already have landed
	-- A bought server luck announces itself once to everyone and then counts down in the banner slot.
	local serverLuckShown: string? = nil
	State.OnChanged("serverLuck", function()
		local luckState = State.GetServerLuck()
		if luckState then
			local key = luckState.playerName .. ":" .. tostring(luckState.bonus)
			if serverLuckShown ~= key then
				serverLuckShown = key
				local multiplierText = ("%d"):format(1 + luckState.bonus)
				-- A window from the developer panel carries the team's name (Strings.ADMIN_LUCK_NAME): its own line, since nobody bought it.
				local text = if luckState.playerName == Strings.ADMIN_LUCK_NAME
					then Strings.TOAST_SERVERLUCK_GIFT:format(multiplierText)
					else Strings.TOAST_SERVERLUCK_START:format(luckState.playerName, multiplierText)
				Toast.Banner(text, Theme.Colors.Featured, Config.AnnounceSeconds)
			end
		else
			serverLuckShown = nil
		end
		refreshEventBanner()
	end)
	-- A late joiner missed the PurchasesChanged push; the answer seeds State unless a push beat it.
	task.spawn(function()
		local raw = Net.func("GetPurchases"):InvokeServer()
		local state = raw :: Types.PurchasesState?
		if state then
			State.SeedPurchases(state)
		end
	end)
	-- A late joiner missed the last ShowerChanged push; the answer seeds State unless a push beat it.
	task.spawn(function()
		local raw = Net.func("GetShower"):InvokeServer()
		local state = raw :: Types.ShowerState?
		if state then
			State.SeedShower(state)
		end
	end)
	-- ...and the last CatchRushChanged push; same rule.
	task.spawn(function()
		local raw = Net.func("GetCatchRush"):InvokeServer()
		local state = raw :: Types.CatchRushState?
		if state then
			State.SeedRush(state)
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

	-- Radar Mk1: the minimap takes the Nearby column's slot once a radar is owned; the free column (tier 0)
	-- hides at Mk1, since its rows would not fit under the disc. From Mk2 the column comes back under the
	-- disc as the compact "not now" list: the disc's bottom edge moves its top (the slot's own top, the
	-- default, while the disc is hidden or no radar is held).
	Radar.Build()
	Radar.OnLayout(function(bottom: number)
		NearbyPanel.SetTop(if Radar.IsShown() then bottom else NearbyPanel.DefaultTop())
	end)
	Compass.Start() -- the strip along the top edge; the refresh below shows it with the other HUD extras
	local function refreshRadarTier()
		local tier = if State.Has() then State.Get().gear.radar else 0
		Radar.SetTier(tier)
		radarTier = tier
		NearbyPanel.SetVisible(nearbyShows())
	end
	refreshRadarTier()
	State.OnChanged("gear", refreshRadarTier)
	-- A tapped blip marks that alien until the player reaches it or it is gone. The tutorial owns the
	-- marker while it runs, so a tap then only explains.
	Radar.OnBlipTapped(function(part: Part)
		local step = State.GetTutorial()
		if step <= #TutorialData.Steps then
			Toast.Show(Strings.TOAST_RADAR_TUTORIAL, Theme.Rarity.Common)
			return
		end
		local speciesId = part:GetAttribute("SpeciesId")
		local def = if type(speciesId) == "string" then Species.ById[speciesId] else nil
		local entry = if type(speciesId) == "string" and State.Has() then State.Get().codex[speciesId] else nil
		local name = if def and entry and entry.count > 0 then def.name else Strings.CODEX_UNKNOWN
		radarTarget = part
		Compass.SetTarget(part)
		Waypoint.Show(function()
			return if part.Parent then part.Position else nil
		end, name)
		Toast.Show(Strings.TOAST_RADAR_MARKED:format(name), Theme.Colors.Select)
	end)

	local known: { [string]: boolean } = {}
	for species, entry in pairs(profile.codex) do
		if entry.count > 0 then
			known[species] = true
		end
	end
	WildRenderer.Start(known)
	CampRenderer.Start()
	HomeRenderer.Start()
	HangarRenderer.Start()
	SightingRenderer.Start()
	CompanionRenderer.Start()
	NodeRenderer.Start()
	Ambience.Start()
	LightingDirector.Start()
	WeatherFx.Start()

	-- A brand-new profile opens with the crash landing: the camera drops from the sky to the wreck while
	-- the HUD waits. Anything already started (a plate collected, a rejoin) skips it.
	if profile.tutorialStep == 1 and profile.tutorialCounter == 0 then
		cinematic = true
		Hud.SetVisible(false)
		CameraDirector.CrashLanding(function()
			cinematic = false
			Hud.SetVisible(true)
		end)
	end

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
	local blizzardHinted = false -- the hide-and-Heater hint shows once per blizzard
	local function onClock(state: Types.ClockState)
		Hud.SetClock(state)
		State.SetClock(state)
		-- A blizzard on a Blizzard-rule world hides far aliens; say so once, and say it again next blizzard.
		if blizzardActive() then
			if not blizzardHinted then
				blizzardHinted = true
				Toast.Banner(Strings.BLIZZARD_HINT:format(Config.BlizzardHideStuds), Theme.Colors.Select, Config.AnnounceSeconds)
			end
		else
			blizzardHinted = false
		end
		local world = Worlds[State.Get().world.current]
		if world and world.weather.special.speciesId ~= "" and state.weather == world.weather.special.id and lastWeather ~= nil and lastWeather ~= state.weather then
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
			refreshEventBanner()
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
		Hud.SetMenuVisible(not inCapture and not Reveal.IsOpen() and not cinematic)
		PowerUpBar.SetVisible(not inCapture and not Reveal.IsOpen() and not cinematic) -- it shares the lower third with the capture bar
		TutorialHint.SetVisible(not inCapture and not Reveal.IsOpen() and not Screens.IsAnyOpen() and not cinematic)
		Compass.SetVisible(not inCapture and not Reveal.IsOpen() and not Screens.IsAnyOpen() and not cinematic)
		Radar.SetVisible(not modalOpen() and not cinematic)
		NearbyPanel.SetVisible(nearbyShows())
		Toast.SetTop(if Screens.IsAnyOpen() then TOAST_TOP_WITH_PANEL elseif State.GetShower().active or State.GetRush().active or State.GetServerLuck() ~= nil then TOAST_TOP_WITH_BANNER else nil)
		-- A marked alien's waypoint clears on arrival or when the alien is gone (caught, fled, culled).
		local target = radarTarget
		if target then
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local arrived = root and root:IsA("BasePart") and (root.Position - target.Position).Magnitude <= Config.RadarWaypointArriveStuds
			if not target.Parent or arrived then
				radarTarget = nil
				Compass.SetTarget(nil)
				Waypoint.Clear()
			end
		end
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

	-- While the Build tray is open a tap in the world goes to the plot instead of the capture flow. A click is the
	-- press itself; a touch counts as a tap only when the engine says so (TouchTapInWorld fires on a lift without a
	-- drag), so dragging the camera round the plot never previews or places anything.
	UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
		if not processedByUI and BuildScreen.IsOpen() then
			BuildScreen.OnWorldTap(position.X, position.Y)
		end
	end)

	-- Tapping or clicking an alien itself also starts a catch when it is in reach.
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		local kind = input.UserInputType
		if BuildScreen.IsOpen() then
			if kind == Enum.UserInputType.MouseButton1 then
				BuildScreen.OnWorldTap(input.Position.X, input.Position.Y)
			end
			return
		end
		if modalOpen() then
			return
		end
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
