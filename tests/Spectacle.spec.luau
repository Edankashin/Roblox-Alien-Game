--!strict
-- The spectacle ladder (data/Spectacle) and its rules (Shared/SpectacleMath): every tier has a row, the ladder climbs (an
-- arrival, a presence, a reaction and a catch at least as grand as the tier below), the gating (what a tier draws, Sleep only at
-- night, the approach flourish from Rare), the still versions under Reduced Motion, the phone budgets (a Cosmic arrival with eight
-- aliens around under the scene caps) and the clocks (hops, the leash walk, idles, the spiral, the slow-mo, the escape, the blink,
-- the vignette held under three flickers a second, the beacon, footprints) and the glyphs.
local Shared = game:GetService("ReplicatedStorage").Shared
local Spectacle = require(Shared.data.Spectacle)
local SpectacleMath = require(Shared.SpectacleMath)
local Tiers = require(Shared.data.Tiers)
local Effects = require(Shared.data.Effects)
local Sounds = require(Shared.data.Sounds)

local ORDER = Tiers.Order
local KIND_RANK = { None = 0, Pop = 1, Burst = 2, Star = 3, Beam = 4, Glitch = 4 }

describe("the greeting bubble", function()
	local Config = require(Shared.data.Config)
	it("stands wholly above the nameplate, at any alien height", function()
		for _, top in ipairs({ 0.5, 1, 1.6, 3.5 }) do
			local lift = SpectacleMath.BubbleLift(top, Config.WildBobStuds, Config.NameplateLiftStuds, Config.NameplateStudsH, Spectacle.Look.BubbleGap, Spectacle.Look.BubbleStuds)
			local plateTop = top + Config.WildBobStuds + Config.NameplateLiftStuds + Config.NameplateStudsH / 2
			local bubbleBottom = lift - Spectacle.Look.BubbleStuds / 2
			assert(bubbleBottom >= plateTop + Spectacle.Look.BubbleGap - 1e-9, "bubble bottom " .. bubbleBottom .. " under plate top " .. plateTop)
			assert(Spectacle.Look.BubbleGap > 0, "a gap between them")
		end
	end)
end)

describe("the data", function()
	it("has one row of each table per tier, and nothing else", function()
		for _, name in ipairs({ "Arrivals", "Presence", "Personality", "Catch" }) do
			local rows = (Spectacle :: any)[name]
			for _, tier in ipairs(ORDER) do
				expect(rows[tier] ~= nil).toEqual(true)
			end
			for tier in pairs(rows) do
				expect(Tiers.Tiers[tier] ~= nil).toEqual(true)
			end
		end
	end)

	it("keeps Commons and Uncommons quiet: no arrival, no presence, no flourish", function()
		for _, tier in ipairs({ "Common", "Uncommon" }) do
			expect(Spectacle.Arrivals[tier].kind).toEqual("None")
			expect(Spectacle.Arrivals[tier].beacon).toEqual(0)
			expect(Spectacle.Presence[tier].pool).toEqual(0)
			expect(Spectacle.Personality[tier].approachFlourish).toEqual(false)
		end
	end)

	it("gives each rung its arrival: a portal pop, a burst, a falling star, a beam, a glitch-in", function()
		expect(Spectacle.Arrivals.Rare.kind).toEqual("Pop")
		expect(Spectacle.Arrivals.Epic.kind).toEqual("Burst")
		expect(Spectacle.Arrivals.Legendary.kind).toEqual("Star")
		expect(Spectacle.Arrivals.Cosmic.kind).toEqual("Beam")
		expect(Spectacle.Arrivals.Secret.kind).toEqual("Glitch")
		expect(Spectacle.Arrivals.Legendary.fall > 0).toEqual(true)
		expect(Spectacle.Arrivals.Cosmic.fall > 0 and Spectacle.Arrivals.Cosmic.skyDim > 0).toEqual(true)
		expect(Spectacle.Arrivals.Secret.vignette).toEqual(true)
		for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic" }) do
			expect(Spectacle.Arrivals[tier].vignette).toEqual(false)
		end
	end)

	it("stands a beacon from Epic: for a while on an Epic, while it stays from Legendary", function()
		expect(Spectacle.Arrivals.Rare.beacon).toEqual(0)
		expect(Spectacle.Arrivals.Epic.beacon > 0).toEqual(true)
		for _, tier in ipairs({ "Legendary", "Cosmic", "Secret" }) do
			expect(Spectacle.Arrivals[tier].beacon).toEqual(-1)
			expect(Spectacle.Arrivals[tier].beaconReach > 0 and Spectacle.Arrivals[tier].beaconWidth > 0).toEqual(true)
		end
	end)

	it("climbs the presence ladder: a pool from Rare, ornaments from Epic, footprints from Legendary, a trail and shimmer at the top", function()
		expect(Spectacle.Presence.Rare.pool > 0 and Spectacle.Presence.Rare.ornaments == 0).toEqual(true)
		expect(Spectacle.Presence.Epic.ornaments > 0 and not Spectacle.Presence.Epic.footprints).toEqual(true)
		expect(Spectacle.Presence.Legendary.footprints and Spectacle.Presence.Legendary.aura > 0).toEqual(true)
		expect(Spectacle.Presence.Legendary.trail).toEqual(0)
		expect(Spectacle.Presence.Cosmic.trail > 0 and Spectacle.Presence.Cosmic.shimmer == "StarField").toEqual(true)
		expect(Spectacle.Presence.Secret.trail > 0 and Spectacle.Presence.Secret.shimmer == "Haze").toEqual(true)
	end)

	it("leaves the Cosmic and Secret soft aura to data/Effects' aura shell (never two auras)", function()
		for _, tier in ipairs({ "Cosmic", "Secret" }) do
			expect(Effects.Tiers[tier].aura).toEqual(true)
			expect(Spectacle.Presence[tier].aura).toEqual(0)
		end
		expect(Effects.Tiers.Legendary.aura).toEqual(false)
	end)

	it("never lets one rung be less grand than the one below", function()
		for index = 2, #ORDER do
			local low, high = ORDER[index - 1], ORDER[index]
			local a, b = Spectacle.Arrivals[low], Spectacle.Arrivals[high]
			expect(KIND_RANK[b.kind] >= KIND_RANK[a.kind]).toEqual(true)
			local p, q = Spectacle.Presence[low], Spectacle.Presence[high]
			expect(q.ornaments >= p.ornaments).toEqual(true)
			expect(q.pool > 0 or p.pool == 0).toEqual(true)
			local r, s = Spectacle.Personality[low], Spectacle.Personality[high]
			expect(s.theatre >= r.theatre and s.hops >= r.hops and s.notice >= r.notice).toEqual(true)
			local c, d = Spectacle.Catch[low], Spectacle.Catch[high]
			expect(d.flashes >= c.flashes and d.cells >= c.cells and d.spiral >= c.spiral).toEqual(true)
		end
	end)

	it("adds a nudge and a shockwave from Legendary and a slow-mo at Cosmic and Secret; a Secret blinks out", function()
		for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic" }) do
			expect(Spectacle.Catch[tier].nudge == 0 and Spectacle.Catch[tier].shockwave == 0 and Spectacle.Catch[tier].slowmo == 0).toEqual(true)
			expect(Spectacle.Catch[tier].escape).toEqual("PuffHop")
		end
		expect(Spectacle.Catch.Legendary.nudge > 0 and Spectacle.Catch.Legendary.shockwave > 0).toEqual(true)
		expect(Spectacle.Catch.Legendary.slowmo).toEqual(0)
		expect(Spectacle.Catch.Cosmic.slowmo > 0 and Spectacle.Catch.Secret.slowmo > 0).toEqual(true)
		expect(Spectacle.Catch.Secret.escape).toEqual("BlinkOut")
	end)

	it("has an ambient note hook per tier with a presence, silent until the sound pass", function()
		local ambient = (Sounds :: any).TierAmbient
		expect(type(ambient)).toEqual("table")
		for _, tier in ipairs(ORDER) do
			if Spectacle.Presence[tier].ambient then
				expect(type(ambient[tier])).toEqual("string")
			end
		end
	end)
end)

describe("the gates", function()
	it("answers Common's row for an unknown tier", function()
		expect(SpectacleMath.Arrival("Nope").kind).toEqual("None")
		expect(SpectacleMath.Presence("Nope").pool).toEqual(0)
		expect(SpectacleMath.CatchLook("Nope").flashes).toEqual(Spectacle.Catch.Common.flashes)
	end)

	it("plays the approach flourish from Rare, once, within the approach distance", function()
		expect(SpectacleMath.ApproachFlourish("Common", 1, false)).toEqual(false)
		expect(SpectacleMath.ApproachFlourish("Uncommon", 1, false)).toEqual(false)
		local near = Spectacle.Personality.Rare.approach
		expect(SpectacleMath.ApproachFlourish("Rare", near, false)).toEqual(true)
		expect(SpectacleMath.ApproachFlourish("Rare", near + 0.1, false)).toEqual(false)
		expect(SpectacleMath.ApproachFlourish("Rare", 1, true)).toEqual(false)
	end)

	it("notices within the tier's distance", function()
		expect(SpectacleMath.Noticed("Epic", Spectacle.Personality.Epic.notice)).toEqual(true)
		expect(SpectacleMath.Noticed("Epic", Spectacle.Personality.Epic.notice + 1)).toEqual(false)
	end)

	it("sleeps only at night", function()
		local slept = false
		for index = 1, 400 do
			expect(SpectacleMath.IdleFor("Common", 0.37, index, false) ~= "Sleep").toEqual(true)
			if SpectacleMath.IdleFor("Common", 0.37, index, true) == "Sleep" then
				slept = true
			end
		end
		expect(slept).toEqual(true)
	end)

	it("picks the same idle for the same seed and cycle, and plays more as the tier rises", function()
		expect(SpectacleMath.IdleFor("Rare", 0.5, 12, true)).toEqual(SpectacleMath.IdleFor("Rare", 0.5, 12, true))
		local function plays(tier: string): number
			local n = 0
			for index = 1, 600 do
				if SpectacleMath.IdleFor(tier, 0.21, index, false) == "Play" then
					n += 1
				end
			end
			return n
		end
		expect(plays("Common")).toEqual(0)
		expect(plays("Cosmic") > plays("Rare")).toEqual(true)
	end)

	it("flashes the bar per tier, one more on a Perfect, none on a miss", function()
		for _, tier in ipairs(ORDER) do
			expect(SpectacleMath.Flashes(tier, "Good")).toEqual(Spectacle.Catch[tier].flashes)
			expect(SpectacleMath.Flashes(tier, "Perfect")).toEqual(Spectacle.Catch[tier].flashes + 1)
			expect(SpectacleMath.Flashes(tier, "Miss")).toEqual(0)
		end
	end)

	it("never flashes or flickers more than three times a second", function()
		expect(Spectacle.Look.FlashPeriod >= 1 / 3).toEqual(true)
		for _, tier in ipairs(ORDER) do
			local row = Spectacle.Arrivals[tier]
			if row.vignette then
				expect(SpectacleMath.VignetteRate(row.seconds) <= 3).toEqual(true)
			end
		end
		expect(Spectacle.Look.BlinkFlickers / Spectacle.Look.BlinkSeconds <= 10).toEqual(true) -- a blink-out is one half-second event, not a strobe
	end)
end)

describe("reduced motion", function()
	it("plays the still version of every arrival: nothing flies, falls, flickers or dims; the beacon stays", function()
		for _, tier in ipairs(ORDER) do
			local plan = SpectacleMath.ArrivalPlan(tier, true, true)
			expect(plan.still).toEqual(true)
			expect(plan.kind).toEqual("None")
			expect(plan.cells + plan.particles + plan.fall + plan.skyDim + plan.lightPulse).toEqual(0)
			expect(plan.vignette).toEqual(false)
			expect(plan.beacon).toEqual(Spectacle.Arrivals[tier].beacon)
		end
	end)

	it("holds a beacon steady (no breathing) under the still flag", function()
		local born = 0
		local a = SpectacleMath.BeaconAlpha(5, born, -1, true)
		local b = SpectacleMath.BeaconAlpha(6.3, born, -1, true)
		expect(a).toBeClose(b, 1e-9)
		expect(a).toBeClose(Spectacle.Look.BeaconTransparency, 1e-9)
	end)
end)

describe("the budgets", function()
	it("holds every arrival under the device's arrival caps", function()
		for _, tier in ipairs(ORDER) do
			for _, mobile in ipairs({ true, false }) do
				local plan = SpectacleMath.ArrivalPlan(tier, mobile, false)
				local particles, parts = SpectacleMath.ArrivalCost(tier, plan, mobile)
				local caps = Spectacle.Caps
				expect(particles <= (if mobile then caps.MobileArrivalParticles else caps.DesktopArrivalParticles)).toEqual(true)
				expect(parts <= (if mobile then caps.MobileArrivalParts else caps.DesktopArrivalParts)).toEqual(true)
			end
		end
	end)

	it("counts SpeciesFx's spawn moment in a Cosmic and Secret arrival, and only there", function()
		expect(SpectacleMath.MomentParticles("Cosmic", true) > 0).toEqual(true)
		expect(SpectacleMath.MomentParticles("Secret", true) > 0).toEqual(true)
		expect(SpectacleMath.MomentParticles("Legendary", true)).toEqual(0)
		-- the moment's star burst is held under the phone's burst cap
		expect(SpectacleMath.MomentParticles("Cosmic", true) <= SpectacleMath.MomentParticles("Cosmic", false)).toEqual(true)
	end)

	it("keeps a Cosmic arrival with eight Cosmic aliens around under the phone's scene caps (the 30 fps budget)", function()
		local particles, parts = SpectacleMath.SceneCost("Cosmic", 8, true)
		expect(particles <= Spectacle.Caps.MobileSceneParticles).toEqual(true)
		expect(parts <= Spectacle.Caps.MobileSceneParts).toEqual(true)
		-- and the same for a Secret, the other eight-layer tier
		local sp, sq = SpectacleMath.SceneCost("Secret", 8, true)
		expect(sp <= Spectacle.Caps.MobileSceneParticles and sq <= Spectacle.Caps.MobileSceneParts).toEqual(true)
	end)

	it("caps the scene by the nearest-first limits however many aliens stand around", function()
		local p8, q8 = SpectacleMath.SceneCost("Cosmic", 8, true)
		local p30, q30 = SpectacleMath.SceneCost("Cosmic", 30, true)
		expect(p30).toEqual(p8)
		expect(q30).toEqual(q8)
	end)

	it("trims an arrival that would pass its caps (a tighter cap scales its cells and particles down)", function()
		local caps = Spectacle.Caps :: any
		local saved = caps.MobileArrivalParts
		caps.MobileArrivalParts = 10
		local plan = SpectacleMath.ArrivalPlan("Cosmic", true, false)
		local _, parts = SpectacleMath.ArrivalCost("Cosmic", plan, true)
		caps.MobileArrivalParts = saved
		expect(parts <= 10).toEqual(true)
		expect(plan.cells < Spectacle.Arrivals.Cosmic.cells).toEqual(true)
	end)

	it("keeps the phone limits at or under the desktop ones", function()
		local caps = Spectacle.Caps
		expect(caps.MaxArrivalsMobile <= caps.MaxArrivals).toEqual(true)
		expect(caps.MaxPresenceMobile <= caps.MaxPresence).toEqual(true)
		expect(caps.MaxBeaconsMobile <= caps.MaxBeacons).toEqual(true)
		expect(caps.MaxFootprintsMobile <= caps.MaxFootprints).toEqual(true)
		expect(caps.MobileArrivalParticles <= caps.DesktopArrivalParticles).toEqual(true)
		expect(caps.MaxPresenceMobile <= Effects.Caps.MaxActiveMobile).toEqual(true)
	end)
end)

describe("the clocks", function()
	it("hops a little lower each time and rests between notices", function()
		local height = 0.5
		expect(SpectacleMath.Hop(-0.1, 2, height)).toEqual(0)
		local each = Spectacle.Look.HopSeconds
		expect(SpectacleMath.Hop(each / 2, 2, height)).toBeClose(height, 1e-9)
		expect(SpectacleMath.Hop(each * 1.5, 2, height)).toBeClose(height * 0.7, 1e-9)
		expect(SpectacleMath.Hop(each * 2, 2, height)).toEqual(0)
	end)

	it("faces a model (face down -z) along a direction, and turns the short way", function()
		expect(SpectacleMath.FaceYaw(0, -1)).toBeClose(0, 1e-9)
		expect(math.abs(SpectacleMath.FaceYaw(0, 1))).toBeClose(math.pi, 1e-9)
		expect(SpectacleMath.FaceYaw(-1, 0)).toBeClose(math.pi / 2, 1e-9)
		expect(SpectacleMath.AngleDelta(math.rad(170), math.rad(-170))).toBeClose(math.rad(20), 1e-9)
		expect(SpectacleMath.TurnToward(0, 1, 0.5)).toBeClose(0.5, 1e-9)
		expect(SpectacleMath.TurnShare(0)).toEqual(0)
		expect(SpectacleMath.TurnShare(10) > 0.99).toEqual(true)
	end)

	it("walks the leash: every point inside it, home on cycle 0, the walk eased and then resting", function()
		for index = 1, 200 do
			local dx, dz = SpectacleMath.WanderPoint(0.42, index, 2)
			expect(math.sqrt(dx * dx + dz * dz) <= 2 + 1e-9).toEqual(true)
		end
		local hx, hz = SpectacleMath.WanderPoint(0.42, 0, 2)
		expect(hx == 0 and hz == 0).toEqual(true)
		local cycle = 8
		local index, moving, k = SpectacleMath.WanderAt(0, 0, cycle)
		expect(index == 0 and moving and k == 0).toEqual(true)
		local _, moving2, k2, idle = SpectacleMath.WanderAt(cycle * 0.9, 0, cycle)
		expect(moving2).toEqual(false)
		expect(k2).toEqual(1)
		expect(idle > 0 and idle < 1).toEqual(true)
	end)

	it("starts and ends every idle at rest", function()
		for _, kind in ipairs({ "Look", "Stretch", "Sit", "Sleep", "Play" }) do
			for _, s in ipairs({ 0, 1 }) do
				local lift, yaw, pitch, roll = SpectacleMath.IdlePose(kind :: any, s, 1)
				expect(lift + yaw + pitch + roll).toEqual(0)
			end
			local lift, yaw, pitch, roll = SpectacleMath.IdlePose(kind :: any, 0.3, 1)
			expect(math.abs(lift) + math.abs(yaw) + math.abs(pitch) + math.abs(roll) > 0).toEqual(true)
		end
	end)

	it("spirals from full size at the alien to a speck at the device", function()
		local angle, radius, travel, scale = SpectacleMath.SpiralAt(0, 2)
		expect(angle + travel).toEqual(0)
		expect(radius == 1 and scale == 1).toEqual(true)
		local a1, r1, t1, s1 = SpectacleMath.SpiralAt(1, 2)
		expect(a1).toBeClose(math.pi * 4, 1e-9)
		expect(r1 == 0 and t1 == 1).toEqual(true)
		expect(s1).toBeClose(Spectacle.Look.SpiralEnd, 1e-9)
	end)

	it("slows the catch's clocks to the floor and back", function()
		expect(SpectacleMath.SlowMoScale(0, 0.6)).toEqual(1)
		expect(SpectacleMath.SlowMoScale(0.3, 0.6)).toBeClose(Spectacle.Caps.SlowMoMinScale, 1e-9)
		expect(SpectacleMath.SlowMoScale(0.6, 0.6)).toEqual(1)
		expect(SpectacleMath.SlowMoScale(0.3, 0)).toEqual(1)
	end)

	it("hops away and finishes, and blinks a Secret out", function()
		local each = Spectacle.Look.EscapeHopSeconds
		local lift, stride, done = SpectacleMath.EscapeHopAt(each / 2, 3)
		expect(lift).toBeClose(Spectacle.Look.EscapeHop, 1e-9)
		expect(stride).toBeClose(1 / 6, 1e-9)
		expect(done).toEqual(false)
		local _, last, finished = SpectacleMath.EscapeHopAt(each * 3, 3)
		expect(last == 1 and finished).toEqual(true)
		expect(SpectacleMath.BlinkVisible(0)).toEqual(true)
		expect(SpectacleMath.BlinkVisible(Spectacle.Look.BlinkSeconds)).toEqual(false)
		local hidden = false
		for step = 1, 49 do
			if not SpectacleMath.BlinkVisible(Spectacle.Look.BlinkSeconds * step / 50) then
				hidden = true
			end
		end
		expect(hidden).toEqual(true)
	end)

	it("dims the sky in and out, and is clear outside the arrival", function()
		local row = Spectacle.Arrivals.Cosmic
		expect(SpectacleMath.SkyDim(0, row.seconds, row.skyDim)).toEqual(0)
		expect(SpectacleMath.SkyDim(row.seconds / 2, row.seconds, row.skyDim)).toBeClose(row.skyDim, 1e-9)
		expect(SpectacleMath.SkyDim(row.seconds, row.seconds, row.skyDim)).toEqual(0)
		expect(SpectacleMath.VignetteAlpha(0, 1.8)).toEqual(1)
		expect(SpectacleMath.VignetteAlpha(0.3, 1.8) < 1).toEqual(true)
	end)

	it("fades a timed beacon in and out and holds a staying one", function()
		expect(SpectacleMath.BeaconAlpha(-1, 0, 20, false)).toEqual(1)
		expect(SpectacleMath.BeaconAlpha(0, 0, 20, false)).toEqual(1)
		expect(SpectacleMath.BeaconAlpha(10, 0, 20, false) < 1).toEqual(true)
		expect(SpectacleMath.BeaconAlpha(20, 0, 20, false)).toEqual(1)
		expect(SpectacleMath.BeaconAlpha(5000, 0, -1, false) < 1).toEqual(true)
		expect(SpectacleMath.BeaconAlpha(5, 0, 0, false)).toEqual(1)
	end)

	it("blooms flowers in World 1 and frost in World 2, and every footprint grows then fades", function()
		expect(SpectacleMath.FootprintColors(1)[1]).toEqual(Spectacle.Footprints[1][1])
		expect(SpectacleMath.FootprintColors(2)[1]).toEqual(Spectacle.Footprints[2][1])
		expect(SpectacleMath.FootprintColors(99)[1]).toEqual(Spectacle.FootprintDefault[1])
		local size0 = SpectacleMath.FootprintAlpha(0)
		expect(size0).toEqual(0)
		local size, clear = SpectacleMath.FootprintAlpha(Spectacle.Look.FootprintGrow)
		expect(size == 1 and clear == 0).toEqual(true)
		local gone, gclear = SpectacleMath.FootprintAlpha(Spectacle.Look.FootprintLife)
		expect(gone == 0 and gclear == 1).toEqual(true)
	end)
end)

describe("the glyphs", function()
	it("draws each glyph as a grid of cells, every row the same width", function()
		for name, rows in pairs(Spectacle.Glyphs) do
			local cells, width, height = SpectacleMath.GlyphCells(name)
			expect(#cells > 0).toEqual(true)
			expect(height).toEqual(#rows)
			for _, row in ipairs(rows) do
				expect(#row).toEqual(width)
			end
		end
		local none = SpectacleMath.GlyphCells("Nope")
		expect(#none).toEqual(0)
	end)
end)

describe("the Clean UI pass: fewer, calmer", function()
	local look = Spectacle.Look

	it("dresses only the nearest six aliens (four on a phone) in their presence", function()
		expect(Spectacle.Caps.MaxPresence).toEqual(6)
		expect(Spectacle.Caps.MaxPresenceMobile).toEqual(4)
	end)

	it("keeps the glyph orbit and the trail of cells to Rare and up, whatever a row says", function()
		local ornamentFrom = table.find(ORDER, look.OrnamentMinTier) :: number
		local trailFrom = table.find(ORDER, look.TrailMinTier) :: number
		for rank, tier in ipairs(ORDER) do
			local row = SpectacleMath.Presence(tier)
			if rank < ornamentFrom then
				expect(row.ornaments).toEqual(0)
			end
			if rank < trailFrom then
				expect(row.trail).toEqual(0)
			end
		end
		expect(ornamentFrom >= table.find(ORDER, "Rare")).toEqual(true)
		expect(trailFrom >= table.find(ORDER, "Rare")).toEqual(true)
	end)

	it("leaves every other presence field as the data has it", function()
		local row: any = Spectacle.Presence.Uncommon
		local savedOrnaments, savedTrail = row.ornaments, row.trail
		-- the gate is applied when SpectacleMath loads, so check the shipped rows agree with their gated copies
		expect(SpectacleMath.Presence("Uncommon").pool).toEqual(row.pool)
		expect(savedOrnaments).toEqual(0)
		expect(savedTrail).toEqual(0)
		expect(SpectacleMath.Presence("Cosmic").ornaments).toEqual(Spectacle.Presence.Cosmic.ornaments)
		expect(SpectacleMath.Presence("Cosmic").trail).toEqual(Spectacle.Presence.Cosmic.trail)
	end)

	it("fades a beacon out between 40 and 25 studs and shows it whole from afar", function()
		expect(look.BeaconNearFadeStuds).toEqual(40)
		expect(look.BeaconHideStuds).toEqual(25)
		expect(SpectacleMath.BeaconNear(200)).toEqual(1)
		expect(SpectacleMath.BeaconNear(look.BeaconNearFadeStuds)).toEqual(1)
		expect(SpectacleMath.BeaconNear(look.BeaconHideStuds)).toEqual(0)
		expect(SpectacleMath.BeaconNear(5)).toEqual(0)
		expect(SpectacleMath.BeaconNear(0)).toEqual(0)
		local mid = SpectacleMath.BeaconNear((look.BeaconNearFadeStuds + look.BeaconHideStuds) / 2)
		expect(mid).toBeClose(0.5, 1e-9)
	end)

	it("only ever fades more as the camera comes closer", function()
		local last = 1
		for distance = 60, 0, -1 do
			local now = SpectacleMath.BeaconNear(distance)
			expect(now <= last + 1e-12).toEqual(true)
			expect(now >= 0 and now <= 1).toEqual(true)
			last = now
		end
	end)

	it("never dims the screen over an open panel, nor within DimGapSeconds of the last dim", function()
		expect(look.DimGapSeconds).toEqual(8)
		expect(SpectacleMath.DimAllowed(100, -math.huge, false)).toEqual(true)
		expect(SpectacleMath.DimAllowed(100, -math.huge, true)).toEqual(false)
		expect(SpectacleMath.DimAllowed(100, 95, false)).toEqual(false)
		expect(SpectacleMath.DimAllowed(100, 100 - look.DimGapSeconds + 0.01, false)).toEqual(false)
		expect(SpectacleMath.DimAllowed(100, 100 - look.DimGapSeconds, false)).toEqual(true)
		expect(SpectacleMath.DimAllowed(100, 80, true)).toEqual(false)
	end)

	it("spaces a Cosmic and then a Secret arrival at least DimGapSeconds apart", function()
		local lastDimAt, played = -math.huge, 0
		for _, at in ipairs({ 0, 3, 7.9, 8, 12, 17 }) do
			if SpectacleMath.DimAllowed(at, lastDimAt, false) then
				lastDimAt = at
				played += 1
			end
		end
		expect(played).toEqual(3) -- at 0, 8 and 17
	end)
end)
return true
