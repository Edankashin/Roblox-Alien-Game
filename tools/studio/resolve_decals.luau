--!strict
-- Resolve the Image id behind each uploaded Decal, through Studio. Run it in Studio's command bar (View >
-- Command Bar, paste the whole file, press Enter) or through the Studio MCP execute_luau tool, in Edit mode on
-- the server datamodel. Studio must be signed in as the user (or a member of the group) that owns the Decals.
--
-- Why: an ImageLabel, a ParticleEmitter and a SurfaceAppearance draw the Image asset behind a Decal, not the Decal.
-- The anonymous assetdelivery.roblox.com route answers 401 now (Mac jobs 19 and 40) and the Open Cloud route
-- `upload_assets.py --resolve-images` tries first needs the scope legacy-asset:manage on the key. This snippet is the
-- fallback while the key lacks it: game:GetObjects("rbxassetid://<decalId>") gives the Decal and its Texture holds the Image id.
--
-- 1. python3 -I tools/upload_assets.py --emit-decals-luau | pbcopy     (the Decal ids that have no Image id yet;
--                                                                       icons and textures together)
-- 2. Replace the table between the PASTE markers below with the output, then run this file.
-- 3. Save the Output to a file (select all in the Output window, copy, paste into a text file; the MCP result
--    works the same). Timestamps and the "- Edit" suffix Studio adds to each line are fine.
-- 4. python3 -I tools/upload_assets.py --from-studio <that file>        (fills imageId in asset_ids.json)
--
-- Output, one line per id:
--   {"decal": 110715054641399, "image": 121353948620197}      printed with print
--   FAIL 110715054641399: <why>                                  printed with warn; the id is skipped
-- and one summary line `resolve_decals: N ok, M failed, K total`. --from-studio reads only the JSON lines.
-- A Decal still in moderation fails here too ("not approved" or an HTTP error): run it again later.
-- The script changes nothing in the place: the loaded Decals are destroyed after each read.

-- BEGIN PASTE: output of `python3 -I tools/upload_assets.py --emit-decals-luau`
local DECAL_IDS: { number } = {}
-- END PASTE

-- The id out of a Decal's Texture, either rbxassetid://123 or http://www.roblox.com/asset/?id=123.
local function imageIdOf(texture: string): number?
	local digits = texture:match("rbxassetid://(%d+)") or texture:match("[%?&]id=(%d+)")
	if not digits then
		return nil
	end
	local id = tonumber(digits)
	if id == nil or id <= 0 then
		return nil
	end
	return id
end

-- Loads the Decal and returns its Image id, or nil and the reason. Everything GetObjects returned is destroyed.
local function resolve(decalId: number): (number?, string)
	local ok, loaded = pcall(function(): { Instance }
		return game:GetObjects("rbxassetid://" .. tostring(decalId))
	end)
	if not ok then
		return nil, tostring(loaded)
	end
	local objects = loaded :: { Instance }
	local texture: string? = nil
	for _, object in objects do
		if object:IsA("Decal") then
			texture = object.Texture
		else
			local inner = object:FindFirstChildWhichIsA("Decal", true)
			if inner then
				texture = inner.Texture
			end
		end
		if texture ~= nil then
			break
		end
	end
	for _, object in objects do
		object:Destroy()
	end
	if texture == nil then
		return nil, "the asset holds no Decal (is it an Image already? then use its id as it is)"
	end
	local imageId = imageIdOf(texture)
	if imageId == nil then
		return nil, ("the Decal's Texture holds no asset id: %q"):format(texture)
	end
	if imageId == decalId then
		return nil, "the Decal's Texture points at its own id, not at an Image"
	end
	return imageId, ""
end

local function main()
	if #DECAL_IDS == 0 then
		print("resolve_decals: DECAL_IDS is empty; paste the output of `python3 -I tools/upload_assets.py --emit-decals-luau`")
		return
	end
	local resolved = 0
	local failed = 0
	for _, decalId in DECAL_IDS do
		local imageId, reason = resolve(decalId)
		if imageId then
			resolved += 1
			print(('{"decal": %d, "image": %d}'):format(decalId, imageId))
		else
			failed += 1
			warn(("FAIL %d: %s"):format(decalId, reason))
		end
	end
	print(("resolve_decals: %d ok, %d failed, %d total"):format(resolved, failed, #DECAL_IDS))
end

main()
