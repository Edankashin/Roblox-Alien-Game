--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Delta = require(Shared.AlienDelta)
local StorageMath = require(Shared.StorageMath)
local Config = require(Shared.data.Config)
local Fusion = require(Shared.data.Fusion)
local Growth = require(Shared.data.Growth)
local Jobs = require(Shared.data.Jobs)
local Modules = require(Shared.data.Modules)
local Sizes = require(Shared.data.Sizes)
local Species = require(Shared.data.Species)
local Storage = require(Shared.data.Storage)
local F = require(script.Parent.Fixtures)

-- Fixtures -----------------------------------------------------------------

local STAMP = os.time() -- a ten-digit caughtAt, like a real record's
local grown = Growth.ById.Grown.workedSeconds
local jobs = Jobs.Order
local slots = Config.StationMaxSlots

local function uidOf(index)
	return string.format("%08x-0000-4000-8000-%012x", index, index) -- 36 characters, like HttpService:GenerateGUID
end

local function plain(index)
	return {
		uid = uidOf(index),
		species = Species.List[index % #Species.List + F.one].id,
		level = F.one,
		overlay = "None",
		caughtAt = STAMP,
		size = Sizes.Default,
		workedSeconds = F.zero,
	}
end

-- `count` records; the first jobs x slots of them work (every seat full, slot = position), the rest rest. The stations
-- table is the profile's: one entry per job with the seated uids in slot order.
local function camp(count)
	local mirror = { aliens = {}, stations = {} }
	local index = F.zero
	for _, job in ipairs(jobs) do
		local assigned = {}
		for slot = F.one, slots do
			index += F.one
			local record = plain(index)
			record.station = job
			record.slot = slot
			record.workedSeconds = grown + index
			mirror.aliens[record.uid] = record
			table.insert(assigned, record.uid)
		end
		mirror.stations[job] = { slots = slots, assigned = assigned }
	end
	while index < count do
		index += F.one
		local record = plain(index)
		mirror.aliens[record.uid] = record
	end
	return mirror
end

local function seated(mirror)
	local list = {}
	for _, job in ipairs(jobs) do
		for _, uid in ipairs(mirror.stations[job].assigned) do
			table.insert(list, mirror.aliens[uid])
		end
	end
	return list
end

-- The first resting records of the mirror in uid order (a camp's resting records start after the seated ones).
local function resting(mirror, count)
	local list = {}
	for _, record in pairs(mirror.aliens) do
		if record.station == nil then
			table.insert(list, record)
		end
	end
	table.sort(list, function(a, b)
		return a.uid < b.uid
	end)
	local out = {}
	for index = F.one, count do
		table.insert(out, list[index])
	end
	return out
end

-- Equal when neither differs from the other by Diff, the rule under test, plus a count so a pure subset cannot pass.
local function same(a, b)
	local count = function(mirror)
		local total = F.zero
		for _ in pairs(mirror.aliens) do
			total += F.one
		end
		return total
	end
	return Delta.Diff(a, b, F.zero) == nil and Delta.Diff(b, a, F.zero) == nil and count(a) == count(b)
end

local function uids(records)
	local out = {}
	for _, record in ipairs(records) do
		table.insert(out, record.uid)
	end
	return out
end

-- Compact JSON length of a value (the encoding of HttpService:JSONEncode for these plain tables): quoted strings, numbers as
-- printed, objects and arrays with their separators.
local function jsonBytes(value)
	local kind = type(value)
	if kind == "string" then
		return #value + F.two
	elseif kind == "number" then
		return #tostring(value)
	elseif kind == "boolean" then
		return #tostring(value)
	end
	local isArray = next(value) == nil or value[F.one] ~= nil
	local total = F.two
	local first = true
	if isArray then
		for _, item in ipairs(value) do
			total += jsonBytes(item) + (if first then F.zero else F.one)
			first = false
		end
	else
		for key, item in pairs(value) do
			total += #key + F.two + F.one + jsonBytes(item) + (if first then F.zero else F.one) -- "key":value
			first = false
		end
	end
	return total
end

-- The ceiling today: every module of every world finished, every Storage Bay level bought, the pass.
local function ceilingToday()
	local ids = {}
	for _, defs in pairs(Modules.Worlds) do
		for _, def in ipairs(defs) do
			table.insert(ids, def.id)
		end
	end
	return StorageMath.CapFor(ids, #Storage.Bay.Levels, true)
end

-- Presentation and the size bound of the payload test, not game numbers: a percent, milliseconds, and "at most a tenth".
local PERCENT = 100
local MILLISECONDS = 1000
local WHOLE_PER_EVENT = 10

-- Tests --------------------------------------------------------------------

describe("AlienDelta.Diff", function()
	it("is nil for two mirrors that agree, and for a copy", function()
		local before = camp(Storage.BaseCap)
		expect(Delta.Diff(before, Delta.Copy(before), F.one)).toEqual(nil)
	end)

	it("reports a new record as added, sorted by uid, with its number and nothing else", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local second, first = plain(Storage.BaseCap + F.two), plain(Storage.BaseCap + F.one)
		after.aliens[second.uid] = second
		after.aliens[first.uid] = first
		local delta = Delta.Diff(before, after, F.two)
		expect(delta.seq).toEqual(F.two)
		expect(#delta.added).toEqual(F.two)
		expect(delta.added[F.one]).toEqual(first)
		expect(delta.added[F.two]).toEqual(second)
		expect(delta.changed).toEqual(nil)
		expect(delta.removed).toEqual(nil)
		expect(delta.stations).toEqual(nil)
	end)

	it("reports a changed field as changed with the whole new record", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local target = seated(after)[F.one]
		target.workedSeconds += F.tick
		local delta = Delta.Diff(before, after, F.one)
		expect(#delta.changed).toEqual(F.one)
		expect(delta.changed[F.one]).toEqual(target)
		expect(delta.changed[F.one].workedSeconds).toEqual(grown + F.one + F.tick)
		expect(delta.added).toEqual(nil)
		expect(delta.removed).toEqual(nil)
		expect(delta.stations).toEqual(nil)
	end)

	it("reports a field that appeared or disappeared as changed", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local picked = resting(after, F.one)[F.one]
		picked.habitat = "habitat-uid"
		local delta = Delta.Diff(before, after, F.one)
		expect(uids(delta.changed)[F.one]).toEqual(picked.uid)
		local back = Delta.Diff(after, before, F.one)
		expect(uids(back.changed)[F.one]).toEqual(picked.uid)
		expect(back.changed[F.one].habitat).toEqual(nil)
	end)

	it("reports a deleted record's uid as removed", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local gone = resting(after, F.two)
		for _, record in ipairs(gone) do
			after.aliens[record.uid] = nil
		end
		local delta = Delta.Diff(before, after, F.one)
		expect(#delta.removed).toEqual(F.two)
		local expected = uids(gone)
		table.sort(expected)
		expect(delta.removed[F.one]).toEqual(expected[F.one])
		expect(delta.removed[F.two]).toEqual(expected[F.two])
		expect(delta.added).toEqual(nil)
		expect(delta.changed).toEqual(nil)
		expect(delta.stations).toEqual(nil)
	end)

	it("a seat move changes the two records and only the two stations", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		-- The first seated alien of the first job and the first of the second swap seats.
		local firstJob, secondJob = jobs[F.one], jobs[F.two]
		local a = after.aliens[after.stations[firstJob].assigned[F.one]]
		local b = after.aliens[after.stations[secondJob].assigned[F.one]]
		a.station, b.station = secondJob, firstJob
		after.stations[firstJob].assigned[F.one] = b.uid
		after.stations[secondJob].assigned[F.one] = a.uid
		local delta = Delta.Diff(before, after, F.one)
		expect(#delta.changed).toEqual(F.two)
		expect(delta.added).toEqual(nil)
		expect(delta.removed).toEqual(nil)
		local changedUids = uids(delta.changed)
		expect(table.find(changedUids, a.uid) ~= nil).toEqual(true)
		expect(table.find(changedUids, b.uid) ~= nil).toEqual(true)
		local stationCount = F.zero
		for _ in pairs(delta.stations) do
			stationCount += F.one
		end
		expect(stationCount).toEqual(F.two)
		expect(delta.stations[firstJob].assigned[F.one]).toEqual(b.uid)
		expect(delta.stations[secondJob].assigned[F.one]).toEqual(a.uid)
	end)

	it("a slot count or a bought bonus on a station is a stations-only delta", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local job = jobs[F.one]
		after.stations[job].slots += F.one
		after.stations[job].bonus = F.one
		local delta = Delta.Diff(before, after, F.one)
		expect(delta.added).toEqual(nil)
		expect(delta.changed).toEqual(nil)
		expect(delta.removed).toEqual(nil)
		expect(delta.stations[job].slots).toEqual(slots + F.one)
		expect(delta.stations[job].bonus).toEqual(F.one)
		expect(delta.stations[jobs[F.two]]).toEqual(nil)
	end)

	it("one update that adds, changes, removes and reseats is one delta", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local fodder = resting(after, Fusion.DuplicatesPerLevel)
		for _, record in ipairs(fodder) do
			after.aliens[record.uid] = nil
		end
		seated(after)[F.one].level += F.one
		local newcomer = plain(Storage.BaseCap + F.one)
		after.aliens[newcomer.uid] = newcomer
		local delta = Delta.Diff(before, after, F.one)
		expect(#delta.removed).toEqual(Fusion.DuplicatesPerLevel)
		expect(#delta.changed).toEqual(F.one)
		expect(#delta.added).toEqual(F.one)
		expect(delta.stations).toEqual(nil)
	end)
end)

describe("AlienDelta.Apply", function()
	it("turns the old mirror into the new one for every kind of change", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		-- add, change (level and growth), remove, and a seat swap, all in one delta
		local newcomer = plain(Storage.BaseCap + F.one)
		after.aliens[newcomer.uid] = newcomer
		seated(after)[F.two].workedSeconds += grown
		for _, record in ipairs(resting(after, Fusion.DuplicatesPerLevel)) do
			after.aliens[record.uid] = nil
		end
		local firstJob, secondJob = jobs[F.one], jobs[F.two]
		local a = after.aliens[after.stations[firstJob].assigned[F.one]]
		local b = after.aliens[after.stations[secondJob].assigned[F.one]]
		a.station, b.station = secondJob, firstJob
		after.stations[firstJob].assigned[F.one] = b.uid
		after.stations[secondJob].assigned[F.one] = a.uid
		local delta = Delta.Diff(before, after, F.one)
		local mirror = Delta.Copy(before)
		local result = Delta.Apply(mirror, delta)
		expect(result).toEqual(mirror) -- the same table, changed in place
		expect(same(mirror, after)).toEqual(true)
		expect(mirror.aliens[newcomer.uid].species).toEqual(newcomer.species)
		expect(mirror.stations[firstJob].assigned[F.one]).toEqual(b.uid)
	end)

	it("copies what it is given: changing the delta afterwards leaves the mirror alone", function()
		local before = camp(Storage.BaseCap)
		local after = Delta.Copy(before)
		local newcomer = plain(Storage.BaseCap + F.one)
		after.aliens[newcomer.uid] = newcomer
		after.stations[jobs[F.one]].assigned[F.one] = newcomer.uid
		local delta = Delta.Diff(before, after, F.one)
		local mirror = Delta.Copy(before)
		Delta.Apply(mirror, delta)
		delta.added[F.one].level = F.two
		delta.stations[jobs[F.one]].assigned[F.one] = "tampered"
		expect(mirror.aliens[newcomer.uid].level).toEqual(F.one)
		expect(mirror.stations[jobs[F.one]].assigned[F.one]).toEqual(newcomer.uid)
	end)

	it("ignores a removed uid it never held and replaces a record added under a held uid", function()
		local mirror = camp(Storage.BaseCap)
		local held = resting(mirror, F.one)[F.one]
		local replacement = table.clone(held)
		replacement.level = F.two
		Delta.Apply(mirror, { seq = F.one, removed = { "not-a-uid" }, added = { replacement } })
		expect(mirror.aliens[held.uid].level).toEqual(F.two)
		local total = F.zero
		for _ in pairs(mirror.aliens) do
			total += F.one
		end
		expect(total).toEqual(Storage.BaseCap)
	end)

	it("an empty delta changes nothing and says so", function()
		local mirror = camp(Storage.BaseCap)
		local copy = Delta.Copy(mirror)
		local empty = { seq = F.one }
		expect(Delta.IsEmpty(empty)).toEqual(true)
		expect(Delta.IsEmpty({ seq = F.one, removed = { "x" } })).toEqual(false)
		Delta.Apply(mirror, empty)
		expect(same(mirror, copy)).toEqual(true)
	end)

	it("a chain of deltas keeps a mirror equal to the source after every step", function()
		local source = camp(Storage.BaseCap)
		local shadow = Delta.Copy(source) -- the server's record of what the client holds
		local client = Delta.Copy(source)
		local steps = {
			function() -- a catch
				local record = plain(Storage.BaseCap + F.one)
				source.aliens[record.uid] = record
			end,
			function() -- growth
				for _, record in ipairs(seated(source)) do
					record.workedSeconds += F.tick
				end
			end,
			function() -- a fusion
				for _, record in ipairs(resting(source, Fusion.DuplicatesPerLevel)) do
					source.aliens[record.uid] = nil
				end
				seated(source)[F.one].level += F.one
			end,
			function() -- nothing changes
			end,
			function() -- a release
				source.aliens[resting(source, F.one)[F.one].uid] = nil
			end,
		}
		local seq = F.zero
		for _, step in ipairs(steps) do
			step()
			local delta = Delta.Diff(shadow, source, seq + F.one)
			if delta then
				Delta.Apply(shadow, delta)
				seq = delta.seq
				Delta.Apply(client, delta)
			end
			expect(same(client, source)).toEqual(true)
			expect(same(shadow, source)).toEqual(true)
		end
		expect(seq).toEqual(#steps - F.one) -- the idle step sent nothing, so it took no number
	end)
end)

describe("AlienDelta.Classify", function()
	it("applies the next number, ignores the ones already held, and calls a skipped number a gap", function()
		local have = Storage.BaseCap
		expect(Delta.Classify(have, have + F.one)).toEqual("Apply")
		expect(Delta.Classify(have, have)).toEqual("Stale")
		expect(Delta.Classify(have, have - F.one)).toEqual("Stale")
		expect(Delta.Classify(have, F.zero)).toEqual("Stale")
		expect(Delta.Classify(have, have + F.two)).toEqual("Gap")
		expect(Delta.Classify(have, have + Storage.BaseCap)).toEqual("Gap")
	end)

	it("a snapshot at 0 takes delta 1 and calls delta 2 a gap", function()
		expect(Delta.Classify(F.zero, F.one)).toEqual("Apply")
		expect(Delta.Classify(F.zero, F.two)).toEqual("Gap")
	end)

	it("a client that misses one delta pulls once, then takes the next ones in order", function()
		-- The server side as AlienSync does it, the client side as State does it.
		local source = camp(Storage.BaseCap)
		local shadow = Delta.Copy(source)
		local shadowSeq = F.zero
		local client = Delta.Copy(source)
		local clientSeq = F.zero
		local pulls = F.zero
		local function send(change, delivered)
			change()
			local delta = Delta.Diff(shadow, source, shadowSeq + F.one)
			if not delta then
				return
			end
			Delta.Apply(shadow, delta)
			shadowSeq = delta.seq
			if not delivered then
				return -- lost on the way
			end
			local verdict = Delta.Classify(clientSeq, delta.seq)
			if verdict == "Apply" then
				Delta.Apply(client, delta)
				clientSeq = delta.seq
			elseif verdict == "Gap" then
				pulls += F.one
				-- GetAliens: a new snapshot of the source under the next number.
				shadow = Delta.Copy(source)
				shadowSeq += F.one
				client = Delta.Copy(source)
				clientSeq = shadowSeq
			end
		end
		local function catch(index)
			return function()
				local record = plain(index)
				source.aliens[record.uid] = record
			end
		end
		send(catch(Storage.BaseCap + F.one), true)
		expect(clientSeq).toEqual(F.one)
		send(catch(Storage.BaseCap + F.two), false) -- delta 2 is lost
		expect(same(client, source)).toEqual(false)
		send(catch(Storage.BaseCap + F.two + F.one), true) -- delta 3 arrives: a gap
		expect(pulls).toEqual(F.one)
		expect(same(client, source)).toEqual(true)
		send(catch(Storage.BaseCap + F.two + F.two), true) -- and the stream goes on, no second pull
		expect(pulls).toEqual(F.one)
		expect(same(client, source)).toEqual(true)
		expect(clientSeq).toEqual(shadowSeq)
	end)
end)

describe("AlienDelta payloads", function()
	-- Prints the bytes of what the client was sent before (every record on every change) and now (the delta), at the storage ceiling
	-- today and at the hard cap, and holds each event to a tenth of the whole list.
	for _, scale in ipairs({ { name = "ceiling today", records = ceilingToday() }, { name = "hard cap", records = Storage.HardCap } }) do
		it("each event is far smaller than the whole list at the " .. scale.name, function()
			local before = camp(scale.records)
			local fullBytes = jsonBytes(before.stations) + jsonBytes(before.aliens)
			local function drifted(after) -- the seated aliens' worked time since the client was last told
				for _, record in ipairs(seated(after)) do
					record.workedSeconds += F.tick * Config.StationMaxSlots
				end
			end
			local events = {
				{ name = "catch, newcomer rests", run = function(after)
					local record = plain(scale.records + F.one)
					after.aliens[record.uid] = record
				end },
				{ name = "catch, newcomer takes a seat", run = function(after)
					local record = plain(scale.records + F.one)
					local job = jobs[F.one]
					local bumped = after.aliens[after.stations[job].assigned[slots]]
					bumped.station, bumped.slot = nil, nil
					record.station, record.slot = job, slots
					after.stations[job].assigned[slots] = record.uid
					after.aliens[record.uid] = record
				end },
				{ name = "fusion (4 consumed, 1 levelled)", run = function(after)
					for _, record in ipairs(resting(after, Fusion.DuplicatesPerLevel)) do
						after.aliens[record.uid] = nil
					end
					resting(after, F.one)[F.one].level += F.one
				end },
				{ name = "release one", run = function(after)
					after.aliens[resting(after, F.one)[F.one].uid] = nil
				end },
				{ name = "release a full page", run = function(after)
					for _, record in ipairs(resting(after, Storage.MaxReleasePerCall)) do
						after.aliens[record.uid] = nil
					end
				end },
				{ name = "optimize (two seats swap)", run = function(after)
					local firstJob, secondJob = jobs[F.one], jobs[F.two]
					local a = after.aliens[after.stations[firstJob].assigned[F.one]]
					local b = after.aliens[after.stations[secondJob].assigned[F.one]]
					a.station, b.station = secondJob, firstJob
					after.stations[firstJob].assigned[F.one] = b.uid
					after.stations[secondJob].assigned[F.one] = a.uid
				end },
				{ name = "growth stage (seated records only)", run = function() end },
			}
			print(string.format("alien list at %s: %d records, %d seated, whole list %d bytes (what every change used to send)", scale.name, scale.records, #jobs * slots, fullBytes))
			for _, event in ipairs(events) do
				local after = Delta.Copy(before)
				event.run(after)
				drifted(after)
				local delta = Delta.Diff(before, after, F.one)
				local bytes = jsonBytes(delta)
				print(string.format("  %-36s %7d bytes (%.2f%% of the whole list)", event.name, bytes, bytes / fullBytes * PERCENT))
				expect(bytes * WHOLE_PER_EVENT < fullBytes).toEqual(true)
			end
		end)
	end

	it("a diff of the largest camp takes well under a second", function()
		local before = camp(Storage.HardCap)
		local after = Delta.Copy(before)
		local started = os.clock()
		Delta.Diff(before, after, F.one)
		local elapsed = os.clock() - started
		print(string.format("diff of %d unchanged records: %.2f ms", Storage.HardCap, elapsed * MILLISECONDS))
		expect(elapsed < F.one).toEqual(true)
	end)
end)
return true
