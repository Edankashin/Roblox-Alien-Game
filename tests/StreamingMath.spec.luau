--!strict
-- Shared.StreamingMath and the numbers in data/Streaming: the live Workspace against the table, the cinematic's far shot positions,
-- and the rules the table keeps (the minimum radius covers the spawn ring, the target stops at the world's far corner, every
-- container the client scans by name is Persistent). default.project.json agreeing with the table is tools/lint_data.py's job.
local Shared = game:GetService("ReplicatedStorage").Shared
local StreamingMath = require(Shared.StreamingMath)
local Streaming = require(Shared.data.Streaming)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local WorldGen1 = require(Shared.data.WorldGen1)
local WorldGen2 = require(Shared.data.WorldGen2)

local want: StreamingMath.Want = { Enabled = true, MinRadius = 128, TargetRadius = 280, IntegrityMode = "PauseOutsideLoadedArea" }
local function live(change: { [string]: any }?): StreamingMath.Live
	local made: any = { enabled = true, minRadius = 128, targetRadius = 280, integrityMode = "PauseOutsideLoadedArea" }
	for key, value in pairs(change or {}) do
		made[key] = value
	end
	return made
end

describe("StreamingMath.Mismatch", function()
	it("is empty when the place matches", function()
		expect(#StreamingMath.Mismatch(live(), want)).toEqual(0)
	end)
	it("names each property that differs", function()
		expect(#StreamingMath.Mismatch(live({ enabled = false }), want)).toEqual(1)
		expect(#StreamingMath.Mismatch(live({ minRadius = 64 }), want)).toEqual(1)
		expect(#StreamingMath.Mismatch(live({ targetRadius = 1024 }), want)).toEqual(1)
		expect(#StreamingMath.Mismatch(live({ integrityMode = "Default" }), want)).toEqual(1)
		expect(#StreamingMath.Mismatch(live({ minRadius = 64, targetRadius = 1024, integrityMode = "Default" }), want)).toEqual(3)
	end)
	it("reads only the switch when the world does not stream", function()
		local off: StreamingMath.Want = { Enabled = false, MinRadius = 128, TargetRadius = 280, IntegrityMode = "PauseOutsideLoadedArea" }
		expect(#StreamingMath.Mismatch(live({ enabled = false, minRadius = 64, targetRadius = 1024 }), off)).toEqual(0)
		expect(#StreamingMath.Mismatch(live({ enabled = true }), off)).toEqual(1)
	end)
end)

describe("StreamingMath.FarPoints", function()
	local origin = { x = 0, y = 10, z = 0 }
	it("keeps only the points past the distance, in order", function()
		local points = { { x = 10, y = 10, z = 0 }, { x = 177, y = 10, z = 0 }, { x = 0, y = 10, z = -200 } }
		local far = StreamingMath.FarPoints(points, origin, 128, 3)
		expect(#far).toEqual(2)
		expect(far[1].x).toEqual(177)
		expect(far[2].z).toEqual(-200)
	end)
	it("treats the distance as strict and measures in three dimensions", function()
		expect(#StreamingMath.FarPoints({ { x = 128, y = 10, z = 0 } }, origin, 128, 3)).toEqual(0)
		expect(#StreamingMath.FarPoints({ { x = 0, y = 139, z = 0 } }, origin, 128, 3)).toEqual(1)
	end)
	it("asks once for a repeated spot and stops at the limit", function()
		local spot = { x = 200, y = 10, z = 0 }
		expect(#StreamingMath.FarPoints({ spot, { x = 200, y = 10, z = 0 }, spot }, origin, 128, 3)).toEqual(1)
		local many = { { x = 200, y = 0, z = 0 }, { x = 201, y = 0, z = 0 }, { x = 202, y = 0, z = 0 }, { x = 203, y = 0, z = 0 } }
		expect(#StreamingMath.FarPoints(many, origin, 128, 3)).toEqual(3)
		expect(#StreamingMath.FarPoints(many, origin, 128, 0)).toEqual(0)
	end)
end)

describe("data/Streaming", function()
	it("covers the spawn ring with the minimum radius", function()
		expect(Streaming.MinRadius >= Config.SpawnRadius).toEqual(true)
	end)
	it("keeps the target between the minimum and the farthest corner of every streamed world", function()
		expect(Streaming.TargetRadius >= Streaming.MinRadius).toEqual(true)
		for _, gen in ipairs({ WorldGen1, WorldGen2 }) do
			local half = gen.Count * gen.Cell / 2
			expect(Streaming.TargetRadius <= math.ceil(half * math.sqrt(2))).toEqual(true)
		end
	end)
	it("names every built world, and not the home planet", function()
		for id, world in pairs(Worlds) do
			if type(id) == "number" and type(world) == "table" and (world :: any).built ~= false then
				expect(type(Streaming.Enabled[id])).toEqual("boolean")
			end
		end
		expect(Streaming.Enabled[0]).toEqual(false)
		expect(Streaming.Enabled[1]).toEqual(true)
	end)
	it("lists the containers once each", function()
		local seen: { [string]: boolean } = {}
		for _, name in ipairs(Streaming.Persistent) do
			expect(seen[name]).toEqual(nil)
			seen[name] = true
		end
		for _, name in ipairs({ "Wild", "Materials", "Heaters", "Sightings" }) do
			expect(seen[name]).toEqual(true)
		end
	end)
	it("asks for a bounded number of cinematic streams", function()
		expect(Streaming.CinematicRequests >= 0 and Streaming.CinematicRequests <= 6).toEqual(true)
		expect(Streaming.RequestTimeoutSeconds > 0).toEqual(true)
	end)
end)

return true
