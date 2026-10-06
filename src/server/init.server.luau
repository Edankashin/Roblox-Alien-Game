--!strict
-- Server bootstrap. Loads every service under Services, calls Init on all, then Start on all.
-- Order matters for a few: PlayerData must come first so other services can read profiles;
-- Analytics right after it (every service reports to it, and it only requires shared data);
-- Friends right after Analytics (the one friendship cache: it needs PlayerData.OnLoaded and Analytics, and Buffs and DailyQuests read it);
-- Monetization right after Friends (it requires only those two and shared data; Economy, Buffs,
-- Shop and Gifts register their Robux granters with it at Init, and its pass check must run before
-- Economy's offline settlement on load); WorldClock before Spawner (conditions), Events right after WorldClock (it switches the Shower
-- condition on that clock and Buffs and Spawner read its luck and Cosmic share), Weekly after WorldClock and Events and before
-- Spawner (Spawner reads its species and overlay; it requires only WorldClock, Analytics and shared code, nothing that requires Spawner), Meadow before
-- Materials and Spawner (floor), Leaderboard after PlayerData and before Economy (Economy reports each
-- catch to it), CatchRush right after Leaderboard (Catching reports each wild catch to it; it requires Gifts, Events, Analytics and PlayerData and nothing
-- that requires Catching, and only uses Gifts when a round ends), Economy
-- before Catching (a catch is granted and seated there), Economy after PlayerData (it listens for
-- loads), Buffs before Shop (Shop registers its WalkSpeed setter with Buffs) and before Catching
-- (Steady Hands widens the zones), Shop after Economy (it shares ScrapChanged and InventoryChanged)
-- and before Catching (lures bought there are spent in a catch), DailyQuests right before Quests (Quests
-- forwards every catch, pickup and craft to it; it requires no service that requires Quests), Quests after Meadow, Spawner and
-- Shop (the horn summons the Warden at the shrine through Spawner.SpawnAt; Shop registers its gear
-- grant with Quests) and before Catching (a lost Warden encounter is reported to Quests), Tutorial
-- after Spawner (its trainee aliens are placed through Spawner.SpawnAt) and after Economy and
-- Materials (both report to it, and Economy's offline settlement must run before the tutorial's own
-- load step), Peddler after Economy and Catching (eggs are granted through Economy; the visit clock
-- starts last), Gifts after Economy and Spawner (the Welcome Week egg is granted through Economy with
-- Spawner's overlay roll) and after PlayerData (it counts the day on load), Social after Gifts (rewards go through Gifts.GrantRewards; its load hook counts the session and pays referrals after Gifts' day count) and Analytics, Codes right after Social (it pays through Gifts.GrantRewards and hands that to DailyQuests at Init), Settings after PlayerData
-- (it writes profile.settings) and before Dev (which stays last), Admin right before Dev (the developer panel; it requires Monetization, Events, WorldClock and Analytics, so all four come first, and nothing requires it), Outposts after Economy and Analytics and before Launch (Launch banks a flight's outpost through it), Launch after Economy (both move the
-- same profile fields through PlayerData; Economy's load settlement creates this world's module states
-- that Launch reads for completeness) and after Analytics (it reports each launch), Heaters after Economy
-- (and so after Meadow, whose Workspace.World its folder lives in, WorldClock, PlayerData and Analytics), Companions after
-- Economy and before Buffs (Buffs registers its luck push with it at Init; it requires only PlayerData, Analytics and Monetization), HomeBuild right after Launch (the house grid on the home planet; it requires only PlayerData, Analytics, Net, Meadow, Economy and Place, and pays Scrap through the same ScrapChanged push), Habitats right after HomeBuild (aliens on display in the home habitats and their lazy Scrap; it requires Economy and Companions, both earlier, and PlayerData's load hook settles it on arriving home), Mail right after Habitats (the home mailbox: it requires PlayerData, Gifts, Analytics and Net and claims through Gifts.GrantRewards; Admin sends letters through it and Dev too, and it registers the MailChanged and MailArrived events), Sightings right after Spawner and
-- after Meadow (its floor and the Workspace.World folder the Warden's part lives in) and Analytics (it counts every player online at a
-- start); it requires nothing that requires it (only Dev does).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)

type Service = { Init: (() -> ())?, Start: (() -> ())? }

local ORDER = { "PlayerData", "Analytics", "Friends", "Monetization", "WorldClock", "Events", "Weekly", "Meadow", "Materials", "Spawner", "Sightings", "Leaderboard", "CatchRush", "Economy", "Companions", "Heaters", "Outposts", "Launch", "HomeBuild", "Habitats", "Mail", "Buffs", "Shop", "DailyQuests", "Quests", "Tutorial", "Catching", "Peddler", "Gifts", "Social", "Codes", "Settings", "Admin", "Dev" }

local servicesFolder = script:WaitForChild("Services")
local services: { [string]: Service } = {}
for _, child in ipairs(servicesFolder:GetChildren()) do
	if child:IsA("ModuleScript") then
		services[child.Name] = require(child) :: Service
	end
end

local sequence: { string } = {}
local seen: { [string]: boolean } = {}
for _, name in ipairs(ORDER) do
	if services[name] then
		table.insert(sequence, name)
		seen[name] = true
	end
end
local rest: { string } = {}
for name in pairs(services) do
	if not seen[name] then
		table.insert(rest, name)
	end
end
table.sort(rest)
for _, name in ipairs(rest) do
	table.insert(sequence, name)
end

for _, name in ipairs(sequence) do
	local svc = services[name]
	if svc.Init then
		svc.Init()
	end
end
for _, name in ipairs(sequence) do
	local svc = services[name]
	if svc.Start then
		svc.Start()
	end
end

print(("[%s] server started: %s"):format(Config.WorkingTitle, table.concat(sequence, ", ")))
