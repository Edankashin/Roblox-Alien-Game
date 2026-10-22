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
-- The look is block cells (UI Playbook "Block cells" and "Screens after the HUD", Decisions B44): the panel is a cream block plate
-- at the panel cell, the header tab, the close button and every button block plates and block buttons; the station cards and the
-- alien cards are edged blocks (lit top row, shaded edges, no grout or jitter: a grid of them stays a few frames each), the slot
-- squares and the chips flat blocks, a rarity ring the ink. The layout, every binding and every string key are as before.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local HomeBuildData = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local Growth = require(Shared:WaitForChild("Growth"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local BadgeFit = require(Shared:WaitForChild("BadgeFit"))
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
local ViewFit = require(Shared:WaitForChild("ViewFit"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local Toast = require(script.Parent.Toast)
local ScrapGap = require(script.Parent.ScrapGap)
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
-- The picture area, where the species' model fills the card (framed whole by its bounding box, SpeciesThumb): under the corner chips
-- and the chip row, above the name. The plus block of SHAPE_Y stays only as the empty state, when there is no model.
local PICTURE_Y = 0.08
local PICTURE_W = 0.8
local PICTURE_H = 0.58
local CHIP_W = 0.38
local CHIP_Y = 0.59
local CHIP_H = 0.14
local NAME_Y = 0.66
local NAME_H = 0.14
local STATUS_Y = 0.80
local STATUS_H = 0.14
local RIDE_Y = 0.78 -- the Ride button takes the status slot but stands taller (a 21 px tap target at the reference card, not 17)
local RIDE_H = 0.18
local CARD_ROWS = 10 -- an alien card is an edged block this many cells tall (about 7.5 px cells on an iPhone SE card of 83 px)
local SQUARE_ROWS = 3 -- the shape square, a slot square and a chip: flat blocks of the fewest rows a stepped corner takes
local STATION_ROWS = 8 -- a station card: an edged block this many rows tall (the strip is 0.18 of the screen)
-- A station card's slot row (UI Playbook "Aliens slot names"): the row is SLOTS_W of the card from SLOTS_X; a slot's square is
-- SLOT_SQUARE_H of the row and its name the rest, one line at the 14 px floor in the slot's own width and no wider, so the gap
-- between two slots is a gap between their names too ("MoopMoopMoop", Studio 2026-10-22). "Moop" and "Open" fit whole with three
-- slots at iPhone SE (40 px of label, tests/BlockMath.spec.luau "Aliens slot names"); a name wider than its slot ends in an
-- ellipsis instead of wrapping into a cut second line ("Moo") or running into its neighbour.
local SLOTS_X = 0.02
local SLOTS_W = 0.96
local SLOT_SQUARE_H = 0.5
local PANEL_H = 0.78 -- the panel's height, of the screen (its rows come from it, at the panel cell)
local PANEL_ASPECT = 1.35

-- The card's top corners: the speed chip top right, the overlay badge top left, and a fused copy's level chip
-- (the speed chip's size) in the top-left corner too, or directly under the badge when the badge holds it.
-- The badge is fitted to its name (Shared/BadgeFit, widths measured once by Builder.overlayName at the 14 px floor): it is
-- BADGE_W wide at least and shares the first row with the speed chip while it stays within BADGE_BESIDE_W. A name wider than
-- that takes the whole row (BADGE_FULL_W) and the speed and level chips move to the row under it; a name wider than the row
-- ("Launch Gold" on a card under about 105 px, every phone) wraps to one pill per word, and the speed chip takes the row
-- beside the short last word. A row is CORNER_H tall and starts CORNER_H + CORNER_GAP under the one above.
local CORNER_X = 0.04
local CORNER_Y = 0.04
local CORNER_H = 0.17
local SPEED_W = 0.36
local BADGE_W = 0.5
local CORNER_GAP = 0.01
local BADGE_FULL_W = 1 - 2 * CORNER_X
local BADGE_BESIDE_W = BADGE_FULL_W - SPEED_W - CORNER_GAP

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
local badgeFits: { (number) -> () } = {} -- one per overlay badge on the cards now drawn; each takes the card's width in px and refits its badge
local emptyLabel: TextLabel? = nil
local fuseButton: Frame? = nil
local cardCount = 0
local open = false
local pending = false -- one server request in flight at a time
local bayBusy = false -- a BuyStorageBay request is in flight

-- The cards' model views (SpeciesThumb): one entry per card drawn, its view made only while the card is within a window's height
-- of the grid's visible window (ViewFit.Near) and dropped when it scrolls farther, so a full storage holds a few rows of
-- ViewportFrames. A model fills the card's picture area and the colour square (the plus block) goes; without a model the square
-- stays and shows the species' name (never the placeholder shape's).
type CardView = { square: Frame, picture: Frame, label: TextLabel, def: Types.SpeciesDef?, thumb: SpeciesThumb.Thumb? }
local cardViews: { CardView } = {}

-- Helpers ----------------------------------------------------------------

local function speciesColor(def: Types.SpeciesDef?): Color3
	return if def then Color3.fromHex(def.placeholder.color) else Theme.Rarity.Common
end

local function speciesName(def: Types.SpeciesDef?, id: string): string
	return if def then def.name else id
end

-- Gives the cards near the grid's window their model views and drops the views of cards far from it.
local function syncCardViews()
	local frame = grid
	if not frame or #cardViews == 0 then
		return
	end
	local viewTop = frame.AbsolutePosition.Y
	local viewBottom = viewTop + frame.AbsoluteSize.Y
	local margin = frame.AbsoluteSize.Y
	for _, entry in ipairs(cardViews) do
		local top = entry.square.AbsolutePosition.Y
		local near = ViewFit.Near(top, top + entry.square.AbsoluteSize.Y, viewTop, viewBottom, margin)
		local thumb = entry.thumb
		if near and not thumb then
			local made = SpeciesThumb.New(entry.picture, 1, PICTURE_W / PICTURE_H)
			entry.thumb = made
			entry.square.Visible = not SpeciesThumb.Show(made, entry.def, false)
		elseif not near and thumb then
			SpeciesThumb.Destroy(thumb)
			entry.thumb = nil
			entry.square.Visible = true
		end
	end
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
-- `habitatUid` is nil. The mirror is never touched here: the camp push (an AliensDelta) carries the record's habitat
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
local function askFuse(species: string): (Types.FuseResult?, string?)
	local ok, result, reason = pcall(function()
		return Net.func("FuseSpecies"):InvokeServer(species)
	end)
	if ok and type(result) == "table" then
		return result :: Types.FuseResult, nil
	end
	local why = tostring(if ok then reason else result)
	print(("[%s] FuseSpecies refused: %s"):format(Config.WorkingTitle, why))
	return nil, why
end

local function toastFused(result: Types.FuseResult)
	local name = speciesName(Species.ById[result.species], result.species)
	Toast.Show(Strings.TOAST_FUSED:format(name, result.level), Theme.Colors.Featured)
end

-- The Fuse button's face block and text fade and it stops taking taps while a fusion is in flight.
local function setFuseBusy(busy: boolean)
	local button = fuseButton
	local face = if button then button:FindFirstChild("Face") else nil
	local plate = if button then button:FindFirstChild("Plate") else nil
	if face and face:IsA("TextButton") then
		face.Active = not busy
		face.TextTransparency = if busy then FUSE_BUSY_ALPHA else 0
	end
	if plate then
		Builder.setBlockFade(plate, if busy then FUSE_BUSY_ALPHA else 0)
	end
end

-- Fuse everything fusable. One call is in flight at a time (the shared `pending`); each species is asked again
-- while the server keeps answering with a result (one level per call) until it refuses, at most as often as
-- its copies allow. The calls are paced (Config.FuseCallGapSeconds) under the server's rate limit, and a
-- RateLimited answer waits Config.FuseRetryWaitSeconds and asks the same species again, at most Config.FuseRetries
-- times, so a store with many fusable species never skips a fusion (found in Studio 2026-10-14: ten refusals in
-- 0.15 s). The mirror is never touched: the server's camp push redraws the cards.
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
				local result, why = askFuse(candidate.species)
				local retries = 0
				while not result and why == "RateLimited" and retries < Config.FuseRetries do
					retries += 1
					task.wait(Config.FuseRetryWaitSeconds)
					result, why = askFuse(candidate.species)
				end
				if not result then
					break
				end
				last = result
				if Fusion.ToastEach then
					toastFused(result)
				end
				task.wait(Config.FuseCallGapSeconds)
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
	-- A flat block: locked a darker grey in navy ink, filled the species colour in its tier's ink, open the panel cream in navy.
	local square: Builder.BlockProps = {
		parent = cell,
		name = "Square",
		color = Theme.Colors.Panel,
		aspect = 1,
		rows = SQUARE_ROWS,
		cells = false,
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, SLOT_SQUARE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	}
	local label: string? = nil
	if index > station.slots then
		square.color = Builder.darker(Theme.Rarity.Common)
	elseif record then
		local def = Species.ById[record.species]
		square.color = speciesColor(def)
		square.ink = Builder.tierColor(if def then def.tier else "Common")
		label = speciesName(def, record.species)
	else
		label = Strings.STATION_EMPTY_SLOT
	end
	Builder.blockPlate(square)
	if label then
		-- One line at the floor across the slot's pitch (its own width and the gap, so neighbours meet and never overlap); a
		-- name wider than that ends in an ellipsis rather than wrapping into a second line the row cuts off.
		local nameLabel = Builder.label({
			parent = cell,
			name = "Name",
			text = label,
			textSize = Theme.TextSize.Min,
			position = UDim2.fromScale(0.5, SLOT_SQUARE_H),
			size = UDim2.fromScale((width + STRIP_GAP) / width, 1 - SLOT_SQUARE_H),
			anchor = Vector2.new(0.5, 0),
			zIndex = 5,
		})
		nameLabel.TextScaled = false
		nameLabel.TextWrapped = false
		nameLabel.TextSize = Theme.TextSize.Min
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end
end

local function buildStationCard(parent: Frame, index: number, width: number, job: string, profile: Types.Profile)
	local station = stationOf(profile, job)
	local assigned = #station.assigned
	-- A fitted edged block (its width is the strip's share), white, its ink gold while it has workers.
	local card = Builder.blockPlate({
		parent = parent,
		name = "Station" .. job,
		color = Theme.Colors.White,
		ink = if assigned > 0 then Theme.Colors.Featured else Theme.Rarity.Common,
		rows = STATION_ROWS,
		cells = false,
		edges = true,
		size = UDim2.fromScale(width, 1),
		zIndex = 3,
	})
	card.LayoutOrder = index
	local cardTop = Builder.blockTop(card)

	Builder.label({
		parent = card,
		name = "Name",
		text = Builder.text("STATION_" .. job),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.04, 0.05),
		size = UDim2.fromScale(0.6, 0.25),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = cardTop,
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
		zIndex = cardTop,
	})
	Builder.label({
		parent = card,
		name = "Job",
		text = Builder.text("JOB_" .. job),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.04, 0.3),
		size = UDim2.fromScale(0.46, 0.18),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = cardTop,
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
		zIndex = cardTop,
	})

	local slots = Builder.frame({
		parent = card,
		name = "Slots",
		position = UDim2.fromScale(SLOTS_X, 0.52),
		size = UDim2.fromScale(SLOTS_W, 0.44),
		zIndex = cardTop,
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
	-- The cards are square, so a cell's width is a card's width. The overlay badges fit their names against it, less the
	-- scrollbar's thickness (the canvas gives it up once the cards overflow), so the fit is never a pixel short.
	local cardPx = CELL_W * math.max(0, abs.X - SCROLLBAR_PX)
	for _, fit in ipairs(badgeFits) do
		fit(cardPx)
	end
end

-- The top of row `row` of the card's corner band (row 0 is the first), as a Scale of the card.
local function cornerRowY(row: number): number
	return CORNER_Y + row * (CORNER_H + CORNER_GAP)
end

-- A chip on an alien card: a fitted flat block (the overlay badge's width changes as it fits its name) in `color`, its label on
-- top. The caller adds the label at Builder.blockTop(chip).
local function cardChip(card: Frame, name: string, color: Color3, position: UDim2, size: UDim2, anchor: Vector2?): Frame
	return Builder.blockPlate({
		parent = card,
		name = name,
		color = color,
		rows = SQUARE_ROWS,
		cells = false,
		position = position,
		size = size,
		anchor = anchor,
		zIndex = Builder.blockTop(card),
	})
end

local function buildCard(parent: ScrollingFrame, index: number, entry: Entry)
	local record, def = entry.record, entry.def
	local tierColor = Builder.tierColor(if def then def.tier else "Common")
	-- An edged block in the tier's colour: square, its grid fixed (the grid's cell sets its size), a lit top row and shaded edges.
	local card = Builder.blockPlate({
		parent = parent,
		name = record.uid,
		color = tierColor,
		aspect = 1,
		rows = CARD_ROWS,
		cells = false,
		edges = true,
		zIndex = 3,
	})
	card.LayoutOrder = index
	local top = Builder.blockTop(card)

	-- The placeholder stand-in until art exists: a flat block in the species colour with the shape name.
	local shape = Builder.blockPlate({
		parent = card,
		name = "Shape",
		color = speciesColor(def),
		aspect = 1,
		rows = SQUARE_ROWS,
		cells = false,
		position = UDim2.fromScale(0.5, SHAPE_Y),
		size = UDim2.fromScale(SHAPE_W, SHAPE_W),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = top,
	})
	local picture = Builder.frame({
		parent = card,
		name = "Picture",
		position = UDim2.fromScale(0.5, PICTURE_Y),
		size = UDim2.fromScale(PICTURE_W, PICTURE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = top,
	})
	-- The species' real model in a still view filling the picture area (SpeciesThumb, made by syncCardViews while the card is
	-- near the grid's window, and the square goes); without one, the species' display name on the square. Never the placeholder
	-- shape's name.
	local speciesLabel = Builder.label({
		parent = shape,
		name = "SpeciesName",
		text = speciesName(def, record.species),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(shape),
	})
	table.insert(cardViews, { square = shape, picture = picture, label = speciesLabel, def = def, thumb = nil })
	Builder.label({
		parent = card,
		name = "Name",
		text = entry.name,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, NAME_Y),
		size = UDim2.fromScale(0.92, NAME_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = top,
	})

	local chip = cardChip(
		card,
		"Speed",
		Theme.Block.Trough,
		UDim2.fromScale(1 - CORNER_X, CORNER_Y),
		UDim2.fromScale(SPEED_W, CORNER_H),
		Vector2.new(1, 0)
	)
	Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.ALIENS_SPEED:format(("%.1f"):format(entry.speed)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(chip),
	})

	-- The overlay badge, fitted to its name (BadgeFit.Card): one pill holding the whole name, or one pill per word when the
	-- name does not fit the card's row. The card's width is not known until the grid has laid it out, so the first pill
	-- starts at BADGE_W and layoutGrid fits it (and makes a second pill the first time a card needs one). The fit also
	-- seats the speed chip and a fused copy's level chip, which move to the row under the badge when it takes their corner.
	local levelChip: Frame? = nil
	if record.overlay ~= "None" then
		local name = Builder.overlayName(record.overlay)
		local color = Builder.overlayColor(record.overlay)
		local tinted = Builder.overlayTint(record.overlay) ~= nil
		local params = Builder.badgeParams(BADGE_W, BADGE_FULL_W, BADGE_BESIDE_W)
		local pills: { Frame } = {}
		local labels: { TextLabel } = {}
		local function pillAt(row: number): (Frame, TextLabel)
			local existing = pills[row + 1]
			if existing then
				return existing, labels[row + 1]
			end
			local pill = cardChip(
				card,
				if row == 0 then "Overlay" else "Overlay" .. (row + 1),
				color,
				UDim2.fromScale(CORNER_X, cornerRowY(row)),
				UDim2.fromScale(BADGE_W, CORNER_H)
			)
			if tinted then
				Builder.shine(pill) -- the slow sparkle of a tinted overlay (Launch Gold); it stops when the card is rebuilt
			end
			local label = Builder.label({
				parent = pill,
				name = "Text",
				text = name.whole.text,
				textSize = Theme.TextSize.Body,
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(Builder.BadgeTextFraction, 0.75),
				anchor = Vector2.new(0.5, 0.5),
				zIndex = Builder.blockTop(pill),
			})
			pills[row + 1] = pill
			labels[row + 1] = label
			return pill, label
		end
		pillAt(0)
		local fittedPx = 0
		table.insert(badgeFits, function(cardPx: number)
			if math.abs(cardPx - fittedPx) < 0.5 then
				return -- the same width as the last fit: nothing to set
			end
			fittedPx = cardPx
			local plan = BadgeFit.Card(name, cardPx, params)
			for line, text in ipairs(plan.texts) do
				local pill, label = pillAt(line - 1)
				pill.Visible = true
				pill.Position = UDim2.fromScale(CORNER_X, cornerRowY(line - 1))
				pill.Size = UDim2.fromScale(plan.widths[line], CORNER_H)
				if label.Text ~= text then
					label.Text = text
				end
			end
			for extra = #plan.texts + 1, #pills do
				pills[extra].Visible = false
			end
			chip.Position = UDim2.fromScale(1 - CORNER_X, cornerRowY(plan.speedRow))
			local level = levelChip
			if level then
				level.Position = UDim2.fromScale(CORNER_X, cornerRowY(plan.levelRow))
			end
		end)
	end

	-- A fused copy (level above 1; level 1 shows nothing) wears its level in gold: top left, the speed chip's
	-- size, or directly under the overlay badge when the badge already sits in that corner.
	if record.level > 1 then
		local levelPill = cardChip(
			card,
			"Level",
			Theme.Block.Trough,
			UDim2.fromScale(CORNER_X, cornerRowY(if record.overlay ~= "None" then 1 else 0)),
			UDim2.fromScale(SPEED_W, CORNER_H)
		)
		levelChip = levelPill
		Builder.label({
			parent = levelPill,
			name = "Text",
			text = Strings.ALIENS_LEVEL:format(record.level),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Builder.blockTop(levelPill),
		})
	end

	-- A band that names itself (Tiny, Big, HUGE: data/Sizes label) gets a small gold chip at the left of
	-- the chip row; Normal and Small show nothing.
	local displayed = record.habitat ~= nil
	local band = Sizes.ById[record.size] or Sizes.ById[Sizes.Default]
	if band.label and not displayed then
		local sizeChip = cardChip(
			card,
			"Size",
			Theme.Block.Trough,
			UDim2.fromScale(0.02, CHIP_Y),
			UDim2.fromScale(CHIP_W, CHIP_H),
			Vector2.new(0, 0.5)
		)
		Builder.label({
			parent = sizeChip,
			name = "Text",
			text = Builder.text("SIZE_" .. band.id),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Builder.blockTop(sizeChip),
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
		local stageChip = cardChip(
			card,
			"Stage",
			Theme.Block.Trough,
			UDim2.fromScale(0.98, CHIP_Y),
			UDim2.fromScale(CHIP_W, CHIP_H), -- the size chip's mirror
			Vector2.new(1, 0.5)
		)
		Builder.label({
			parent = stageChip,
			name = "Text",
			text = chipText,
			textSize = Theme.TextSize.Body,
			color = chipColor,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Builder.blockTop(stageChip),
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
		local pill = cardChip(
			card,
			"OnDisplay",
			Theme.Colors.Codex,
			UDim2.fromScale(0.5, CHIP_Y),
			UDim2.fromScale(0.94, CHIP_H),
			Vector2.new(0.5, 0.5)
		)
		Builder.label({
			parent = pill,
			name = "Text",
			text = Strings.ALIENS_ON_DISPLAY,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Builder.blockTop(pill),
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
			zIndex = top,
		})
	end

	-- A following mount gets a Ride button (gold; blue "Hop off" on the ridden card) in the status slot, above the
	-- Tap overlay. It only asks: the card redraws from the server's push. No other card has one: a resting
	-- mount shows none until it follows.
	if rideable then
		Builder.blockButton({
			parent = card,
			name = "Ride",
			text = if entry.riding then Strings.ALIENS_HOP_OFF else Strings.ALIENS_RIDE,
			color = if entry.riding then Theme.Colors.Select else Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			rows = SQUARE_ROWS,
			cells = false, -- one per card: a flat face
			zIndex = RIDE_Z,
		}, function()
			setMount(if entry.riding then nil else record.uid, entry.name)
		end)
	end

	-- Display (Codex purple) and Bring back (Common grey) take the status slot, above the Tap overlay. They only ask:
	-- the card redraws from the server's push.
	if canDisplay and def ~= nil then
		local world = def.world
		Builder.blockButton({
			parent = card,
			name = "Display",
			text = Strings.ALIENS_DISPLAY,
			color = Theme.Colors.Codex,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			rows = SQUARE_ROWS,
			cells = false, -- one per card: a flat face
			zIndex = RIDE_Z,
		}, function()
			displayAlien(record.uid, entry.name, world)
		end)
	elseif canBringBack and def ~= nil then
		local worldName = Builder.text("WORLD_" .. def.world)
		Builder.blockButton({
			parent = card,
			name = "BringBack",
			text = Strings.ALIENS_BRING_BACK,
			color = Theme.Rarity.Common,
			position = UDim2.fromScale(0.5, RIDE_Y),
			size = UDim2.fromScale(0.94, RIDE_H),
			anchor = Vector2.new(0.5, 0),
			textSize = Theme.TextSize.Body,
			rows = SQUARE_ROWS,
			cells = false, -- one per card: a flat face
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
	table.clear(badgeFits) -- the old cards' badges are gone with them
	table.clear(cardViews) -- and their views
	for index, entry in ipairs(entries) do
		buildCard(frame, index, entry)
	end
	layoutGrid()
	task.defer(syncCardViews) -- once the grid layout has placed the new cards
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
		-- Studio 2026-10-14 (50b step 4): after `/world 2` the Bay button went stale while the panel was still drawn. A
		-- world change closes every screen (the bootstrap's "world" listener), so a drawn panel with `open` false is the
		-- state to catch; this line says so in Output until the retest settles it.
		if RunService:IsStudio() and not open and gui ~= nil and gui.Enabled then
			warn(("[%s] aliens: Bay refresh skipped: the screen is closed but still drawn"):format(Config.WorkingTitle))
		end
		return
	end
	local profile = State.Get()
	setCount(cardCount)
	local row, why = StorageMath.NextBayLevel(State.GetBayLevel(), profile.world.unlocked)
	local perLevel = Builder.formatNumber(Storage.Bay.PerLevel)
	if not row then
		Builder.restyleBlockButton(bayButton, Strings.STORAGE_BAY_MAX, Theme.Rarity.Common, true)
	elseif why == "NeedsWorld" then
		Builder.restyleBlockButton(bayButton, Strings.STORAGE_BAY_NEEDS_WORLD:format(perLevel, row.world), Theme.Rarity.Common, true)
	else
		local color = if profile.scrap >= row.scrap then Theme.Colors.Confirm else Theme.Rarity.Common
		Builder.restyleBlockButton(bayButton, Strings.STORAGE_BAY_BUY:format(perLevel, Builder.formatNumber(row.scrap)), color, true)
	end
end

-- A tap on the Bay button: a toast for each reason the level cannot be bought (never a silent tap), else the server is
-- asked. It answers (ok, reason, the new cap); the toast on success says how much the cap rose, from the cap shown before.
local function buyStorageBay()
	if RunService:IsStudio() then
		print(("[%s] aliens: Bay tap (open=%s busy=%s)"):format(Config.WorkingTitle, tostring(open), tostring(bayBusy)))
	end
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
		-- How much more, never a bare refusal (TikTok batch 9 lesson 3).
		ScrapGap.Show(row.scrap, profile.scrap, Theme.Rarity.Common)
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
			local held = if State.Has() then State.Get().scrap else 0
			ScrapGap.Show(row.scrap, held, Theme.Rarity.Common)
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

	-- The panel: a cream block plate at the panel cell (about 26 by 19 cells), the header tab and the close button on it.
	local body = Builder.blockPlate({
		parent = root,
		name = "Panel",
		color = Theme.Colors.Panel,
		aspect = PANEL_ASPECT,
		rows = Builder.blockPanelRows(PANEL_H),
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, PANEL_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	panel = body
	local top = Builder.blockTop(body)

	-- Header tab straddling the top edge, title in white outlined text.
	Builder.blockHeader(body, PANEL_ASPECT, Strings.ALIENS_TITLE, Theme.Colors.Featured)
	Builder.blockClose(body, PANEL_H, function()
		AliensScreen.Close()
	end)

	-- Release: the menu of "Release all unused" (and the hint about holding a card), over the panel.
	Builder.blockButton({
		parent = body,
		name = "Release",
		text = Strings.RELEASE_BUTTON,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(RELEASE_X, RELEASE_Y),
		size = UDim2.fromScale(RELEASE_W, RELEASE_H),
		rows = Builder.blockButtonRows(RELEASE_H * PANEL_H), -- a fitted block button: its size is a share of the panel
		textSize = Theme.TextSize.Label,
		zIndex = top + 1,
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
		zIndex = top,
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
		zIndex = top,
	})
	companionsLabel = Builder.label({
		parent = body,
		name = "Companions",
		text = Strings.ALIENS_COMPANIONS:format(0, Config.CompanionSlots),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(Theme.Margin, STORAGE_Y + COUNT_H),
		size = UDim2.fromScale(STORAGE_LEFT_W, COUNT_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	bayButton = Builder.blockButton({
		parent = body,
		name = "StorageBay",
		text = Strings.STORAGE_BAY_BUY:format(Builder.formatNumber(Storage.Bay.PerLevel), Builder.formatNumber(Storage.Bay.Levels[1].scrap)),
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(1 - Theme.Margin, STORAGE_Y),
		size = UDim2.fromScale(BAY_W, BAY_H),
		rows = Builder.blockButtonRows(BAY_H * PANEL_H),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		zIndex = top + 1,
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
		zIndex = top,
	})

	-- 3. The grid: a ScrollingFrame with a thin dark bar; cards are rebuilt on refresh.
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Theme.Margin, GRID_Y)
	scroller.Size = UDim2.fromScale(1 - Theme.Margin * 2, GRID_H)
	scroller.ZIndex = top
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
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(syncCardViews)
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(syncCardViews)
	end)

	local empty = Builder.label({
		parent = body,
		name = "Empty",
		text = Strings.ALIENS_EMPTY,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, GRID_Y + GRID_H / 2),
		size = UDim2.fromScale(0.7, 0.1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = top,
	})
	empty.Visible = false
	emptyLabel = empty

	-- 4. Footer: a button row (Companion Token while one is held, Fuse, then Optimize at the right edge) over a
	-- one-line hint in the minimum text size. Optimize asks the server to reseat the crew; Fuse asks it to fuse every
	-- species with spare copies; the token button asks it to spend a Companion Token on a slot.
	local buttonsBottom = 1 - Theme.Margin - HINT_H
	Builder.blockButton({
		parent = body,
		name = "Optimize",
		text = Strings.OPTIMIZE,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin, buttonsBottom),
		size = UDim2.fromScale(FOOTER_BUTTON_W, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = top + 1,
	}, function()
		ask("StationOptimize")
	end)
	fuseButton = Builder.blockButton({
		parent = body,
		name = "Fuse",
		text = Strings.FUSE_BUTTON,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(1 - Theme.Margin - FOOTER_BUTTON_W - FOOTER_GAP, buttonsBottom),
		size = UDim2.fromScale(FOOTER_BUTTON_W, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = top + 1,
	}, fuseAll)
	local token = Builder.blockButton({
		parent = body,
		name = "UseToken",
		text = Strings.ALIENS_USE_TOKEN:format(0),
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin - 2 * (FOOTER_BUTTON_W + FOOTER_GAP), buttonsBottom), -- left of Fuse, a gap between
		size = UDim2.fromScale(TOKEN_BUTTON_W, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = top + 1,
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
		zIndex = top,
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
