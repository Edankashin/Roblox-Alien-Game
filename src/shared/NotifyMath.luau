--!strict
-- ReplicatedStorage.Shared.NotifyMath: the pure half of the notification budget (data/Notify; UI/Toast draws it; the spec is
-- tests/NotifyMath.spec.luau). Nothing here touches an Instance or a clock: callers pass the time in.
--   * Classes: the class of a named message, and of someone else's catch by the Announcements level and the tier;
--   * the banner queue: priority order, one per kind (the latest wins), a limit, the stale drop, and when the next may show;
--   * the toast stack: whether an incoming toast or quiet line shows, waits or is dropped, and which line it pushes out;
--   * merging: whether a second message within the window updates the live one, and the running total ("+3 Wreck Plate");
--   * the cue gap: at most one UI sound in CueGapSeconds;
--   * the offline welcome toast: its lines, at most OfflineLinesMax.

local Notify = require(script.Parent.data.Notify)
local Strings = require(script.Parent.strings.en)

local NotifyMath = {}

export type Class = Notify.Class

-- A banner waiting for the slot: its kind, when it was queued, and whatever the drawer needs (opaque here).
export type Banner = { kind: string, queuedAt: number, payload: any }

local LOWEST = 1000 -- the priority of a banner kind the data does not name: after every named one

-- Classes ---------------------------------------------------------------------------

-- The class of a named message (data/Notify Messages); a message the table does not name is a Toast.
function NotifyMath.MessageClass(id: string): Class
	return Notify.Messages[id] or "Toast"
end

-- Someone else's catch of `tier`, at the Announcements `level` (0 Off, 1 Big only, 2 All; a level outside that reads as the default):
-- Banner, Toast, Quiet, Chat or None.
function NotifyMath.OthersCatchClass(level: number, tier: string): Class
	local index = math.floor(level)
	local row = Notify.OthersCatch[index + 1]
	if row == nil then
		row = Notify.OthersCatch[Notify.AnnounceLevelDefault + 1]
	end
	if row == nil then
		return "None"
	end
	return row[tier] or "None"
end

-- The banner queue ------------------------------------------------------------------

-- The priority of a banner kind: lower shows first.
function NotifyMath.BannerPriority(kind: string): number
	local row = Notify.BannerKinds[kind]
	return if row then row.priority else LOWEST
end

-- Seconds after a banner of `kind` leaves before the next may show (BannerGapSeconds, none for a cinematic line).
function NotifyMath.BannerGap(kind: string): number
	local row = Notify.BannerKinds[kind]
	if row and not row.gap then
		return 0
	end
	return Notify.BannerGapSeconds
end

-- Puts `banner` in the queue in priority order, behind the others of its priority (ahead of them with `front`, which a banner that was
-- on screen and came down for a quiet moment uses). A queued banner of the same kind goes first: the latest wins. Past
-- BannerQueueMax the last one is dropped, which can be the new banner itself. Edits `queue` in place; answers the dropped banner.
function NotifyMath.InsertBanner(queue: { Banner }, banner: Banner, front: boolean): Banner?
	for index = #queue, 1, -1 do
		if queue[index].kind == banner.kind then
			table.remove(queue, index)
		end
	end
	local priority = NotifyMath.BannerPriority(banner.kind)
	local at = #queue + 1
	for index, other in ipairs(queue) do
		local theirs = NotifyMath.BannerPriority(other.kind)
		if theirs > priority or (front and theirs == priority) then
			at = index
			break
		end
	end
	table.insert(queue, at, banner)
	if #queue > Notify.BannerQueueMax then
		return table.remove(queue) :: Banner
	end
	return nil
end

-- Removes the banners queued longer than BannerStaleSeconds before `now`, in place; answers how many went.
function NotifyMath.DropStale(queue: { Banner }, now: number): number
	local dropped = 0
	for index = #queue, 1, -1 do
		if now - queue[index].queuedAt > Notify.BannerStaleSeconds then
			table.remove(queue, index)
			dropped += 1
		end
	end
	return dropped
end

-- The next banner to show at `now` when the slot is free from `freeAt` (the time the last one left plus its gap): the stale ones
-- are dropped first; nil while the slot is not free yet or the queue is empty. The banner is removed from the queue.
function NotifyMath.NextBanner(queue: { Banner }, now: number, freeAt: number): Banner?
	NotifyMath.DropStale(queue, now)
	if now < freeAt or #queue == 0 then
		return nil
	end
	return table.remove(queue, 1) :: Banner
end

-- The toast stack ---------------------------------------------------------------------

export type StackAnswer = "show" | "wait" | "drop"

-- What happens to `incoming` ("Toast" or "Quiet") when `live` (the classes on the stack, oldest first) is on screen:
--   show: there is room, or a quiet line gives its place (the second answer is that line's index, nil when there is room);
--   wait: a toast with no room, held until one leaves;
--   drop: a quiet line with no room, never held.
function NotifyMath.StackAnswer(live: { string }, incoming: string): (StackAnswer, number?)
	if #live < Notify.ToastMax then
		return "show", nil
	end
	if incoming == "Quiet" then
		return "drop", nil
	end
	for index, class in ipairs(live) do
		if class == "Quiet" then
			return "show", index
		end
	end
	return "wait", nil
end

-- Merging ---------------------------------------------------------------------------

-- Whether a message at `now` joins the live one last updated at `lastAt` (inside MergeSeconds).
function NotifyMath.CanMerge(lastAt: number, now: number): boolean
	return now - lastAt >= 0 and now - lastAt <= Notify.MergeSeconds
end

-- The running total of a merged message: `add` on top of `previous` when the last update was inside the window, else a fresh `add`.
function NotifyMath.MergedTotal(previous: number, lastAt: number, now: number, add: number): number
	if NotifyMath.CanMerge(lastAt, now) then
		return previous + add
	end
	return add
end

-- Cues ------------------------------------------------------------------------------

-- Whether a UI sound may play at `now`, the last one having played at `lastCueAt`.
function NotifyMath.CueAllowed(now: number, lastCueAt: number): boolean
	return now - lastCueAt >= Notify.CueGapSeconds
end

-- The offline welcome toast --------------------------------------------------------------

export type OfflineParts = {
	scrapText: string?, -- the Scrap earned, formatted (nil or "": none)
	moduleNames: { string }, -- the ship modules finished while away
	grown: number, -- the aliens that grew while away
}

-- The lines of the one welcome toast: the greeting (carrying the Scrap when there is some), then one line for the modules, then one for
-- the growth; at most OfflineLinesMax. Several modules read as a count, so the line never wraps.
function NotifyMath.OfflineLines(parts: OfflineParts): { string }
	local lines: { string } = {}
	local scrap = parts.scrapText
	if scrap ~= nil and scrap ~= "" then
		table.insert(lines, Strings.OFFLINE_SUMMARY:format(scrap))
	else
		table.insert(lines, Strings.OFFLINE_TITLE)
	end
	local modules = parts.moduleNames
	if #modules == 1 then
		table.insert(lines, Strings.OFFLINE_LINE_MODULE:format(modules[1]))
	elseif #modules > 1 then
		table.insert(lines, Strings.OFFLINE_LINE_MODULES:format(#modules))
	end
	if parts.grown == 1 then
		table.insert(lines, Strings.OFFLINE_LINE_GREW_ONE)
	elseif parts.grown > 1 then
		table.insert(lines, Strings.OFFLINE_LINE_GREW:format(parts.grown))
	end
	while #lines > Notify.OfflineLinesMax do
		table.remove(lines)
	end
	return lines
end

return NotifyMath
