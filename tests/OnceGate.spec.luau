--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local OnceGate = require(Shared.OnceGate)

describe("OnceGate", function()
	it("lets a key through once and refuses it after", function()
		local gate = OnceGate.new()
		expect(gate.Take("toast")).toEqual(true)
		expect(gate.Take("toast")).toEqual(false)
		expect(gate.Take("toast")).toEqual(false)
	end)
	it("keeps keys apart", function()
		local gate = OnceGate.new()
		expect(gate.Take("lift")).toEqual(true)
		expect(gate.Take("toast")).toEqual(true)
		expect(gate.Take("lift")).toEqual(false)
	end)
	it("Clear lets every key through again", function()
		local gate = OnceGate.new()
		gate.Take("a")
		gate.Take("b")
		gate.Clear()
		expect(gate.Take("a")).toEqual(true)
		expect(gate.Take("b")).toEqual(true)
	end)
	it("two gates do not share keys", function()
		local first, second = OnceGate.new(), OnceGate.new()
		first.Take("lift")
		expect(second.Take("lift")).toEqual(true)
	end)
end)

-- The launch sequence's shape: the lift-done callback may be told twice (a cancel raises the same event as a finish);
-- the return, and the toast inside it, run once. A new launch gets a new gate.
describe("OnceGate (the launch return and its toast)", function()
	local function launch(liftDoneCalls)
		local gate = OnceGate.new()
		local returns, toasts = 0, 0
		for _ = 1, liftDoneCalls do
			if gate.Take("lift") then
				returns += 1
				if gate.Take("noPlaceToast") then
					toasts += 1
				end
			end
		end
		return returns, toasts
	end
	it("a lift that reports its end twice still returns and toasts once", function()
		local returns, toasts = launch(2)
		expect(returns).toEqual(1)
		expect(toasts).toEqual(1)
	end)
	it("a lift that reports once is unchanged", function()
		local returns, toasts = launch(1)
		expect(returns).toEqual(1)
		expect(toasts).toEqual(1)
	end)
	it("the next launch toasts again", function()
		local _, first = launch(2)
		local _, second = launch(2)
		expect(first + second).toEqual(2)
	end)
end)

-- The Sightings service's shape: the line is offered at every begin, a restart finishes with a run behind it (the gate
-- stays), the Warden going really ends it (the gate clears).
describe("OnceGate (the sighting line)", function()
	local function session(events)
		local gate = OnceGate.new()
		local printed = 0
		for _, event in ipairs(events) do
			if event == "begin" then
				if gate.Take("Gaiabloom crosses world 1 now, 74s left") then
					printed += 1
				end
			elseif event == "restart" then
				-- finish(t, true): nothing cleared
			elseif event == "end" then
				gate.Clear()
			end
		end
		return printed
	end
	it("five restarts of one sighting print one line", function()
		expect(session({ "begin", "restart", "begin", "restart", "begin", "restart", "begin", "restart", "begin" })).toEqual(1)
	end)
	it("the next sighting, after the Warden has gone, prints again", function()
		expect(session({ "begin", "end", "begin" })).toEqual(2)
	end)
	it("a restart that follows the end is a new sighting", function()
		expect(session({ "begin", "restart", "begin", "end", "begin", "restart", "begin" })).toEqual(2)
	end)
end)
return true
