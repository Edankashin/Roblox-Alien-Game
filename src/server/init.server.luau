--!strict
-- Server bootstrap. Loads every service under Services, calls Init on all, then Start on all.
-- Order matters for a few: PlayerData must come first so other services can read profiles;
-- WorldClock before Spawner (conditions), Meadow before Materials and Spawner (floor), Economy
-- before Catching (a catch is granted and seated there), Economy after PlayerData (it listens for
-- loads), Buffs before Shop (Shop registers its WalkSpeed setter with Buffs) and before Catching
-- (Steady Hands widens the zones), Shop after Economy (it shares ScrapChanged and InventoryChanged)
-- and before Catching (lures bought there are spent in a catch), Quests after Meadow, Spawner and
-- Shop (the horn summons the Warden at the shrine through Spawner.SpawnAt; Shop registers its gear
-- grant with Quests) and before Catching (a lost Warden encounter is reported to Quests), Tutorial
-- after Spawner (its trainee aliens are placed through Spawner.SpawnAt) and after Economy and
-- Materials (both report to it, and Economy's offline settlement must run before the tutorial's own
-- load step), Peddler after Economy and Catching (eggs are granted through Economy; the visit clock
-- starts last).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)

type Service = { Init: (() -> ())?, Start: (() -> ())? }

local ORDER = { "PlayerData", "WorldClock", "Meadow", "Materials", "Spawner", "Economy", "Buffs", "Shop", "Quests", "Tutorial", "Catching", "Peddler", "Dev" }

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
