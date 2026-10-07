--!strict
-- ServerScriptService.Server.Services.Seasons: the seasonal event (data/Seasons) on the server's wall clock.
-- Which season runs is a pure function of os.time() and the data tables (Shared/SeasonMath), so every server in
-- the game agrees and only the quest track's progress is saved (profile.seasons[id]). This service reads that
-- function at Start and then every Seasons.PushSeconds, and when the season changes (it begins, it ends, or Dev's
-- /season forces one) it acts once: it scales the nights through WorldClock.SetNightScale, tells every client through
-- SeasonChanged (the override; each client recomputes the season from SeasonMath with the server time), reports
-- SeasonStart to Analytics for every player online and prints one line. A late joiner asks GetSeason once for the
-- override. Spawner reads EventSpecies, ReturningHere, OverlayActive and the two chances for the event aliens, the
-- Vault Rotation's returning species and the event overlay, and IsEventSpawn for the condition-despawn exemption.
-- The track: Catching reports each wild catch (OnCatch) and a Meteor Shower that ends reports itself (OnShowerEnded,
-- registered with Events at Init); each counts into profile.seasons[id].progress and pushes SeasonProgressChanged.
-- ClaimSeasonQuest marks a finished quest claimed first, then pays: the Scrap, lure, spin and power-up rows through
-- the reward granter (Gifts.GrantRewards) and each alien row through the alien granter (Economy.GrantAlien, the one
-- door an alien enters a profile through), the last alien's Reveal payload going back to the client. The client
-- renders the banner, the tab and the Reveal; it never counts, never claims on its own and never decides a thing.
-- It never decides what an overlay is worth or how a spawn is rolled (Overlays, Spawner).
--
-- Requires run one way: this module requires PlayerData, Analytics, WorldClock, Events, Net, Place and shared code
-- only. Spawner, Catching, Gifts and Dev require this module, and Economy requires Spawner, so this module cannot
-- require Economy: Gifts hands over Gifts.GrantRewards and Economy.GrantAlien through SetRewardGranter and
-- SetAlienGranter at Init (the way Codes does for DailyQuests).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local SeasonsData = require(Shared.data.Seasons)
local Species = require(Shared.data.Species)
local AnalyticsData = require(Shared.data.Analytics)
local SeasonMath = require(Shared.SeasonMath)
local Strings = require(Shared.strings.en)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local WorldClock = require(script.Parent.WorldClock)
local Events = require(script.Parent.Events)

local Seasons = {}

type RewardGranter = (Player, { any }) -> boolean
type AlienGranter = (Player, string, Types.Overlay, boolean, string?) -> Types.GrantResult?
type Matcher = (SeasonsData.Objective) -> boolean

local SNAPSHOT_RATE_PER_SECOND = 2 -- GetSeason and GetSeasonProgress calls per player per second
local CLAIM_RATE_PER_SECOND = 2 -- ClaimSeasonQuest calls per player per second

local override: string? = nil -- the season id Dev's /season forces on; nil in play
local current: SeasonMath.Current? = nil -- the season as of the last read
local hasRead = false -- whether a read has been acted on yet (the first one always counts as a change)
local readOverride: string? = nil -- the override the last acted-on read used
local eventHere: { string } = table.freeze({}) -- the running season's event species when this world is one of its worlds
local returningHere: { string } = table.freeze({}) -- the running season's returning species that belong to this world
local rewardGranter: RewardGranter? = nil -- Gifts.GrantRewards, registered by Gifts at Init
local alienGranter: AlienGranter? = nil -- Economy.GrantAlien, registered by Gifts at Init

local function emptyState(): Types.SeasonProgress
	return { progress = {}, claimed = {} }
end

local function nameOf(season: SeasonsData.Season): string
	local named = (Strings :: any)["SEASON_" .. season.id]
	return if type(named) == "string" then named else season.id
end

-- The season as one line: "Haunted Nebula on (2 event aliens, Spectral 3%, nights x2, returns Panpipe)".
local function describe(state: SeasonMath.Current?): string
	if not state then
		return "no event"
	end
	local season = state.season
	local parts: { string } = { ("%d event aliens"):format(#season.species) }
	if season.overlay then
		table.insert(parts, ("%s %g%%"):format(season.overlay, season.overlayChance))
	end
	table.insert(parts, ("nights x%g"):format(season.nightScale))
	table.insert(parts, "returns " .. (if #season.returns > 0 then table.concat(season.returns, ", ") else "nothing"))
	return ("%s on (%s)"):format(nameOf(season), table.concat(parts, ", "))
end

-- Rebuilds the two species lists Spawner reads every roll, so the roll itself allocates nothing.
local function refreshLists()
	local events: { string } = {}
	local returning: { string } = {}
	local state = current
	if state then
		local season = state.season
		local worldId = Place.WorldId()
		if table.find(season.worldIds, worldId) ~= nil then
			for _, id in ipairs(season.species) do
				table.insert(events, id)
			end
		end
		for _, id in ipairs(season.returns) do
			local def = Species.ById[id]
			if def and def.world == worldId then
				table.insert(returning, id)
			end
		end
	end
	eventHere = table.freeze(events)
	returningHere = table.freeze(returning)
end

-- Reads the season from the clock. Anything new (a different season, a different override, or the first read) is
-- acted on once: the night scale, the SeasonChanged broadcast, one SeasonStart per player online when a season
-- begins, one print.
local function read()
	local fresh = SeasonMath.Current(os.time(), override)
	local freshId = if fresh then fresh.season.id else nil
	local oldId = if current then current.season.id else nil
	local seasonChanged = not hasRead or freshId ~= oldId
	local overrideChanged = readOverride ~= override
	current = fresh
	if not seasonChanged and not overrideChanged then
		return
	end
	hasRead = true
	readOverride = override

	refreshLists()
	WorldClock.SetNightScale(if fresh then fresh.season.nightScale else 1)
	Net.event("SeasonChanged"):FireAllClients(override)
	if seasonChanged and fresh then
		for _, player in ipairs(Players:GetPlayers()) do
			Analytics.Event(player, AnalyticsData.Events.SeasonStart, 1, { id = fresh.season.id })
		end
	end
	print(("[%s] Seasons: %s"):format(Config.WorkingTitle, describe(fresh)))
end

-- Progress ----------------------------------------------------------------

-- The player's track state for a season, created empty in the profile when missing. Runs inside PlayerData.Update.
local function stateIn(profile: Types.Profile, seasonId: string): Types.SeasonProgress
	local state = profile.seasons[seasonId]
	if not state then
		state = emptyState()
		profile.seasons[seasonId] = state
	end
	return state
end

-- Tells the player's client its track state for the season (an empty one when it has none yet).
local function push(player: Player, seasonId: string)
	local profile = PlayerData.Get(player)
	if profile then
		Net.event("SeasonProgressChanged"):FireClient(player, seasonId, profile.seasons[seasonId] or emptyState())
	end
end

-- Counts one toward every unclaimed track quest whose objective `matches`, never past its count. True when
-- anything moved.
local function bump(season: SeasonsData.Season, state: Types.SeasonProgress, matches: Matcher): boolean
	local changed = false
	for _, quest in ipairs(season.track) do
		if not state.claimed[quest.id] and matches(quest.objective) then
			local have = state.progress[quest.id] or 0
			if have < quest.objective.count then
				state.progress[quest.id] = have + 1
				changed = true
			end
		end
	end
	return changed
end

-- Counts `matches` into the player's track for `season` in one profile update; pushes when anything moved.
local function advance(player: Player, season: SeasonsData.Season, matches: Matcher)
	local changed = false
	local ok = PlayerData.Update(player, function(profile)
		changed = bump(season, stateIn(profile, season.id), matches)
	end)
	if ok and changed then
		push(player, season.id)
	end
end

local function findQuest(season: SeasonsData.Season, questId: string): SeasonsData.Quest?
	for _, quest in ipairs(season.track) do
		if quest.id == questId then
			return quest
		end
	end
	return nil
end

-- Remotes -----------------------------------------------------------------

-- GetSeason() -> override. The only thing a late joiner needs besides the server time; nil also when rate limited.
local function onGetSeason(player: Player): string?
	if not Net.allow(player, "GetSeason", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return override
end

-- GetSeasonProgress() -> (seasonId, state) for the running season: an empty state when the player has none yet (or
-- no profile yet; the push on load follows), nil, nil when no season runs or when rate limited.
local function onGetSeasonProgress(player: Player): (string?, Types.SeasonProgress?)
	if not Net.allow(player, "GetSeasonProgress", SNAPSHOT_RATE_PER_SECOND) then
		return nil, nil
	end
	local running = current
	if not running then
		return nil, nil
	end
	local seasonId = running.season.id
	local profile = PlayerData.Get(player)
	local state = if profile then profile.seasons[seasonId] else nil
	return seasonId, state or emptyState()
end

-- Takes a claim back after a payment the granter refused, so the player can try again.
local function unmark(player: Player, seasonId: string, questId: string)
	PlayerData.Update(player, function(profile)
		local state = profile.seasons[seasonId]
		if state then
			state.claimed[questId] = nil
		end
	end)
end

-- ClaimSeasonQuest(questId) -> (ok, reason, grant). Pays a finished track quest once. Reasons: BadArgs,
-- RateLimited, NoProfile, NoSeason, Unknown (not in the running season's track), Claimed, NotDone, Refused (the
-- reward granter answered false). The claim is marked first, in one profile update, so a second call in the same
-- frame finds it taken; then the non-alien rows pay through the reward granter in one call (a false answer unmarks
-- the claim) and each alien row through the alien granter. `grant` is the last alien's Reveal payload, nil when the
-- quest pays no alien.
local function onClaim(player: Player, questId: any): (boolean, string?, Types.GrantResult?)
	if type(questId) ~= "string" then
		return false, "BadArgs", nil
	end
	if not Net.allow(player, "ClaimSeasonQuest", CLAIM_RATE_PER_SECOND) then
		return false, "RateLimited", nil
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile", nil
	end
	local running = current
	if not running then
		return false, "NoSeason", nil
	end
	local season = running.season
	local found = findQuest(season, questId)
	if not found then
		return false, "Unknown", nil
	end
	local quest: SeasonsData.Quest = found

	local reason: string? = nil
	local ok = PlayerData.Update(player, function(profile)
		local state = stateIn(profile, season.id)
		if state.claimed[quest.id] then
			reason = "Claimed"
		elseif not SeasonMath.TrackDone(quest, state.progress) then
			reason = "NotDone"
		else
			state.claimed[quest.id] = true
		end
	end)
	if not ok then
		return false, "NoProfile", nil
	end
	if reason ~= nil then
		return false, reason, nil
	end

	local rows: { any } = {}
	local aliens: { string } = {}
	for _, reward in ipairs(quest.rewards) do
		if reward.kind == "alien" then
			local id = reward.id
			if id then
				for _ = 1, math.max(1, math.floor(reward.amount)) do
					table.insert(aliens, id)
				end
			end
		else
			table.insert(rows, reward)
		end
	end

	if #rows > 0 then
		local grant = rewardGranter
		if not grant then
			warn(("[%s] Seasons: no reward granter registered (Gifts.Init), %s not paid"):format(Config.WorkingTitle, quest.id))
		end
		if not grant or not grant(player, rows) then
			unmark(player, season.id, quest.id)
			return false, "Refused", nil
		end
	end

	local result: Types.GrantResult? = nil
	for _, speciesId in ipairs(aliens) do
		local give = alienGranter
		local got = if give then give(player, speciesId, "None", false, nil) else nil
		if got then
			result = got
		else
			warn(("[%s] Seasons: %s's alien %s was not granted"):format(Config.WorkingTitle, quest.id, speciesId))
		end
	end

	Analytics.Event(player, AnalyticsData.Events.SeasonClaim, 1, { id = season.id, quest = quest.id })
	print(("[%s] Seasons: %s claimed %s (%s)"):format(Config.WorkingTitle, player.Name, quest.id, season.id))
	push(player, season.id)
	return true, nil, result
end

-- Public API -------------------------------------------------------------

-- Gifts.GrantRewards, registered by Gifts at Init (see the header).
function Seasons.SetRewardGranter(callback: RewardGranter)
	rewardGranter = callback
end

-- Economy.GrantAlien, registered by Gifts at Init (see the header).
function Seasons.SetAlienGranter(callback: AlienGranter)
	alienGranter = callback
end

-- The season as of the last read (at most SeasonsData.PushSeconds old), nil when none runs or before Start.
function Seasons.Current(): SeasonMath.Current?
	return current
end


-- Developer override (Dev's /season): forces the season with this id on (nil goes back to the calendar) and
-- re-reads at once, so the clock, the clients and the Spawner follow within the same frame. An unknown id is ignored.
function Seasons.SetOverride(id: string?)
	if id ~= nil and SeasonMath.Find(id) == nil then
		warn(("[%s] Seasons: no season with id %s"):format(Config.WorkingTitle, id))
		return
	end
	override = id
	read()
end

-- The running season's event species when this place's world is one of its worlds, else {}. Read-only.
function Seasons.EventSpecies(): { string }
	return eventHere
end

-- The share of this world's wild spawns that is an event species (0 when no season runs).
function Seasons.SpawnChance(): number
	local state = current
	return if state then state.season.spawnChance else 0
end

-- The share of wild spawns that is a returning species (0 when no season runs).
function Seasons.ReturnChance(): number
	local state = current
	return if state then state.season.returnChance else 0
end

-- The running season's returning species (the Vault Rotation) that belong to this place's world. Read-only.
function Seasons.ReturningHere(): { string }
	return returningHere
end

-- The event overlay and its percent chance on a wild spawn when this place's world is an event world, else nil, 0.
function Seasons.OverlayActive(): (string?, number)
	local state = current
	if state and table.find(state.season.worldIds, Place.WorldId()) ~= nil then
		local overlay = state.season.overlay
		if overlay then
			return overlay, state.season.overlayChance
		end
	end
	return nil, 0
end

-- Whether `species` is an event species of the running season or one it brings back: exempt from the condition
-- despawn (Wisplet and Spookum need Night, Panpipe's condition is Quest, which no clock ever offers).
function Seasons.IsEventSpawn(species: string): boolean
	local state = current
	if not state then
		return false
	end
	local season = state.season
	return table.find(season.species, species) ~= nil or table.find(season.returns, species) ~= nil
end

-- Catching reports a won wild catch: the species and the overlay it carried. Counts catchEvent (an event species of
-- the running season), catchOverlay (the season's overlay) and catchCount (any catch); never showerCount.
function Seasons.OnCatch(player: Player, species: string, overlay: string)
	local running = current
	if not running then
		return
	end
	local season = running.season
	local isEvent = table.find(season.species, species) ~= nil
	local isOverlay = season.overlay ~= nil and overlay == season.overlay
	advance(player, season, function(objective: SeasonsData.Objective): boolean
		local kind = objective.kind
		if kind == "catchEvent" then
			return isEvent
		elseif kind == "catchOverlay" then
			return isOverlay
		elseif kind == "catchCount" then
			return true
		end
		return false
	end)
end

-- A Meteor Shower ended while this player was online (registered with Events at Init). Counts showerCount.
function Seasons.OnShowerEnded(player: Player)
	local running = current
	if not running then
		return
	end
	advance(player, running.season, function(objective: SeasonsData.Objective): boolean
		return objective.kind == "showerCount"
	end)
end

-- Studio only (Dev /season done): every unclaimed quest of the running season is at its count.
function Seasons.DevComplete(player: Player)
	local running = current
	if not running then
		return
	end
	local season = running.season
	local ok = PlayerData.Update(player, function(profile)
		local state = stateIn(profile, season.id)
		for _, quest in ipairs(season.track) do
			if not state.claimed[quest.id] then
				state.progress[quest.id] = quest.objective.count
			end
		end
	end)
	if ok then
		push(player, season.id)
	end
end

function Seasons.Init()
	Net.event("SeasonChanged")
	Net.event("SeasonProgressChanged")
	Net.func("GetSeason").OnServerInvoke = onGetSeason
	Net.func("GetSeasonProgress").OnServerInvoke = onGetSeasonProgress
	Net.func("ClaimSeasonQuest").OnServerInvoke = onClaim

	Events.OnShowerChanged(function(active: boolean)
		if active then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if PlayerData.Get(player) then
				Seasons.OnShowerEnded(player)
			end
		end
	end)

	-- The client may have asked for its track before the profile loaded; this push covers it.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		local running = current
		if running then
			push(player, running.season.id)
		end
	end)
end

function Seasons.Start()
	read()
	task.spawn(function()
		while true do
			task.wait(SeasonsData.PushSeconds)
			read()
		end
	end)
end

return Seasons
