--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.data.Config)
local Settings = require(Shared.data.Settings)
local Jobs = require(Shared.data.Jobs)
local Sizes = require(Shared.data.Sizes)
local F = require(script.Parent.Fixtures)
local Schema = require(script.Parent.Parent.src.server.ProfileSchema).new(Config, Settings, Jobs)

local function clone(value)
	if type(value) ~= "table" then return value end
	local out = {}
	for key, child in pairs(value) do out[key] = clone(child) end
	return out
end

local function same(actual, expected)
	expect(type(actual)).toEqual(type(expected))
	if type(expected) ~= "table" then
		expect(actual).toEqual(expected)
		return
	end
	for key, child in pairs(expected) do same(actual[key], child) end
	for key in pairs(actual) do expect(expected[key] ~= nil).toEqual(true) end
end

-- v1 had the original inventory bags and quest count maps. v2 adds only items
-- and progress inside those blocks; missing top-level fields are template-filled.
local function v1()
	return {
		version = F.one,
		quests = { daily = {}, weekly = {}, fieldNotes = {} },
		inventory = { keyMaterials = {}, lures = {}, powerUps = {} },
		world = { current = F.one, unlocked = { F.one }, outposts = {} },
	}
end

-- Explicit Types.Profile shape, independent of template() so omitting a template
-- field fails. Optional lock/starterSpecies are checked separately below.
local shape = {
	version = "number", scrap = "number", aliens = "table", stations = "table", modules = "table",
	world = { current = "number", unlocked = "table", outposts = "table" },
	codex = "table", gear = { boots = "boolean", hoverboard = "boolean", glider = "boolean", radar = "number" },
	companions = "table", companionSlots = "number",
	home = { unlocked = "boolean", visits = "number", items = "table", habitatSettled = "number",
		mail = "table", visitors = "table", waves = { day = "number", sent = "number", got = "number" } },
	quests = { daily = { period = "string", ids = "table", progress = "table", claimed = "table", rerolls = "number" },
		weekly = { period = "string", ids = "table", progress = "table", claimed = "table", rerolls = "number" },
		fieldNotes = "table", progress = "table" },
	gifts = { daysPlayed = "number", claimed = "table", lastPlayDay = "number" },
	playtime = { day = "number", seconds = "number", claimed = "table" },
	spins = { free = "number", banked = "number", lastFree = "number" }, luck = { pity = "number" },
	purchases = "table", shop = { receipts = "table" }, buffs = "table",
	inventory = { keyMaterials = "table", lures = "table", powerUps = "table", items = "table" },
	stats = { catches = "number", perfects = "number", playSeconds = "number" }, settings = "table",
	tutorialStep = "number", social = { sessions = "number", groupClaimed = "boolean", referredBy = "number",
		referralClaimed = "boolean", referralsRewarded = "number", notifyAskedAt = "number" },
	codes = "table", seasons = "table", tutorialCounter = "number", lastSeen = "number", firstSeen = "number",
}
local function assertShape(value, expected)
	for key, kind in pairs(expected) do
		if type(kind) == "table" then
			expect(type(value[key])).toEqual("table")
			assertShape(value[key], kind)
		else expect(type(value[key])).toEqual(kind) end
	end
end

-- These are schema step identities, not balance expectations.
local settingsVersion = F.two + F.one -- v3
local homeVersion = (F.two + F.one) * (F.two + F.one) + F.one -- v10
local habitatVersion = homeVersion + F.two -- v12
local mailVersion = habitatVersion + F.one -- v13
local waveVersion = mailVersion + F.one -- v14
local seasonVersion = waveVersion + F.one -- v15
local playtimeVersion = seasonVersion + F.one -- v16

describe("ProfileSchema", function()
	it("minimal v1 fills every required Profile field with the right type", function()
		local profile = Schema.migrate(v1())
		expect(profile.version).toEqual(Schema.SCHEMA_VERSION)
		assertShape(profile, shape)
		expect(profile.lock).toEqual(nil)
		expect(profile.shop.starterSpecies).toEqual(nil)
		for _, job in ipairs(Jobs.Order) do
			expect(profile.stations[job].slots).toEqual(Config.StationStartSlots)
			same(profile.stations[job].assigned, {})
		end
		for _, setting in ipairs(Settings.Order) do expect(profile.settings[setting.key]).toEqual(setting.default) end
	end)
	it("migrate(template()) preserves all fields and table identity", function()
		local profile = Schema.template()
		local before = clone(profile)
		expect(Schema.migrate(profile)).toEqual(profile)
		same(profile, before)
	end)
	it("templates own independent nested tables", function()
		local a, b = Schema.template(), Schema.template()
		a.home.items.probe = { itemId = "test" }
		a.stations[Jobs.Order[F.one]].assigned[F.one] = "test"
		expect(next(b.home.items)).toEqual(nil)
		expect(next(b.stations[Jobs.Order[F.one]].assigned)).toEqual(nil)
	end)
	local versions = {}
	for version in pairs(Schema.migrations) do table.insert(versions, version) end
	table.sort(versions)
	for _, version in ipairs(versions) do
		it("step v" .. tostring(version) .. " is idempotent on its migrated result", function()
			local profile = v1()
			for _, previous in ipairs(versions) do
				if previous > version then break end
				profile = Schema.migrations[previous](profile)
			end
			local before = clone(profile)
			expect(Schema.migrations[version](profile)).toEqual(profile)
			same(profile, before)
		end)
	end
	it("v3 drops unknown settings, keeps numeric known values, defaults missing/invalid ones", function()
		local def = Settings.Order[F.one]
		local value = def.levels[#def.levels]
		local saved = { settings = { [def.key] = value, UnknownSetting = F.one } }
		Schema.migrations[settingsVersion](saved)
		expect(saved.settings.UnknownSetting).toEqual(nil)
		for _, row in ipairs(Settings.Order) do
			expect(saved.settings[row.key]).toEqual(if row.key == def.key then value else row.default)
		end
		local invalid = { settings = { [def.key] = "bad" } }
		Schema.migrations[settingsVersion](invalid)
		expect(invalid.settings[def.key]).toEqual(def.default)
	end)
	it("v10 unlocks a missing home only after a launch", function()
		for _, worlds in ipairs({ { F.one }, { F.one, F.two } }) do
			local saved = { world = { unlocked = worlds } }
			Schema.migrations[homeVersion](saved)
			expect(saved.home.unlocked).toEqual(#worlds >= F.two)
		end
		local existing = { home = { unlocked = false, visits = F.one }, world = { unlocked = { F.one, F.two } } }
		local before = clone(existing)
		Schema.migrations[homeVersion](existing)
		same(existing, before)
	end)
	it("v12 timestamps new habitats once and preserves an existing clock", function()
		local saved = { home = {} }
		local before = os.time()
		Schema.migrations[habitatVersion](saved)
		expect(saved.home.habitatSettled >= before and saved.home.habitatSettled <= os.time()).toEqual(true)
		saved.home.habitatSettled = F.tick
		Schema.migrations[habitatVersion](saved)
		expect(saved.home.habitatSettled).toEqual(F.tick)
	end)
	it("v13 mail and visitors start empty and existing entries survive", function()
		local saved = { home = {} }
		Schema.migrations[mailVersion](saved)
		same(saved.home.mail, {})
		same(saved.home.visitors, {})
		saved.home.mail.probe = "mail"
		saved.home.visitors.probe = "visitor"
		local before = clone(saved)
		Schema.migrations[mailVersion](saved)
		same(saved, before)
	end)
	it("v14 initializes the empty wave tally; v15 initializes seasons", function()
		local saved = { home = {} }
		Schema.migrations[waveVersion](saved)
		same(saved.home.waves, { day = F.zero, sent = F.zero, got = F.zero })
		Schema.migrations[seasonVersion](saved)
		same(saved.seasons, {})
		saved.seasons.probe = { progress = F.one }
		local before = clone(saved)
		Schema.migrations[seasonVersion](saved)
		same(saved, before)
	end)
	it("v16 starts today's playtime empty and keeps a saved count and its claims", function()
		local saved = {}
		Schema.migrations[playtimeVersion](saved)
		same(saved.playtime, { day = F.zero, seconds = F.zero, claimed = {} })
		saved.playtime.day = F.tick
		saved.playtime.seconds = F.tick + F.one
		saved.playtime.claimed[tostring(F.one)] = true
		local before = clone(saved)
		Schema.migrations[playtimeVersion](saved)
		same(saved, before)
		local damaged = { playtime = { day = "x", seconds = F.tick, claimed = "no" } }
		Schema.migrations[playtimeVersion](damaged)
		same(damaged.playtime, { day = F.zero, seconds = F.tick, claimed = {} })
	end)
	it("legacy alien size and worked time are added without losing saved values", function()
		local saved = v1()
		saved.aliens = { old = {}, kept = { size = Sizes.Default, workedSeconds = F.tick } }
		Schema.migrate(saved)
		expect(saved.aliens.old.size).toEqual(Sizes.Default)
		expect(saved.aliens.old.workedSeconds).toEqual(F.zero)
		expect(saved.aliens.kept.size).toEqual(Sizes.Default)
		expect(saved.aliens.kept.workedSeconds).toEqual(F.tick)
	end)
	it("future numeric and string versions return untouched, even with missing fields", function()
		for _, version in ipairs({ Schema.SCHEMA_VERSION + F.one, tostring(Schema.SCHEMA_VERSION + F.one) }) do
			local saved = { version = version, future = { marker = "keep", value = F.tick } }
			local nested = saved.future
			local before = clone(saved)
			expect(Schema.isFromTheFuture(saved)).toEqual(true)
			expect(Schema.migrate(saved)).toEqual(saved)
			expect(saved.future).toEqual(nested)
			same(saved, before)
		end
		expect(Schema.isFromTheFuture(Schema.template())).toEqual(false)
	end)
end)
return true
