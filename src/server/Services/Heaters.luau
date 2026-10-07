--!strict
-- ServerScriptService.Server.Services.Heaters: the World 2 (Frostbyte) rule. During the world's special
-- weather, the Blizzard, wild aliens farther than Config.BlizzardHideStuds from a player are hidden on
-- that player's screen (WildRenderer decides what is drawn). A Heater, placed for Config.HeaterScrap
-- Scrap, reveals everything within Config.HeaterRadius of it for Config.HeaterSeconds. Only a world
-- whose rule is "Blizzard" (Worlds[Place.WorldId()].rule) uses it; elsewhere PlaceHeater answers
-- NotThisWorld. The server owns the purchase, the cap and the lifetime: a heater is an anchored Neon disc
-- under Workspace.World.Heaters with the attributes OwnerId, ExpiresAt (os.time) and Radius, which the
-- client reads to light the area up. It never touches an alien: hiding is presentation only, and a
-- catch is still judged by the Catching service's own distance check.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local Place = require(Shared.Place)
local Props = require(Shared.Props)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local WorldClock = require(script.Parent.WorldClock)
local Meadow = require(script.Parent.Meadow)

local Heaters = {}

local RULE = "Blizzard" -- the Worlds[id].rule value that turns the Heater on, and the condition it answers to
local FOLDER_NAME = "Heaters"
local PART_NAME = "Heater"
local REMOTE_RATE_PER_SECOND = 4 -- PlaceHeater calls per player per second
local DISC_DIAMETER = 3 -- studs across
local DISC_HEIGHT = 1.2 -- studs tall
local DISC_COLOR = Color3.fromHex("FF8C42") -- Featured gold-orange
local SINK_TRANSACTION = "Gameplay" -- Analytics.Economy transaction type
local SINK_SKU = "Heater" -- Analytics.Economy sink name (not yet in AnalyticsData.Economy.Sinks)

local ruleOn = Worlds[Place.WorldId()].rule == RULE
local burning: { [number]: number } = {} -- UserId -> heaters of theirs that are lit right now
local heaterFolder: Folder? = nil

-- Workspace.World.Heaters, made once. Meadow's Init has already made Workspace.World by the time any
-- player can place one; if it is somehow missing the folder sits directly under Workspace.
local function folder(): Folder
	local existing = heaterFolder
	if existing and existing.Parent then
		return existing
	end
	local parent: Instance = Workspace:FindFirstChild("World") or Workspace
	local found = parent:FindFirstChild(FOLDER_NAME)
	if found and found:IsA("Folder") then
		heaterFolder = found
		return found
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = parent
	heaterFolder = created
	return created
end

local function rootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Lights a heater at a flat point: seated on the walkable surface, destroyed after Config.HeaterSeconds.
-- The count drops when the part is destroyed, whoever destroys it.
local function light(owner: Player, flat: Vector3)
	local part = Instance.new("Part")
	part.Name = PART_NAME
	part.Shape = Enum.PartType.Cylinder
	-- A Roblox cylinder's axis runs along X, so the disc is made upright and turned to lie flat.
	part.Size = Vector3.new(DISC_HEIGHT, DISC_DIAMETER, DISC_DIAMETER)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = DISC_COLOR
	local surface = Meadow.GetSurfaceTop(flat)
	part.CFrame = CFrame.new(flat.X, surface + DISC_HEIGHT / 2, flat.Z) * CFrame.Angles(0, 0, math.rad(90))
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("ExpiresAt", os.time() + Config.HeaterSeconds)
	part:SetAttribute("Radius", Config.HeaterRadius)

	local ownerId = owner.UserId
	burning[ownerId] = (burning[ownerId] or 0) + 1
	part.Destroying:Connect(function()
		local left = (burning[ownerId] or 1) - 1
		if left > 0 then
			burning[ownerId] = left
		else
			burning[ownerId] = nil
		end
	end)
	-- The imported lamp (Config.HeaterPropName) stands on the surface as a child of the disc, which stays as
	-- its invisible anchor with the attributes, expiry and Neon material; Near still iterates the disc.
	if Props.Place(Config.HeaterPropName, CFrame.new(flat.X, surface, flat.Z), 1, part, false) then
		part.Transparency = 1
	end
	part.Parent = folder()
	task.delay(Config.HeaterSeconds, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

-- PlaceHeater() -> (ok, reason). Lights a heater a few studs in front of the player for Config.HeaterScrap
-- Scrap. Reasons: RateLimited, NoProfile, NotThisWorld (this place's world rule is not "Blizzard"),
-- NoBlizzard (the blizzard is not running), Limit (the player already has Config.HeaterMaxActive
-- burning), NotEnoughScrap, NoCharacter.
local function onPlaceHeater(player: Player): (boolean, string?)
	if not Net.allow(player, "PlaceHeater", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if not ruleOn then
		return false, "NotThisWorld"
	end
	if not WorldClock.HasCondition(RULE) then
		return false, "NoBlizzard"
	end
	if (burning[player.UserId] or 0) >= Config.HeaterMaxActive then
		return false, "Limit"
	end
	if profile.scrap < Config.HeaterScrap then
		return false, "NotEnoughScrap"
	end
	local root = rootPart(player)
	if not root then
		return false, "NoCharacter"
	end
	-- Nothing yields between the checks above and this deduction, so the balance still holds.
	local charged = PlayerData.Update(player, function(p: Types.Profile)
		p.scrap -= Config.HeaterScrap
	end)
	if not charged then
		return false, "NoProfile"
	end
	local live = PlayerData.Get(player)
	if live then
		Net.event("ScrapChanged"):FireClient(player, live.scrap)
		Analytics.Economy(player, "Sink", Config.HeaterScrap, live.scrap, SINK_TRANSACTION, SINK_SKU)
	end

	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local direction = if flatLook.Magnitude > 1e-3 then flatLook.Unit else Vector3.zAxis
	local flat = root.Position + direction * Config.HeaterPlaceStuds
	light(player, flat)
	return true, nil
end

-- Public API -------------------------------------------------------------

-- True when `position` stands within a lit heater's radius (flat distance, the way the client judges
-- it), for other services that want to know whether a spot is revealed.

function Heaters.Init()
	Net.event("ScrapChanged")
	Net.func("PlaceHeater").OnServerInvoke = onPlaceHeater
	if ruleOn then
		folder()
	end
end

function Heaters.Start()
	print(("[%s] Heaters: rule %s for this world"):format(Config.WorkingTitle, if ruleOn then "on" else "off"))
end

return Heaters
