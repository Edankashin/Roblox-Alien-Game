--!strict
-- Species display names (docs/vault/01-game-design/Species-Names.md, decision B26). Ids never change; only `name` does, and
-- the Reveal card, the nameplates and the Codex are laid out for a short word, so every name is non-empty, at most ten
-- characters (the note's "under 11") and unique, ignoring case and punctuation ("Ra-dish" and "Radish" would be one name).
local Shared = game:GetService("ReplicatedStorage").Shared
local Species = require(Shared.data.Species)

local MAX_LENGTH = 10

describe("Species names", function()
	it("every species name is non-empty, under 11 characters and unique", function()
		local seen: { [string]: string } = {}
		for _, def in ipairs(Species.List) do
			assert(#def.name > 0, def.id .. " has an empty name")
			assert(#def.name <= MAX_LENGTH, def.id .. " is called " .. def.name .. ", " .. #def.name .. " characters")
			local key = def.name:lower():gsub("[^%a]", "")
			assert(seen[key] == nil, def.id .. " and " .. tostring(seen[key]) .. " share the name " .. def.name)
			seen[key] = def.id
		end
		expect(next(seen) ~= nil).toEqual(true)
	end)
end)
return true
