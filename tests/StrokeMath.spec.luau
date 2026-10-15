--!strict
-- Shared.StrokeMath: a UIStroke's thickness follows the screen height inside a clamp, and is exactly the Theme.Stroke pixels at
-- the reference height (the look the UI Playbook gives: 2.5 px text, 3 px button, 4 px panel at 1080). The params are the
-- Theme.Stroke ones (ReferenceHeight, MinScale, MaxScale); Theme itself needs the Roblox runtime, so tools/tests/test_stroke_theme.py
-- reads them out of src/shared/Theme.luau and checks they are these.
local Shared = game:GetService("ReplicatedStorage").Shared
local StrokeMath = require(Shared.StrokeMath)

local REFERENCE = 1080
local params: StrokeMath.Params = { referenceHeight = REFERENCE, minScale = 0.8, maxScale = 1.2 }
local TEXT, BUTTON, PANEL = 2.5, 3, 4
local PHONE, TABLET, DESKTOP, MONITOR, FOUR_K = 375, 768, 1080, 1440, 2160
local TOLERANCE = 1e-9

describe("StrokeMath.Scale", function()
	it("is 1 at the reference height, so the Playbook's pixels hold there", function()
		expect(StrokeMath.Scale(REFERENCE, params)).toEqual(1)
		expect(StrokeMath.Thickness(TEXT, REFERENCE, params)).toEqual(TEXT)
		expect(StrokeMath.Thickness(BUTTON, REFERENCE, params)).toEqual(BUTTON)
		expect(StrokeMath.Thickness(PANEL, REFERENCE, params)).toEqual(PANEL)
	end)
	it("follows the height between the clamps", function()
		local height = 1000 -- 0.926 of the reference: inside [0.8, 1.2]
		expect(StrokeMath.Scale(height, params)).toBeClose(height / REFERENCE, TOLERANCE)
		expect(StrokeMath.Thickness(PANEL, height, params)).toBeClose(PANEL * height / REFERENCE, TOLERANCE)
	end)
	it("holds a phone and a tablet window at the smallest scale", function()
		expect(StrokeMath.Scale(PHONE, params)).toEqual(params.minScale)
		expect(StrokeMath.Scale(TABLET, params)).toEqual(params.minScale)
		expect(StrokeMath.Thickness(TEXT, PHONE, params)).toBeClose(TEXT * params.minScale, TOLERANCE)
	end)
	it("holds a big monitor and a 4K window at the largest scale", function()
		expect(StrokeMath.Scale(MONITOR, params)).toEqual(params.maxScale)
		expect(StrokeMath.Scale(FOUR_K, params)).toEqual(params.maxScale)
		expect(StrokeMath.Thickness(PANEL, FOUR_K, params)).toBeClose(PANEL * params.maxScale, TOLERANCE)
	end)
	it("keeps text outlines at 2 to 3 px from a phone to a 4K window (the Playbook's range)", function()
		for _, height in ipairs({ PHONE, TABLET, DESKTOP, MONITOR, FOUR_K }) do
			local px = StrokeMath.Thickness(TEXT, height, params)
			assert(px >= 2 - TOLERANCE and px <= 3 + TOLERANCE, ("%d px tall gives a %.3f px text stroke"):format(height, px))
		end
	end)
	it("never shrinks as the window grows", function()
		local previous = 0
		for _, height in ipairs({ PHONE, TABLET, DESKTOP, MONITOR, FOUR_K }) do
			local px = StrokeMath.Thickness(BUTTON, height, params)
			assert(px >= previous, ("%d px tall is thinner than a smaller window"):format(height))
			previous = px
		end
	end)
	it("is the reference look while the height is unknown (no camera yet, or 0)", function()
		expect(StrokeMath.Scale(0, params)).toEqual(1)
		expect(StrokeMath.Scale(-PHONE, params)).toEqual(1)
		expect(StrokeMath.Thickness(PANEL, 0, params)).toEqual(PANEL)
	end)
end)
return true
