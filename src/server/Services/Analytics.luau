--!strict
-- ServerScriptService.Server.Services.Analytics: a thin, safe wrapper over AnalyticsService. Every
-- service reports here (the onboarding funnel, custom events, Scrap sources and sinks) and this module
-- alone decides whether anything leaves the server: nothing when Config.AnalyticsEnabled is off; one
-- printed line per event in Studio unless Config.AnalyticsInStudio is on, so a Studio test shows what
-- would be sent; otherwise the AnalyticsService call, inside a pcall, so a bad field never breaks play.
-- Every name comes from Shared/data/Analytics (they are the Creator Hub chart names). Passive income is
-- accumulated per player and flushed as one Source event every AnalyticsData.IncomeFlushSeconds (and
-- on leave), so the income tick does not spam. Funnel steps go out once per player per session.
-- Requires run one way: this module requires Config and its data table only; every service requires it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local AnalyticsData = require(Shared.data.Analytics)

local Analytics = {}

export type Flow = "Source" | "Sink"
export type Fields = { [string]: string }

type IncomeBucket = { amount: number, balance: number }

-- Roblox allows three custom field slots per event; the field names, sorted, fill them in order.
local FIELD_KEYS: { EnumItem } = {
	Enum.AnalyticsCustomFieldKeys.CustomField01,
	Enum.AnalyticsCustomFieldKeys.CustomField02,
	Enum.AnalyticsCustomFieldKeys.CustomField03,
}
local DEFAULT_TRANSACTION = Enum.AnalyticsEconomyTransactionType.Gameplay

local enabled: boolean = Config.AnalyticsEnabled
local printOnly: boolean = RunService:IsStudio() and not Config.AnalyticsInStudio

local joinedAt: { [number]: number } = {} -- os.time() the player joined, by UserId (SessionSeconds)
local funnelSent: { [number]: { [number]: boolean } } = {} -- funnel steps already reported this session, by UserId
local income: { [number]: IncomeBucket } = {} -- passive Scrap not yet reported, by UserId

-- Sending ----------------------------------------------------------------

-- The one gate every event passes: dropped when off, printed in Studio, otherwise sent inside a pcall.
local function send(line: string, fn: () -> ())
	if not enabled then
		return
	end
	if printOnly then
		print(("[%s] analytics: %s"):format(Config.WorkingTitle, line))
		return
	end
	local ok, err = pcall(function(): any
		fn()
		return nil
	end)
	if not ok then
		warn(("[%s] analytics: send failed (%s): %s"):format(Config.WorkingTitle, line, tostring(err)))
	end
end

-- Field names in a stable order, so the same event always lands each field in the same slot.
local function sortedNames(fields: Fields): { string }
	local names: { string } = {}
	for name in pairs(fields) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- The customFields table AnalyticsService takes: up to three "name=value" strings under its fixed keys
-- (the name travels inside the value so the Creator Hub breakdown stays readable). Extras are dropped.
local function customFields(fields: Fields?): { [string]: any }?
	if not fields then
		return nil
	end
	local out: { [string]: any } = {}
	local count = 0
	for _, name in ipairs(sortedNames(fields)) do
		if count >= #FIELD_KEYS then
			break
		end
		count += 1
		out[FIELD_KEYS[count].Name] = name .. "=" .. fields[name]
	end
	return if count > 0 then out else nil
end

local function fieldsLine(fields: Fields?): string
	if not fields then
		return ""
	end
	local parts: { string } = {}
	for _, name in ipairs(sortedNames(fields)) do
		table.insert(parts, name .. "=" .. fields[name])
	end
	return table.concat(parts, " ")
end

-- Public API -------------------------------------------------------------

-- One onboarding funnel step reached (AnalyticsData.OnboardingFunnel): tutorial step `step`, named by
-- its data id, or "Done" past the last one. Each step is sent at most once per player per session.
function Analytics.Funnel(player: Player, step: number, stepName: string)
	local userId = player.UserId
	local sent = funnelSent[userId]
	if not sent then
		sent = {}
		funnelSent[userId] = sent
	end
	if sent[step] then
		return
	end
	sent[step] = true
	local funnel = AnalyticsData.OnboardingFunnel
	send(("funnel %s step=%d %s (%s)"):format(funnel, step, stepName, player.Name), function()
		AnalyticsService:LogFunnelStepEvent(player, funnel, nil, step, stepName)
	end)
end

-- A custom event (AnalyticsData.Events) with a value (1 when nil) and up to three string fields.
function Analytics.Event(player: Player, name: string, value: number?, fields: Fields?)
	local v = value or 1
	local line = ("event %s value=%s"):format(name, tostring(v))
	local extra = fieldsLine(fields)
	if extra ~= "" then
		line ..= " " .. extra
	end
	line ..= (" (%s)"):format(player.Name)
	send(line, function()
		AnalyticsService:LogCustomEvent(player, name, v, customFields(fields))
	end)
end

-- Scrap entering (Source) or leaving (Sink) a profile. transactionType is one of
-- Enum.AnalyticsEconomyTransactionType's names (Gameplay, Shop, TimedReward, ...) or any descriptive
-- name, which maps to Gameplay; sku names the source or sink (AnalyticsData.Economy) and falls back to
-- transactionType. Amounts are rounded to whole Scrap and anything under one is not an event.
function Analytics.Economy(player: Player, flow: Flow, amount: number, endingBalance: number, transactionType: string, sku: string?)
	local whole = math.floor(amount + 0.5)
	if whole < 1 then
		return
	end
	local balance = math.max(0, math.floor(endingBalance + 0.5))
	local flowType = if flow == "Sink" then Enum.AnalyticsEconomyFlowType.Sink else Enum.AnalyticsEconomyFlowType.Source
	local transaction = Enum.AnalyticsEconomyTransactionType:FromName(transactionType) or DEFAULT_TRANSACTION
	local itemSku = sku or transactionType
	local currency = AnalyticsData.Economy.Currency
	send(
		("economy %s %s amount=%d balance=%d type=%s sku=%s (%s)"):format(flow, currency, whole, balance, transaction.Name, itemSku, player.Name),
		function()
			AnalyticsService:LogEconomyEvent(player, flowType, currency, whole, balance, transaction.Name, itemSku)
		end
	)
end

-- Passive station income: accumulated per player and reported as one Source (Sources.Income) every
-- AnalyticsData.IncomeFlushSeconds and when the player leaves, with the latest balance.
function Analytics.Income(player: Player, amount: number, balance: number)
	if amount <= 0 then
		return
	end
	local userId = player.UserId
	local bucket = income[userId]
	if not bucket then
		bucket = { amount = 0, balance = 0 }
		income[userId] = bucket
	end
	bucket.amount += amount
	bucket.balance = balance
end

local function flushIncome(player: Player)
	local bucket = income[player.UserId]
	if not bucket then
		return
	end
	income[player.UserId] = nil
	Analytics.Economy(player, "Source", bucket.amount, bucket.balance, "Gameplay", AnalyticsData.Economy.Sources.Income)
end

-- Players ----------------------------------------------------------------

local function onPlayerAdded(player: Player)
	joinedAt[player.UserId] = os.time()
end

-- Leaving: the pending income goes out, then the session length, then every per-player table clears.
local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	flushIncome(player)
	local joined = joinedAt[userId]
	if joined then
		Analytics.Event(player, AnalyticsData.Events.SessionSeconds, math.max(0, os.time() - joined))
	end
	joinedAt[userId] = nil
	funnelSent[userId] = nil
	income[userId] = nil
end

-- Nothing to create at Init: no remotes, no instances. Everything here is server-side only.

function Analytics.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	task.spawn(function()
		while true do
			task.wait(AnalyticsData.IncomeFlushSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				flushIncome(player)
			end
		end
	end)

	local mode = if not enabled then "off" elseif printOnly then "Studio print mode" else "on"
	print(("[%s] Analytics: %s"):format(Config.WorkingTitle, mode))
end

return Analytics
