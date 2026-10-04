--!strict
-- Client bootstrap. Milestone 1: confirm the profile arrives. Later milestones add the HUD and screens here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))

Net.event("ProfileLoaded").OnClientEvent:Connect(function(profile)
	local alienCount = 0
	for _ in pairs(profile.aliens) do
		alienCount += 1
	end
	print(("[%s] client: profile loaded. scrap=%d aliens=%d world=%d"):format(Config.WorkingTitle, profile.scrap, alienCount, profile.world.current))
end)

print(("[%s] client started"):format(Config.WorkingTitle))
