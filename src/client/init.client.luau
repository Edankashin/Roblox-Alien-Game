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
local GuiService = game:GetService("GuiService")
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
local AfkData = require(Shared:WaitForChild("data"):WaitForChild("Afk"))
local CatchRush = require(Shared:WaitForChild("data"):WaitForChild("CatchRush"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local ShopData = require(Shared:WaitForChild("data"):WaitForChild("Shop"))
local ShelfMath = require(Shared:WaitForChild("ShelfMath"))
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
local ScrapGap = require(script:WaitForChild("UI"):WaitForChild("ScrapGap"))
local AliensScreen = require(script:WaitForChild("UI"):WaitForChild("AliensScreen"))
local CodexScreen = require(script:WaitForChild("UI"):WaitForChild("CodexScreen"))
local BuildScreen = require(script:WaitForChild("UI"):WaitForChild("BuildScreen"))
local MailScreen = require(script:WaitForChild("UI"):WaitForChild("MailScreen"))
local VisitScreen = require(script:WaitForChild("UI"):WaitForChild("VisitScreen"))
local AfkScreen = require(script:WaitForChild("UI"):WaitForChild("AfkScreen"))
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
local PlaytimeScreen = require(script:WaitForChild("UI"):WaitForChild("PlaytimeScreen"))
local NotifyCard = require(script:WaitForChild("UI"):WaitForChild("NotifyCard"))
local RadarColumn = require(script:WaitForChild("UI"):WaitForChild("RadarColumn"))
local Compass = require(script:WaitForChild("UI"):WaitForChild("Compass"))
local TutorialData = require(Shared:WaitForChild("data"):WaitForChild("Tutorial"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local NotifyMath = require(Shared:WaitForChild("NotifyMath"))
local Notify = require(Shared:WaitForChild("data"):WaitForChild("Notify"))
local SettingsData = require(Shared:WaitForChild("data"):WaitForChild("Settings"))
local Vfx = require(script:WaitForChild("World"):WaitForChild("Vfx"))
local Spectacle = require(script:WaitForChild("World"):WaitForChild("Spectacle"))
local Ambience = require(script:WaitForChild("World"):WaitForChild("Ambience"))
local MusicDirector = require(script:WaitForChild("World"):WaitForChild("MusicDirector"))
local Haptics = require(script:WaitForChild("World"):WaitForChild("Haptics"))
local MusicMath = require(Shared:WaitForChild("MusicMath"))
local CinematicMath = require(Shared:WaitForChild("CinematicMath"))
local LightingDirector = require(script:WaitForChild("World"):WaitForChild("LightingDirector"))
local LampDirector = require(script:WaitForChild("World"):WaitForChild("LampDirector"))
local WeatherFx = require(script:WaitForChild("World"):WaitForChild("WeatherFx"))
local WorldFx = require(script:WaitForChild("World"):WaitForChild("WorldFx"))
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
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))

local ACTION_POLL_SECONDS = 0.1 -- how often the contextual button re-decides its verb
local TOAST_TOP_WITH_PANEL = 0.03 -- with a panel open, toasts sit over the dimmed HUD row instead of the panel's header
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
local capturePart: Part? = nil -- the wild part the current catch is for
local capturePosition: Vector3? = nil -- where it stood when the catch began: the server removes the part before the result lands, so the burst plays here
local cinematic = false -- the crash-landing opener or a cinematic moment (playCinematic) is running: the HUD, hint and radar stay hidden

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
local markSeen = Net.func("MarkSeen")

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

-- A quiet moment: a catch is running (from the tap, the Legendary opening included, to the Reveal's close) or the Reveal is up.
-- Toast.IsQuiet answers from this, so banners and toasts wait while nothing may cover the Reveal or the capture bar.
local function quietMoment(): boolean
	return inCapture or Reveal.IsOpen()
end

-- A system line in the general chat, shown on this client only (DisplaySystemMessage): a Rare catch by someone else at Announcements "Big only",
-- and a bought Server Luck (TikTok batch 9 lesson 7: everyone sees someone spending, and anyone can add time).
local function chatLine(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = if channels then channels:FindFirstChild("RBXGeneral") else nil
	if general and general:IsA("TextChannel") then
		local ok, err = pcall(function()
			general:DisplaySystemMessage(text)
		end)
		if not ok then
			print(("[%s] chat line skipped: %s"):format(Config.WorkingTitle, tostring(err)))
		end
	end
end

-- The player's Announcements level (data/Settings: 0 Off, 1 Big only, 2 All), the data default while the row or the profile is missing.
local function announceLevel(): number
	if SettingsData.ById.Announcements == nil then
		return Notify.AnnounceLevelDefault
	end
	return Prefs.Level("Announcements")
end

-- Routes a named message (data/Notify Messages) to its class (docs/vault/05-ui-design/Clean-UI-Pass.md "The notification budget"): a banner
-- for what the player can join now, a toast for their own results, a quiet line for the rest, a chat line, or nothing. A banner's id is its
-- kind (its priority in the queue); `mergeKey` lets a later message with the same key update a live toast in place.
local function notify(id: string, text: string, color: Color3, iconKey: string?, mergeKey: string?)
	local class = NotifyMath.MessageClass(id)
	if class == "Banner" then
		Toast.Banner(text, color, Config.AnnounceSeconds, id)
	elseif class == "Quiet" then
		Toast.Quiet(text, color, iconKey, mergeKey)
	elseif class == "Toast" then
		Toast.Show(text, color, iconKey, nil, mergeKey)
	elseif class == "Chat" then
		chatLine(text)
	end
end

-- A catch in progress or a modal screen blocks every other action.
local function modalOpen(): boolean
	return quietMoment() or Screens.IsAnyOpen()
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
	MusicDirector.SetCapture(nil) -- the world's bed returns
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
		Reveal.Present({ -- the quick card for a repeat of a known species below Rare, else the three beats
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
			overflowScrap = result.overflowScrap,
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
			Spectacle.ClearFocus()
			finishCapture()
			return
		end
		CaptureBar.ApplyResult(result)
		if result.outcome == "Caught" then
			Spectacle.Verdict("Caught", result.tier) -- the alien spirals into the device (World.Spectacle), on the server's word
			onCaught(result)
		elseif result.outcome == "Fled" then
			Spectacle.Verdict("Fled") -- it hops away, or a Secret blinks out
			task.delay(0.9, finishCapture)
		end
	end)
end

-- Cinematic moments (milestone 47, data/Cinematics) ------------------------------

-- Remembers that the player has watched the first-time moment `key` (a data/Cinematics SeenKeys entry): in the mirror at
-- once, then on the server, which stores it in the save and accepts only those keys.
local function markSeenKey(key: string)
	if State.HasSeen(key) then
		return
	end
	State.MarkSeen(key)
	task.spawn(function()
		markSeen:InvokeServer(key)
	end)
end

-- Plays the cinematic moment `momentId` with the HUD out of the way (the same flag the crash opener uses), then gives the
-- HUD back and runs `afterwards`. Answers false, with nothing changed, when it could not start: a catch, a launch or
-- another camera moment is running, or CameraDirector.PlayShots declined (an unknown moment, no camera).
local function playCinematic(momentId: string, context: CameraDirector.ShotContext?, afterwards: (() -> ())?): boolean
	if cinematic or inCapture or LaunchSequence.IsPlaying() or CameraDirector.IsBusy() then
		return false
	end
	cinematic = true
	Hud.SetVisible(false)
	Screens.CloseAll()
	local started = CameraDirector.PlayShots(momentId, function()
		cinematic = false
		Hud.SetVisible(true)
		if afterwards then
			afterwards()
		end
	end, context)
	if not started then
		cinematic = false
		Hud.SetVisible(true)
	end
	return started
end

-- The Legendary push-in toward `target`: runs on the calling thread, which waits until the camera moment ends (the
-- camera stays on the pushed-in view, handed straight to the rumble). Returns at once when nothing plays (reduced motion).
local function legendaryPushIn(target: Vector3)
	local thread = coroutine.running()
	local finished = false
	local waiting = false
	local started = CameraDirector.PlayShots("Legendary", function()
		finished = true
		if waiting then
			task.spawn(thread) -- resume at once, in the same frame, so the rumble starts on the pushed-in view
		end
	end, { target = target })
	if started and not finished then
		waiting = true
		coroutine.yield()
	end
end

-- The Legendary opening (a catch on a Legendary or higher alien): a slow push-in toward the alien (Cinematics "Legendary",
-- 1.2 s, no letterbox or blur), then the low rumble sound, the phone buzz and the screen shake on the pushed-in view
-- (Config.LegendaryRumbleSeconds), all BEFORE the catch request, so the bar opens on a fresh first sweep; the intense music
-- is already on. Together they delay the bar by less than Cinematics.LegendaryBudgetSeconds. Reduced motion skips the
-- push-in, the shake and the buzz (PlayShots, CameraDirector.Rumble and Haptics.Pulse answer false) and the request goes at once.
local function legendaryOpening(at: Vector3)
	legendaryPushIn(at)
	Builder.playSound(Sounds.LegendaryRumble)
	Haptics.Pulse(Config.LegendaryHapticSeconds, Config.LegendaryHapticStrength)
	if CameraDirector.Rumble(Config.LegendaryRumbleSeconds, Config.LegendaryRumbleStuds) then
		task.wait(Config.LegendaryRumbleSeconds)
	end
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
	Toast.Hush() -- the capture bar is a quiet moment: a banner or toast drawn a moment ago leaves and replays after the Reveal
	capturePart = part
	Spectacle.Focus(part) -- if the server removes it, its clone plays the catch's outro instead of vanishing
	capturePosition = part.Position
	CameraDirector.Cancel() -- a catch takes priority over any camera moment
	Hud.SetAction(nil)
	-- The catch music starts with the tap: the plain bed, or the intense one for Legendary and above (the tier is on the part).
	local tierAttribute = part:GetAttribute("Tier")
	local kind: MusicMath.CaptureKind = MusicMath.CaptureKind(if type(tierAttribute) == "string" then tierAttribute else "")
	MusicDirector.SetCapture(kind)
	-- Own thread: InvokeServer yields, and callers are input callbacks.
	task.spawn(function()
		if kind == "intense" then
			legendaryOpening(part.Position)
			-- The opening takes a couple of seconds: a catch that ended meanwhile (the character died) is not requested.
			if not inCapture or capturePart ~= part then
				return
			end
		end
		local raw, reason = captureStart:InvokeServer(spawnId)
		local start = raw :: Types.CaptureStartResult?
		if not start then
			inCapture = false
			MusicDirector.SetCapture(nil)
			if reason == "InFlight" then
				Toast.Show(Strings.TOAST_IN_FLIGHT, Theme.Colors.Select) -- a launch or flight is in progress (Exploit-Review D4)
			end
			Spectacle.ClearFocus()
			print(("[%s] capture refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			return
		end
		captureToken = start.token
		local def = Species.ById[start.species]
		CaptureBar.Begin({
			speciesName = if def then def.name else start.species,
			tierName = Builder.text("TIER_" .. start.tier),
			tierColor = Builder.tierColor(start.tier),
			tier = start.tier,
			alienColor = Spectacle.AlienColor(start.species), -- the hit and Perfect flash in the alien's own colour
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
		elseif reason == "InFlight" then
			Toast.Show(Strings.TOAST_IN_FLIGHT, Theme.Colors.Select) -- a launch or flight is in progress (Exploit-Review D4)
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
			notify("waveSent", Strings.TOAST_WAVE_SENT:format(ownerName, if def then def.name else speciesId, Builder.formatNumber(paid)), Theme.Colors.Confirm)
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
			elseif reason == "InFlight" then
				Toast.Show(Strings.TOAST_IN_FLIGHT, Theme.Colors.Select) -- a launch or flight is in progress (Exploit-Review D4)
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
	local materialRun: { [string]: { total: number, at: number } } = {} -- the running count of each material's merged toast
	local grewRun = { total = 0, at = -math.huge } -- and of the aliens that grew, in their merged quiet line
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
				notify("friendJoined", Strings.TOAST_FRIEND_JOINED:format(arrivedName, percent), Theme.Colors.Confirm)
			elseif not (first and count == 0) then
				notify("friendLeft", Strings.TOAST_FRIEND_LEFT:format(percent), Theme.Colors.Select)
			end
		end)
	end)
	task.spawn(function()
		Net.event("MaterialCollected").OnClientEvent:Connect(function(material: string, count: number)
			-- Pickups within a few seconds merge into one toast that counts up ("+1", "+2", "+3 Wreck Plate"), one ding for the run.
			local key = "material:" .. material
			local run = materialRun[material]
			local total = if run and Toast.IsMerging(key) then NotifyMath.MergedTotal(run.total, run.at, os.clock(), count) else count
			materialRun[material] = { total = total, at = os.clock() }
			notify("material", Strings.TOAST_MATERIAL:format(total, Builder.text("MATERIAL_" .. material)), Theme.Colors.Featured, material, key)
		end)
	end)
	task.spawn(function()
		Net.event("ModuleCompleted").OnClientEvent:Connect(function(worldId: number, moduleId: string)
			Builder.playSound(Sounds.ModuleComplete)
			Vfx.ModuleBurst(CampRenderer.ShipPosition(), Theme.Colors.Confirm)
			Toast.QuietFor(Config.VfxModuleBurstSeconds) -- the toasts below (and the storage one that follows) wait until the burst has played
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
	-- A finished ship module raised the alien storage cap (StorageChanged carries `gained` only for that): say by how much.
	-- Joining, the Storage Bay and the pass change the cap without it; the Aliens screen shows those.
	task.spawn(function()
		Net.event("StorageChanged").OnClientEvent:Connect(function(state: Types.StorageState)
			local gained = state.gained
			if gained ~= nil and gained > 0 then
				Toast.Show(Strings.TOAST_STORAGE_GAINED:format(Builder.formatNumber(gained)), Theme.Colors.Featured)
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
				notify("habitatIncome", Strings.TOAST_HABITAT_INCOME:format(Builder.formatNumber(paid)), Theme.Colors.Confirm)
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
			notify("visitor", Strings.TOAST_VISITOR_ARRIVED:format(tostring(name)), Theme.Colors.Select)
			State.RefreshVisitors()
		end)
	end)
	-- The guest's side of a home that closed on them (the owner set the lock to Only me, or to Friends and the guest is
	-- not one): the same wording as the refusal at the door. The HomeView(nil) that follows says they are home again.
	task.spawn(function()
		Net.event("HomeClosed").OnClientEvent:Connect(function(ownerName: string, reason: string)
			local line = if reason == "FriendsOnly" then Strings.TOAST_VISIT_FRIENDSONLY else Strings.TOAST_VISIT_OWNERONLY
			Toast.Show(line:format(tostring(ownerName)), Theme.Colors.Close)
		end)
	end)
	task.spawn(function()
		Net.event("WaveReceived").OnClientEvent:Connect(function(name: string, species: string, scrap: number)
			local def = Species.ById[species]
			notify("waveGot", Strings.TOAST_WAVE_GOT:format(tostring(name), if def then def.name else tostring(species), Builder.formatNumber(scrap)), Theme.Colors.Featured)
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
			Toast.Banner(Strings.FLY_LINE:format(name), Theme.Colors.Select, Config.FlyTeleportDelaySeconds, "fly")
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
	-- Server-wide announcements, each in the class it earns (docs/vault/05-ui-design/Clean-UI-Pass.md "The notification budget"): someone
	-- else's catch by its tier and the player's Announcements setting (a Rare as a chat line, an Epic as a toast, a Legendary and up as a
	-- banner; "All" adds a quiet line for the Rare, "Off" shows none), the Catch Rush winner as a toast (not something to join), a line from
	-- the team as a banner. The server announces every Rare and up to everyone, so the catcher's own client skips the lower three classes.
	task.spawn(function()
		Net.event("Announcement").OnClientEvent:Connect(function(note: Types.Announcement)
			if note.kind == "rush" then
				notify("rushWinner", Strings.ANNOUNCE_RUSH:format(note.playerName, note.catches or 0), Theme.Colors.Featured)
				return
			elseif note.kind == "notice" then
				-- A line from the team (the developer panel), shown as typed in the Codex purple.
				notify("announce", Strings.ANNOUNCE_NOTICE:format(note.text or ""), Theme.Colors.Codex)
				return
			end
			local class = NotifyMath.OthersCatchClass(announceLevel(), note.tier)
			if class == "None" or (class ~= "Banner" and note.playerName == localPlayer.DisplayName) then
				return
			end
			local def = Species.ById[note.species]
			local speciesName = if def then def.name else note.species
			local text = if note.overlay ~= "None"
				then Strings.ANNOUNCE_CATCH_OVERLAY:format(note.playerName, Builder.text("OVERLAY_A_" .. note.overlay), Builder.text("TIER_" .. note.tier), speciesName)
				else Strings.ANNOUNCE_CATCH:format(note.playerName, Builder.text("TIER_A_" .. note.tier), speciesName)
			local color = Builder.tierColor(note.tier)
			if class == "Banner" then
				notify("announce", text, color) -- the Reveal and the capture bar own the screen: Toast holds the banner until they are gone (the latest announcement wins)
			elseif class == "Toast" then
				Toast.Show(text, color)
			elseif class == "Quiet" then
				Toast.Quiet(text, color)
			else
				chatLine(text)
			end
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
				overflowScrap = grant.overflowScrap,
				fromEgg = true, -- a grant: the egg beat plays
				chancePercent = grant.oddsPercent, -- the server's draw; nil for a fixed reward (no chance line)
			})
		end)
	end)
	task.spawn(function()
		Net.event("WardenSummoned").OnClientEvent:Connect(function()
			Builder.playSound(Sounds.WardenAppear)
			notify("warden", Strings.TOAST_WARDEN_AWAKE, Builder.tierColor("Legendary"))
		end)
	end)
	task.spawn(function()
		Net.event("WardenRetreated").OnClientEvent:Connect(function()
			notify("wardenRetreat", Strings.TOAST_WARDEN_RETREAT, Builder.tierColor("Legendary"))
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
				notify("sighting", Strings.SIGHTING_BANNER:format(sightingName(state.species)), Builder.tierColor(if def then def.tier else "Common"))
			else
				local species = if Species.ById[state.species] then state.species else sightingSpecies
				notify("sightingOver", Strings.SIGHTING_OVER:format(sightingName(species)), Theme.Rarity.Common)
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
				-- A quiet line; several growing within a few seconds merge into one that counts them ("3 aliens grew up!").
				local total = if Toast.IsMerging("grew") then NotifyMath.MergedTotal(grewRun.total, grewRun.at, os.clock(), 1) else 1
				grewRun = { total = total, at = os.clock() }
				notify(
					"alienGrew",
					if total == 1 then Strings.TOAST_ALIEN_GREW:format(name, Builder.text("STAGE_" .. stageId)) else Strings.TOAST_ALIENS_GREW:format(total),
					Theme.Colors.Featured,
					nil,
					"grew"
				)
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
		-- One welcome toast, one line per kind, three lines at most (NotifyMath.OfflineLines): the Scrap, the finished modules, the growth.
		-- (It used to be six or more toasts and dings in the first seconds.)
		local moduleNames: { string } = {}
		for _, moduleId in ipairs(summary.completedModules) do
			table.insert(moduleNames, Builder.text("MODULE_" .. moduleId))
		end
		local lines = NotifyMath.OfflineLines({
			scrapText = if summary.scrap > 0 then Builder.formatNumber(summary.scrap) else nil,
			moduleNames = moduleNames,
			grown = if summary.grown then #summary.grown else 0,
		})
		notify("welcomeBack", table.concat(lines, "\n"), Theme.Colors.Featured)
	end)
end

-- Resting (milestone 46, data/Afk) ---------------------------------------------


-- The HUD's Scrap per minute: the camp rate times the station factor the server applies right now (RateChanged carries
-- both; the factor covers Double Shift, the Friend Boost and resting). The server pays it; this only draws it.
local function showRate()
	local state = State.GetRate()
	Hud.SetRate(state.ratePerSecond * (state.multiplier or 1))
end

-- The Resting screen and what feeds it. The server decides who rests (AfkChanged: resting or not, since when, the Scrap
-- earned) and wakes a player who moves or uses the game; the client only draws and keeps two idle clocks. ANY local
-- input hides the screen (the server may not have heard of it yet: a menu read, a camera drag), "Back to play" also
-- tells the server (AfkWake). A screen hidden while the server still says resting comes back after Afk.IdleAfterSeconds
-- with no input. Roblox disconnects a player with no input for 20 minutes, so at Afk.RejoinAfterIdleSeconds idle
-- (Player.Idled's seconds, or the clock of the last local input, whichever is larger) the client asks AfkRejoin once
-- per idle stretch; the server answers ok when the rejoin is under way.
local function connectAfk()
	local lastState: Types.AfkState = { resting = false, since = 0, earned = 0 }
	local hiddenByInput = false -- the screen was hidden by local input while the server still says resting
	local lastInput = os.clock()
	local idledSeconds = 0 -- the engine's Player.Idled figure and the clock it arrived at
	local idledAt = 0
	local rejoinAsked = false

	-- Seconds without input: the larger of the local clock and the engine's figure (extrapolated), the engine's only
	-- while no input has been seen since it arrived.
	local function idleSeconds(): number
		local now = os.clock()
		local engine = if idledAt > lastInput then idledSeconds + (now - idledAt) else 0
		return math.max(now - lastInput, engine)
	end

	local function requestRejoin()
		task.spawn(function()
			local called, ok = pcall(function(): (any, any)
				return Net.func("AfkRejoin"):InvokeServer()
			end)
			if called and ok == true then
				AfkScreen.SetRejoining(true)
			end
		end)
	end

	task.spawn(function()
		Net.event("AfkChanged").OnClientEvent:Connect(function(state: Types.AfkState)
			if type(state) ~= "table" or type(state.resting) ~= "boolean" or type(state.since) ~= "number" or type(state.earned) ~= "number" then
				return
			end
			local was = lastState.resting
			lastState = state
			MusicDirector.SetResting(state.resting)
			showRate()
			if state.resting then
				if not was then
					hiddenByInput = false
					Builder.playSound(Sounds.RestStart) -- the crew starts resting (not on a re-show of the screen)
					AfkScreen.Show(state)
				else
					AfkScreen.Update(state) -- hidden or not: the numbers are ready for a re-show
				end
			else
				hiddenByInput = false
				AfkScreen.Hide()
				if was then
					Toast.Show(Strings.TOAST_AFK_BACK:format(Builder.formatNumber(state.earned)), Theme.Colors.Confirm)
				end
			end
		end)
	end)
	-- The server accepted a rejoin (the client's own request or /afk rejoin): the screen says so, and comes back up if
	-- a key press had hidden it.
	task.spawn(function()
		Net.event("AfkRejoining").OnClientEvent:Connect(function()
			if not lastState.resting then
				return
			end
			if not AfkScreen.IsShown() then
				hiddenByInput = false
				AfkScreen.Show(lastState)
			end
			AfkScreen.SetRejoining(true)
		end)
	end)

	-- Use of the game the server cannot see (opening menus, scrolling a list) is reported with AfkWake, the same
	-- "use of the game" call the resting screen's button makes, at most every ActivityPingSeconds while playing, so a
	-- player reading the shop without walking is not resting. While resting, a press wakes the server at once.
	local lastPing = 0
	local function reportUse(now: boolean)
		local clock = os.clock()
		if now or clock - lastPing >= AfkData.ActivityPingSeconds then
			lastPing = clock
			Net.event("AfkWake"):FireServer()
		end
	end

	AfkScreen.OnBack(function()
		hiddenByInput = true
		AfkScreen.Hide()
		reportUse(true)
	end)

	-- Any press, tap or key: the player is here. While resting it hides the screen and wakes the server in the same
	-- step (the screen used to hide on mouse-down, before its button's Activated could fire, so the server never
	-- heard the player was back).
	UserInputService.InputBegan:Connect(function()
		lastInput = os.clock()
		rejoinAsked = false
		if lastState.resting then
			if AfkScreen.IsShown() then
				hiddenByInput = true
				AfkScreen.Hide()
			end
			reportUse(true)
		else
			reportUse(false)
		end
	end)
	-- A moving mouse or finger is input for Roblox's idle timer too, so it keeps the rejoin clock honest (it does not
	-- hide the screen: only a press or tap does).
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.MouseWheel or kind == Enum.UserInputType.Touch then
			lastInput = os.clock()
			rejoinAsked = false
		end
		-- Scrolling a list or dragging a finger is use of the game while playing (a resting player wakes with a press).
		if not lastState.resting and (kind == Enum.UserInputType.MouseWheel or kind == Enum.UserInputType.Touch) then
			reportUse(false)
		end
	end)
	localPlayer.Idled:Connect(function(seconds: number)
		idledSeconds = seconds
		idledAt = os.clock()
	end)

	task.spawn(function()
		while true do
			task.wait(AfkData.CheckSeconds)
			if lastState.resting then
				local idle = idleSeconds()
				if hiddenByInput and idle >= AfkData.IdleAfterSeconds then
					hiddenByInput = false
					AfkScreen.Show(lastState)
				end
				if not rejoinAsked and idle >= AfkData.RejoinAfterIdleSeconds then
					rejoinAsked = true
					requestRejoin()
				end
			end
		end
	end)
end

-- Boot ---------------------------------------------------------------------

local function start(profile: Types.Profile)
	if started then
		-- The other copy (the join push or the boot pull, whichever landed second) holds the same records but a newer alien
		-- list number: keep the number, or the next AliensDelta reads as a gap.
		State.AdoptAliensSeq(profile.aliensSeq)
		return
	end
	started = true

	State.Set(profile)
	localPlayer:SetAttribute("ClientStarted", true) -- ReplicatedFirst.LoadingScreen watches this and fades itself out
	State.Start()
	Prefs.Start() -- applies volumes, motion and silhouette preferences before anything plays or renders

	-- The default chat window sits top-left over the Scrap pill and the menu stack; move it bottom-left.
	local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if chatWindow then
		chatWindow.HorizontalAlignment = Enum.HorizontalAlignment.Left
		chatWindow.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end
	-- Down there it covers a panel's lower-left corner, and the chat (CoreGui) takes a tap before any game button under it,
	-- faded or not (Studio, 2026-10-22: the Aliens footer's Storage Bay and the Menu's Settings row never fired). It steps
	-- aside while a modal or the Menu drop-down is up.
	local chatInputBar = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
	local chatShown = true
	local function setChatShown(shown: boolean)
		if shown == chatShown then
			return
		end
		chatShown = shown
		if chatWindow then
			chatWindow.Enabled = shown
		end
		if chatInputBar then
			chatInputBar.Enabled = shown
		end
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
	showRate()
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
	Spectacle.SetPanelProbe(Screens.IsAnyOpen) -- an arrival's screen dim waits for a clear screen
	Toast.SetQuietProbe(quietMoment) -- toasts and banners wait while the Reveal or a catch is up
	Screens.Register("Ship", ShipScreen)
	Screens.Register("Shop", ShopScreen)
	Screens.Register("Peddler", PeddlerScreen)
	Screens.Register("Quests", QuestsScreen)
	Screens.Register("Gifts", GiftsScreen)
	Screens.Register("Playtime", PlaytimeScreen)
	Screens.Register("Settings", SettingsScreen)
	Screens.Register("StarChart", StarChartScreen)
	Screens.Register("Ranks", LeaderboardScreen)
	Screens.Register("Build", BuildScreen)
	Screens.Register("Mail", MailScreen)
	Screens.Register("Visit", VisitScreen)
	-- An alien the server granted without a catch (a Peddler egg, a gift egg, an event track's last row) comes
	-- back as a GrantResult and hatches through the same reveal as a wild catch.
	local function showGrantReveal(grant: Types.GrantResult)
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
			overflowScrap = grant.overflowScrap,
			fromEgg = true, -- a grant: the egg beat plays
			chancePercent = grant.oddsPercent, -- the server's draw; nil for a fixed reward (no chance line)
		})
	end
	PeddlerScreen.OnGrant(showGrantReveal)
	QuestsScreen.OnGrant(showGrantReveal)
	PeddlerRenderer.Start()
	PowerUpBar.Build()
	State.OnChanged("luck", function()
		Hud.SetLuck(State.GetLuck())
	end)
	Hud.SetLuck(State.GetLuck())
	Screens.Register("Aliens", AliensScreen)
	Screens.Register("Codex", CodexScreen)
	Reveal.OnPlace(function() -- the Reveal's "Place it": the Aliens screen, where the newcomer can be seated or displayed
		Screens.Open("Aliens")
	end)
	local function menu(name: string)
		return function()
			if not inCapture and not Reveal.IsOpen() then
				Screens.Toggle(name)
			end
		end
	end
	Hud.AddMenuButton("Shop", Theme.Colors.Confirm, menu("Shop"))
	-- The Shop stays on the left edge on its own; every other screen is a row of the Menu drop-down under it (Decision B53), shown
	-- in the order added. A row's badge counts also add up on the Menu button.
	Hud.AddMenuRow("Aliens", Theme.Colors.Featured, menu("Aliens"))
	Hud.AddMenuRow("Codex", Theme.Colors.Codex, menu("Codex"))
	Hud.AddMenuRow("Ship", Theme.Colors.Select, menu("Ship"))
	Hud.AddMenuRow("Quests", Theme.Colors.Heading, menu("Quests"))
	Hud.AddMenuRow("Gifts", Theme.Colors.Close, menu("Gifts"))
	Hud.AddMenuRow("Mail", Theme.Colors.Select, menu("Mail"))
	Hud.AddMenuRow("Friends", Theme.Colors.Confirm, onFriendChipTap) -- the invite sheet; the Friend Boost chip hides at +0%
	Hud.AddMenuRow("Ranks", Theme.Colors.Featured, menu("Ranks"))
	Hud.AddMenuRow("Settings", Theme.Colors.Select, menu("Settings"))
	-- Playtime gifts (data/Playtime): the button stays hidden until the server says the gifts are on, and its badge counts
	-- the gifts unlocked and not yet claimed. PlaytimeChanged pushes the state whenever that changes; one pull seeds a
	-- client that joined after the last push (a push that already landed is newer and wins).
	Hud.AddMenuRow("Playtime", Theme.Colors.Confirm, menu("Playtime"))
	Hud.SetMenuRowVisible("Playtime", false)
	PlaytimeScreen.OnGrant(showGrantReveal)
	local playtimeBadge = -1 -- what the badge shows now, so a state that changes nothing does not pop the button
	PlaytimeScreen.OnState(function(playtime: Types.PlaytimeState)
		Hud.SetMenuRowVisible("Playtime", playtime.enabled)
		local ready = if playtime.enabled then PlaytimeScreen.ReadyCount() else 0
		if ready ~= playtimeBadge then
			playtimeBadge = ready
			Hud.SetBadge("Playtime", ready)
		end
	end)
	task.spawn(function()
		Net.event("PlaytimeChanged").OnClientEvent:Connect(function(playtime: Types.PlaytimeState)
			PlaytimeScreen.SetState(playtime)
		end)
		PlaytimeScreen.Pull()
	end)
	GiftsScreen.OnGrant(showGrantReveal)
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

	-- The offer (TikTok batch 9 lesson 4, data/Shop HudOffer): a gold button beside the Shop with the Starter Pack's pixel present
	-- (Ethan chose it over a Menu row, B53a), shown while the pack can be sold and this player has not bought it
	-- (Shared/ShelfMath.OfferShows); a tap opens the Shop, which starts on the Featured shelf where the pack is the first card.
	local offerId = ShopData.HudOffer
	local offerItem: ShopData.ShopItem? = nil
	for _, item in ipairs(ShopData.Items) do
		if item.id == offerId then
			offerItem = item
		end
	end
	Hud.AddSideButton(offerId, Theme.Colors.Featured, function()
		if not inCapture and not Reveal.IsOpen() then
			Screens.Open("Shop")
		end
	end)
	local function refreshOfferButton()
		local purchases, known = State.GetPurchases()
		local item = offerItem
		local shows = item ~= nil
			and ShelfMath.OfferShows(item, ShopData.Grants[offerId], purchases.purchases[offerId] or 0, known)
		Hud.SetSideButtonVisible(offerId, shows)
	end
	State.OnChanged("purchases", refreshOfferButton)
	refreshOfferButton()

	-- The Earn faster chip (Decision B51, Decide-Now 48c): a tap on it, on the "Need N more Scrap" toast of any Scrap screen, opens
	-- the Shop on the Boosts shelf at Scrap Magnet (UI/ScrapGap decides when it shows). Never during a catch or the Reveal, and it
	-- only opens the Shop: buying is still the card's own pill.
	ScrapGap.SetOpener(function(itemId: string)
		if not inCapture and not Reveal.IsOpen() then
			Screens.Open("Shop")
			ShopScreen.Focus(itemId)
		end
	end)

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
	-- "Nd Nh" for the weekly's and the season's time left.
	local function daysHoursText(seconds: number): string
		local left = math.max(0, math.floor(seconds))
		return Strings.TIME_DH:format(left // SECONDS_PER_DAY, (left % SECONDS_PER_DAY) // SECONDS_PER_HOUR)
	end
	local function weeklyLeftText(current: WeeklyMath.Current): string
		return daysHoursText(current.secondsLeft)
	end
	local function weeklyWeather(current: WeeklyMath.Current): string?
		local weather = current.drop.weather
		return if weather then Builder.text("WEATHER_" .. weather) else nil
	end
	-- The event bed the music director plays (data/Music): a running shower, else a rush, else the season in this world
	-- (its Music row is its id). None while the tutorial holds the event banners.
	local function eventMusic(): string?
		if eventBannersHeld() then
			return nil
		end
		local current = State.GetSeason()
		local seasonId = if current and table.find(current.season.worldIds, Place.WorldId()) ~= nil then current.season.id else nil
		return MusicMath.EventState(State.GetShower().active, State.GetRush().active, seasonId)
	end
	local function refreshEventBanner()
		MusicDirector.SetEvent(eventMusic())
		local shower, elapsed = State.GetShower()
		local rushState, rushElapsed = State.GetRush()
		local held = eventBannersHeld()
		-- The rush's edges first (a toast at the start and at the end); the banner slot below still goes to
		-- a running shower, which keeps priority when both are up.
		if rushState.active then
			if held then
				if not rushWasActive then
					rushBannerHeld = true -- it began unseen under the tutorial's hold
				end
			else
				if not rushWasActive or rushBannerHeld then
					if not rushWasActive then
						Builder.playSound(Sounds.RushStart) -- the round begins; a banner that waited for the hold has no second cue
					end
					-- A hold that just lifted releases only the highest-priority banner still running: with a shower on too, the
					-- shower's banner (below) shows and the rush is already in the event chip. A rush that starts later queues behind a
					-- banner on screen (Toast keeps one at a time).
					if not (rushBannerHeld and shower.active) then
						Toast.Banner(Strings.RUSH_NOW, Theme.Colors.Featured, Config.AnnounceSeconds, "rush")
					end
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
			Hud.SetEventBanner(Strings.SHOWER_NOW, Strings.SHOWER_LEFT:format(timeLeftText(shower.secondsLeft - elapsed)), Strings.SHOWER_LUCK:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)), "Shower", true)
			Hud.SetEventCountdown(nil)
			if not showerWasActive then
				Builder.playSound(Sounds.ShowerHorn)
				Vfx.SetShowerSky(true)
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds, "shower")
			elseif showerBannerHeld then
				-- The hold just lifted mid-shower: the banner it kept back shows now, without the horn.
				Toast.Banner(Strings.SHOWER_NOW, Theme.Colors.Codex, Config.AnnounceSeconds, "shower")
			end
			showerBannerHeld = false
			showerWasActive = true
			return
		end
		if showerWasActive then
			Vfx.SetShowerSky(false)
			if not showerBannerHeld then -- a shower the player never saw announced needs no goodbye
				notify("showerOver", Strings.SHOWER_OVER, Theme.Colors.Codex)
			end
		end
		showerWasActive = false
		showerBannerHeld = false
		if held then
			Hud.SetEventBanner(nil, nil, nil)
			Hud.SetEventCountdown(nil)
			return
		end
		-- No shower: a running Catch Rush takes the banner slot, else server luck someone bought, else the season.
		local luckState, luckElapsed = State.GetServerLuck()
		local season = State.GetSeason()
		if rushState.active then
			local own = 0
			for _, row in ipairs(rushState.rows) do
				if row.userId == localPlayer.UserId then
					own = row.catches
				end
			end
			local top = if rushState.rows[1] then rushState.rows[1].catches else 0
			-- no icon for the rush yet: the banner shows its placeholder square
			Hud.SetEventBanner(Strings.RUSH_NOW, Strings.RUSH_LEFT:format(timeLeftText(rushState.secondsLeft - rushElapsed)), Strings.RUSH_SCORE:format(own, top), nil, true)
		elseif luckState and luckState.secondsLeft - luckElapsed > 0 then
			local timeText = timeLeftText(luckState.secondsLeft - luckElapsed)
			local multiplier = ("%d"):format(1 + luckState.bonus)
			-- no icon for server luck yet: the banner shows its placeholder square
			Hud.SetEventBanner(Strings.SERVERLUCK_BANNER:format(multiplier), Strings.SERVERLUCK_LEFT:format(timeText), Strings.SERVERLUCK_CHIP:format(("%.1f"):format(math.floor(State.GetLuck() * 10 + 0.5) / 10)))
		elseif season then
			-- The seasonal event: its name, the days and hours left (the end is on the banner from the first day) and
			-- the overlay it rolls with that overlay's multiplier ("Spectral x2"; %g drops a trailing .0). The weekly
			-- drop waits for the season to end. No icon yet: the banner shows its placeholder square.
			local overlay = season.season.overlay
			local overlayRow = if overlay then Overlays.Overlays[overlay] else nil
			local chip = if overlay and overlayRow then Strings.SEASON_CHIP:format(Builder.text("OVERLAY_" .. overlay), ("%g"):format(overlayRow.multiplier)) else nil
			Hud.SetEventBanner(Builder.text("SEASON_" .. season.season.id), Strings.SEASON_LEFT:format(daysHoursText(season.secondsLeft)), chip, nil)
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
				local subtitle = if elsewhere
					then Strings.WEEKLY_LEFT_ELSEWHERE:format(weeklyName(current), current.drop.worldId, weeklyLeftText(current))
					else Strings.WEEKLY_LEFT:format(weeklyName(current), weeklyLeftText(current))
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
		elseif not Place.IsHome() and not rushState.active and rushState.nextInSeconds > 0 and rushNextIn > 0 and rushNextIn <= CatchRush.WarnSeconds then
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
		notify("weeklyStart", if weather then Strings.WEEKLY_NOW_WEATHER:format(name, weather) else Strings.WEEKLY_NOW:format(name), Theme.Colors.Codex) -- it lasts a week: a toast now, the event chip afterwards
	end
	State.OnChanged("weekly", function()
		announceWeekly()
		refreshEventBanner()
	end)
	State.OnChanged("tutorial", announceWeekly)
	announceWeekly() -- the server's answer may already have landed
	-- The seasonal event says when it starts and when it ends, with a toast. The first value after join (the
	-- server's answer, State.HasSeason) is only remembered, so a player who joins mid-season is not told it began;
	-- after that a different id is news: a new one begins, none after one is the end. A calendar flip reaches
	-- here through State's own clock check, a Dev /season through SeasonChanged.
	local seasonShown: string? = nil
	local seasonShownSet = false
	local function onSeason()
		refreshEventBanner()
		if not State.HasSeason() then
			return
		end
		local current = State.GetSeason()
		local id = if current then current.season.id else nil
		if not seasonShownSet then
			seasonShownSet = true
			seasonShown = id
			return
		end
		if id == seasonShown then
			return
		end
		local previous = seasonShown
		seasonShown = id
		if current then
			local firstWorld = current.season.worldIds[1]
			Toast.Show(Strings.SEASON_NOW:format(Builder.text("SEASON_" .. current.season.id), Builder.text("WORLD_" .. tostring(firstWorld))), Theme.Colors.Codex)
		elseif previous then
			Toast.Show(Strings.SEASON_OVER:format(Builder.text("SEASON_" .. previous)), Theme.Colors.Select)
		end
	end
	State.OnChanged("season", onSeason)
	onSeason() -- the server's answer may already have landed
	-- A bought server luck announces itself once to everyone and then counts down in the banner slot.
	local serverLuckShown: string? = nil
	-- The same announcement as a system line in the general chat (chatLine), so the buyer is named where everyone reads.
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
				notify("serverluck", text, Theme.Colors.Featured)
				if luckState.playerName ~= Strings.ADMIN_LUCK_NAME then
					chatLine(Strings.CHAT_SERVERLUCK_START:format(luckState.playerName, multiplierText))
				end
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
	-- The radar column (Decision B52): a column of shadows on the right edge once a radar is owned (or while a Scanner Pulse runs).
	-- It is presentation of the wild parts the client already sees; nothing on it can be tapped.
	RadarColumn.Build()
	Compass.Start() -- the strip along the top edge; the refresh below shows it with the other HUD extras
	local function refreshRadarTier()
		RadarColumn.SetTier(if State.Has() then State.Get().gear.radar else 0)
	end
	refreshRadarTier()
	State.OnChanged("gear", refreshRadarTier)

	local known: { [string]: boolean } = {}
	for species, entry in pairs(profile.codex) do
		if entry.count > 0 then
			known[species] = true
		end
	end
	WildRenderer.Start(known)
	CampRenderer.OnModuleSnapped(function(_moduleId: string, part: BasePart)
		Vfx.Assemble(part, part.Color) -- the build effect in the module's own colour, as the part pops in
	end)
	CampRenderer.Start()
	HomeRenderer.Start()
	HangarRenderer.Start()
	SightingRenderer.Start()
	CompanionRenderer.Start()
	NodeRenderer.Start()
	Ambience.Start()
	MusicDirector.Start() -- the first clock push below picks the world's bed (the home planet, world 0, plays Home)
	LightingDirector.Start()
	LampDirector.Start() -- the nearest few lantern, glowcap and crystal lights lit and lifted at night (data/Lighting Lamps)
	WeatherFx.Start()
	WorldFx.Start() -- the generated world's ambient effects at their places (mist, sparkle, petals, butterflies, steam, aurora)

	-- The first arrival in this place. A brand-new profile on the tutorial's world opens with the crash landing: the camera
	-- drops from the sky to the wreck while the HUD waits (anything already started, a plate collected or a rejoin, skips it);
	-- the crash is that world's arrival, so Arrival_<world> counts as watched once it ends. Everywhere else the first
	-- arrival of the profile in this world plays its Arrival moment (data/Cinematics): a fly-through from the far side of
	-- the world to an establishing pull-out, ending behind the character. It is marked watched as it starts, so a
	-- rejoin or a flight back never plays it again.
	local arrival = CinematicMath.ArrivalMoment(Place.WorldId())
	if profile.tutorialStep == 1 and profile.tutorialCounter == 0 and Place.WorldId() == TutorialData.World then
		cinematic = true
		Hud.SetVisible(false)
		CameraDirector.CrashLanding(function()
			cinematic = false
			Hud.SetVisible(true)
			if CinematicMath.IsSeenKey(arrival) then
				markSeenKey(arrival)
			end
		end)
	elseif CinematicMath.IsSeenKey(arrival) and CinematicMath.HasMoment(arrival) and not State.HasSeen(arrival) then
		if playCinematic(arrival, nil, nil) then
			markSeenKey(arrival)
		end
	end
	-- Studio's /cinematic <momentId>: play a moment now (the server only fires this in Studio). The Legendary push-in aims
	-- at the nearest wild alien in catch range, or a point that far ahead of the character when none is.
	task.spawn(function()
		Net.event("DevCinematic").OnClientEvent:Connect(function(momentId: any)
			if not CinematicMath.HasMoment(momentId) then
				return
			end
			local context: CameraDirector.ShotContext? = nil
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local near = WildRenderer.Nearest(Config.CaptureInteractDistance)
			if near then
				context = { target = near.Position }
			elseif root and root:IsA("BasePart") then
				context = { target = root.Position + root.CFrame.LookVector * Config.CaptureInteractDistance }
			end
			if not playCinematic(momentId, context, nil) then
				print(("[%s] cinematic %s did not start (a catch, a launch or another camera moment is running)"):format(Config.WorkingTitle, momentId))
			end
		end)
	end)

	State.OnChanged("scrap", function()
		Hud.SetScrap(State.Get().scrap)
	end)
	State.OnChanged("rate", function()
		showRate()
		refreshShip()
	end)
	State.OnChanged("modules", refreshShip)

	-- The world's special weather gets a banner naming its signature alien when it starts.
	local lastWeather: string? = nil
	local blizzardHinted = false -- the hide-and-Heater hint shows once per blizzard
	local function onClock(state: Types.ClockState)
		Hud.SetClock(state)
		State.SetClock(state)
		MusicDirector.SetWorldState(Place.WorldId(), state.isNight) -- the day and night beds crossfade at the clock edge
		-- A blizzard on a Blizzard-rule world hides far aliens; say so once, and say it again next blizzard.
		if blizzardActive() then
			if not blizzardHinted then
				blizzardHinted = true
				notify("blizzard", Strings.BLIZZARD_HINT:format(Config.BlizzardHideStuds), Theme.Colors.Select)
			end
		else
			blizzardHinted = false
		end
		local world = Worlds[State.Get().world.current]
		if world and world.weather.special.speciesId ~= "" and state.weather == world.weather.special.id and lastWeather ~= nil and lastWeather ~= state.weather then
			local def = Species.ById[world.weather.special.speciesId]
			local text = Strings.WEATHER_SPECIAL_BANNER:format(Builder.text("WEATHER_" .. state.weather), if def then def.name else world.weather.special.speciesId)
			notify("specialWeather", text, if def then Builder.tierColor(def.tier) else Theme.Colors.Select, state.weather)
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
	connectAfk()

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
		RadarColumn.SetVisible(not modalOpen() and not cinematic)
		setChatShown(not modalOpen() and not Hud.IsMenuOpen()) -- the Menu drop-down's lower rows sit under it too
		MusicDirector.SetMenuOpen(Screens.IsAnyOpen()) -- a panel lowers the bed
		Toast.SyncPanel() -- a banner already up when a panel opens drops to the bottom slot, off the panel's header
		Toast.SetTop(if Screens.IsAnyOpen() then TOAST_TOP_WITH_PANEL else nil) -- the centre column is gone (the event chip carries events): the stack starts at its default under the banner's slot
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
	-- The engine does not always mark a touch on a button as processed (Studio's touch emulation, 2026-10-07), so a tap
	-- over any visible button or input-sinking frame (the tray's cards, the action button) belongs to the interface
	-- and never reaches the plot. A tap's position includes the top bar's inset; the interface's coordinates do not.
	UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
		if processedByUI or not BuildScreen.IsOpen() then
			return
		end
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local inset = GuiService:GetGuiInset()
			for _, gui in ipairs(playerGui:GetGuiObjectsAtPosition(position.X - inset.X, position.Y - inset.Y)) do
				if gui.Visible and (gui:IsA("GuiButton") or gui.Active) then
					return
				end
			end
		end
		BuildScreen.OnWorldTap(position.X, position.Y, true)
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
