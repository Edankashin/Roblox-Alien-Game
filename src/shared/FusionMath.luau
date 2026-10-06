--!strict
-- ReplicatedStorage.Shared.FusionMath: pure selection from copies already ranked best first.
-- Economy owns ranking, profile validation and all mutations; returned records are unchanged references.
local Types = require(script.Parent.types.Types)
local Fusion = require(script.Parent.data.Fusion)
local FusionMath = {}

function FusionMath.Select(copies: { Types.AlienRecord }, companions: { string }, cap: number): (Types.AlienRecord?, { Types.AlienRecord }, string?)
	if #copies < Fusion.DuplicatesPerLevel + 1 then
		return nil, {}, "NotEnough"
	end
	local kept: Types.AlienRecord? = nil
	for _, record in ipairs(copies) do
		if record.level < cap then
			kept = record
			break
		end
	end
	if not kept then
		return nil, {}, "MaxLevel"
	end
	local others: { Types.AlienRecord } = {}
	for _, record in ipairs(copies) do
		if record ~= kept and record.level <= kept.level then
			table.insert(others, record)
		end
	end
	if #others < Fusion.DuplicatesPerLevel then
		return nil, {}, "NotEnough"
	end
	local consumed: { Types.AlienRecord } = {}
	for pass = 1, 2 do
		for index = #others, 1, -1 do
			if #consumed >= Fusion.DuplicatesPerLevel then
				break
			end
			local record = others[index]
			local offCrew = record.habitat ~= nil or table.find(companions, record.uid) ~= nil
			local eligible = pass == 2 or (record.station == nil and not offCrew) or not Fusion.ConsumeRestingFirst
			if eligible and not table.find(consumed, record) then
				table.insert(consumed, record)
			end
		end
	end
	return kept, consumed, nil
end

return FusionMath
