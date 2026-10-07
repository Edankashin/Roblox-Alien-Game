--!strict
-- ReplicatedStorage.Shared.AlienDelta: the alien list's change set, shared so the server builds a delta (Diff) and the client
-- applies it (Apply) with the same rules, and both can be tested without Studio. Pure functions of the tables passed in; nothing
-- here reads a clock, a remote or a profile.
-- A mirror is the pair every side keeps: the records by uid and the stations (who sits where, how many slots). The server holds
-- one per player as "what the client was last told" (AlienSync's shadow); the client's is the profile it mirrors. Diff finds what
-- differs between two mirrors, Apply brings a mirror to the other one, and Classify is the sequence rule: a delta carries
-- seq = the number of the delta before it + 1, so the client applies the next one, ignores one it has already had, and pulls
-- the whole snapshot when one is missing.
-- Records are compared field by field (every key, so a field added to AlienRecord later is covered); a record with a
-- table-valued field would always compare different, which only costs bytes, never correctness.

local Types = require(script.Parent.types.Types)

local AlienDelta = {}

export type Mirror = { aliens: { [string]: Types.AlienRecord }, stations: { [string]: Types.StationState } }

-- What a received delta means for a mirror that has applied everything up to `have`: Apply it (it is the next one), ignore it
-- as Stale (already applied or older), or the mirror has missed one (Gap) and needs the snapshot.
export type Verdict = "Apply" | "Stale" | "Gap"

local function recordsEqual(a: Types.AlienRecord, b: Types.AlienRecord): boolean
	for key, value in pairs(a :: any) do
		if (b :: any)[key] ~= value then
			return false
		end
	end
	for key in pairs(b :: any) do
		if (a :: any)[key] == nil then
			return false
		end
	end
	return true
end

local function stationsEqual(a: Types.StationState, b: Types.StationState): boolean
	if #a.assigned ~= #b.assigned then
		return false
	end
	for index, uid in ipairs(a.assigned) do
		if b.assigned[index] ~= uid then
			return false
		end
	end
	for key, value in pairs(a :: any) do
		if key ~= "assigned" and (b :: any)[key] ~= value then
			return false
		end
	end
	for key in pairs(b :: any) do
		if key ~= "assigned" and (a :: any)[key] == nil then
			return false
		end
	end
	return true
end

local function cloneStation(state: Types.StationState): Types.StationState
	local copy = table.clone(state)
	copy.assigned = table.clone(state.assigned)
	return copy
end

local function byUid(a: Types.AlienRecord, b: Types.AlienRecord): boolean
	return a.uid < b.uid
end

-- Whether a delta carries nothing but its number.
function AlienDelta.IsEmpty(delta: Types.AliensDelta): boolean
	return delta.added == nil and delta.changed == nil and delta.removed == nil and delta.stations == nil
end

-- A copy of a mirror that shares no table with it (the server keeps one as its shadow; a mirror it was copied from can keep
-- changing). Only the aliens and stations are taken, so a whole profile can be passed.
function AlienDelta.Copy(mirror: Mirror): Mirror
	local aliens: { [string]: Types.AlienRecord } = {}
	for uid, record in pairs(mirror.aliens) do
		aliens[uid] = table.clone(record)
	end
	local stations: { [string]: Types.StationState } = {}
	for job, state in pairs(mirror.stations) do
		stations[job] = cloneStation(state)
	end
	return { aliens = aliens, stations = stations }
end

-- What turns `before` into `after`, numbered `seq`, or nil when they already agree. `added` and `changed` hold `after`'s own
-- records and `stations` its own station tables (not copies): send the delta at once, or Apply it, which copies. Lists are
-- sorted by uid so the same pair always gives the same delta. A job missing from `after` is not reported: stations are
-- created with the profile and never removed. An unchanged station is left out, so a catch that seats nobody sends none.
function AlienDelta.Diff(before: Mirror, after: Mirror, seq: number): Types.AliensDelta?
	local added: { Types.AlienRecord } = {}
	local changed: { Types.AlienRecord } = {}
	for uid, record in pairs(after.aliens) do
		local old = before.aliens[uid]
		if old == nil then
			table.insert(added, record)
		elseif not recordsEqual(old, record) then
			table.insert(changed, record)
		end
	end
	local removed: { string } = {}
	for uid in pairs(before.aliens) do
		if after.aliens[uid] == nil then
			table.insert(removed, uid)
		end
	end
	local stations: { [string]: Types.StationState } = {}
	local stationsChanged = false
	for job, state in pairs(after.stations) do
		local old = before.stations[job]
		if old == nil or not stationsEqual(old, state) then
			stations[job] = state
			stationsChanged = true
		end
	end
	if #added == 0 and #changed == 0 and #removed == 0 and not stationsChanged then
		return nil
	end
	table.sort(added, byUid)
	table.sort(changed, byUid)
	table.sort(removed)
	return {
		seq = seq,
		added = if #added > 0 then added else nil,
		changed = if #changed > 0 then changed else nil,
		removed = if #removed > 0 then removed else nil,
		stations = if stationsChanged then stations else nil,
	}
end

-- Brings `mirror` to the state the delta describes and returns it (the same table, changed in place). Records are copied in,
-- so the delta can be reused or its tables changed afterwards. A removed uid the mirror never held is ignored; an added or
-- changed record replaces whatever the mirror holds under its uid. The delta's number is not touched here: the caller keeps it.
function AlienDelta.Apply(mirror: Mirror, delta: Types.AliensDelta): Mirror
	local removed = delta.removed
	if removed then
		for _, uid in ipairs(removed) do
			mirror.aliens[uid] = nil
		end
	end
	local added = delta.added
	if added then
		for _, record in ipairs(added) do
			mirror.aliens[record.uid] = table.clone(record)
		end
	end
	local changed = delta.changed
	if changed then
		for _, record in ipairs(changed) do
			mirror.aliens[record.uid] = table.clone(record)
		end
	end
	local stations = delta.stations
	if stations then
		for job, state in pairs(stations) do
			mirror.stations[job] = cloneStation(state)
		end
	end
	return mirror
end

-- The sequence rule. `have` is the number of the last delta (or the snapshot) the mirror holds; `got` is the number on the
-- one that just arrived.
function AlienDelta.Classify(have: number, got: number): Verdict
	if got == have + 1 then
		return "Apply"
	end
	if got <= have then
		return "Stale"
	end
	return "Gap"
end

return AlienDelta
