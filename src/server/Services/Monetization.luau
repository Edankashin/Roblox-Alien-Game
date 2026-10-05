--!strict
-- ServerScriptService.Server.Services.Monetization: the Robux launch shop (Shared/data/Shop).
-- The server owns every purchase: the client sends an item id and nothing else, and this service
-- prompts the Roblox purchase (so product and pass ids never leave the server), processes developer
-- product receipts idempotently (profile.shop.receipts remembers every granted PurchaseId, pruned to
-- Config.ReceiptMemory), detects game passes on join (UserOwnsGamePassAsync, retried
-- Config.PassCheckRetries times) and when a prompt finishes, and hands each item's grants
-- (Shop.Grants, in order) to the service that owns that kind of thing. Scrap is never sold; no grant
-- here writes profile.scrap. The two Server Luck products are the only paid random items and are hidden
-- and refused where PolicyService says ArePaidRandomItemsRestricted.
--
-- Requires run one way: this module requires PlayerData, Analytics, Net, Config, the data tables and
-- Species only. Every other service requires this one and registers a granter at Init
-- (SetGranter: Economy for alien and slots, Shop for gear, Gifts for spins, Buffs for powerUp); the
-- kinds serverLuck (shared luck, broadcast to everyone), cosmetic (an owned id in profile.purchases) and
-- passFlag (nothing to grant: the owning service reads OwnsPass live) are handled here. Buffs adds
-- ServerLuckBonus to every luck number and registers its LuckChanged broadcast through
-- OnServerLuckChanged, so this module never requires Buffs back.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local ShopData = require(Shared.data.Shop)
local Species = require(Shared.data.Species)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local Monetization = {}

export type Grant = ShopData.ShopGrant
export type GrantSource = "receipt" | "pass" | "dev"
export type Granter = (Player, Grant) -> (boolean, string?)

type ServerLuck = { bonus: number, endsAt: number, playerName: string }

local SNAPSHOT_RATE_PER_SECOND = 2 -- GetPurchases, PromptPurchase and GetPolicy calls per player per second
local CHOICE_RATE_PER_SECOND = 4 -- SetStarterChoice calls per player per second
local PASS_RETRY_SECONDS = 1 -- pause between UserOwnsGamePassAsync attempts

-- Catalog views ----------------------------------------------------------

local ITEMS_BY_ID: { [string]: ShopData.ShopItem } = {}
local ITEMS_BY_PRODUCT: { [number]: ShopData.ShopItem } = {} -- live developer product ids only (never 0)
local ITEMS_BY_PASS: { [number]: ShopData.ShopItem } = {} -- live game pass ids only (never 0)
local LAUNCH_IDS: { [string]: boolean } = {} -- what the launch shop sells (Shop.Launch sections)
local LAUNCH_PASSES: { ShopData.ShopItem } = {} -- the passes checked on every join
local STARTER_CHOICES: { [string]: boolean } = {}

for _, item in ipairs(ShopData.Items) do
	ITEMS_BY_ID[item.id] = item
	local productId = item.productId or 0
	local passId = item.passId or 0
	if item.kind == "product" and productId ~= 0 then
		ITEMS_BY_PRODUCT[productId] = item
	elseif item.kind == "pass" and passId ~= 0 then
		ITEMS_BY_PASS[passId] = item
	end
end
for _, section in ipairs(ShopData.Launch) do
	for _, id in ipairs(section.items) do
		LAUNCH_IDS[id] = true
		local item = ITEMS_BY_ID[id]
		if item and item.kind == "pass" then
			table.insert(LAUNCH_PASSES, item)
		end
	end
end
for _, id in ipairs(ShopData.StarterChoices) do
	STARTER_CHOICES[id] = true
end

-- State -------------------------------------------------------------------

local granters: { [string]: Granter } = {}
local passes: { [number]: { [string]: boolean } } = {} -- owned passes this session, by UserId -> item id
local policyCache: { [number]: boolean } = {} -- ArePaidRandomItemsRestricted once fetched, by UserId
local serverLuck: ServerLuck? = nil
local luckListeners: { (boolean) -> () } = {} -- Buffs.PushLuckAll, see the header
local luckLoopRunning = false

-- Helpers -----------------------------------------------------------------

local function grantsOf(itemId: string): { Grant }
	return ShopData.Grants[itemId] or {}
end

-- A pass with something to hand over once (slots, gear); a flag-only pass is read live and never recorded.
local function hasOneTimeGrants(itemId: string): boolean
	for _, grant in ipairs(grantsOf(itemId)) do
		if grant.kind ~= "passFlag" then
			return true
		end
	end
	return false
end

local function ownedPasses(userId: number): { [string]: boolean }
	local owned = passes[userId]
	if not owned then
		owned = {}
		passes[userId] = owned
	end
	return owned
end

local function purchasesState(player: Player, profile: Types.Profile): Types.PurchasesState
	return { purchases = profile.purchases, passes = ownedPasses(player.UserId), starterSpecies = profile.shop.starterSpecies }
end

local function pushPurchases(player: Player)
	local profile = PlayerData.Get(player)
	if profile then
		Net.event("PurchasesChanged"):FireClient(player, purchasesState(player, profile))
	end
end

-- Server luck ------------------------------------------------------------

local function luckSnapshot(): Types.ServerLuckState
	local running = serverLuck
	if not running then
		return nil
	end
	return { bonus = running.bonus, secondsLeft = math.max(0, running.endsAt - os.time()), playerName = running.playerName }
end

local function broadcastLuck()
	Net.event("ServerLuckChanged"):FireAllClients(luckSnapshot())
end

-- Each listener runs in its own thread so one failing service cannot stall a purchase.
local function fireLuckListeners(active: boolean)
	for _, callback in ipairs(luckListeners) do
		task.spawn(callback, active)
	end
end

-- Re-pushes the countdown every ServerLuckPushSeconds while the luck runs, then ends it: nil to every
-- client and the listeners hear the end. One loop at a time; an extension just moves endsAt.
local function runLuckLoop()
	if luckLoopRunning then
		return
	end
	luckLoopRunning = true
	task.spawn(function()
		while true do
			local running = serverLuck
			if not running then
				break
			end
			local left = running.endsAt - os.time()
			if left <= 0 then
				break
			end
			task.wait(math.min(Config.ServerLuckPushSeconds, left))
			if serverLuck then
				broadcastLuck()
			end
		end
		serverLuck = nil
		luckLoopRunning = false
		broadcastLuck()
		fireLuckListeners(false)
	end)
end

-- A bigger bonus takes over (its clock never shorter than what was left); the same bonus adds its time;
-- a smaller one while a bigger runs adds its time to the bigger (nobody is ever downgraded).
local function startServerLuck(player: Player, bonus: number, seconds: number)
	local now = os.time()
	local current = serverLuck
	if current and current.endsAt > now then
		if bonus > current.bonus then
			serverLuck = { bonus = bonus, endsAt = math.max(current.endsAt, now + seconds), playerName = player.DisplayName }
		else
			current.endsAt += seconds
		end
		broadcastLuck()
		return
	end
	serverLuck = { bonus = bonus, endsAt = now + seconds, playerName = player.DisplayName }
	broadcastLuck()
	fireLuckListeners(true)
	runLuckLoop()
end

-- Granting ----------------------------------------------------------------

-- Runs one grant through its owner. The resolved grant is a copy, so a chosen species can be filled in.
local function applyGrant(player: Player, grant: Grant): (boolean, string?)
	local kind = grant.kind
	if kind == "serverLuck" then
		startServerLuck(player, grant.bonus or 0, grant.seconds or 0)
		return true, nil
	elseif kind == "cosmetic" then
		local id = grant.id
		if not id then
			return false, "BadGrant"
		end
		local ok = PlayerData.Update(player, function(profile)
			profile.purchases[id] = 1
		end)
		return ok, if ok then nil else "NoProfile"
	elseif kind == "passFlag" then
		return true, nil -- the owning service reads OwnsPass live
	end
	local granter = granters[kind]
	if not granter then
		return false, "NoGranter"
	end
	return granter(player, grant)
end

-- Hands over everything an item grants, in order, then records it. Reasons: Unknown (no such item),
-- NoProfile, AlreadyOwned (a `once` product or a pass already recorded), NoChoice (a Starter Pack
-- before the player picked a Rare; a receipt then stays NotProcessedYet so nobody is charged early),
-- NoGranter (no service registered that kind), BadGrant, or whatever the owning granter refused with.
function Monetization.GrantItem(player: Player, itemId: string, source: GrantSource): (boolean, string?)
	local item = ITEMS_BY_ID[itemId]
	if not item then
		return false, "Unknown"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local recorded = profile.purchases[itemId]
	if (item.once or item.kind == "pass") and recorded ~= nil and recorded > 0 then
		return false, "AlreadyOwned"
	end

	-- Resolve everything that can be checked before anything is written.
	local resolved: { Grant } = {}
	for _, grant in ipairs(grantsOf(itemId)) do
		local copy = table.clone(grant)
		if copy.kind == "alien" and copy.choose then
			local species = profile.shop.starterSpecies
			if not species then
				return false, "NoChoice"
			end
			copy.id = species
		end
		table.insert(resolved, copy)
	end

	for _, grant in ipairs(resolved) do
		local ok, reason = applyGrant(player, grant)
		if not ok then
			warn(("[%s] Monetization: %s grant %s for %s refused: %s"):format(Config.WorkingTitle, itemId, grant.kind, player.Name, tostring(reason)))
			return false, reason
		end
	end

	local oneTime = hasOneTimeGrants(itemId)
	PlayerData.Update(player, function(p)
		if item.kind == "product" then
			p.purchases[itemId] = (p.purchases[itemId] or 0) + 1
		elseif oneTime then
			p.purchases[itemId] = 1 -- the pass's one-time grants were applied; never again
		end
	end)
	pushPurchases(player)
	Analytics.Event(player, AnalyticsData.Events.ShopBuy, 1, { kind = "robux", id = itemId, source = source :: string })
	return true, nil
end

-- Passes ------------------------------------------------------------------

-- An owned pass whose one-time grants were never applied gets them now, once (GrantItem records it).
local function applyPassGrants(player: Player, itemId: string, source: GrantSource)
	if not hasOneTimeGrants(itemId) then
		return
	end
	local profile = PlayerData.Get(player)
	if not profile or profile.purchases[itemId] ~= nil then
		return
	end
	Monetization.GrantItem(player, itemId, source)
end

-- Asks Roblox about every live launch pass, all at once, retrying each up to PassCheckRetries. Yields
-- until every answer is in (or given up), so the OnLoaded callbacks after this one (Economy's offline
-- cap) already see the passes. With no live pass ids nothing yields.
local function checkPasses(player: Player)
	local userId = player.UserId
	local owned = ownedPasses(userId)
	local pending = 0
	local retries = math.max(1, Config.PassCheckRetries)
	for _, item in ipairs(LAUNCH_PASSES) do
		local passId = item.passId or 0
		if passId ~= 0 then
			pending += 1
			task.spawn(function()
				for attempt = 1, retries do
					local ok, result = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
					end)
					if ok then
						if result == true then
							owned[item.id] = true
						end
						break
					end
					if attempt == retries then
						warn(("[%s] Monetization: pass %s check failed for %s: %s"):format(Config.WorkingTitle, item.id, player.Name, tostring(result)))
					else
						task.wait(PASS_RETRY_SECONDS)
					end
				end
				pending -= 1
			end)
		end
	end
	while pending > 0 do
		task.wait()
	end
end

local function onLoaded(player: Player, _profile: Types.Profile)
	checkPasses(player)
	if player.Parent ~= Players then
		return
	end
	for itemId in pairs(ownedPasses(player.UserId)) do
		applyPassGrants(player, itemId, "pass")
	end
	pushPurchases(player)
	if serverLuck then
		Net.event("ServerLuckChanged"):FireClient(player, luckSnapshot())
	end
end

local function onPassPromptFinished(player: Player, passId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	local item = ITEMS_BY_PASS[passId]
	if not item then
		return
	end
	ownedPasses(player.UserId)[item.id] = true
	if hasOneTimeGrants(item.id) then
		applyPassGrants(player, item.id, "pass") -- records and reports the purchase
	else
		Analytics.Event(player, AnalyticsData.Events.ShopBuy, 1, { kind = "robux", id = item.id, source = "pass" })
	end
	pushPurchases(player)
end

-- Receipts ----------------------------------------------------------------

-- Keeps the newest ReceiptMemory receipt ids; the rest are old enough that Roblox will not resend them.
local function pruneReceipts(receipts: { [string]: number })
	local ids: { string } = {}
	for id in pairs(receipts) do
		table.insert(ids, id)
	end
	local excess = #ids - Config.ReceiptMemory
	if excess <= 0 then
		return
	end
	table.sort(ids, function(a, b)
		return receipts[a] < receipts[b]
	end)
	for index = 1, excess do
		receipts[ids[index]] = nil
	end
end

-- PurchaseGranted: the receipt was already granted (idempotent), or the item was granted now and the
-- receipt id recorded. NotProcessedYet: unknown product, player not in game or not loaded, or a grant
-- refused (a Starter Pack with no choice, a granter failure); Roblox retries later. Never throws.
local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local ok, decision = pcall(function(): Enum.ProductPurchaseDecision
		local productId = tonumber(receipt.ProductId) or 0
		local purchaseId = tostring(receipt.PurchaseId)
		local item = ITEMS_BY_PRODUCT[productId]
		if not item then
			warn(("[%s] Monetization: receipt for unknown product %d"):format(Config.WorkingTitle, productId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(tonumber(receipt.PlayerId) or 0)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local profile = PlayerData.Get(player)
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if profile.shop.receipts[purchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local granted, reason = Monetization.GrantItem(player, item.id, "receipt")
		if not granted then
			warn(("[%s] Monetization: receipt %s (%s) for %s not granted: %s"):format(Config.WorkingTitle, purchaseId, item.id, player.Name, tostring(reason)))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		PlayerData.Update(player, function(p)
			p.shop.receipts[purchaseId] = os.time()
			pruneReceipts(p.shop.receipts)
		end)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end)
	if not ok then
		warn(("[%s] Monetization: ProcessReceipt failed: %s"):format(Config.WorkingTitle, tostring(decision)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return decision
end

-- Policy ------------------------------------------------------------------

-- Whether paid random items are restricted for this player; a failed lookup counts as restricted (and
-- is not cached, so a later call can recover).
local function paidRandomRestricted(player: Player): boolean
	local cached = policyCache[player.UserId]
	if cached ~= nil then
		return cached
	end
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or type(info) ~= "table" then
		return true
	end
	local restricted = info.ArePaidRandomItemsRestricted == true
	policyCache[player.UserId] = restricted
	return restricted
end

-- Remotes -----------------------------------------------------------------

-- GetPurchases() -> PurchasesState: products granted so far, the passes owned now and the Starter Pack
-- choice. nil when rate limited or before the profile loads.
local function onGetPurchases(player: Player): Types.PurchasesState?
	if not Net.allow(player, "GetPurchases", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return nil
	end
	return purchasesState(player, profile)
end

-- SetStarterChoice(speciesId) -> (ok, reason). The Rare a Starter Pack will hand over; it can change
-- until the pack is granted. Reasons: BadArgs (not one of Shop.StarterChoices), RateLimited,
-- NoProfile, AlreadyOwned.
local function onSetStarterChoice(player: Player, speciesId: any): (boolean, string?)
	if type(speciesId) ~= "string" or not STARTER_CHOICES[speciesId] or not Species.ById[speciesId] then
		return false, "BadArgs"
	end
	if not Net.allow(player, "SetStarterChoice", CHOICE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if (profile.purchases.StarterPack or 0) > 0 then
		return false, "AlreadyOwned"
	end
	PlayerData.Update(player, function(p)
		p.shop.starterSpecies = speciesId
	end)
	pushPurchases(player)
	return true, nil
end

-- PromptPurchase(itemId) -> (ok, reason). The server opens the Roblox prompt for a launch item; the
-- result arrives through ProcessReceipt or PromptGamePassPurchaseFinished, never through this call.
-- Reasons: BadArgs (not in the launch sections), RateLimited, NoProfile, Restricted (a paid random item
-- where policy forbids them), AlreadyOwned (a `once` product granted, or a pass owned), NoChoice (a
-- Starter Pack before the pick), NotLive (placeholder id 0), PromptFailed.
local function onPromptPurchase(player: Player, itemId: any): (boolean, string?)
	if type(itemId) ~= "string" or not LAUNCH_IDS[itemId] then
		return false, "BadArgs"
	end
	if not Net.allow(player, "PromptPurchase", SNAPSHOT_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local item = ITEMS_BY_ID[itemId]
	local profile = PlayerData.Get(player)
	if not item or not profile then
		return false, "NoProfile"
	end
	if item.paidRandom and paidRandomRestricted(player) then
		return false, "Restricted"
	end
	if item.kind == "pass" then
		if ownedPasses(player.UserId)[itemId] then
			return false, "AlreadyOwned"
		end
	else
		if item.once and (profile.purchases[itemId] or 0) > 0 then
			return false, "AlreadyOwned"
		end
		for _, grant in ipairs(grantsOf(itemId)) do
			if grant.kind == "alien" and grant.choose and not profile.shop.starterSpecies then
				return false, "NoChoice"
			end
		end
	end
	local liveId = if item.kind == "pass" then item.passId or 0 else item.productId or 0
	if liveId == 0 then
		return false, "NotLive"
	end
	local ok, err = pcall(function(): any
		if item.kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, liveId)
		else
			MarketplaceService:PromptProductPurchase(player, liveId)
		end
		return nil
	end)
	if not ok then
		warn(("[%s] Monetization: prompt for %s failed: %s"):format(Config.WorkingTitle, itemId, tostring(err)))
		return false, "PromptFailed"
	end
	return true, nil
end

-- GetPolicy() -> { paidRandomRestricted }: the client hides the paid random items when true.
local function onGetPolicy(player: Player): { paidRandomRestricted: boolean }?
	if not Net.allow(player, "GetPolicy", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return { paidRandomRestricted = paidRandomRestricted(player) }
end

-- Public API --------------------------------------------------------------

-- A service hands over the function that grants one kind (alien, gear, spins, powerUp, slots). It returns
-- false with a reason to refuse the whole item.
function Monetization.SetGranter(kind: string, fn: Granter)
	granters[kind] = fn
end

-- Whether this player owns the pass right now (this session's checks and prompts; nothing is saved).
function Monetization.OwnsPass(player: Player, itemId: string): boolean
	local owned = passes[player.UserId]
	return owned ~= nil and owned[itemId] == true
end

-- The shared luck every player on the server carries while a bought Server Luck runs, else 0.
function Monetization.ServerLuckBonus(): number
	local running = serverLuck
	if running and running.endsAt > os.time() then
		return running.bonus
	end
	return 0
end

-- Server-side hook: `callback` runs with true when a server luck starts and false when it ends.
function Monetization.OnServerLuckChanged(callback: (boolean) -> ())
	table.insert(luckListeners, callback)
end

-- Developer overrides (Studio commands, guarded by Dev): grant an item as if bought, and own or drop a
-- pass for this session (owning applies its one-time grants once, like a real pass).
function Monetization.DevGrant(player: Player, itemId: string): (boolean, string?)
	return Monetization.GrantItem(player, itemId, "dev")
end

function Monetization.DevSetPass(player: Player, itemId: string, owned: boolean): (boolean, string?)
	local item = ITEMS_BY_ID[itemId]
	if not item or item.kind ~= "pass" then
		return false, "Unknown"
	end
	local ownedNow = ownedPasses(player.UserId)
	if owned then
		ownedNow[itemId] = true
		applyPassGrants(player, itemId, "dev")
	else
		ownedNow[itemId] = nil
	end
	pushPurchases(player)
	return true, nil
end

function Monetization.Init()
	Net.event("PurchasesChanged")
	Net.event("ServerLuckChanged")
	Net.func("GetPurchases").OnServerInvoke = onGetPurchases
	Net.func("SetStarterChoice").OnServerInvoke = onSetStarterChoice
	Net.func("PromptPurchase").OnServerInvoke = onPromptPurchase
	Net.func("GetPolicy").OnServerInvoke = onGetPolicy
	PlayerData.OnLoaded(onLoaded)
end

function Monetization.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassPromptFinished)
	Players.PlayerRemoving:Connect(function(player: Player)
		passes[player.UserId] = nil
		policyCache[player.UserId] = nil
	end)

	local products, passCount, live = 0, 0, 0
	for id in pairs(LAUNCH_IDS) do
		local item = ITEMS_BY_ID[id]
		if item then
			if item.kind == "pass" then
				passCount += 1
				if (item.passId or 0) ~= 0 then
					live += 1
				end
			else
				products += 1
				if (item.productId or 0) ~= 0 then
					live += 1
				end
			end
		end
	end
	print(("[%s] Monetization: %d products, %d passes (live ids: %d)"):format(Config.WorkingTitle, products, passCount, live))
end

return Monetization
