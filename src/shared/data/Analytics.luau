--!strict
-- Names the server sends to AnalyticsService. Changing a name here changes the Creator Hub charts, so
-- treat them as stable once live. The onboarding funnel has one step per tutorial step (data/Tutorial
-- Steps, in order) plus the final "Done" step; custom events carry a value and a few fields.
return {
	OnboardingFunnel = "Onboarding", -- LogFunnelStepEvent; step N = tutorial step N reached, step #Steps + 1 = done
	Events = {
		Catch = "Catch", -- value 1; fields tier, species, perfect
		CatchMiss = "CatchMiss", -- value 1; fields tier (a sweep missed)
		Flee = "Flee", -- value 1; fields tier
		FirstCatchSeconds = "FirstCatchSeconds", -- value: seconds since firstSeen, once
		FirstModuleSeconds = "FirstModuleSeconds", -- value: seconds since firstSeen, once
		ModuleComplete = "ModuleComplete", -- value 1; fields moduleId, worldId
		ShowerAttend = "ShowerAttend", -- value 1 per player online when a shower starts
		PeddlerBuy = "PeddlerBuy", -- value 1; field offer kind
		GiftClaim = "GiftClaim", -- value: day
		Spin = "Spin", -- value 1; field segmentId
		ShopBuy = "ShopBuy", -- value 1; fields kind, id
		SessionSeconds = "SessionSeconds", -- value: seconds, on leave
		Launch = "Launch", -- value 1; fields from, to (world ids)
	},
	Economy = {
		Currency = "Scrap",
		Sources = { Catch = "Catch", Codex = "Codex", Income = "Income", Gift = "Gift", Spin = "Spin", Offline = "Offline" },
		Sinks = { Module = "Module", Shop = "Shop", Peddler = "Peddler", Heater = "Heater" },
	},
	IncomeFlushSeconds = 60, -- passive income is reported as one source event per player every this many seconds
}
