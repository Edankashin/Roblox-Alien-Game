--!strict
-- Shared.ViewFit: a species thumbnail's camera distance (the whole model in the square view, from any side) and which cards of a
-- scrolling grid carry a live view (UI Playbook "Studio fixes after the block cells (2026-10-22)").
local Shared = game:GetService("ReplicatedStorage").Shared
local ViewFit = require(Shared.ViewFit)

-- The angle (radians) between the camera's line of sight to the box's centre and a ray to point (x, y, z), the camera at
-- `distance` along the unit direction (dx, dy, dz) from the centre.
local function angleTo(distance: number, dx: number, dy: number, dz: number, x: number, y: number, z: number): number
	local cx, cy, cz = dx * distance, dy * distance, dz * distance
	local ax, ay, az = -cx, -cy, -cz
	local bx, by, bz = x - cx, y - cy, z - cz
	local dot = ax * bx + ay * by + az * bz
	local la = math.sqrt(ax * ax + ay * ay + az * az)
	local lb = math.sqrt(bx * bx + by * by + bz * bz)
	return math.acos(math.clamp(dot / (la * lb), -1, 1))
end

describe("ViewFit.Distance", function()
	it("every corner of the box is inside the view, from the front, above and the front-left", function()
		local boxes = { { 2.47, 2.47, 2.47 }, { 1.8, 3.5, 1.2 }, { 4, 1, 1 }, { 0.5, 3.44, 2 } }
		local directions = { { 0, 0, 1 }, { 0, 1, 0 }, { -0.5, 0.35, 0.79 } }
		for _, box in ipairs(boxes) do
			for _, fov in ipairs({ 30, 40, 70 }) do
				local distance = ViewFit.Distance(box[1], box[2], box[3], fov, 1)
				for _, d in ipairs(directions) do
					local len = math.sqrt(d[1] * d[1] + d[2] * d[2] + d[3] * d[3])
					local dx, dy, dz = d[1] / len, d[2] / len, d[3] / len
					for _, sx in ipairs({ -1, 1 }) do
						for _, sy in ipairs({ -1, 1 }) do
							for _, sz in ipairs({ -1, 1 }) do
								local a = angleTo(distance, dx, dy, dz, sx * box[1] / 2, sy * box[2] / 2, sz * box[3] / 2)
								assert(a <= math.rad(fov) / 2 + 1e-9, "a corner is outside the view at fov " .. fov)
							end
						end
					end
				end
			end
		end
	end)
	it("is no farther than it needs: the bounding sphere touches the cone at margin 1", function()
		local distance = ViewFit.Distance(2, 2, 2, 40, 1)
		local radius = math.sqrt(12) / 2
		expect(math.abs(math.sin(math.rad(20)) * distance - radius) < 1e-9).toEqual(true)
	end)
	it("grows with the margin and shrinks with a wider field", function()
		assert(ViewFit.Distance(2, 3, 2, 40, 1.2) > ViewFit.Distance(2, 3, 2, 40, 1), "margin")
		assert(ViewFit.Distance(2, 3, 2, 70, 1) < ViewFit.Distance(2, 3, 2, 40, 1), "field")
	end)
	it("never puts the camera on the target for an empty box or a silly field", function()
		assert(ViewFit.Distance(0, 0, 0, 40, 1.1) >= 1, "empty box")
		assert(ViewFit.Distance(2, 2, 2, 0, 1) > 0, "zero field")
		assert(ViewFit.Distance(2, 2, 2, 400, 1) > 0, "field over 180")
	end)
end)

describe("ViewFit.Near", function()
	it("a card in the window, or within the margin above or below, is near; one past it is not", function()
		expect(ViewFit.Near(100, 180, 90, 300, 0)).toEqual(true)
		expect(ViewFit.Near(300, 380, 90, 300, 0)).toEqual(true) -- its top on the window's bottom edge
		expect(ViewFit.Near(320, 400, 90, 300, 80)).toEqual(true) -- the next row down
		expect(ViewFit.Near(420, 500, 90, 300, 80)).toEqual(false)
		expect(ViewFit.Near(-50, 30, 90, 300, 80)).toEqual(true) -- the row above
		expect(ViewFit.Near(-200, -100, 90, 300, 80)).toEqual(false)
	end)
end)
return true
