--!strict
-- StarterPlayerScripts.Client.UI.AliensScreen: the Aliens panel. A strip of station cards across
-- the top (one per unlocked job: name, slots, rate and a row of slot squares), the owned count, a
-- scrolling grid of one square card per alien (rarity gradient, placeholder shape, name, speed chip,
-- overlay badge, a level chip on a fused copy, a size chip and a growth chip that counts a working alien down to
-- its next stage, where it is working or that it follows you; a following mount shows a Ride button in the status
-- slot instead), a storage band (the aliens owned over the storage cap above the companion slots in use, and the Storage Bay
-- button beside them) with a perks line under it, and a footer with Optimize and Fuse buttons, a Companion Token button while a
-- token is held, and a one-line fuse hint.
-- Storage (milestones 50 and 50b, data/Storage): the owned count reads "Aliens: 12 / 60", the cap being what the server last said
-- (State.GetStorageCap: it grows with the ship's modules, the Storage Bay and the pass), gold from WarnFraction of the cap and red
-- when full. The Storage Bay button beside it buys the next level with Scrap ("+20 storage: 2,500 Scrap"); it is green while
-- the level can be bought and grey, with the reason in its words or in the toast a tap brings, when the Scrap is short, the
-- level waits for a world or the Bay is maxed out. A Release button at the top left opens the ReleasePanel menu (release all
-- unused Commons or Uncommons), and holding an alien card for Storage.HoldSeconds opens the same panel for that one alien; a
-- plain tap still follows or stops.
-- Habitats (milestone 42c): at home, a resting alien whose world has a habitat on the plot shows a Display button in
-- the status slot, and an alien on display shows a purple "On display" pill in the chip row (in place of the size and
-- growth chips) and, at home, a Bring back button in the status slot; a plain tap on a displayed card does nothing.
-- Neither button shows while the player is visiting someone else's home (State.IsVisiting, milestone 42e): a guest
-- never displays or takes back at another's plot, and the cards redraw on the "visit" topic when that changes.
-- Every value is read from the profile mirror in State and the shared Economy and Growth math; the only taps
-- that leave the client ask the server (StationOptimize, FuseSpecies, SetCompanion, SetMount, SetDisplay,
-- UseCompanionToken, BuyStorageBay, and through the ReleasePanel ReleaseAliens and ReleaseAllOfTier). Nothing here decides an outcome: Fuse only picks which species to ask about, a card tap only
-- asks to follow or stop (or, on the ridden card, to hop off), the Ride button only asks to ride or hop off, the
-- Display and Bring back buttons only ask to put an alien in a habitat or take it out, and the cards redraw from
-- the camp, companion and home pushes the server sends back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local HomeBuildData = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local Growth = require(Shared:WaitForChild("Growth"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Place = require(Shared:WaitForChild("Place"))
local Companions = require(Shared:WaitForChild("data"):WaitForChild("Companions"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Fusion = require(Shared:WaitForChild("data"):WaitForChild("Fusion"))
local Jobs = require(Shared:WaitForChild("data"):WaitForChild("Jobs"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Storage = require(Shared:WaitForChild("data"):WaitForChild("Storage"))
local StorageMath = require(Shared:WaitForChild("StorageMath"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local ReleasePanel = require(script.Parent.ReleasePanel)
local State = require(script.Parent.Parent.State)
local HomeRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("HomeRenderer"))

local AliensScreen = {}

type JobDef = { name: string, station: string, verb: string, commonsOnly: boolean, unlockWorld: number }
local jobDefs: { [string]: JobDef } = Jobs.Jobs
local jobOrder: { string } = Jobs.Order

-- One grid entry, sorted before the cards are built.
type Entry = {
	record: Types.AlienRecord,
	def: Types.SpeciesDef?,
	speed: number,
	name: string,
	following: boolean,
	riding: boolean, -- the local player rides this one (State.GetRiding)
}

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close
-- button reaches down to 0.155, so the body starts under it. Top to bottom: the station strip, the storage band
-- (the aliens owned over the cap and the companion slots in use stacked at the left, the Storage Bay button at the right),
-- the one-line perks row, the grid, then the footer. The grid ends at 0.845, above the 0.855 where the footer's button row
-- starts, and one row of square cards is about 0.285 tall, so a full row fits without scrolling. The strip gave the band
-- 0.04 of its height (0.27 before the Storage Bay, 0.23 now): the button needs a chunky row of its own, and the text of
-- "+20 storage: 1,000,000 Scrap" needs about half the panel's width at the 14 px minimum.
local STRIP_Y = 0.17
local STRIP_H = 0.23
local STRIP_GAP = 0.02 -- between station cards, of the strip width
local STORAGE_Y = 0.405
local COUNT_H = 0.045 -- each of the two stacked labels; together they are as tall as the Bay button
local STORAGE_LEFT_W = 0.41 -- the labels' width
local BAY_W = 0.55 -- the Storage Bay button's width, anchored at the right margin
local BAY_H = COUNT_H * 2
local PERKS_Y = 0.50
local PERKS_H = 0.04 -- one line of 14 px text
local GRID_Y = 0.545
local GRID_H = 0.30
local FOOTER_H = 0.075 -- the button row; the one-line fuse hint sits under it
local HINT_H = 0.05 -- one line of 14 px text
local FOOTER_BUTTON_W = 0.24 -- Fuse and Optimize, side by side at the right
local TOKEN_BUTTON_W = 0.30 -- the Companion Token button, left of Fuse while a token is held; wider than Fuse so "Use Token (1)" stays one line on a phone
local FOOTER_GAP = 0.02 -- between them
local FUSE_BUSY_ALPHA = 0.5 -- the Fuse button's face and text fade by this while a fusion is in flight
-- The Release button at the top left, opposite the Close button and clear of the header tab (which starts at 0.29).
local RELEASE_X = 0.015
local RELEASE_Y = 0.02
local RELEASE_W = 0.2
local RELEASE_H = 0.1

-- Grid: four square cards per row; the cell width is a fraction of the grid's canvas width and the
-- cell height is derived from it so the cells come out square (see layoutGrid).
local COLUMNS = 4
local CELL_W = 0.22
local CELL_GAP = 0.02
local SCROLLBAR_PX = 6 -- thickness, not a Size: a thin dark bar on the right

-- The alien card's mid band: the shape square in the centre, then a chip row across its lower edge (size
-- on the left, growth on the right), then the name and the station. A chip is CHIP_W of the card so five
-- characters ("Elder", "HUGE", "23h") fit at the 14 px minimum on an iPhone SE card; the chips sit on the
-- shape's bottom edge, below its label, drawn above it. Every row is one line at the minimum size: a
-- square card has no room for a second line anywhere.
local SHAPE_Y = 0.38
local SHAPE_W = 0.36
local CHIP_W = 0.38
local CHIP_Y = 0.59
local CHIP_H = 0.14
local NAME_Y = 0.66
local NAME_H = 0.14
local STATUS_Y = 0.80
local STATUS_H = 0.14
local RIDE_Y = 0.78 -- the Ride button takes the status slot but stands taller (a 21 px tap target at the reference card, not 17)
local RIDE_H = 0.18

-- The card's top corners: the speed chip top right, the overlay badge top left, and a fused copy's level chip
-- (the speed chip's size) in the top-left corner too, or directly under the badge when the badge holds it.
local CORNER_X = 0.04
local CORNER_Y = 0.04
local CORNER_H = 0.17
local SPEED_W = 0.36
local BADGE_W = 0.5
local CORNER_GAP = 0.01

-- The Ride button of a following mount (a species with `ride`) takes the status label's place exactly: the status
-- row is the card's full width, so "Hop off" (49.5 px at the 14 px minimum, Fredoka) fits one line even on a 78 px
-- card (73 px of button). Its ZIndex sits above the invisible Tap overlay, so a tap on it asks to ride or hop off and
-- never reaches the card.
local TAP_Z = 8
local RIDE_Z = TAP_Z + 1

-- The perk kinds in the order the perks line lists them (the kinds of data/Companions PerkByJob).
local PERK_ORDER: { string } = { "catchScrap", "zone", "luck", "radar" }

-- Time units, in seconds, for the growth countdown.
local MINUTE = 60
local HOUR = 60 * MINUTE

local gui: ScreenGui? = nil
local panel: Frame? = nil
local strip: Frame? = nil
local countLabel: TextLabel? = nil
local companionsLabel: TextLabel? = nil
local bayButton: Frame? = nil -- the Storage Bay button
local perksLabel: TextLabel? = nil
local tokenButton: Frame? = nil
local grid: ScrollingFrame? = nil
local gridLayout: UIGridLayout? = nil
local emptyLabel: TextLabel? = nil
local fuseButton: Frame? = nil
local cardCount = 0
local open = false
local pending = false -- one server request in flight at a time
local bayBusy = false -- a BuyStorageBay request is in flight

-- Helpers ----------------------------------------------------------------

local function speciesColor(def: Types.SpeciesDef?): Color3
	return if def then Color3.fromHex(def.placeholder.color) else Theme.Rarity.Common
end

local function speciesName(def: Types.SpeciesDef?, id: string): string
	return if def then def.name else id
end

local function shapeName(def: Types.SpeciesDef?): string
	return Builder.text("SHAPE_" .. (if def then def.placeholder.shape else "Ball"))
end

-- The server creates one station per job with StationStartSlots; until its first push lands, show the same shape.
local function stationOf(profile: Types.Profile, job: string): Types.StationState
	return profile.stations[job] or { slots = Config.StationStartSlots, assigned = {} }
end

-- Jobs the ship's highest world has unlocked (Economy.unlockWorld: the stations stand at home too), in Jobs.Order.
local function unlockedJobs(profile: Types.Profile): { string }
	local out: { string } = {}
	local world = Economy.unlockWorld(profile)
	for _, job in ipairs(jobOrder) do
		local def = jobDefs[job]
		if def and def.unlockWorld <= world then
			table.insert(out, job)
		end
	end
	return out
end

-- The growth countdown, short enough for a chip: whole hours ("2h") from an hour up, else whole minutes
-- ("59m"); both round up, so the last minute reads 1m and 59m 59s reads 1h, never 60m.
local function timeLeftText(seconds: number): string
	local minutes = math.ceil(math.max(0, seconds) / MINUTE)
	if minutes >= HOUR / MINUTE then
		return Strings.TIME_H:format(math.ceil(minutes / (HOUR / MINUTE)))
	end
	return Strings.TIME_M:format(minutes)
end

local function clearChildren(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- The owned count over the storage cap the server last said (State.GetStorageCap), in the warning colour from
-- Storage.WarnFraction and the Close colour when full.
local function setCount(count: number)
	local label = countLabel
	if not label then
		return
	end
	local cap = State.GetStorageCap()
	label.Text = Strings.ALIENS_COUNT_CAP:format(Builder.formatNumber(count), Builder.formatNumber(cap))
	label.TextColor3 = if StorageMath.IsFull(count, cap) then Theme.Colors.Close elseif StorageMath.IsWarning(count, cap) then Theme.Colors.Featured else Theme.Colors.White
end

-- Server calls -------------------------------------------------------------

-- Invokes a RemoteFunction that answers (ok, reason). Runs in its own thread: callers are taps.
local function ask(name: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func(name):InvokeServer()
		pending = false
		if ok ~= true then
			print(("[%s] %s refused: %s"):format(Config.WorkingTitle, name, tostring(reason)))
		end
	end)
end

-- One RemoteFunction call that answers (ok, reason), guarded so a remote that errors never leaves `pending` set.
-- It yields: callers run it inside task.spawn.
local function invoke(name: string, ...: any): (boolean, string?)
	local remote = Net.func(name)
	local called, ok, reason = pcall(remote.InvokeServer, remote, ...)
	if not called then
		return false, tostring(ok)
	end
	return ok == true, if reason ~= nil then tostring(reason) else nil
end

-- Companions ---------------------------------------------------------------

-- The perks line for the followers in the profile mirror, and whether any perk is active. The same sum the server
-- makes (Companions.Perk): each follower gives the perk of its species' first job at its tier's factor, a kind's
-- total is capped, and zero kinds are skipped. Display only; Buffs and the capture maths read the server's number.
local function perksLine(profile: Types.Profile): (string, boolean)
	local sums: { [string]: number } = {}
	for _, uid in ipairs(profile.companions) do
		local record = profile.aliens[uid]
		local def = if record then Species.ById[record.species] else nil
		local firstJob = if def then def.jobs[1] else nil
		if def and firstJob then
			local perk = Companions.PerkByJob[firstJob.job]
			local factor = Companions.TierFactor[def.tier]
			if perk and factor then
				sums[perk.kind] = (sums[perk.kind] or 0) + perk.amount * factor
			end
		end
	end
	local parts: { string } = {}
	for _, kind in ipairs(PERK_ORDER) do
		local amount = sums[kind] or 0
		local cap = Companions.PerkCap[kind]
		if cap then
			amount = math.min(amount, cap)
		end
		if amount > 0 then
			table.insert(parts, Builder.text("PERK_" .. kind):format(math.floor(amount * 100 + 0.5)))
		end
	end
	if #parts == 0 then
		return Strings.ALIENS_PERKS_NONE, false
	end
	return Strings.ALIENS_PERKS:format(table.concat(parts, Strings.ALIENS_PERK_SEPARATOR)), true
end

-- Asks the server to start or stop a follow. The mirror is never touched here: the server's CompanionsChanged push
-- lands in State and the "companions" topic redraws the screen. One request in flight at a time.
local function setCompanion(uid: string, follow: boolean, name: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = invoke("SetCompanion", uid, follow)
		pending = false
		if ok then
			if follow then
				Toast.Show(Strings.TOAST_COMPANION_ON:format(name), Theme.Colors.Confirm)
			else
				Toast.Show(Strings.TOAST_COMPANION_OFF:format(name), Theme.Rarity.Common)
			end
		elseif reason == "Full" then
			Toast.Show(Strings.TOAST_COMPANION_FULL:format(State.GetCompanionSlots()), Theme.Rarity.Common)
		elseif reason == "Seated" then
			Toast.Show(Strings.TOAST_COMPANION_SEATED:format(name), Theme.Rarity.Common)
		else
			print(("[%s] SetCompanion refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- Asks the server to ride the follower `uid`, or to hop off when `uid` is nil. The mirror is never touched here: the
-- server's CompanionsChanged push carries the riding uid into State and the "companions" topic redraws the cards.
-- One request in flight at a time.
local function setMount(uid: string?, name: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = invoke("SetMount", uid)
		pending = false
		if ok then
			if uid then
				Builder.playSound(Sounds.Mount)
				Toast.Show(Strings.TOAST_MOUNT_ON:format(name), Theme.Colors.Featured)
			else
				Builder.playSound(Sounds.Dismount)
				Toast.Show(Strings.TOAST_MOUNT_OFF:format(name), Theme.Rarity.Common)
			end
		elseif reason == "NotFollowing" then
			Toast.Show(Strings.TOAST_MOUNT_FOLLOW_FIRST:format(name), Theme.Rarity.Common)
		else
			print(("[%s] SetMount refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- Whether the data has a habitat item for this world at all (data/HomeBuild rows of kind "habitat"): the Display
-- button shows for every such world; whether one stands on the plot is asked fresh at the tap (displayAlien).
local function habitatExists(world: number): boolean
	for _, item in ipairs(HomeBuildData.Items) do
		if item.kind == "habitat" and item.worldId == world then
			return true
		end
	end
	return false
end

-- Asks the server to put the alien `uid` on display in the habitat `habitatUid`, or to bring it back to camp when
-- `habitatUid` is nil. The mirror is never touched here: the camp push (StationsChanged) carries the record's habitat
-- and the "stations" topic redraws the cards and the habitat. One request in flight at a time.
local function setDisplay(uid: string, habitatUid: string?, name: string, worldName: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = invoke("SetDisplay", uid, habitatUid)
		pending = false
		if ok then
			if habitatUid then
				Toast.Show(Strings.TOAST_DISPLAY_ON:format(name), Theme.Colors.Confirm)
			else
				Toast.Show(Strings.TOAST_DISPLAY_OFF:format(name), Theme.Rarity.Common)
			end
		elseif reason == "NotAtHome" or reason == "NoHabitat" then
			Toast.Show(Strings.TOAST_HABITAT_NONE:format(worldName), Theme.Rarity.Common)
		elseif reason == "Full" then
			Toast.Show(Strings.TOAST_HABITAT_FULL:format(worldName), Theme.Rarity.Common)
		else
			print(("[%s] SetDisplay refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- The Display button: the first habitat of the alien's world with a free place, asked fresh from the mirror. With
-- none built (it can have gone since the card was drawn) or none with room, the player is told here and no request
-- is spent (the server would refuse both).
local function displayAlien(uid: string, name: string, world: number)
	local worldName = Builder.text("WORLD_" .. world)
	local habitats = HomeRenderer.HabitatsFor(world)
	if #habitats == 0 then
		Toast.Show(Strings.TOAST_HABITAT_NONE:format(worldName), Theme.Rarity.Common)
		return
	end
	for _, habitat in ipairs(habitats) do
		if habitat.free > 0 then
			setDisplay(uid, habitat.uid, name, worldName)
			return
		end
	end
	Toast.Show(Strings.TOAST_HABITAT_FULL:format(worldName), Theme.Rarity.Common)
end

-- A tap on an alien card. The ridden card hops off first (the next tap, on a plain follower, unfollows); an alien on
-- display does nothing but click; a follower is asked to stop; a seated alien and a full set of slots are told to the player here (the server would refuse
-- both, so no request is spent); a resting alien with a free slot is asked to follow.
local function onCardTapped(uid: string, name: string)
	Builder.playSound(Sounds.Click)
	if not State.Has() then
		return
	end
	if State.GetRiding() == uid then
		setMount(nil, name)
		return
	end
	local profile = State.Get()
	local record = profile.aliens[uid]
	if not record then
		return
	end
	if record.habitat ~= nil then
		return -- on display: never follows; the Bring back button is the way off
	end
	local slots = State.GetCompanionSlots()
	if table.find(profile.companions, uid) then
		setCompanion(uid, false, name)
	elseif record.station ~= nil then
		Toast.Show(Strings.TOAST_COMPANION_SEATED:format(name), Theme.Rarity.Common)
	elseif #profile.companions >= slots then
		Toast.Show(Strings.TOAST_COMPANION_FULL:format(slots), Theme.Rarity.Common)
	else
		setCompanion(uid, true, name)
	end
end

-- Fusion -------------------------------------------------------------------

-- A species worth asking the server to fuse, found in the profile mirror: how many copies are owned (each
-- fusion consumes Fusion.DuplicatesPerLevel of them and keeps one) so the ask loop has a hard bound.
type FuseCandidate = { species: string, copies: number }

-- Species the server would fuse, in id order: the kept copy is the best one below the level cap, and only copies
-- at or below its level are fodder (a capped Lv 3 is never consumed for a plain Lv 1), so a species counts when
-- DuplicatesPerLevel such copies exist beside the kept one. `copies` is the kept copy plus its fodder, which bounds
-- the ask loop. The server re-checks everything; this only decides whether Fuse has anything to ask about.
local function fuseCandidates(profile: Types.Profile): { FuseCandidate }
	local cap = 1 + Fusion.MaxFusionLevels
	local levels: { [string]: { number } } = {}
	for _, record in pairs(profile.aliens) do
		local list = levels[record.species]
		if not list then
			list = {}
			levels[record.species] = list
		end
		table.insert(list, record.level)
	end
	local out: { FuseCandidate } = {}
	for species, list in pairs(levels) do
		local keptLevel = 0
		for _, level in ipairs(list) do
			if level < cap and level > keptLevel then
				keptLevel = level
			end
		end
		local fodder = -1 -- the kept copy itself is counted below and taken back out
		for _, level in ipairs(list) do
			if level <= keptLevel then
				fodder += 1
			end
		end
		if keptLevel > 0 and fodder >= Fusion.DuplicatesPerLevel then
			table.insert(out, { species = species, copies = fodder + 1 })
		end
	end
	table.sort(out, function(a: FuseCandidate, b: FuseCandidate): boolean
		return a.species < b.species
	end)
	return out
end

-- The server's answer to one FuseSpecies call: a result, or nil on any refusal (NotEnough, MaxLevel, ...).
local function askFuse(species: string): Types.FuseResult?
	local ok, result, reason = pcall(function()
		return Net.func("FuseSpecies"):InvokeServer(species)
	end)
	if ok and type(result) == "table" then
		return result :: Types.FuseResult
	end
	print(("[%s] FuseSpecies refused: %s"):format(Config.WorkingTitle, tostring(if ok then reason else result)))
	return nil
end

local function toastFused(result: Types.FuseResult)
	local name = speciesName(Species.ById[result.species], result.species)
	Toast.Show(Strings.TOAST_FUSED:format(name, result.level), Theme.Colors.Featured)
end

-- The Fuse button's face fades and stops taking taps while a fusion is in flight.
local function setFuseBusy(busy: boolean)
	local button = fuseButton
	local face = if button then button:FindFirstChild("Face") else nil
	if face and face:IsA("TextButton") then
		face.Active = not busy
		face.BackgroundTransparency = if busy then FUSE_BUSY_ALPHA else 0
		face.TextTransparency = if busy then FUSE_BUSY_ALPHA else 0
	end
end

-- Fuse everything fusable. One call is in flight at a time (the shared `pending`); each species is asked again
-- while the server keeps answering with a result (one level per call) until it refuses, at most as often as
-- its copies allow. The mirror is never touched: the server's camp push redraws the cards.
local function fuseAll()
	if pending then
		return
	end
	local candidates: { FuseCandidate } = if State.Has() then fuseCandidates(State.Get()) else {}
	if #candidates == 0 then
		Toast.Show(Strings.TOAST_FUSE_NONE, Theme.Rarity.Common)
		return
	end
	pending = true
	setFuseBusy(true)
	task.spawn(function()
		local last: Types.FuseResult? = nil
		for _, candidate in ipairs(candidates) do
			for _ = 1, (candidate.copies - 1) // Fusion.DuplicatesPerLevel do
				local result = askFuse(candidate.species)
				if not result then
					break
				end
				last = result
				if Fusion.ToastEach then
					toastFused(result)
				end
			end
		end
		if not last then
			Toast.Show(Strings.TOAST_FUSE_NONE, Theme.Rarity.Common) -- the server refused what the mirror allowed
		elseif not Fusion.ToastEach then
			toastFused(last)
		end
		pending = false
		setFuseBusy(false)
	end)
end

-- Station strip ------------------------------------------------------------

-- One slot square: filled (species colour, tier stroke, name beneath), open (outlined, "Open"
-- beneath) or locked (darker, no label) for slots the station has not grown into yet.
local function buildSlot(parent: Frame, index: number, width: number, profile: Types.Profile, station: Types.StationState)
	local cell = Builder.frame({
		parent = parent,
		name = "Slot" .. index,
		size = UDim2.fromScale(width, 1),
		zIndex = 4,
	})
	cell.LayoutOrder = index

	local uid = station.assigned[index]
	local record = if uid then profile.aliens[uid] else nil
	local square: Builder.FrameProps = {
		parent = cell,
		name = "Square",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, 0.62),
		anchor = Vector2.new(0.5, 0),
		corner = Theme.Corner.Card,
		aspect = 1,
		zIndex = 4,
	}
	local label: string? = nil
	if index > station.slots then
		square.color = Builder.darker(Theme.Rarity.Common)
		square.stroke = Theme.Stroke.Text
		square.strokeColor = Theme.Colors.Outline
	elseif record then
		local def = Species.ById[record.species]
		square.color = speciesColor(def)
		square.stroke = Theme.Stroke.Button
		square.strokeColor = Builder.tierColor(if def then def.tier else "Common")
		label = speciesName(def, record.species)
	else
		square.color = Theme.Colors.Panel
		square.stroke = Theme.Stroke.Button
		square.strokeColor = Theme.Colors.Outline
		label = Strings.STATION_EMPTY_SLOT
	end
	Builder.frame(square)
	if label then
		Builder.label({
			parent = cell,
			name = "Name",
			text = label,
			textSize = Theme.TextSize.Min,
			position = UDim2.fromScale(0.5, 0.66),
			size = UDim2.fromScale(1, 0.34),
			anchor = Vector2.new(0.5, 0),
			zIndex = 5,
		})
	end
end

local function buildStationCard(parent: Frame, index: number, width: number, job: string, profile: Types.Profile)
	local station = stationOf(profile, job)
	local assigned = #station.assigned
	local card = Builder.frame({
		parent = parent,
		name = "Station" .. job,
		size = UDim2.fromScale(width, 1),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = if assigned > 0 then Theme.Colors.Featured else Theme.Rarity.Common,
		zIndex = 3,
	})
	card.LayoutOrder = index

	Builder.label({
		parent = card,
		name = "Name",
		text = Builder.text("STATION_" .. job),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.04, 0.05),
		size = UDim2.fromScale(0.6, 0.25),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Slots",
		text = Strings.STATION_SLOTS:format(assigned, station.slots),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.96, 0.05),
		size = UDim2.fromScale(0.3, 0.25),
		anchor = Vector2.new(1, 0),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Job",
		text = Builder.text("JOB_" .. job),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.04, 0.3),
		size = UDim2.fromScale(0.46, 0.18),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Rate",
		text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(Economy.stationRate(profile, job) * 60)),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.96, 0.3),
		size = UDim2.fromScale(0.46, 0.18),
		anchor = Vector2.new(1, 0),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})

	local slots = Builder.frame({
		parent = card,
		name = "Slots",
		position = UDim2.fromScale(0.04, 0.52),
		size = UDim2.fromScale(0.92, 0.44),
		zIndex = 4,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(STRIP_GAP, 0)
	layout.Parent = slots
	local max = Config.StationMaxSlots + (station.bonus or 0) -- bought slots (the +1 pass) add a square past the cap
	local slotWidth = (1 - STRIP_GAP * (max - 1)) / max
	for slot = 1, max do
		buildSlot(slots, slot, slotWidth, profile, station)
	end
end

local function rebuildStrip(profile: Types.Profile)
	local parent = strip
	if not parent then
		return
	end
	clearChildren(parent)
	local jobs = unlockedJobs(profile)
	if #jobs == 0 then
		return
	end
	local width = (1 - STRIP_GAP * (#jobs - 1)) / #jobs
	for index, job in ipairs(jobs) do
		buildStationCard(parent, index, width, job, profile)
	end
end

-- Grid -----------------------------------------------------------------------

-- Sizes the cells and the canvas so every card is square and the canvas is exactly as tall as the
-- rows need. Children of a ScrollingFrame scale against the canvas, so the cell height is divided by
-- the page count. Everything set here is a Scale value; pixels are only read to find the ratio.
local function layoutGrid()
	local frame, layout = grid, gridLayout
	if not frame or not layout then
		return
	end
	local abs = frame.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return
	end
	local cellPx = CELL_W * abs.X
	local gapPx = CELL_GAP * abs.X
	-- With pixel cell heights the canvas can follow the content exactly (no feedback), so the page maths
	-- that ran against a not-yet-final frame height (a 1020 px canvas for 336 px of cards) is gone.
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.fromScale(0, 0)
	-- The cell height is the cell width in pixels, derived from the frame on every resize. A Scale height
	-- inside a ScrollingFrame resolves against the canvas, and the canvas grows to hold the grid's content,
	-- so a Scale cell fed back into a taller canvas until one card sat 150 px down a 565 px canvas (Studio,
	-- 2026-10-05). Width and padding stay Scale.
	layout.CellSize = UDim2.new(CELL_W, 0, 0, cellPx) -- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)
	layout.CellPadding = UDim2.new(CELL_GAP, 0, 0, gapPx) -- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)
end

local function buildCard(parent: ScrollingFrame, index: number, entry: Entry)
	local record, def = entry.record, entry.def
	local tierColor = Builder.tierColor(if def then def.tier else "Common")
	local card = Builder.frame({
		parent = parent,
		name = record.uid,
		color = tierColor,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(tierColor),
		aspect = 1,
		zIndex = 3,
	})
	card.LayoutOrder = index
	Builder.gradient(card, tierColor)

	-- The placeholder stand-in until art exists: a square in the species colour with the shape name.
	local shape = Builder.frame({
		parent = card,
		name = "Shape",
		position = UDim2.fromScale(0.5, SHAPE_Y),
		size = UDim2.fromScale(SHAPE_W, SHAPE_W),
		anchor = Vector2.new(0.5, 0.5),
		color = speciesColor(def),
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 4,
	})
	Builder.label({
		parent = shape,
		name = "ShapeName",
		text = shapeName(def),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	Builder.label({
		parent = card,
		name = "Name",
		text = entry.name,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, NAME_Y),
		size = UDim2.fromScale(0.92, NAME_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})

	local chip = Builder.pill({
		parent = card,
		name = "Speed",
		position = UDim2.fromScale(1 - CORNER_X, CORNER_Y),
		size = UDim2.fromScale(SPEED_W, CORNER_H),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})
	Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.ALIENS_SPEED:format(("%.1f"):format(entry.speed)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 6,
	})

	if record.overlay ~= "None" then
		local badge = Builder.pill({
			parent = card,
			name = "Overlay",
			position = UDim2.fromScale(CORNER_X, CORNER_Y),
			size = UDim2.fromScale(BADGE_W, CORNER_H),
			color = Theme.Colors.Codex,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 5,
		})
		Builder.gradient(badge, Theme.Colors.Codex)
		Builder.label({
			parent = badge,
			name = "Text",
			text = Builder.text("OVERLAY_" .. record.overlay),
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 6,
		})
	end

	-- A fused copy (level above 1; level 1 shows nothing) wears its level in gold: top left, the speed chip's
	-- size, or directly under the overlay badge when the badge already sits in that corner.
	if record.level > 1 then
		local levelChip = Builder.pill({
			parent = card,
			name = "Level",
			position = UDim2.fromScale(CORNER_X, if record.overlay ~= "None" then CORNER_Y + CORNER_H + CORNER_GAP else CORNER_Y),
			size = UDim2.fromScale(SPEED_W, CORNER_H),
			color = Theme.Colors.Trough,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 5,
		})
		Builder.label({
			parent = levelChip,
			name = "Text",
			text = Strings.ALIENS_LEVEL:format(record.level),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 6,
		})
	end

	-- A band that names itself (Tiny, Big, HUGE: data/Sizes label) gets a small gold chip at the left of
	-- the chip row; Normal and Small show nothing.
	local displayed = record.habitat ~= nil
	local band = Sizes.ById[record.size] or Sizes.ById[Sizes.Default]
	if band.label and not displayed then
		local sizeChip = Builder.pill({
			parent = card,
			name = "Size",
			position = UDim2.fromScale(0.02, CHIP_Y),
			size = UDim2.fromScale(CHIP_W, CHIP_H),
			anchor = Vector2.new(0, 0.5),
			color = Theme.Colors.Trough,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 6,
		})
		Builder.label({
			parent = sizeChip,
			name = "Text",
			text = Builder.text("SIZE_" .. band.id),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 7,
		})
	end

	-- The growth chip (data/Growth) mirrors the size chip at the right of the chip row. A seated alien with a
	-- stage ahead shows the work time left to it in white ("2h", "59m": only a working alien earns time); otherwise
	-- a stage that names itself (Grown, Elder) shows its name in sky blue, and a resting Hatchling shows nothing.
	local job = record.station
	local stage = Growth.StageOf(record)
	local secondsLeft = Growth.SecondsToNext(record.workedSeconds or 0)
	local chipText: string? = nil
	local chipColor = Theme.Colors.Select
	if job and secondsLeft then
		chipText = timeLeftText(secondsLeft)
		chipColor = Theme.Colors.White
	elseif stage.label then
		chipText = Builder.text("STAGE_" .. stage.id)
	end
	if chipText and not displayed then
		local stageChip = Builder.pill({
			parent = card,
			name = "Stage",
			position = UDim2.fromScale(0.98, CHIP_Y),
			size = UDim2.fromScale(CHIP_W, CHIP_H), -- the size chip's mirror
			anchor = Vector2.new(1, 0.5),
			color = Theme.Colors.Trough,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 6,
		})
		Builder.label({
			parent = stageChip,
			name = "Text",
			text = chipText,
			textSize = Theme.TextSize.Body,
			color = chipColor,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 7,
		})
	end

	-- What it is doing, one line: where it works as the station's name alone ("Picnic Table"; one line at the
	-- minimum size is all a square card has, and the job verb is the station's), that it follows the player, or
	-- that a resting one can be tapped to follow. A following mount has a Ride button in this slot instead (below),
	-- so it gets no status label: "Ride" says it follows, and "Hop off" says it is ridden.
	local rideable = entry.following and def ~= nil and def.ride ~= nil
	-- At home an alien whose world has a habitat row in the data gets a Display button when it rests (with none built
	-- yet the tap says to build one, so the player learns the habitat exists), or a Bring back button when it is on
	-- display; either takes the status slot like the Ride button. An alien on display shows the purple "On display"
	-- pill (below) in the chip row instead of a status label.
	local displayWorld = if def then def.world else nil
	local canDisplay = Place.IsHome()
		and not State.IsVisiting() -- a guest never puts an alien on display at someone else's home
		and displayWorld ~= nil
		and job == nil
		and not entry.following
		and not displayed
		and habitatExists(displayWorld)
	local canBringBack = Place.IsHome() and not State.IsVisiting() and displayWorld ~= nil and displayed
	local statusText = Strings.ALIENS_TAP_FOLLOW
	local statusColor = Theme.Rarity.Common
	if job then
		statusText = Builder.text("STATION_" .. job)
		statusColor = Theme.Colors.White
	elseif entry.following then
		statusText = Strings.ALIENS_FOLLOWING
		statusColor = Theme.Colors.Confirm
	end
	if displayed then
		-- The size and growth chips stand aside for a full-width pill (a displayed alien is not working, so it
		-- has no growth countdown to show).
		local pill = Builder.pill({
			parent = card,
			name = "OnDisplay",
			position = UDim2.fromScale(0.5, CHIP_Y),
			size = UDim2.fromScale(0.94, CHIP_H),
			anchor = Vector2.new(0.5, 0.5),
			color = Theme.Colors.Codex,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 6,
		})
		Builder.label({
			parent = pill,
			name = "Text",
			text = Strings.ALIENS_ON_DISPLAY,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 7,
		})
	end
	if not rideable and not canDisplay and not displayed then
		Builder.label({
			parent = card,
			name = "Status",
			text = statusText,
			textSize = Theme.TextSize.Body,
			color = statusColor,
			position = UDim2.fromScale(0.5, STATUS_Y),
			size = UDim2.fromScale(0.94, STATUS_H),
			anchor = Vector2.new(0.5, 0),
			zIndex = 4,
		})
	end

	-- A following mount gets a Ride button (gold; blue "Hop off" on the ridden card) in the status slot, above the
	-- Tap overlay. It only asks: the card redraws from the server's push. No other card has one: a resting
	-- mount shows none until it follows.
	if rideable then
		Builder.button({
			parent = card,
			name = "Ride",
			text = if entry.riding then Strings.ALIENS_HOP_OFF else Strings.ALIENS_RIDE,
			color = if entry.riding then Theme.Colors.Select else Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			zIndex = RIDE_Z,
		}, function()
			setMount(if entry.riding then nil else record.uid, entry.name)
		end)
	end

	-- Display (Codex purple) and Bring back (Common grey) take the status slot, above the Tap overlay. They only ask:
	-- the card redraws from the server's push.
	if canDisplay and def ~= nil then
		local world = def.world
		Builder.button({
			parent = card,
			name = "Display",
			text = Strings.ALIENS_DISPLAY,
			color = Theme.Colors.Codex,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			zIndex = RIDE_Z,
		}, function()
			displayAlien(record.uid, entry.name, world)
		end)
	elseif canBringBack and def ~= nil then
		local worldName = Builder.text("WORLD_" .. def.world)
		Builder.button({
			parent = card,
			name = "BringBack",
			text = Strings.ALIENS_BRING_BACK,
			color = Theme.Rarity.Common,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			zIndex = RIDE_Z,
		}, function()
			setDisplay(record.uid, nil, entry.name, worldName)
		end)
	end

	-- An invisible button over the whole card, above every chip: a tap asks to follow or stop (onCardTapped), or to
	-- hop off on the ridden card.
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = TAP_Z
	tap.Parent = card
	-- Holding the card for Storage.HoldSeconds opens its Release panel instead of following: the press must stay down
	-- and not drift past Storage.HoldMovePixels (a drag is the grid scrolling). The tap that ends a hold is swallowed.
	local holdId = 0
	local held = false
	tap.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		held = false
		holdId += 1
		local mine = holdId
		local start = input.Position
		task.delay(Storage.HoldSeconds, function()
			if holdId ~= mine or not open then
				return
			end
			local state = input.UserInputState
			if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then
				return
			end
			if (input.Position - start).Magnitude > Storage.HoldMovePixels then
				return
			end
			held = true
			Builder.playSound(Sounds.Click)
			ReleasePanel.ShowAlien(record.uid, entry.name, speciesColor(def))
		end)
	end)
	tap.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holdId += 1
		end
	end)
	tap.Activated:Connect(function()
		if held then
			held = false
			return
		end
		onCardTapped(record.uid, entry.name)
	end)
end

-- Owned aliens: the ridden one first, then followers, then fastest first, then by name, then by uid so the order is
-- stable between refreshes.
local function sortedEntries(profile: Types.Profile): { Entry }
	local ridden = State.GetRiding()
	local followers: { [string]: boolean } = {}
	for _, uid in ipairs(profile.companions) do
		followers[uid] = true
	end
	local entries: { Entry } = {}
	for _, record in pairs(profile.aliens) do
		local def = Species.ById[record.species]
		table.insert(entries, {
			record = record,
			def = def,
			speed = Economy.workSpeed(record),
			name = speciesName(def, record.species),
			following = followers[record.uid] == true,
			riding = ridden ~= nil and record.uid == ridden,
		})
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		if a.riding ~= b.riding then
			return a.riding
		end
		if a.following ~= b.following then
			return a.following
		end
		if a.speed ~= b.speed then
			return a.speed > b.speed
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.record.uid < b.record.uid
	end)
	return entries
end

local function rebuildGrid(profile: Types.Profile)
	local frame = grid
	if not frame then
		return
	end
	local entries = sortedEntries(profile)
	cardCount = #entries
	clearChildren(frame)
	for index, entry in ipairs(entries) do
		buildCard(frame, index, entry)
	end
	layoutGrid()
	if emptyLabel then
		emptyLabel.Visible = cardCount == 0
	end
	setCount(cardCount)
end

-- The count row's companion label, the perks line and the Companion Token button: slots in use, the perks they
-- give, and the button shown only while a token is held (its label carries how many).
local function updateCompanionRows(profile: Types.Profile)
	if companionsLabel then
		companionsLabel.Text = Strings.ALIENS_COMPANIONS:format(#profile.companions, State.GetCompanionSlots())
	end
	if perksLabel then
		local text, any = perksLine(profile)
		perksLabel.Text = text
		perksLabel.TextColor3 = if any then Theme.Colors.Confirm else Theme.Rarity.Common
	end
	local button = tokenButton
	if button then
		local tokens = profile.inventory.items[Companions.TokenItem] or 0
		button.Visible = tokens > 0
		local face = button:FindFirstChild("Face")
		if face and face:IsA("TextButton") then
			face.Text = Strings.ALIENS_USE_TOKEN:format(tokens)
		end
	end
end

-- Storage Bay ----------------------------------------------------------------

-- The Bay button's face for the profile mirror: the next level's offer in green while it can be bought; in grey the same
-- offer when the Scrap is short, the world it waits for, or that the Bay is maxed out. The server judges the purchase
-- (BuyStorageBay); this only says what a tap will do. The grey face still takes taps: a tap on it explains in a toast.
local function refreshStorageRow()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	setCount(cardCount)
	local row, why = StorageMath.NextBayLevel(State.GetBayLevel(), profile.world.unlocked)
	local perLevel = Builder.formatNumber(Storage.Bay.PerLevel)
	if not row then
		Builder.restyleButton(bayButton, Strings.STORAGE_BAY_MAX, Theme.Rarity.Common, true)
	elseif why == "NeedsWorld" then
		Builder.restyleButton(bayButton, Strings.STORAGE_BAY_NEEDS_WORLD:format(perLevel, row.world), Theme.Rarity.Common, true)
	else
		local color = if profile.scrap >= row.scrap then Theme.Colors.Confirm else Theme.Rarity.Common
		Builder.restyleButton(bayButton, Strings.STORAGE_BAY_BUY:format(perLevel, Builder.formatNumber(row.scrap)), color, true)
	end
end

-- A tap on the Bay button: a toast for each reason the level cannot be bought (never a silent tap), else the server is
-- asked. It answers (ok, reason, the new cap); the toast on success says how much the cap rose, from the cap shown before.
local function buyStorageBay()
	if bayBusy or not State.Has() then
		return
	end
	local profile = State.Get()
	local row, why = StorageMath.NextBayLevel(State.GetBayLevel(), profile.world.unlocked)
	if not row then
		Toast.Show(Strings.TOAST_STORAGE_BAY_MAX, Theme.Rarity.Common)
		return
	end
	if why == "NeedsWorld" then
		Toast.Show(Strings.TOAST_STORAGE_BAY_NEEDS_WORLD:format(row.world), Theme.Rarity.Common)
		return
	end
	if profile.scrap < row.scrap then
		Toast.Show(Strings.TOAST_STORAGE_BAY_NEED_SCRAP, Theme.Rarity.Common)
		return
	end
	bayBusy = true
	local before = State.GetStorageCap()
	task.spawn(function()
		local remote = Net.func("BuyStorageBay")
		local called, ok, reason, newCap = pcall(remote.InvokeServer, remote)
		bayBusy = false
		if called and ok == true then
			local rose = if type(newCap) == "number" then math.max(0, newCap - before) else Storage.Bay.PerLevel
			Toast.Show(Strings.TOAST_STORAGE_BAY_BOUGHT:format(Builder.formatNumber(rose)), Theme.Colors.Confirm)
			return
		end
		local refusal = if called then tostring(reason) else tostring(ok)
		print(("[%s] BuyStorageBay refused: %s"):format(Config.WorkingTitle, refusal))
		if refusal == "NotEnoughScrap" then
			Toast.Show(Strings.TOAST_STORAGE_BAY_NEED_SCRAP, Theme.Rarity.Common)
		elseif refusal == "NeedsWorld" then
			Toast.Show(Strings.TOAST_STORAGE_BAY_NEEDS_WORLD:format(row.world), Theme.Rarity.Common)
		elseif refusal == "Max" then
			Toast.Show(Strings.TOAST_STORAGE_BAY_MAX, Theme.Rarity.Common)
		else
			Toast.Show(Strings.TOAST_STORAGE_BAY_FAILED, Theme.Rarity.Common)
		end
		refreshStorageRow()
	end)
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	rebuildStrip(profile)
	rebuildGrid(profile)
	updateCompanionRows(profile)
	refreshStorageRow()
end

-- The inventory and the passes touch the companion rows only (a token arrived, a pass was bought), not the cards.
local function refreshCompanionRows()
	if open and State.Has() then
		updateCompanionRows(State.Get())
	end
end

-- Spends a Companion Token for one more slot. The server did exactly Companions.TokenSlots more slots when it says
-- ok, so the mirror takes the same step (the inventory push brings the token count); a refusal only redraws.
local function useToken()
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = invoke("UseCompanionToken")
		pending = false
		if ok then
			if State.Has() then
				local profile = State.Get()
				profile.companionSlots += Companions.TokenSlots
			end
			refresh()
			Toast.Show(Strings.TOAST_COMPANION_SLOT:format(State.GetCompanionSlots()), Theme.Colors.Confirm)
		else
			print(("[%s] UseCompanionToken refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			refresh()
		end
	end)
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("AliensScreen", 20)
	root.Enabled = false
	gui = root

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		AliensScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.35,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.ALIENS_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(0.985, 0.015),
		size = UDim2.fromScale(0.11, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		AliensScreen.Close()
	end)

	-- Release: the menu of "Release all unused" (and the hint about holding a card), over the panel.
	Builder.button({
		parent = body,
		name = "Release",
		text = Strings.RELEASE_BUTTON,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(RELEASE_X, RELEASE_Y),
		size = UDim2.fromScale(RELEASE_W, RELEASE_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		ReleasePanel.ShowMenu()
	end)
	ReleasePanel.Build(root)

	-- 1. Station strip: one card per unlocked job, rebuilt on refresh.
	local stripFrame = Builder.frame({
		parent = body,
		name = "Stations",
		position = UDim2.fromScale(Theme.Margin, STRIP_Y),
		size = UDim2.fromScale(1 - Theme.Margin * 2, STRIP_H),
		zIndex = 3,
	})
	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Padding = UDim.new(STRIP_GAP, 0)
	stripLayout.Parent = stripFrame
	strip = stripFrame

	-- 2. Storage band: the aliens owned over the storage cap with the companion slots in use under it, at the left, and the
	-- Storage Bay button at the right; the perks line is under them (one line at the minimum size).
	countLabel = Builder.label({
		parent = body,
		name = "Count",
		text = Strings.ALIENS_COUNT_CAP:format(Builder.formatNumber(0), Builder.formatNumber(Storage.BaseCap)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(Theme.Margin, STORAGE_Y),
		size = UDim2.fromScale(STORAGE_LEFT_W, COUNT_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})
	companionsLabel = Builder.label({
		parent = body,
		name = "Companions",
		text = Strings.ALIENS_COMPANIONS:format(0, Config.CompanionSlots),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(Theme.Margin, STORAGE_Y + COUNT_H),
		size = UDim2.fromScale(STORAGE_LEFT_W, COUNT_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})
	bayButton = Builder.button({
		parent = body,
		name = "StorageBay",
		text = Strings.STORAGE_BAY_BUY:format(Builder.formatNumber(Storage.Bay.PerLevel), Builder.formatNumber(Storage.Bay.Levels[1].scrap)),
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(1 - Theme.Margin, STORAGE_Y),
		size = UDim2.fromScale(BAY_W, BAY_H),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, buyStorageBay)
	perksLabel = Builder.label({
		parent = body,
		name = "Perks",
		text = Strings.ALIENS_PERKS_NONE,
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(Theme.Margin, PERKS_Y),
		size = UDim2.fromScale(1 - Theme.Margin * 2, PERKS_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})

	-- 3. The grid: a ScrollingFrame with a thin dark bar; cards are rebuilt on refresh.
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Theme.Margin, GRID_Y)
	scroller.Size = UDim2.fromScale(1 - Theme.Margin * 2, GRID_H)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.fromScale(0, 0)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = body
	local cells = Instance.new("UIGridLayout")
	cells.FillDirection = Enum.FillDirection.Horizontal
	cells.FillDirectionMaxCells = COLUMNS
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cells.VerticalAlignment = Enum.VerticalAlignment.Top
	cells.StartCorner = Enum.StartCorner.TopLeft
	cells.CellSize = UDim2.fromScale(CELL_W, CELL_W)
	cells.CellPadding = UDim2.fromScale(CELL_GAP, CELL_GAP)
	cells.Parent = scroller
	grid = scroller
	gridLayout = cells
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGrid)

	local empty = Builder.label({
		parent = body,
		name = "Empty",
		text = Strings.ALIENS_EMPTY,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, GRID_Y + GRID_H / 2),
		size = UDim2.fromScale(0.7, 0.1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	empty.Visible = false
	emptyLabel = empty

	-- 4. Footer: a button row (Companion Token while one is held, Fuse, then Optimize at the right edge) over a
	-- one-line hint in the minimum text size. Optimize asks the server to reseat the crew; Fuse asks it to fuse every
	-- species with spare copies; the token button asks it to spend a Companion Token on a slot.
	local buttonsBottom = 1 - Theme.Margin - HINT_H
	Builder.button({
		parent = body,
		name = "Optimize",
		text = Strings.OPTIMIZE,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin, buttonsBottom),
		size = UDim2.fromScale(FOOTER_BUTTON_W, FOOTER_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		ask("StationOptimize")
	end)
	fuseButton = Builder.button({
		parent = body,
		name = "Fuse",
		text = Strings.FUSE_BUTTON,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(1 - Theme.Margin - FOOTER_BUTTON_W - FOOTER_GAP, buttonsBottom),
		size = UDim2.fromScale(FOOTER_BUTTON_W, FOOTER_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, fuseAll)
	local token = Builder.button({
		parent = body,
		name = "UseToken",
		text = Strings.ALIENS_USE_TOKEN:format(0),
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin - 2 * (FOOTER_BUTTON_W + FOOTER_GAP), buttonsBottom), -- left of Fuse, a gap between
		size = UDim2.fromScale(TOKEN_BUTTON_W, FOOTER_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, useToken)
	token.Visible = false -- shown by updateCompanionRows while a token is held
	tokenButton = token
	Builder.label({
		parent = body,
		name = "FuseHint",
		text = Strings.FUSE_HINT:format(1 + Fusion.MaxFusionLevels),
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, 1 - Theme.Margin),
		size = UDim2.fromScale(1 - Theme.Margin * 2, HINT_H),
		anchor = Vector2.new(0.5, 1),
		zIndex = 3,
	})

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "stations", "rate", "companions", "home", "visit" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
	for _, topic in ipairs({ "inventory", "purchases" }) do
		State.OnChanged(topic :: State.Topic, refreshCompanionRows)
	end
	-- The Bay button and the count follow the cap (storage), what the next level costs (scrap), the world it waits for (world)
	-- and the pass (purchases, in the cap State derives before the server's first push).
	for _, topic in ipairs({ "storage", "scrap", "world", "purchases" }) do
		State.OnChanged(topic :: State.Topic, refreshStorageRow)
	end
end

-- Public API -------------------------------------------------------------

function AliensScreen.IsOpen(): boolean
	return open
end

function AliensScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function AliensScreen.Close()
	if not open then
		return
	end
	open = false
	ReleasePanel.Hide()
	local root, body = gui, panel
	if root and body then
		Builder.close(body, function()
			if not open then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

function AliensScreen.Toggle()
	if open then
		AliensScreen.Close()
	else
		AliensScreen.Open()
	end
end

return AliensScreen
