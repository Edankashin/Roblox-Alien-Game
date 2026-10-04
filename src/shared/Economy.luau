--!strict
-- ReplicatedStorage.Shared.Economy: the camp math both sides agree on. The server applies it to the
-- real profile (income, assembly, completion); the client runs the same functions on its mirror to
-- draw rates and extrapolate progress between server pushes. Every number comes from a data table.
-- Mutations (assigning aliens, paying gates) live in the server's Economy service, not here.

local Types = require(script.Parent.types.Types)
local Config = require(script.Parent.data.Config)
local Tiers = require(script.Parent.data.Tiers)
local Overlays = require(script.Parent.data.Overlays)
local Species = require(script.Parent.data.Species)
local Jobs = require(script.Parent.data.Jobs)
local Modules = require(script.Parent.data.Modules)

local Economy = {}

-- Aliens -----------------------------------------------------------------

-- Work speed of one alien: tier speed x overlay multiplier x level bonus. A plain Common at level 1 is 1.
function Economy.workSpeed(record: Types.AlienRecord): number
	local def = Species.ById[record.species]
	if not def then
		return 0
	end
	local tier = Tiers.Tiers[def.tier]
	local overlay = Overlays.Overlays[record.overlay]
	local level = math.max(1, record.level)
	return tier.workSpeed * (if overlay then overlay.multiplier else 1) * (1 + Config.LevelSpeedStep * (level - 1))
end

-- The level this species works a job at, or nil when it cannot work it.
function Economy.jobLevel(def: Types.SpeciesDef, job: string): number?
	for _, entry in ipairs(def.jobs) do
		if entry.job == job then
			return entry.level
		end
	end
	return nil
end

-- Jobs this species can work, best level first, limited to jobs unlocked by the given world.
function Economy.jobsFor(def: Types.SpeciesDef, world: number): { Types.Job }
	local sorted = table.clone(def.jobs)
	table.sort(sorted, function(a, b)
		return a.level > b.level
	end)
	local out: { Types.Job } = {}
	for _, entry in ipairs(sorted) do
		local jobDef = Jobs.Jobs[entry.job]
		if jobDef and jobDef.unlockWorld <= world then
			table.insert(out, entry.job)
		end
	end
	return out
end

-- Stations ---------------------------------------------------------------

-- Camp-wide passive bonus: the sum of tier passives over every owned alien (Legendary +10%, Cosmic +25%).
function Economy.campPassive(profile: Types.Profile): number
	local total = 0
	for _, record in pairs(profile.aliens) do
		local def = Species.ById[record.species]
		if def then
			total += Tiers.Tiers[def.tier].passive
		end
	end
	return total
end

-- Summed work speed of the aliens assigned to a station.
function Economy.stationSpeed(profile: Types.Profile, job: string): number
	local station = profile.stations[job]
	if not station then
		return 0
	end
	local total = 0
	for _, uid in ipairs(station.assigned) do
		local record = profile.aliens[uid]
		if record then
			total += Economy.workSpeed(record)
		end
	end
	return total
end

-- Scrap per second from one station.
function Economy.stationRate(profile: Types.Profile, job: string): number
	return Config.BaseScrapPerSecond * Economy.stationSpeed(profile, job) * (1 + Economy.campPassive(profile))
end

-- Scrap per second from the whole camp.
function Economy.totalRate(profile: Types.Profile): number
	local total = 0
	for _, job in ipairs(Jobs.Order) do
		total += Economy.stationRate(profile, job)
	end
	return total
end

-- Assembly speed for a module of this job: the player's own crew plus the aliens at that job's station.
function Economy.assemblySpeed(profile: Types.Profile, job: string): number
	return Config.AssemblyPlayerSpeed + Economy.stationSpeed(profile, job) * (1 + Economy.campPassive(profile))
end

-- The CampState payload the server pushes on RateChanged.
function Economy.campState(profile: Types.Profile): Types.CampState
	local speeds: { [string]: number } = {}
	for _, job in ipairs(Jobs.Order) do
		speeds[job] = Economy.assemblySpeed(profile, job)
	end
	return { ratePerSecond = Economy.totalRate(profile), assemblySpeed = speeds }
end

-- Offline income for an absence: OfflineRate of the live rate, counting at most OfflineCapSeconds.
function Economy.offlineScrap(profile: Types.Profile, awaySeconds: number): number
	local counted = math.clamp(awaySeconds, 0, Config.OfflineCapSeconds)
	return math.floor(Economy.totalRate(profile) * Config.OfflineRate * counted)
end

-- Modules ----------------------------------------------------------------

function Economy.moduleDefs(worldId: number): { Modules.ModuleDef }
	return Modules.Worlds[worldId] or {}
end

function Economy.moduleDef(worldId: number, moduleId: string): Modules.ModuleDef?
	for _, def in ipairs(Economy.moduleDefs(worldId)) do
		if def.id == moduleId then
			return def
		end
	end
	return nil
end

function Economy.moduleState(profile: Types.Profile, worldId: number, moduleId: string): Types.ModuleProgress?
	local world = profile.modules[tostring(worldId)]
	return if world then world[moduleId] else nil
end

function Economy.isComplete(state: Types.ModuleProgress?): boolean
	return state ~= nil and state.completedAt ~= nil
end

-- Modules build in order. The active one is the first not yet complete; nil once the ship is done.
function Economy.activeModuleIndex(profile: Types.Profile, worldId: number): number?
	for index, def in ipairs(Economy.moduleDefs(worldId)) do
		if not Economy.isComplete(Economy.moduleState(profile, worldId, def.id)) then
			return index
		end
	end
	return nil
end

-- Both gates paid: assembly may start.
function Economy.gatesPaid(def: Modules.ModuleDef, state: Types.ModuleProgress?): boolean
	return state ~= nil and state.scrapPaid >= def.scrap and state.keyPaid >= def.keyCount
end

-- Assembly progress at `now` (a wall clock: os.time() on the server, workspace:GetServerTimeNow() on
-- the client), extrapolated from the last server write at the given assembly speed. Assembly keeps
-- running while the player is offline because this only ever reads the clock.
function Economy.progressAt(def: Modules.ModuleDef, state: Types.ModuleProgress, speed: number, now: number): number
	if state.completedAt then
		return 1
	end
	if not state.started then
		return math.clamp(state.progress, 0, 1)
	end
	local elapsed = math.max(0, now - state.updatedAt)
	return math.clamp(state.progress + elapsed * speed / def.assemblySeconds, 0, 1)
end

-- Seconds until the module completes at this speed; math.huge when it cannot progress.
function Economy.secondsLeft(def: Modules.ModuleDef, state: Types.ModuleProgress, speed: number, now: number): number
	local remaining = 1 - Economy.progressAt(def, state, speed, now)
	if speed <= 0 then
		return math.huge
	end
	return remaining * def.assemblySeconds / speed
end

-- Ship completion 0..1: the weighted sum of module progress.
function Economy.shipPercent(profile: Types.Profile, worldId: number, now: number): number
	local total = 0
	for _, def in ipairs(Economy.moduleDefs(worldId)) do
		local state = Economy.moduleState(profile, worldId, def.id)
		local progress = if state then Economy.progressAt(def, state, Economy.assemblySpeed(profile, def.job), now) else 0
		total += def.weight * progress
	end
	return math.clamp(total, 0, 1)
end

-- Cumulative weight at the end of each module, for tick marks on the ship bar.
function Economy.milestones(worldId: number): { number }
	local out: { number } = {}
	local acc = 0
	for _, def in ipairs(Economy.moduleDefs(worldId)) do
		acc += def.weight
		table.insert(out, acc)
	end
	return out
end

return Economy
