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
local NotifyCard = require(script:WaitForChild("UI"):WaitForChild("NotifyCard"))
local Radar = require(script:WaitForChild("UI"):WaitForChild("Radar"))
local Waypoint = require(script:WaitForChild("World"):WaitForChild("Waypoint"))
local TutorialData = require(Shared:WaitForChild("data"):WaitForChild("Tutorial"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Vfx = require(script:WaitForChild("World"):WaitForChild("Vfx"))
local Ambience = require(script:WaitForChild("World"):WaitForChild("Ambience"))
local CameraDirector = require(script:WaitForChild("World"):WaitForChild("CameraDirector"))
local LaunchSequence = require(script:WaitForChild("World"):WaitForChild("LaunchSequence"))
local Prefs = require(script:WaitForChild("Prefs"))
local SettingsScreen = require(script:WaitForChild("UI"):WaitForChild("SettingsScreen"))
local StarChartScreen = require(script:WaitForChild("UI"):WaitForChild("StarChartScreen"))
local LeaderboardScreen = require(script:WaitForChild("UI"):WaitForChild("LeaderboardScreen"))
local LandmarkRenderer = require(script:WaitForChild("World"):WaitForChild("LandmarkRenderer"))
local Quests = require(Shared:WaitForChild("data"):WaitForChild("Quests"))
local Social = require(Shared:WaitForChild("data"):WaitForChild("Social"))

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
local radarTarget: Part? = nil -- the wild part a tapped radar blip marked with the waypoint
local capturePart: Part? = nil -- the wild part the current catch is for
local capturePosition: Vector3? = nil -- where it stood when the catch began: the server removes the part before the result lands, so the burst plays here
local cinematic = false
local radarTier = 0 -- the Nearby column shows only without a radar and outside a cinematic -- the crash-landing opener is running: the HUD, hint and radar stay hidden

type Action = "Catch" | "Collect" | "Build" | "Launch" | "Trade" | "Horn" | "Heater"
local currentAction: Action? = nil
local ACTION_TEXT: { [string]: string } = {
	Catch = Strings.ACTION_CATCH,
	Collect = Strings.ACTION_COLLECT,
	Build = Strings.ACTION_BUILD,
	Launch = Strings.ACTION_LAUNCH,
	Trade = Strings.ACTION_TRADE,
	Horn = Strings.ACTION_HORN,
	Heater = Strings.ACTION_HEATER,
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
	-- The Heater is the lowest priority: offered during a blizzard only when nothing else is in reach.
	if best == nil and blizzardActive() then
		best = "Heater"
	end
	return best
end

local launching = false -- one Launch request in flight at a time
local flying = false -- a Star Chart Fly's fade is under way

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

local function connectToasts()
	task.spawn(function()
		Net.event("MaterialCollected").OnClientEvent:Connect(function(material: string, count: number)
			Toast.Show(Strings.TOAST_MATERIAL:format(count, Builder.text("MATERIAL_" .. material)), Theme.Colors.Featured)
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
	-- The group gift's state: the server pushes it whenever membership or the claim changes.
	task.spawn(function()
		Net.event("SocialChanged").OnClientEvent:Connect(function(snapshot: GiftsScreen.SocialSnapshot)
			GiftsScreen.SetSocial(snapshot)
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
	Screens.Register("Settings", SettingsScreen)
	Screens.Register("StarChart", StarChartScreen)
	Screens.Register("Ranks", LeaderboardScreen)
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
			Hud.SetEventBanner(Strings.SHOWER_NOW, Strings.SHOWER_LEFT:format(timeText), Strings.SHOWER_LUCK:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)))
			Hud.SetShowerCountdown(nil)
			if not showerWasActive then
				Builder.playSound(Sounds.ShowerHorn)
				Vfx.SetShowerSky(true)
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds)
			end
			showerWasActive = true
			return
		end
		if showerWasActive then
			Vfx.SetShowerSky(false)
			Toast.Show(Strings.SHOWER_OVER, Theme.Colors.Codex)
		end
		showerWasActive = false
		-- Server luck someone bought takes the banner slot while no shower runs.
		local luckState, luckElapsed = State.GetServerLuck()
		if luckState and luckState.secondsLeft - luckElapsed > 0 then
			local left = math.ceil(luckState.secondsLeft - luckElapsed)
			local minutes, seconds = left // 60, left % 60
			local timeText = if minutes > 0 then Strings.TIME_MS:format(minutes, seconds) else Strings.TIME_S:format(seconds)
			local multiplier = ("%d"):format(1 + luckState.bonus)
			Hud.SetEventBanner(Strings.SERVERLUCK_BANNER:format(multiplier), Strings.SERVERLUCK_LEFT:format(timeText), Strings.SERVERLUCK_CHIP:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)))
		else
			Hud.SetEventBanner(nil, nil, nil)
		end
		local nextIn = math.max(0, shower.nextInSeconds - elapsed)
		if shower.nextInSeconds > 0 and nextIn <= Config.ShowerWarnSeconds then
			Hud.SetShowerCountdown(nextIn)
		else
			Hud.SetShowerCountdown(nil)
		end
	end
	State.OnChanged("shower", refreshShower)
	State.OnChanged("luck", refreshShower)
	-- A bought server luck announces itself once to everyone and then counts down in the banner slot.
	local serverLuckShown: string? = nil
	State.OnChanged("serverLuck", function()
		local luckState = State.GetServerLuck()
		if luckState then
			local key = luckState.playerName .. ":" .. tostring(luckState.bonus)
			if serverLuckShown ~= key then
				serverLuckShown = key
				Toast.Banner(Strings.TOAST_SERVERLUCK_START:format(luckState.playerName, ("%d"):format(1 + luckState.bonus)), Theme.Colors.Featured, Config.AnnounceSeconds)
			end
		else
			serverLuckShown = nil
		end
		refreshShower()
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
	-- hides, since its rows would not fit under the disc.
	Radar.Build()
	local function refreshRadarTier()
		local tier = if State.Has() then State.Get().gear.radar else 0
		Radar.SetTier(tier)
		radarTier = tier
		NearbyPanel.SetVisible(tier < 1 and not cinematic)
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
	NodeRenderer.Start()
	Ambience.Start()

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
		Hud.SetMenuVisible(not inCapture and not Reveal.IsOpen() and not cinematic)
		PowerUpBar.SetVisible(not inCapture and not Reveal.IsOpen() and not cinematic) -- it shares the lower third with the capture bar
		TutorialHint.SetVisible(not inCapture and not Reveal.IsOpen() and not Screens.IsAnyOpen() and not cinematic)
		Radar.SetVisible(not modalOpen() and not cinematic)
		NearbyPanel.SetVisible(radarTier < 1 and not cinematic)
		Toast.SetTop(if Screens.IsAnyOpen() then TOAST_TOP_WITH_PANEL elseif State.GetShower().active or State.GetServerLuck() ~= nil then TOAST_TOP_WITH_BANNER else nil)
		-- A marked alien's waypoint clears on arrival or when the alien is gone (caught, fled, culled).
		local target = radarTarget
		if target then
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local arrived = root and root:IsA("BasePart") and (root.Position - target.Position).Magnitude <= Config.RadarWaypointArriveStuds
			if not target.Parent or arrived then
				radarTarget = nil
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
