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
		PlaytimeGift = "PlaytimeGift", -- value: the gift's index (1 to 6, data/Playtime)
		ShopBuy = "ShopBuy", -- value 1; fields kind, id
		SessionSeconds = "SessionSeconds", -- value: seconds, on leave
		Launch = "Launch", -- value 1; fields from, to (world ids)
		Fly = "Fly", -- value 1; fields from, to (world ids): a Star Chart flight
		GroupReward = "GroupReward", -- value 1: the group gift claimed
		Referral = "Referral", -- value 1; field role (invitee, inviter)
		NotifyAsk = "NotifyAsk", -- value 1; field answer (yes, no)
		DailyQuest = "DailyQuest", -- value 1; fields period (daily, weekly), id, action (claim, reroll)
		Code = "Code", -- value 1; field id
		FriendsInServer = "FriendsInServer", -- value: friends of the player in this server, on every change
		CatchRush = "CatchRush", -- value: the player's catches in a round; field rank (0 = unranked)
		Fuse = "Fuse", -- value: the kept copy's new level; field species
		Companion = "Companion", -- value 1; fields action (follow, unfollow, token), species
		Mount = "Mount", -- value 1; fields action (mount, dismount), species, traversal
		MailClaim = "MailClaim", -- value 1; field from
		Display = "Display", -- value 1; fields action (on, off), species
		HomePlace = "HomePlace", -- value: the Scrap paid; fields item
		HomeRemove = "HomeRemove", -- value 1; fields item
		Admin = "Admin", -- value 1; fields action (luck, shower, weather, say), by (the developer's user id); once per server that applies it
		Sighting = "Sighting", -- value 1 per player online when a Warden sighting starts; field species
		WeeklyFlip = "WeeklyFlip", -- value: the rotation index; fields species, weather; once per server when the week changes
		SeasonStart = "SeasonStart", -- value 1 per player online when a season begins (or is forced on); field id
		SeasonClaim = "SeasonClaim", -- value 1; fields id (the season), quest
		Rest = "Rest", -- value: seconds rested; field earned (the Scrap the crew made meanwhile); on waking or leaving
		Visit = "Visit", -- value 1; fields owner (the home's owner user id), how (here: the view switched in this server; trip: a reserved server)
		Wave = "Wave", -- value: the Scrap paid the visitor; fields owner, species
		TutorialSkipped = "TutorialSkipped", -- value: the step left behind when a profile left World 1 mid-tutorial; field world (the one moved to)
	},
	Economy = {
		Currency = "Scrap",
		Sources = { Catch = "Catch", Codex = "Codex", Income = "Income", Gift = "Gift", Playtime = "Playtime", Spin = "Spin", Offline = "Offline", Outpost = "Outpost", Social = "Social", Rush = "Rush", Habitat = "Habitat", Mail = "Mail", Wave = "Wave" },
		Sinks = { Module = "Module", Shop = "Shop", Peddler = "Peddler", Heater = "Heater", Outpost = "Outpost", Home = "Home" },
	},
	IncomeFlushSeconds = 60, -- passive income is reported as one source event per player every this many seconds
}
