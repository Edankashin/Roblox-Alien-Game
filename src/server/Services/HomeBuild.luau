--!strict
-- ServerScriptService.Server.Services.HomeBuild: the house grid on the home planet (docs/GAME_DESIGN.md section 10,
-- "House (Bloxburg-lite)"; data/HomeBuild has the catalogue). The plot is PlotCells x PlotCells cells (this layout's
-- numbers); an item covers whole cells and turns in quarter steps. The server owns every placement: the client
-- sends an item id, a cell and a rotation and nothing else, and this service checks that the place is the home,
-- that the item exists, that every cell of its footprint is on the plot and free, that the kind's cap has room and
-- that the Scrap is there, then pays, records the item in profile.home.items under a fresh uid and pushes the
-- result (ScrapChanged, HomeChanged). The client only previews on the grid and draws what the profile says.
-- Footprints: the cell (cellX, cellZ) is the item's corner with the lowest cell numbers (0-based from the plot's
-- -X -Z corner); the item covers cellsX x cellsZ cells from there, the two swapped on a quarter or three-quarter
-- turn, so its cells run cellX .. cellX + width - 1 and cellZ .. cellZ + depth - 1. Two items overlap when their
-- cell ranges meet on both axes. Removing an item pays RemoveRefund of its price (none today); removing a habitat
-- also takes every alien on display in it off display, in the same update, and the camp is pushed after HomeChanged
-- (the client draws the displayed aliens from the records). Only the home planet (Place.IsHome) builds; every other
-- place answers NotAtHome. HomeBuild.OnChanged(callback) lists a listener told the owner after every accepted Place or
-- Remove, once the pushes are out (Visiting rebuilds the view of everyone looking at that home). Requires PlayerData,
-- Analytics, Meadow (the plot exists), Economy (PushCamp) and Place, and nothing requires it back except the
-- bootstrap's order (Visiting registers its listener at Init).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local HomeData = require(Shared.data.HomeBuild)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Meadow = require(script.Parent.Meadow)
local Economy = require(script.Parent.Economy)

local HomeBuild = {}

local REMOTE_RATE_PER_SECOND = 4 -- PlaceHomeItem, RemoveHomeItem and GetHome calls per player per second each

local listeners: { (Player) -> () } = {} -- Visiting: rebuild the views of this owner's visitors after a change

-- The cells an item covers: inclusive cell ranges on each axis.
type Footprint = { x0: number, z0: number, x1: number, z1: number }

-- Footprint maths -----------------------------------------------------------

-- An item at (cellX, cellZ) turned by `rotation` quarter steps. Odd turns swap width and depth.
local function footprintOf(item: HomeData.Item, cellX: number, cellZ: number, rotation: number): Footprint
	local sideways = rotation % 2 == 1
	local width = if sideways then item.cellsZ else item.cellsX
	local depth = if sideways then item.cellsX else item.cellsZ
	return { x0 = cellX, z0 = cellZ, x1 = cellX + width - 1, z1 = cellZ + depth - 1 }
end

-- True when two cell ranges share at least one cell.
local function overlaps(a: Footprint, b: Footprint): boolean
	return a.x0 <= b.x1 and b.x0 <= a.x1 and a.z0 <= b.z1 and b.z0 <= a.z1
end

-- True when every cell of the range lies inside 0 .. cells - 1 on both axes.
local function insidePlot(f: Footprint, cells: number): boolean
	return f.x0 >= 0 and f.z0 >= 0 and f.x1 <= cells - 1 and f.z1 <= cells - 1
end

local function isInteger(value: any): boolean
	return type(value) == "number" and value % 1 == 0 -- NaN and infinities fail the remainder test
end

-- The plot's side in cells for this place, or nil when no plot stands here (the layout sets none).
local function plotCells(): number?
	local cells = Place.Layout().PlotCells
	if cells == nil or Meadow.GetPlotCenter() == nil then
		return nil
	end
	return cells
end

-- Pushes -----------------------------------------------------------------

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushHome(player: Player, profile: Types.Profile)
	Net.event("HomeChanged"):FireClient(player, profile.home.items)
end

-- Tells every OnChanged listener the owner's house changed. Each runs in its own thread, so a listener that yields or
-- fails never holds up or breaks the placement that was already accepted.
local function notifyChanged(player: Player)
	for _, callback in ipairs(listeners) do
		task.spawn(callback, player)
	end
end

-- Runs fn against the live profile inside PlayerData.Update. fn returns a refusal reason or nil.
local function mutate(player: Player, fn: (Types.Profile) -> string?): (boolean, string?)
	local reason: string? = nil
	local ok = PlayerData.Update(player, function(profile)
		reason = fn(profile)
	end)
	if not ok then
		return false, "NoProfile"
	end
	if reason then
		return false, reason
	end
	return true, nil
end

-- Public API -------------------------------------------------------------

-- Server-side hook: `callback` runs with the owner after a Place or Remove was accepted and pushed.
function HomeBuild.OnChanged(callback: (Player) -> ())
	table.insert(listeners, callback)
end

-- Places one item for the Scrap in its data row. Returns true, or false with a reason: NoProfile, NotAtHome,
-- Unknown (no such item), BadArgs (a cell that is not a whole number, a rotation outside 0 .. RotationSteps - 1),
-- OffPlot (a cell of the footprint is off the plot), Taken (a cell is under a placed item), Full (the kind's cap is
-- reached), NotEnoughScrap. Nothing changes unless it returns true.
function HomeBuild.Place(player: Player, itemId: string, cellX: number, cellZ: number, rotation: number): (boolean, string?)
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if not Place.IsHome() then
		return false, "NotAtHome"
	end
	local item = HomeData.ById[itemId]
	if not item then
		return false, "Unknown"
	end
	if not isInteger(cellX) or not isInteger(cellZ) or not isInteger(rotation) or rotation < 0 or rotation >= HomeData.RotationSteps then
		return false, "BadArgs"
	end
	local cells = plotCells()
	if cells == nil then
		return false, "OffPlot"
	end
	local footprint = footprintOf(item, cellX, cellZ, rotation)
	if not insidePlot(footprint, cells) then
		return false, "OffPlot"
	end
	local uid = HttpService:GenerateGUID(false)
	local ok, reason = mutate(player, function(profile)
		local ofKind = 0
		for _, placed in pairs(profile.home.items) do
			local placedItem = HomeData.ById[placed.itemId]
			if placedItem then -- a row dropped from the data has no footprint to test and counts for nothing
				if overlaps(footprint, footprintOf(placedItem, placed.cellX, placed.cellZ, placed.rotation)) then
					return "Taken"
				end
				if placedItem.kind == item.kind then
					ofKind += 1
				end
			end
		end
		if ofKind >= HomeData.Caps[item.kind] then
			return "Full"
		end
		if profile.scrap < item.scrap then
			return "NotEnoughScrap"
		end
		profile.scrap -= item.scrap
		profile.home.items[uid] = { uid = uid, itemId = itemId, cellX = cellX, cellZ = cellZ, rotation = rotation }
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushHome(player, profile)
	end
	notifyChanged(player)
	Analytics.Event(player, AnalyticsData.Events.HomePlace, item.scrap, { item = itemId })
	local paid = PlayerData.Get(player)
	if paid then
		Analytics.Economy(player, "Sink", item.scrap, paid.scrap, "Shop", AnalyticsData.Economy.Sinks.Home) -- the house is a Scrap sink on the economy dashboard
	end
	print(("[%s] HomeBuild: %s placed %s at cell %d,%d turn %d"):format(Config.WorkingTitle, player.Name, itemId, cellX, cellZ, rotation))
	return true, nil
end

-- Takes one placed item away, by the uid it was placed under, and pays RemoveRefund of its price back (none
-- today). Returns true, or false with a reason: NoProfile, NotAtHome, Unknown (no placed item with that uid).
function HomeBuild.Remove(player: Player, uid: string): (boolean, string?)
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if not Place.IsHome() then
		return false, "NotAtHome"
	end
	local removedId = ""
	local refund = 0
	local undisplayed = false -- an alien was on display in the removed item
	local ok, reason = mutate(player, function(profile)
		local placed = profile.home.items[uid]
		if not placed then
			return "Unknown"
		end
		removedId = placed.itemId
		local item = HomeData.ById[placed.itemId]
		if item then
			refund = math.floor(HomeData.RemoveRefund * item.scrap)
		end
		profile.home.items[uid] = nil
		profile.scrap += refund
		for _, record in pairs(profile.aliens) do
			if record.habitat == uid then
				record.habitat = nil -- a removed habitat sends its aliens back to rest
				undisplayed = true
			end
		end
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushHome(player, profile)
		if refund > 0 then
			pushScrap(player, profile)
		end
		if undisplayed then
			Economy.PushCamp(player) -- the records changed: the client stops drawing them in the habitat
		end
	end
	notifyChanged(player)
	Analytics.Event(player, AnalyticsData.Events.HomeRemove, 1, { item = removedId })
	print(("[%s] HomeBuild: %s removed %s (refund %d)"):format(Config.WorkingTitle, player.Name, removedId, refund))
	return true, nil
end

-- Remotes ----------------------------------------------------------------

-- PlaceHomeItem(itemId, cellX, cellZ, rotation) -> (ok, reason). Reasons: BadArgs, RateLimited, then
-- HomeBuild.Place's.
local function onPlace(player: Player, itemId: any, cellX: any, cellZ: any, rotation: any): (boolean, string?)
	if type(itemId) ~= "string" or not isInteger(cellX) or not isInteger(cellZ) or not isInteger(rotation) then
		return false, "BadArgs"
	end
	if not Net.allow(player, "PlaceHomeItem", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return HomeBuild.Place(player, itemId, cellX, cellZ, rotation)
end

-- RemoveHomeItem(uid) -> (ok, reason). Reasons: BadArgs, RateLimited, then HomeBuild.Remove's.
local function onRemove(player: Player, uid: any): (boolean, string?)
	if type(uid) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "RemoveHomeItem", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return HomeBuild.Remove(player, uid)
end

-- GetHome() -> the player's placed items by uid, for a client that joined after the last HomeChanged (empty
-- before the profile loads or when rate limited; the next HomeChanged fills it in).
local function onGetHome(player: Player): { [string]: Types.HomeItem }
	local profile = PlayerData.Get(player)
	if not profile or not Net.allow(player, "GetHome", REMOTE_RATE_PER_SECOND) then
		return {}
	end
	return profile.home.items
end

function HomeBuild.Init()
	Net.event("HomeChanged")
	Net.event("ScrapChanged")
	Net.func("PlaceHomeItem").OnServerInvoke = onPlace
	Net.func("RemoveHomeItem").OnServerInvoke = onRemove
	Net.func("GetHome").OnServerInvoke = onGetHome
end

function HomeBuild.Start()
	print(("[%s] HomeBuild: %d items (%d rooms, %d furniture at most), %d turns, home %s"):format(
		Config.WorkingTitle,
		#HomeData.Items,
		HomeData.Caps.room,
		HomeData.Caps.furniture,
		HomeData.RotationSteps,
		if Place.IsHome() then "build on" else "build off here"
	))
end

return HomeBuild
