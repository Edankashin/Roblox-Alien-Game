--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Bucket = require(Shared.TokenBucket)
local Data = require(Shared.data.Visiting)
local F = require(script.Parent.Fixtures)

local function fresh()
	return Bucket.New(Data.LookupBurst, Data.LookupRefillSeconds, F.zero)
end

-- Takes until the bucket refuses (at one instant) and says how many it gave.
local function drain(bucket, now)
	local taken = F.zero
	while Bucket.Take(bucket, now) do
		taken += F.one
		assert(taken <= Data.LookupBurst, "a bucket gave more than its capacity")
	end
	return taken
end

describe("TokenBucket (Visiting's lookup budget)", function()
	it("a new bucket gives LookupBurst tokens at once and then refuses", function()
		expect(drain(fresh(), F.zero)).toEqual(Data.LookupBurst)
	end)
	it("one token comes back each LookupRefillSeconds, not sooner", function()
		local bucket = fresh()
		drain(bucket, F.zero)
		expect(Bucket.Take(bucket, Data.LookupRefillSeconds - F.one)).toEqual(false)
		expect(Bucket.Take(bucket, Data.LookupRefillSeconds)).toEqual(true)
		expect(Bucket.Take(bucket, Data.LookupRefillSeconds)).toEqual(false)
	end)
	it("a steady stream at the refill rate is never refused", function()
		local bucket = fresh()
		drain(bucket, F.zero)
		for step = F.one, Data.LookupBurst do
			expect(Bucket.Take(bucket, step * Data.LookupRefillSeconds)).toEqual(true)
		end
	end)
	it("idle time banks no more than the burst", function()
		local bucket = fresh()
		drain(bucket, F.zero)
		local later = Data.LookupRefillSeconds * Data.LookupBurst * F.two * F.two
		expect(drain(bucket, later)).toEqual(Data.LookupBurst)
	end)
	it("a clock that goes backwards refills nothing", function()
		local bucket = fresh()
		local later = Data.LookupRefillSeconds * Data.LookupBurst
		drain(bucket, later)
		expect(Bucket.Take(bucket, F.zero)).toEqual(false)
	end)
end)
return true
