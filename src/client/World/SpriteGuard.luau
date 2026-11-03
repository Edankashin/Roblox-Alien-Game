--!strict
-- StarterPlayerScripts.Client.World.SpriteGuard: a particle texture that never draws as a white square. Every uploaded
-- sprite id goes through Apply, which sets the texture and checks the id once with ContentProvider:PreloadAsync in the
-- background; an id Roblox cannot serve (Mac jobs 70 to 77, 2026-11-01: 22 of 34 approved Image ids failed to fetch, so
-- every emitter on them painted a solid square and washed the ground white under the Cosmics) is swapped, on every
-- emitter that holds it, for Roblox's own soft sprite, which is always present. A later Apply of a known-bad id takes
-- the soft sprite at once and reports false so the caller skips its flipbook settings (a sheet makes no sense on it).
-- The client only draws; nothing here decides anything.

local ContentProvider = game:GetService("ContentProvider")

local SOFT = "rbxasset://textures/particles/sparkles_main.dds" -- Roblox's default emitter sprite: soft, round, never missing

local SpriteGuard = {}

local failed: { [number]: boolean } = {}
local checked: { [number]: boolean } = {}
local guarded: { [ParticleEmitter]: number } = setmetatable({}, { __mode = "k" }) :: any
local pending: { number } = {}
local running = false

local function soften(emitter: ParticleEmitter)
	emitter.Texture = SOFT
	emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.None
end

-- Checks every pending id (more can arrive while a batch runs), then softens the emitters on the ones that failed.
local function run()
	running = true
	while #pending > 0 do
		local batch = pending
		pending = {}
		local urls: { string } = {}
		for _, id in ipairs(batch) do
			table.insert(urls, "rbxassetid://" .. tostring(id))
		end
		pcall(function()
			ContentProvider:PreloadAsync(urls, function(url: string, status: Enum.AssetFetchStatus)
				if status == Enum.AssetFetchStatus.Failure then
					local id = tonumber(string.match(url, "%d+") or "")
					if id then
						failed[id] = true
					end
				end
			end)
		end)
		for emitter, id in pairs(guarded) do
			if failed[id] and emitter.Parent ~= nil then
				soften(emitter)
			end
		end
	end
	running = false
end

-- Sets `emitter` to draw the uploaded sprite `id` (or the soft sprite when the id is known to fail) and keeps the
-- emitter in view for the check. Returns true when the uploaded sprite is in place, false when the soft one is.
function SpriteGuard.Apply(emitter: ParticleEmitter, id: number): boolean
	if id <= 0 or failed[id] then
		soften(emitter)
		return false
	end
	emitter.Texture = "rbxassetid://" .. tostring(id)
	guarded[emitter] = id
	if not checked[id] then
		checked[id] = true
		table.insert(pending, id)
		if not running then
			task.spawn(run)
		end
	end
	return true
end

-- Whether an id is known to fail (the world cards ask before they trust a picture).
function SpriteGuard.Failed(id: number): boolean
	return failed[id] == true
end

return SpriteGuard
