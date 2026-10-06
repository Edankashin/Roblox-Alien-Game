--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Capture = require(Shared.Capture)
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local Variants = require(Shared.data.CatchVariants)
local F = require(script.Parent.Fixtures)
local tier = Tiers.Tiers.Common
local period = F.one / tier.tickerSpeed
local center = Config.CaptureZoneCenterMin

describe("Capture", function()
	for name, row in pairs({
		zero = { F.zero, F.zero }, quarter = { period * F.quarter, F.half },
		half = { period * F.half, F.one }, full = { period, F.zero },
	}) do
		it("triangle wave at " .. name .. " period", function()
			expect(Capture.position(row[F.one], tier.tickerSpeed)).toBeClose(row[F.two], F.tolerance)
		end)
	end
	it("negative time and zero speed stay at zero", function()
		expect(Capture.position(-F.tick, tier.tickerSpeed)).toEqual(F.zero)
		expect(Capture.position(period, F.zero)).toEqual(F.zero)
	end)
	for _, sign in ipairs({ -F.one, F.one }) do
		it("inclusive Perfect edge " .. tostring(sign), function()
			expect(Capture.outcome(center + sign * tier.perfectZone / F.two, center, tier.goodZone, tier.perfectZone)).toEqual("Perfect")
		end)
		it("inclusive Good edge " .. tostring(sign), function()
			expect(Capture.outcome(center + sign * tier.goodZone / F.two, center, tier.goodZone, tier.perfectZone)).toEqual("Good")
		end)
		it("near miss and outside margin " .. tostring(sign), function()
			local edge = center + sign * tier.goodZone / F.two
			expect(Capture.isNearMiss(edge, center, tier.goodZone, Config.CaptureNearMissWidth)).toEqual(false)
			local near = edge + sign * Config.CaptureNearMissWidth * F.half
			expect(Capture.outcome(near, center, tier.goodZone, tier.perfectZone)).toEqual("Miss")
			expect(Capture.isNearMiss(near, center, tier.goodZone, Config.CaptureNearMissWidth)).toEqual(true)
			expect(Capture.isNearMiss(edge + sign * Config.CaptureNearMissWidth * F.two, center, tier.goodZone, Config.CaptureNearMissWidth)).toEqual(false)
		end)
	end
	local variant = Variants.Rows.Chase
	it("zero amplitude returns base", function()
		expect(Capture.driftCenter(period, center, F.zero, variant.driftPeriodSeconds, F.zero, variant.driftClampMin, variant.driftClampMax)).toEqual(center)
	end)
	it("zero phase and elapsed return base", function()
		expect(Capture.driftCenter(F.zero, center, variant.driftAmplitude, variant.driftPeriodSeconds, F.zero, variant.driftClampMin, variant.driftClampMax)).toEqual(center)
	end)
	it("drift clamps at both limits", function()
		local quarter = variant.driftPeriodSeconds * F.quarter
		expect(Capture.driftCenter(quarter, variant.driftClampMax, variant.driftAmplitude, variant.driftPeriodSeconds, F.zero, variant.driftClampMin, variant.driftClampMax)).toEqual(variant.driftClampMax)
		expect(Capture.driftCenter(quarter + variant.driftPeriodSeconds * F.half, variant.driftClampMin, variant.driftAmplitude, variant.driftPeriodSeconds, F.zero, variant.driftClampMin, variant.driftClampMax)).toEqual(variant.driftClampMin)
	end)
end)
return true
