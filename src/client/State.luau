--!strict
-- StarterPlayerScripts.Client.State: the client's mirror of its own profile. The server owns the real
-- one and pushes changes (ScrapChanged, StationsChanged, ModulesChanged, InventoryChanged, RateChanged);
-- this module applies them to the copy and tells screens which topic changed. Nothing here decides
-- anything; it only remembers what the server said last. InventoryChanged carries the whole inventory
-- table (key materials, lures, power-ups); GearChanged carries the gear table.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Economy = require(Shared:WaitForChild("Economy"))
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))

local State = {}

-- "profile" fires once when the whole profile arrives; every topic listener also runs then.
export type Topic = "scrap" | "stations" | "modules" | "inventory" | "gear" | "rate" | "clock" | "biome" | "codex" | "buffs" | "peddler" | "luck" | "profile"

local profile: Types.Profile? = nil
local rate: Types.CampState = { ratePerSecond = 0, assemblySpeed = {} }
local ratePushed = false -- until the server's first RateChanged, the rate is derived from the profile
local clock: Types.ClockState = { isNight = false, weather = "Clear", secondsLeft = 0 }
local biome: Types.Biome = "Meadow"
local buffs: { [string]: number } = {} -- id -> server wall-clock time (os.time scale) the buff ends at
local peddler: Types.PeddlerVisit? = nil
local luck = 1
local changed = Instance.new("BindableEvent")
local started = false

local function fire(topic: Topic)
	changed:Fire(topic)
end

function State.Set(p: Types.Profile)
	profile = p
	if not ratePushed then
		-- A client that booted after the server's pushes still shows the right rate: same shared maths.
		rate = Economy.campState(p)
	end
	fire("profile")
end

function State.Has(): boolean
	return profile ~= nil
end

function State.Get(): Types.Profile
	local p = profile
	assert(p, "State.Get before State.Set")
	return p
end

function State.GetRate(): Types.CampState
	return rate
end

-- The last ClockChanged state the HUD received (the bootstrap feeds it in).
function State.GetClock(): Types.ClockState
	return clock
end

function State.SetClock(state: Types.ClockState)
	clock = state
	fire("clock")
end

-- The single spawn condition the server judges by: Rain beats Night beats Day (mirrors WorldClock).
function State.GetCondition(): Types.Condition
	if clock.weather == "Rain" then
		return "Rain"
	end
	return if clock.isNight then "Night" else "Day"
end

-- The biome the local player stands in (the bootstrap polls Biomes.At and feeds it in).
function State.GetBiome(): Types.Biome
	return biome
end

function State.SetBiome(b: Types.Biome)
	if b ~= biome then
		biome = b
		fire("biome")
	end
end

-- Active power-ups as end times on the server wall clock; compare with State.Now().
function State.GetBuffs(): { [string]: number }
	return buffs
end

-- The current Peddler visit, or nil between visits.
function State.GetPeddler(): Types.PeddlerVisit?
	return peddler
end

function State.GetLuck(): number
	return luck
end

-- Mirrors the server's codex write for a catch the server just confirmed (the CaptureHit result is
-- authoritative; this only keeps the local copy current until the next full profile).
function State.ApplyCatch(species: string, overlay: Types.Overlay)
	local p = profile
	if not p then
		return
	end
	local entry = p.codex[species]
	if not entry then
		entry = { count = 0, bestOverlay = "None", firstCaughtAt = 0 }
		p.codex[species] = entry
	end
	if entry.count == 0 then
		entry.firstCaughtAt = Workspace:GetServerTimeNow()
	end
	entry.count += 1
	local rank = table.find(Overlays.Order, overlay) or 0
	local bestRank = table.find(Overlays.Order, entry.bestOverlay) or 0
	if rank > bestRank then
		entry.bestOverlay = overlay
	end
	fire("codex")
end

-- Server-synced wall clock, comparable with ModuleProgress.updatedAt (os.time() on the server).
function State.Now(): number
	return Workspace:GetServerTimeNow()
end

function State.OnChanged(topic: Topic, fn: () -> ()): RBXScriptConnection
	return changed.Event:Connect(function(fired: Topic)
		if fired == topic or fired == "profile" then
			fn()
		end
	end)
end

-- Connects the server pushes. Each wait runs in its own thread so a remote the server has not
-- created yet never blocks the others.
function State.Start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		Net.event("ScrapChanged").OnClientEvent:Connect(function(scrap: number)
			if profile then
				profile.scrap = scrap
				fire("scrap")
			end
		end)
	end)
	task.spawn(function()
		Net.event("StationsChanged").OnClientEvent:Connect(function(stations: { [string]: Types.StationState }, aliens: { [string]: Types.AlienRecord })
			if profile then
				profile.stations = stations
				profile.aliens = aliens
				fire("stations")
			end
		end)
	end)
	task.spawn(function()
		Net.event("ModulesChanged").OnClientEvent:Connect(function(worldId: number, modules: { [string]: Types.ModuleProgress })
			if profile then
				profile.modules[tostring(worldId)] = modules
				fire("modules")
			end
		end)
	end)
	task.spawn(function()
		Net.event("InventoryChanged").OnClientEvent:Connect(function(inventory: { keyMaterials: { [string]: number }, lures: { [string]: number }, powerUps: { [string]: number } })
			if profile then
				profile.inventory = inventory
				fire("inventory")
			end
		end)
	end)
	task.spawn(function()
		Net.event("GearChanged").OnClientEvent:Connect(function(gear: { boots: boolean, hoverboard: boolean, glider: boolean, radar: number })
			if profile then
				profile.gear = gear
				fire("gear")
			end
		end)
	end)
	task.spawn(function()
		-- BuffsChanged carries seconds remaining per active power-up; stored as end times so the client
		-- can count down between pushes with State.Now().
		Net.event("BuffsChanged").OnClientEvent:Connect(function(remaining: { [string]: number })
			local now = Workspace:GetServerTimeNow()
			local next: { [string]: number } = {}
			for id, seconds in pairs(remaining) do
				next[id] = now + seconds
			end
			buffs = next
			fire("buffs")
		end)
	end)
	task.spawn(function()
		Net.event("PeddlerChanged").OnClientEvent:Connect(function(visit: Types.PeddlerVisit?)
			peddler = visit
			fire("peddler")
		end)
	end)
	task.spawn(function()
		Net.event("LuckChanged").OnClientEvent:Connect(function(value: number)
			luck = value
			fire("luck")
		end)
	end)
	task.spawn(function()
		Net.event("RateChanged").OnClientEvent:Connect(function(state: Types.CampState)
			rate = state
			ratePushed = true
			fire("rate")
		end)
	end)
end

return State
