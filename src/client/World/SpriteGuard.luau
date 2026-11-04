--!strict
-- StarterPlayerScripts.Client.World.SpriteGuard: a particle texture that never draws as a white square. Every uploaded
-- sprite id goes through Apply, which sets the texture and checks the id once in the background; an id Roblox cannot
-- serve is swapped, on every emitter that holds it, for Roblox's own soft sprite, which is always present. A later Apply
-- of a known-bad id takes the soft sprite at once and reports false so the caller skips its flipbook settings.
-- The check is a real ImageLabel (Mac job 78, 2026-11-01: `ContentProvider:PreloadAsync` on an id string answers
-- `Failure` for good images, so it cannot be the signal): a tiny, all-but-invisible label on a ScreenGui is rendered,
-- so the engine fetches its image; `IsLoaded` turning true clears the id, and only `GetAssetFetchStatus` reporting
-- `Failure` after the label has been on screen marks it bad. Time running out marks nothing: a slow phone keeps its
-- uploaded sprites. The client only draws; nothing here decides anything.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local SOFT = "rbxasset://textures/particles/sparkles_main.dds" -- Roblox's default emitter sprite: soft, round, never missing
local PROBE_SECONDS = 20 -- how long a probe label waits for IsLoaded or a Failure before it is taken down as good
local PROBE_TRANSPARENCY = 0.98 -- rendered (so fetched), unseen; a label at 1 is never rendered and never fetched

local SpriteGuard = {}

local failed: { [number]: boolean } = {}
local checked: { [number]: boolean } = {}
local guarded: { [ParticleEmitter]: number } = setmetatable({}, { __mode = "k" }) :: any
local gui: ScreenGui? = nil

local function soften(emitter: ParticleEmitter)
	emitter.Texture = SOFT
	emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.None
end

local function screen(): ScreenGui
	local existing = gui
	if existing and existing.Parent then
		return existing
	end
	local root = Instance.new("ScreenGui")
	root.Name = "SpriteProbe"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.DisplayOrder = -100
	local player = Players.LocalPlayer
	root.Parent = player:WaitForChild("PlayerGui")
	gui = root
	return root
end

-- One probe: a one-pixel label with the image, on screen until it loads, fails, or the wait runs out.
local function probe(id: number)
	local label = Instance.new("ImageLabel")
	label.Name = tostring(id)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(0.002, 0.002) -- about two pixels: rendered, unseen (Scale, never Offset)
	label.Position = UDim2.fromScale(0, 0)
	label.ImageTransparency = PROBE_TRANSPARENCY
	label.Image = "rbxassetid://" .. tostring(id)
	label.Parent = screen()
	local waited = 0
	local bad = false
	while waited < PROBE_SECONDS do
		if label.IsLoaded then
			break
		end
		local ok, status = pcall(function()
			return ContentProvider:GetAssetFetchStatus(label.Image)
		end)
		if ok and status == Enum.AssetFetchStatus.Failure then
			bad = true
			break
		end
		waited += task.wait(0.5)
	end
	label:Destroy()
	if bad then
		failed[id] = true
		for emitter, held in pairs(guarded) do
			if held == id and emitter.Parent ~= nil then
				soften(emitter)
			end
		end
	end
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
		task.spawn(probe, id)
	end
	return true
end

-- Whether an id is known to fail.
function SpriteGuard.Failed(id: number): boolean
	return failed[id] == true
end

return SpriteGuard
