--!strict
-- StarterPlayerScripts.Client.UI.AliensScreen: the Aliens panel. Under the header band (Builder.panelHeader: "Aliens 34 / 160" and
-- "Companions 2 / 4") a strip of station cards across the top (one per unlocked job: name, slots, rate and a row of slot squares),
-- then the featured card (UI.FeaturedCard) beside a scrolling grid of one square tile per alien (tier-coloured face with the tier's
-- studs, the species' model, name, speed chip, overlay badge, a level chip on a fused copy, a size chip and a growth chip that counts
-- a working alien down to its next stage, where it works, a Companion or Riding stamp across its foot), and a footer: a button row
-- with the Storage Bay button at the left, Optimize and Fuse at the right and a Companion Token button while a token is held, and
-- under it one info line (the perks). A tap on a tile selects it (the selected tile takes the gold ink) and fills the featured card,
-- which carries the one main action: Follow, Stop following, Hop off, Bring back, with Ride or Display beside it. At a panel of 620 by
-- 330 px or more the card stands left of a three-column grid (side mode); under that (iPhone SE) it is a strip across the top of the
-- body over a five-column grid (strip mode); Shared/FeaturedMath picks the mode and the buttons.
-- Storage (milestones 50 and 50b, data/Storage): the owned count reads "Aliens: 12 / 60", the cap being what the server last said
-- (State.GetStorageCap: it grows with the ship's modules, the Storage Bay and the pass), gold from WarnFraction of the cap and red
-- when full. The Storage Bay button beside it buys the next level with Scrap ("+20 storage: 2,500 Scrap"); it is green while
-- level can be bought and grey, with the reason in its words or in the toast a tap brings, when the Scrap is short, the
-- level waits for a world or the Bay is maxed out. A Release button in the footer opens the ReleasePanel menu (release all
-- unused Commons or Uncommons), and holding an alien tile for Storage.HoldSeconds opens the same panel for that one alien; a
-- plain tap selects it. The owned count and the companion slots live in the band's pills now.
-- Habitats (milestone 42c): at home, a resting alien whose world has a habitat on the plot gets a Display button on the featured card
-- (beside Follow), and an alien on display shows a purple "On display" pill in the chip row (in place of the size and growth chips)
-- and, at home, a Bring back button on the featured card; a displayed alien never follows.
-- Neither button shows while the player is visiting someone else's home (State.IsVisiting, milestone 42e): a guest
-- never displays or takes back at another's plot, and the cards redraw on the "visit" topic when that changes.
-- Every value is read from the profile mirror in State and the shared Economy and Growth math; the only taps
-- that leave the client ask the server (StationOptimize, FuseSpecies, SetCompanion, SetMount, SetDisplay,
-- UseCompanionToken, BuyStorageBay, and through the ReleasePanel ReleaseAliens and ReleaseAllOfTier). Nothing here decides an outcome: Fuse only picks which species to ask about, a tile tap only
-- selects, the featured card's Follow and Stop following only ask to follow or stop, Ride and Hop off only ask to ride or hop
-- off, the Display and Bring back buttons only ask to put an alien in a habitat or take it out, and the tiles redraw from
-- the camp, companion and home pushes the server sends back.
-- The look is block cells (UI Playbook "Block cells" and "Screens after the HUD", Decisions B44): the panel is a cream block plate
-- at the panel cell, the header tab, the close button and every button block plates and block buttons; the station cards and the
-- alien cards are edged blocks (lit top row, shaded edges, no grout or jitter: a grid of them stays a few frames each), the slot
-- squares and the chips flat blocks, a rarity ring the ink. The layout, every binding and every string key are as before.
-- The clean pass (docs/vault/05-ui-design/Clean-UI-Pass.md, package C): a station slot is its square alone (the species colour; the
-- names under the squares are gone, the card keeps "4/4" and the rate); Release moved from the header's left corner into the footer's
-- button row, left of the Storage Bay button; the footer has one green button at a time (the Bay button, while a level can be
-- bought). Shared/PanelQuiet.AliensFooter places the row, with and without a Companion Token button.
-- The richness pass (docs/vault/05-ui-design/UI-Richness-Pass.md section 4, package C): the band replaces the header tab, the featured
-- card takes the follow, ride and display actions off the tiles (a tile shows the result as a stamp), the grid is one list sorted
-- companions first and then by tier, and the count and companion lines left the footer for the band's pills ("say it once").

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
local Panels = require(Shared:WaitForChild("data"):WaitForChild("Panels"))
local Storage = require(Shared:WaitForChild("data"):WaitForChild("Storage"))
local StorageMath = require(Shared:WaitForChild("StorageMath"))
local PanelQuiet = require(Shared:WaitForChild("PanelQuiet"))
local FeaturedMath = require(Shared:WaitForChild("FeaturedMath"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local ViewFit = require(Shared:WaitForChild("ViewFit"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local FeaturedCard = require(script.Parent.FeaturedCard)
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
	tierRank: number, -- FeaturedMath.TierRank of its species
}

-- Panel layout, as fractions of the panel. The header band fills the top 0.16 (Panels.Shell.BodyTop). Top to bottom: the station strip,
-- then the featured card and the grid (data/Panels.Featured.Aliens: side by side at a panel of 620 by 330 px or more, the card as a
-- strip over the grid under that), then the footer's button row (the Storage Bay button at the left, the Companion Token button while a
-- token is held, then Fuse and Optimize at the right) and under it one line (the perks). At iPhone SE (667x375: a 425 by 315 px panel)
-- the strip mode leaves one row of 72 px tiles and a peek of the second under a 54 px station strip and a 50 px card; at the default
-- window the side mode shows three columns of about 125 px tiles. Tests/BlockMath.spec.luau "Aliens header and grid".
local FOOTER_Y = 0.864 -- the button row
local FOOTER_H = 0.072
local INFO_Y = 0.939 -- one line of 14 px text under the buttons
local INFO_H = 0.041
local STRIP_GAP = 0.02 -- between station cards, of the strip width
-- The footer's button widths and places are data/Panels.AliensFooter, worked out by PanelQuiet.AliensFooter: Release then the Storage
-- Bay button ("+20 storage: 2,500 Scrap" is about 156 px at the 14 px floor; "+20 for 2,500" while a token button shares the row) at
-- the left, the Companion Token button (while a token is held, "Use Token (1)" about 86 px), Fuse and Optimize at the right.
-- The perks line takes the whole row under the buttons (the count and the companions moved to the band's pills).
local FUSE_BUSY_ALPHA = 0.5 -- the Fuse button's face and text fade by this while a fusion is in flight

-- Grid: square tiles, three per row beside the featured card and five across a strip (FeaturedMath.AliensGrid); the cell width is a
-- fraction of the grid's canvas width and the cell height is derived from it so the cells come out square (see layoutGrid).
local SCROLLBAR_PX = 6 -- thickness, not a Size: a thin dark bar on the right
local SELECTED_INK = Theme.Colors.Featured -- a selection is an ink colour (the Playbook): the selected tile's border
local TILE_INK = Theme.Colors.Outline

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
local CARD_ROWS = 10 -- an alien card is an edged block this many cells tall (about 7.5 px cells on an iPhone SE card of 83 px)
local SQUARE_ROWS = 3 -- the shape square, a slot square and a chip: flat blocks of the fewest rows a stepped corner takes
local STATION_ROWS = 8 -- a station card: an edged block this many rows tall (the strip is 0.18 of the screen)
-- A station card's slot row: the row is SLOTS_W of the card from SLOTS_X; a slot is its square alone, the whole height of the row (the
-- names under the squares went in the clean pass: the square's colour says who works there, the card says "4/4" and the rate).
local SLOTS_X = 0.02
local SLOTS_W = 0.96
local SLOT_SQUARE_H = 1
local PANEL_H = Panels.Shell.Height -- the panel's height, of the screen (its rows come from it, at the panel cell)
local PANEL_ASPECT = 1.35 -- its width in px was already this at the shell's height, so it keeps it

-- The card's top corners: the speed chip top right, the overlay badge top left, and a fused copy's level chip
-- (the speed chip's size) in the top-left corner too, or directly under the badge when the badge holds it.
-- The badge is fitted to its name (Shared/BadgeFit, widths measured once by Builder.overlayName at the 14 px floor): it is
-- BADGE_W wide at least and shares the first row with the speed chip while it stays within BADGE_BESIDE_W. A name wider than
-- that takes the whole row (BADGE_FULL_W) and the speed and level chips move to the row under it; a name wider than the row
-- ("Launch Gold" on a card under about 105 px, every phone) wraps to one pill per word, and the speed chip takes the row
-- beside the short last word. A row is CORNER_H tall and starts CORNER_H + CORNER_GAP under the one above.
local CORNER_X = 0.04
local CORNER_Y = 0.04
local CORNER_H = 0.19
local SPEED_W = 0.36
local BADGE_W = 0.5
local CORNER_GAP = 0.01
local BADGE_FULL_W = 1 - 2 * CORNER_X
local BADGE_BESIDE_W = BADGE_FULL_W - SPEED_W - CORNER_GAP

-- The invisible Tap overlay sits above every chip and stamp of the tile (a tap selects it, a hold opens its Release panel).
local TAP_Z = 8

-- The perk kinds in the order the perks line lists them (the kinds of data/Companions PerkByJob).
local PERK_ORDER: { string } = { "catchScrap", "zone", "luck", "radar" }

-- Time units, in seconds, for the growth countdown.
local MINUTE = 60
local HOUR = 60 * MINUTE

local gui: ScreenGui? = nil
local panel: Frame? = nil
local header: Builder.PanelHeader? = nil -- the band (Builder.panelHeader): refresh feeds its two pills
local strip: Frame? = nil
local featured: FeaturedCard.Card? = nil -- the featured card, built once and refilled on every selection
local layoutMode: FeaturedMath.Mode? = nil -- the shape the body is laid out in now (side or strip)
local selectedUid: string? = nil -- the tile the featured card shows
local pendingSpecies: string? = nil -- AliensScreen.Select asked for the first alien of this species on the next refresh
local entriesByUid: { [string]: Entry } = {} -- the tiles drawn now
local tileByUid: { [string]: Frame } = {}
local selectTile: (string) -> () = function(_uid: string) end -- a tap on a tile: assigned with the featured card below
local gridColumns = 3 -- the grid's columns, cell width and gap for the mode (FeaturedMath.AliensGrid)
local gridCell = 0.31
local gridGap = 0.035
local bayButton: Frame? = nil -- the Storage Bay button
local perksLabel: TextLabel? = nil
local tokenButton: Frame? = nil
local grid: ScrollingFrame? = nil
local gridLayout: UIGridLayout? = nil
local badgeFits: { (number) -> () } = {} -- one per overlay badge on the cards now drawn; each takes the card's width in px and refits its badge
local fuseButton: Frame? = nil
local releaseButton: Frame? = nil
local optimizeButton: Frame? = nil
local tokenHeld = false -- a Companion Token is held: the token button shows and the footer row re-spaces
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

-- The band's pills: the owned count over the storage cap the server last said (State.GetStorageCap), its face red from Storage.WarnFraction
-- of the cap (StorageMath.IsWarning, full included), and the companions in use over the slots (State.GetCompanionSlots).
local function updatePills()
	local band = header
	if not band or not State.Has() then
		return
	end
	local cap = State.GetStorageCap()
	local owned: any = { cardCount, cap }
	owned.warn = StorageMath.IsWarning(cardCount, cap)
	band.setPills({ owned, { #State.Get().companions, State.GetCompanionSlots() } })
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

-- The Follow button of the featured card: a seated alien and a full set of slots are told to the player here (the server would refuse
-- both, so no request is spent); a resting alien with a free slot is asked to follow. An alien on display never follows.
local function followTap(uid: string, name: string)
	if not State.Has() then
		return
	end
	local profile = State.Get()
	local record = profile.aliens[uid]
	if not record or record.habitat ~= nil then
		return
	end
	local slots = State.GetCompanionSlots()
	if record.station ~= nil then
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

-- One slot square: filled (species colour, tier ring), open (the cream square) or locked (darker) for slots the station has not
-- grown into yet. No label under it.
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
	if index > station.slots then
		square.color = Builder.darker(Theme.Rarity.Common)
	elseif record then
		local def = Species.ById[record.species]
		square.color = speciesColor(def)
		square.ink = Builder.tierColor(if def then def.tier else "Common")
	end
	Builder.blockPlate(square)
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
	local cellPx = gridCell * abs.X
	local gapPx = gridGap * abs.X
	-- With pixel cell heights the canvas can follow the content exactly (no feedback), so the page maths
	-- that ran against a not-yet-final frame height (a 1020 px canvas for 336 px of cards) is gone.
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.fromScale(0, 0)
	-- The cell height is the cell width in pixels, derived from the frame on every resize. A Scale height
	-- inside a ScrollingFrame resolves against the canvas, and the canvas grows to hold the grid's content,
	-- so a Scale cell fed back into a taller canvas until one card sat 150 px down a 565 px canvas (Studio,
	-- 2026-10-05). Width and padding stay Scale.
	layout.FillDirectionMaxCells = gridColumns
	layout.CellSize = UDim2.new(gridCell, 0, 0, cellPx) -- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)
	layout.CellPadding = UDim2.new(gridGap, 0, 0, gapPx) -- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)
	-- The cards are square, so a cell's width is a card's width. The overlay badges fit their names against it, less the
	-- scrollbar's thickness (the canvas gives it up once the cards overflow), so the fit is never a pixel short.
	local cardPx = gridCell * math.max(0, abs.X - SCROLLBAR_PX)
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
		ink = if record.uid == selectedUid then SELECTED_INK else TILE_INK,
		aspect = 1,
		rows = CARD_ROWS,
		cells = false,
		edges = true,
		zIndex = 3,
	})
	card.LayoutOrder = index
	local top = Builder.blockTop(card)
	Builder.tierFrame(card, if def then def.tier else "Common") -- the ladder's studs and tint (Rare one stud up to four from Legendary)
	tileByUid[record.uid] = card
	-- Where it is and what it is doing: a Riding or Companion stamp across its foot (the featured card holds the buttons).
	if entry.riding then
		Builder.stamp(card, "Riding")
	elseif entry.following then
		Builder.stamp(card, "Companion")
	end

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

	local job = record.station
	local displayed = record.habitat ~= nil
	-- A band that names itself (Tiny, Big, HUGE: data/Sizes label) gets a small gold chip at the left of
	-- the chip row; Normal and Small show nothing.
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

	-- What it is doing, one line: where it works as the station's name alone ("Picnic Table"; one line at the minimum size is all a
	-- square card has). A companion or a mount wears a stamp instead and a resting alien says nothing (a tap selects it; the
	-- featured card follows, rides and displays). An alien on display shows the purple "On display" pill in the chip row.
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
	if job then
		Builder.label({
			parent = card,
			name = "Status",
			text = Builder.text("STATION_" .. job),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.White,
			position = UDim2.fromScale(0.5, STATUS_Y),
			size = UDim2.fromScale(0.94, STATUS_H),
			anchor = Vector2.new(0.5, 0),
			zIndex = top,
		})
	end

	-- An invisible button over the whole card, above every chip: a tap selects the tile (the featured card follows), a hold opens
	-- its Release panel.
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
		Builder.playSound(Sounds.Click)
		selectTile(record.uid)
	end)
end

-- Owned aliens in the grid's order (FeaturedMath.Before): the ridden one first, then the companions, then the rarer tier, then the
-- faster, then by name and uid so the order is stable between refreshes.
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
			tierRank = FeaturedMath.TierRank(if def then def.tier else "Common"),
		})
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		return FeaturedMath.Before(
			{ riding = a.riding, following = a.following, tierRank = a.tierRank, speed = a.speed, name = a.name, uid = a.record.uid },
			{ riding = b.riding, following = b.following, tierRank = b.tierRank, speed = b.speed, name = b.name, uid = b.record.uid }
		)
	end)
	return entries
end

-- Keeps the selection on a tile that still exists: the first alien of the species Select asked for, else the one already selected,
-- else the default (the mount you ride, the first companion, the newest alien).
local function settleSelection(profile: Types.Profile, entries: { Entry })
	if pendingSpecies ~= nil then
		local species = pendingSpecies
		pendingSpecies = nil
		for _, entry in ipairs(entries) do
			if entry.record.species == species then
				selectedUid = entry.record.uid
				return
			end
		end
	end
	local current = selectedUid
	if current ~= nil and entriesByUid[current] ~= nil then
		return
	end
	local caughtAt: { [string]: number } = {}
	for uid, record in pairs(profile.aliens) do
		caughtAt[uid] = record.caughtAt
	end
	selectedUid = FeaturedMath.AliensDefault(State.GetRiding(), profile.companions, caughtAt)
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
	table.clear(entriesByUid)
	table.clear(tileByUid)
	for _, entry in ipairs(entries) do
		entriesByUid[entry.record.uid] = entry
	end
	settleSelection(profile, entries)
	for index, entry in ipairs(entries) do
		buildCard(frame, index, entry)
	end
	layoutGrid()
	task.defer(syncCardViews) -- once the grid layout has placed the new cards
	updatePills()
end

-- The count row's companion label, the perks line and the Companion Token button: slots in use, the perks they
-- give, and the button shown only while a token is held (its label carries how many).
-- Places the footer's buttons for whether a token is held (Shared/PanelQuiet.AliensFooter): every button stands at its left edge.
local function layoutFooter()
	local footer = PanelQuiet.AliensFooter(tokenHeld)
	local function place(button: Frame?, slot: PanelQuiet.Slot?)
		if button and slot then
			button.AnchorPoint = Vector2.zero
			button.Position = UDim2.fromScale(slot.x, FOOTER_Y)
			button.Size = UDim2.fromScale(slot.w, FOOTER_H)
		end
	end
	place(releaseButton, footer.release)
	place(bayButton, footer.bay)
	place(tokenButton, footer.token)
	place(fuseButton, footer.fuse)
	place(optimizeButton, footer.optimize)
end

local function updateCompanionRows(profile: Types.Profile)
	updatePills()
	if perksLabel then
		local text, any = perksLine(profile)
		perksLabel.Text = text
		perksLabel.TextColor3 = if any then Theme.Colors.Confirm else Theme.Rarity.Common
	end
	local button = tokenButton
	if button then
		local tokens = profile.inventory.items[Companions.TokenItem] or 0
		button.Visible = tokens > 0
		if (tokens > 0) ~= tokenHeld then
			tokenHeld = tokens > 0
			layoutFooter() -- Release, the Bay button and the rest re-space (the Bay's words follow in refreshStorageRow)
		end
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
	updatePills()
	local row, why = StorageMath.NextBayLevel(State.GetBayLevel(), profile.world.unlocked)
	local perLevel = Builder.formatNumber(Storage.Bay.PerLevel)
	if not row then
		Builder.restyleBlockButton(bayButton, Strings.STORAGE_BAY_MAX, Theme.Rarity.Common, true)
	elseif why == "NeedsWorld" then
		Builder.restyleBlockButton(bayButton, Strings.STORAGE_BAY_NEEDS_WORLD:format(perLevel, row.world), Theme.Rarity.Common, true)
	else
		-- the one green button of the footer, while a level can be bought; its short words while the token button shares the row
		local color = if profile.scrap >= row.scrap then Theme.Colors.Confirm else Theme.Rarity.Common
		local template = if tokenHeld then Strings.STORAGE_BAY_SHORT else Strings.STORAGE_BAY_BUY
		Builder.restyleBlockButton(bayButton, template:format(perLevel, Builder.formatNumber(row.scrap)), color, true)
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

-- Featured card ---------------------------------------------------------------------------------------------

-- Runs one of the featured card's buttons (FeaturedMath's ids) for an entry. Every one only asks: the server answers and the pushes redraw.
local function runAction(id: string, entry: Entry)
	local record, def = entry.record, entry.def
	local uid, name = record.uid, entry.name
	if id == "Follow" then
		followTap(uid, name)
	elseif id == "Unfollow" then
		setCompanion(uid, false, name)
	elseif id == "Ride" then
		setMount(uid, name)
	elseif id == "HopOff" then
		setMount(nil, name)
	elseif id == "Display" then
		if def then
			displayAlien(uid, name, def.world)
		end
	elseif id == "BringBack" then
		if def then
			setDisplay(uid, nil, name, Builder.text("WORLD_" .. def.world))
		end
	end
end

local function cardAction(action: FeaturedMath.Action?, entry: Entry): FeaturedCard.Action?
	if not action then
		return nil
	end
	return {
		word = Builder.text(action.word),
		role = action.role,
		onTap = function()
			runAction(action.id, entry)
		end,
	}
end

-- Fills the featured card from the selected tile: its model, tier tag, name, flavour line and the buttons FeaturedMath.Button gives its
-- state (riding, following, on display, working at a station, a free companion slot, a habitat at home, a guest). With nothing owned the
-- card says so. The view keeps its clone while the species stays the same.
local function refreshFeatured()
	local card = featured
	if not card or not State.Has() then
		return
	end
	local profile = State.Get()
	local selected = selectedUid
	local entry = if selected then entriesByUid[selected] else nil
	local def = if entry then entry.def else nil
	if not entry or not def then
		FeaturedCard.Fill(card, nil, Strings.ALIENS_EMPTY)
		return
	end
	local record = entry.record
	local visiting = State.IsVisiting()
	local atHome = Place.IsHome() and not visiting
	local displayed = record.habitat ~= nil
	local resting = record.station == nil and not entry.following and not displayed
	local buttons = FeaturedMath.Button({
		screen = "Aliens",
		visiting = visiting,
		riding = entry.riding,
		following = entry.following,
		displayed = displayed,
		seated = record.station ~= nil,
		slotFree = #profile.companions < State.GetCompanionSlots(),
		canRide = def.ride ~= nil,
		canDisplay = atHome and resting and habitatExists(def.world),
		canBringBack = atHome and displayed,
	})
	local function has(key: string): boolean
		return Builder.text(key) ~= key
	end
	local tierId: string = def.tier
	FeaturedCard.Fill(card, {
		def = def,
		shadowed = false,
		mark = false,
		name = entry.name,
		tier = tierId,
		tierWord = Builder.text("TIER_" .. tierId),
		flavour = Builder.text(FeaturedMath.FlavourKey(def.id, tierId, has)),
		facts = {},
		main = cardAction(buttons.main, entry),
		side = cardAction(buttons.side, entry),
	}, nil)
end

-- A tap on a tile: it takes the gold ink, the card follows. One more tap than the old tap-to-follow; the stamps show the result.
selectTile = function(uid: string)
	if entriesByUid[uid] == nil then
		return
	end
	selectedUid = uid
	for id, tile in pairs(tileByUid) do
		Builder.setBlockInk(tile, if id == uid then SELECTED_INK else TILE_INK)
	end
	local tile = tileByUid[uid]
	if tile then
		Builder.pop(tile, 1.08)
	end
	refreshFeatured()
end

-- The panel's px with the open tween taken out, or the usual window's before it is laid out (a disabled gui measures zero).
local function panelPx(): (number, number)
	local body = panel
	local size = if body then FeaturedCard.UnscaledSize(body) else Vector2.zero
	if size.X > 0 and size.Y > 0 then
		return size.X, size.Y
	end
	local camera = workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else Vector2.new(1154, 663)
	local w = math.min(PANEL_H * screen.Y * PANEL_ASPECT, 0.8 * screen.X)
	return w, w / PANEL_ASPECT
end

-- Lays the body out for the panel's shape (FeaturedMath.Mode): at 620 by 330 px or more the card stands left of a three-column grid,
-- under that it is a strip over a five-column grid. The station strip is the same in both. Runs again when the mode changes.
local function applyLayout(force: boolean)
	local card, stripFrame, scroller = featured, strip, grid
	if not card or not stripFrame or not scroller then
		return
	end
	local w, h = panelPx()
	local mode: FeaturedMath.Mode = FeaturedMath.Mode(w, h)
	if not force and mode == layoutMode then
		return
	end
	layoutMode = mode
	local f = Panels.Featured
	local a = f.Aliens
	gridColumns, gridCell, gridGap = FeaturedMath.AliensGrid(mode)
	stripFrame.Position = UDim2.fromScale(f.Wide.X, a.StationY)
	stripFrame.Size = UDim2.fromScale(f.Wide.W, a.StationH)
	if mode == "side" then
		FeaturedCard.Place(card, mode, UDim2.fromScale(f.Side.CardX, a.SideTop), UDim2.fromScale(f.Side.CardW, a.Bottom - a.SideTop))
		scroller.Position = UDim2.fromScale(f.Side.GridX, a.SideTop)
		scroller.Size = UDim2.fromScale(f.Side.GridW, a.Bottom - a.SideTop)
	else
		FeaturedCard.Place(card, mode, UDim2.fromScale(f.Wide.X, a.StripTop), UDim2.fromScale(f.Wide.W, a.StripH))
		scroller.Position = UDim2.fromScale(f.Wide.X, a.StripGridTop)
		scroller.Size = UDim2.fromScale(f.Wide.W, a.Bottom - a.StripGridTop)
	end
	layoutGrid()
	task.defer(syncCardViews)
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
	refreshFeatured()
end

-- The inventory and the passes touch the companion rows only (a token arrived, a pass was bought), not the cards.
local function refreshCompanionRows()
	if open and State.Has() then
		updateCompanionRows(State.Get())
		refreshStorageRow() -- the Bay button's words depend on whether the token button is up
		refreshFeatured() -- and the featured card's Follow on whether a slot is free
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

	-- The panel: a cream block plate at the panel cell (about 26 by 19 cells) under the Scrap pill (the shell's top), the header band on it.
	local body = Builder.blockPlate({
		parent = root,
		name = "Panel",
		color = Theme.Colors.Panel,
		aspect = PANEL_ASPECT,
		rows = Builder.blockPanelRows(PANEL_H),
		quiet = true, -- one cream surface behind the text (Clean UI pass)
		position = UDim2.fromScale(0.5, Panels.Shell.Top), -- below the Scrap pill, which ends at Top; the band is inside the panel
		size = UDim2.fromScale(0.8, PANEL_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 2,
	})
	panel = body
	local top = Builder.blockTop(body)

	-- The header band: gold, the Aliens icon, "Aliens n / cap" and "Companions n / slots" pills (updatePills), the red X.
	header = Builder.panelHeader(body, { panelId = "Aliens", panelAspect = PANEL_ASPECT, panelHeight = PANEL_H }, function()
		AliensScreen.Close()
	end)

	-- Release (the menu of "Release all unused", and the hint about holding a card) sits in the footer's button row, left of the
	-- Storage Bay button; layoutFooter places it.
	releaseButton = Builder.blockButton({
		parent = body,
		name = "Release",
		text = Strings.RELEASE_BUTTON,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(Theme.Margin, FOOTER_Y),
		size = UDim2.fromScale(Panels.AliensFooter.Release, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H), -- a fitted block button: its size is a share of the panel
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 1,
	}, function()
		ReleasePanel.ShowMenu()
	end)
	ReleasePanel.Build(root)

	-- 1. Station strip: one card per unlocked job, rebuilt on refresh.
	local stripFrame = Builder.frame({
		parent = body,
		name = "Stations",
		position = UDim2.fromScale(Panels.Featured.Wide.X, Panels.Featured.Aliens.StationY), -- applyLayout keeps it
		size = UDim2.fromScale(Panels.Featured.Wide.W, Panels.Featured.Aliens.StationH),
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

	-- 2. The info line under the footer's buttons: the perks the companions give, one line at the 14 px floor (a TextScaled label narrower
	-- than its text wraps it mid-word; this one ends in an ellipsis). The owned count and the companion slots are the band's pills.
	local perks = Builder.label({
		parent = body,
		name = "Perks",
		text = Strings.ALIENS_PERKS_NONE,
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(Theme.Margin, INFO_Y),
		size = UDim2.fromScale(1 - Theme.Margin * 2, INFO_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	perks.TextScaled = false
	perks.TextWrapped = false
	perks.TextSize = Theme.TextSize.Min
	perks.TextTruncate = Enum.TextTruncate.AtEnd
	perksLabel = perks
	bayButton = Builder.blockButton({
		parent = body,
		name = "StorageBay",
		text = Strings.STORAGE_BAY_BUY:format(Builder.formatNumber(Storage.Bay.PerLevel), Builder.formatNumber(Storage.Bay.Levels[1].scrap)),
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(Theme.Margin, FOOTER_Y), -- layoutFooter places it
		size = UDim2.fromScale(Panels.AliensFooter.Bay, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 1,
	}, buyStorageBay)

	-- 3. The grid: a ScrollingFrame with a thin dark bar; cards are rebuilt on refresh.
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Panels.Featured.Side.GridX, Panels.Featured.Aliens.SideTop) -- applyLayout keeps it
	scroller.Size = UDim2.fromScale(Panels.Featured.Side.GridW, Panels.Featured.Aliens.Bottom - Panels.Featured.Aliens.SideTop)
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
	cells.FillDirectionMaxCells = gridColumns
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cells.VerticalAlignment = Enum.VerticalAlignment.Top
	cells.StartCorner = Enum.StartCorner.TopLeft
	cells.CellSize = UDim2.fromScale(gridCell, gridCell)
	cells.CellPadding = UDim2.fromScale(gridGap, gridGap)
	cells.Parent = scroller
	grid = scroller
	gridLayout = cells
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGrid)
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(syncCardViews)
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(syncCardViews)
	end)

	-- The featured card (UI.FeaturedCard), built once and refilled on every selection; applyLayout places it for the panel's shape.
	featured = FeaturedCard.Build(body, "Featured", top, false)

	-- 4. Footer: the button row at the right (Companion Token while one is held, Fuse, then Optimize at the right edge) beside the
	-- Storage Bay button. Optimize asks the server to reseat the crew; Fuse asks it to fuse every species with spare copies (the
	-- toast of a tap with nothing to fuse says what a fusion needs); the token button asks it to spend a Companion Token on a slot.
	optimizeButton = Builder.blockButton({
		parent = body,
		name = "Optimize",
		text = Strings.OPTIMIZE,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin - Panels.AliensFooter.Optimize, FOOTER_Y), -- layoutFooter places it
		size = UDim2.fromScale(Panels.AliensFooter.Optimize, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 1,
	}, function()
		ask("StationOptimize")
	end)
	fuseButton = Builder.blockButton({
		parent = body,
		name = "Fuse",
		text = Strings.FUSE_BUTTON,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0, FOOTER_Y), -- layoutFooter places it
		size = UDim2.fromScale(Panels.AliensFooter.Fuse, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 1,
	}, fuseAll)
	local token = Builder.blockButton({
		parent = body,
		name = "UseToken",
		text = Strings.ALIENS_USE_TOKEN:format(0),
		color = Theme.Colors.Select,
		position = UDim2.fromScale(0, FOOTER_Y), -- left of Fuse, a gap between (layoutFooter places it)
		size = UDim2.fromScale(Panels.AliensFooter.Token, FOOTER_H),
		rows = Builder.blockButtonRows(FOOTER_H * PANEL_H),
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 1,
	}, useToken)
	token.Visible = false -- shown by updateCompanionRows while a token is held
	tokenButton = token
	layoutFooter()
	applyLayout(true)
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyLayout(false) -- the mode follows the panel's real size once it is laid out, and when the window changes
	end)

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
	selectedUid = nil -- the default selection on open (the mount you ride, the first companion, the newest alien), or what Select asked for
	root.Enabled = true
	applyLayout(true)
	refresh()
	Builder.open(body)
end

-- Opens the panel (or, when it is open, moves it) on the first alien of `speciesId`: the Codex's "See in Aliens". Call it before
-- Screens.Open("Aliens"); with none owned the default selection stands.
function AliensScreen.Select(speciesId: string)
	pendingSpecies = speciesId
	if open then
		refresh()
	end
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
