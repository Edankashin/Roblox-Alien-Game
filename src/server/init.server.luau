--!strict
-- Server bootstrap. Loads every service under Services, calls Init on all, then Start on all.
-- Order matters for a few: PlayerData must come first so other services can read profiles;
-- WorldClock before Spawner (conditions), Meadow before Spawner (floor), Spawner before Catching.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)

type Service = { Init: (() -> ())?, Start: (() -> ())? }

local ORDER = { "PlayerData", "WorldClock", "Meadow", "Spawner", "Catching" }

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
