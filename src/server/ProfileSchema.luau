--!strict
-- ServerScriptService.Server.ProfileSchema: serialized save defaults and migrations.
-- Dependencies are data tables supplied by PlayerData; no services, yields or persistence.
local ProfileSchema = {}
local SCHEMA_VERSION = 15

function ProfileSchema.new(
	Config: { StationStartSlots: number },
	SettingsData: { Order: { { key: string, kind: "level" | "toggle", levels: { number }?, levelKeys: { string }?, default: number } } },
	Jobs: { Order: { string } }
)
	-- Every preference at its data default (data/Settings.luau).
	local function defaultSettings(): { [string]: number }
		local out: { [string]: number } = {}
		for _, def in ipairs(SettingsData.Order) do
			out[def.key] = def.default
		end
		return out
	end

	-- The social block (data/Social.luau): session count, the one-time group gift, referral state, the last
	-- notifications ask.
	-- One period's dealt quests (data/DailyQuests): empty until the service deals the first set.
	local function emptyPeriodQuests()
		return { period = "", ids = {}, progress = {}, claimed = {}, rerolls = 0 }
	end

	local function defaultSocial()
		return { sessions = 0, groupClaimed = false, referredBy = 0, referralClaimed = false, referralsRewarded = 0, notifyAskedAt = 0 }
	end

	local function template(): any
		local stations: { [string]: { slots: number, assigned: { string } } } = {}
		for _, job in ipairs(Jobs.Order) do
			stations[job] = { slots = Config.StationStartSlots, assigned = {} }
		end
		return {
			version = SCHEMA_VERSION,
			scrap = 0,
			aliens = {},
			stations = stations,
			modules = {},
			world = { current = 1, unlocked = { 1 }, outposts = {} },
			codex = {},
			gear = { boots = false, hoverboard = false, glider = false, radar = 0 },
			companions = {},
			companionSlots = 0,
			home = { unlocked = false, visits = 0, items = {}, habitatSettled = 0, mail = {}, visitors = {}, waves = { day = 0, sent = 0, got = 0 } },
			quests = { daily = emptyPeriodQuests(), weekly = emptyPeriodQuests(), fieldNotes = {}, progress = {} },
			gifts = { daysPlayed = 0, claimed = {}, lastPlayDay = 0 },
			spins = { free = 1, banked = 0, lastFree = 0 },
			luck = { pity = 0 },
			purchases = {},
			shop = { starterSpecies = nil, receipts = {} },
			buffs = {},
			inventory = { keyMaterials = {}, lures = {}, powerUps = {}, items = {} },
			stats = { catches = 0, perfects = 0, playSeconds = 0 },
			settings = defaultSettings(),
			tutorialStep = 1,
			social = defaultSocial(),
			codes = {},
			seasons = {},
			tutorialCounter = 0,
			lastSeen = 0,
			firstSeen = 0,
			lock = nil,
		}
	end

	-- Migrations run in order from the saved version up to SCHEMA_VERSION. Add one entry per bump.
	local migrations: { [number]: (any) -> any } = {
		-- v2: quest objective progress and a general item bag (the Warden's Horn)
		[2] = function(data)
			data.quests = data.quests or {}
			data.quests.progress = data.quests.progress or {}
			data.inventory = data.inventory or {}
			data.inventory.items = data.inventory.items or {}
			return data
		end,
		-- v3: player preferences (the Settings screen); unknown keys are dropped, missing ones take the default
		[3] = function(data)
			local saved = if type(data.settings) == "table" then data.settings else {}
			local settings = defaultSettings()
			for key, value in pairs(saved) do
				if settings[key] ~= nil and type(value) == "number" then
					settings[key] = value
				end
			end
			data.settings = settings
			return data
		end,
		-- v4: the Robux shop's receipt memory and the Starter Pack choice
		[4] = function(data)
			local shop = if type(data.shop) == "table" then data.shop else {}
			shop.receipts = if type(shop.receipts) == "table" then shop.receipts else {}
			data.shop = shop
			return data
		end,
		-- v5: the social block (group gift, referrals, the notifications ask)
		[5] = function(data)
			local saved = if type(data.social) == "table" then data.social else {}
			local social = defaultSocial()
			for key, value in pairs(saved) do
				if social[key] ~= nil and type(value) == type(social[key]) then
					social[key] = value
				end
			end
			data.social = social
			return data
		end,
		-- v6: dealt daily and weekly quests replace the old count maps; redeemed promo codes
		[6] = function(data)
			local quests = if type(data.quests) == "table" then data.quests else {}
			quests.daily = emptyPeriodQuests()
			quests.weekly = emptyPeriodQuests()
			quests.fieldNotes = if type(quests.fieldNotes) == "table" then quests.fieldNotes else {}
			quests.progress = if type(quests.progress) == "table" then quests.progress else {}
			data.quests = quests
			data.codes = if type(data.codes) == "table" then data.codes else {}
			return data
		end,
		-- v7: every alien record carries a size band (data/Sizes); older records are Normal
		[7] = function(data)
			local aliens = if type(data.aliens) == "table" then data.aliens else {}
			for _, record in pairs(aliens) do
				if type(record) == "table" and type(record.size) ~= "string" then
					record.size = "Normal"
				end
			end
			data.aliens = aliens
			return data
		end,
		-- v8: every alien record carries its time worked at a station (data/Growth stages); older records start at 0
		[8] = function(data)
			local aliens = if type(data.aliens) == "table" then data.aliens else {}
			for _, record in pairs(aliens) do
				if type(record) == "table" and type(record.workedSeconds) ~= "number" then
					record.workedSeconds = 0
				end
			end
			data.aliens = aliens
			return data
		end,
		-- v9: companions follow the player; the token-bought slot count starts at 0 and the list is kept when it exists
		[9] = function(data)
			if type(data.companions) ~= "table" then
				data.companions = {}
			end
			if type(data.companionSlots) ~= "number" then
				data.companionSlots = 0
			end
			return data
		end,
		-- v10: the home planet; a profile that has launched already (two unlocked worlds) owns its home at once
		[10] = function(data)
			if type(data.home) ~= "table" then
				local unlocked = if type(data.world) == "table" and type(data.world.unlocked) == "table" then data.world.unlocked else {}
				data.home = { unlocked = #unlocked >= 2, visits = 0 }
			end
			return data
		end,
		-- v11: the house grid; a home without an items table gets an empty one
		[11] = function(data)
			if type(data.home) ~= "table" then
				data.home = { unlocked = false, visits = 0 }
			end
			if type(data.home.items) ~= "table" then
				data.home.items = {}
			end
			return data
		end,
		-- v12: habitats; the payout clock starts at the migration (nothing owed for the time before)
		[12] = function(data)
			if type(data.home) ~= "table" then
				data.home = { unlocked = false, visits = 0, items = {} }
			end
			if type(data.home.habitatSettled) ~= "number" then
				data.home.habitatSettled = os.time()
			end
			return data
		end,
		-- v13: the mailbox and the Visitor Book start empty
		[13] = function(data)
			if type(data.home) ~= "table" then
				data.home = { unlocked = false, visits = 0, items = {}, habitatSettled = os.time() }
			end
			if type(data.home.mail) ~= "table" then
				data.home.mail = {}
			end
			if type(data.home.visitors) ~= "table" then
				data.home.visitors = {}
			end
			return data
		end,
		-- v14: visiting; today's wave tally starts empty
		[14] = function(data)
			if type(data.home) ~= "table" then
				data.home = { unlocked = false, visits = 0, items = {}, habitatSettled = os.time(), mail = {}, visitors = {} }
			end
			if type(data.home.waves) ~= "table" then
				data.home.waves = { day = 0, sent = 0, got = 0 }
			end
			return data
		end,
		-- v15: seasonal events; the tracks start empty
		[15] = function(data)
			if type(data.seasons) ~= "table" then
				data.seasons = {}
			end
			return data
		end,
	}

	-- A save written by a newer version of the game (a server still running old code during an update) is returned
	-- untouched: this code does not know its fields, so it neither migrates nor fills it. tryLoad refuses to own such a
	-- save, so it is never written back by old code.
	local function isFromTheFuture(data: any): boolean
		return (tonumber(data.version) or 1) > SCHEMA_VERSION
	end

	local function migrate(data: any): any
		if isFromTheFuture(data) then
			return data :: any
		end
		local version = tonumber(data.version) or 1
		while version < SCHEMA_VERSION do
			local step = migrations[version + 1]
			if step then
				data = step(data)
			end
			version += 1
			data.version = version
		end
		-- fill any missing top-level fields from the template without touching existing values
		local fresh = template()
		for k, v in pairs(fresh) do
			if data[k] == nil then
				data[k] = v
			end
		end
		return data :: any
	end

	return {
		SCHEMA_VERSION = SCHEMA_VERSION,
		template = template,
		migrations = migrations,
		migrate = migrate,
		isFromTheFuture = isFromTheFuture,
	}
end

return ProfileSchema
