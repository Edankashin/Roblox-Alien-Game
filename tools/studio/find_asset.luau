--!strict
-- Find every instance that names an asset id, to track down an Output line such as
--   ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type
--   Failed to load sound rbxassetid://203785492
-- when the id is in no repo table (`grep -r <id> src assets` finds nothing, and tools/lint_data refuses an id used
-- under two asset types, so the id is place content, an avatar item, a Toolbox model or a Studio plugin).
-- Run it in Studio's command bar (View > Command Bar, paste the file) or through the Studio MCP execute_luau tool, once
-- in Edit mode (the saved place) and once while Playing (the server DataModel; the client's PlayerGui and character
-- are only in the client's DataModel, so also paste it into the command bar's client context during a Play).
-- Set ASSET_ID, run, read the printed paths. It writes nothing.

local ASSET_ID = "203785492"

local PROPERTIES: { [string]: { string } } = {
	Sound = { "SoundId" },
	Decal = { "Texture" },
	Texture = { "Texture" },
	ImageLabel = { "Image" },
	ImageButton = { "Image", "HoverImage", "PressedImage" },
	ParticleEmitter = { "Texture" },
	Beam = { "Texture" },
	Trail = { "Texture" },
	Sky = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId" },
	MeshPart = { "MeshId", "TextureID" },
	SpecialMesh = { "MeshId", "TextureId" },
	Animation = { "AnimationId" },
	SurfaceAppearance = { "ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap" },
	Shirt = { "ShirtTemplate" },
	Pants = { "PantsTemplate" },
	ShirtGraphic = { "Graphic" },
}

local ROOTS: { Instance } = {
	game:GetService("Workspace"),
	game:GetService("Lighting"),
	game:GetService("ReplicatedStorage"),
	game:GetService("ReplicatedFirst"),
	game:GetService("ServerStorage"),
	game:GetService("ServerScriptService"),
	game:GetService("StarterGui"),
	game:GetService("StarterPack"),
	game:GetService("StarterPlayer"),
	game:GetService("SoundService"),
	game:GetService("Players"),
	game:GetService("Chat"),
	game:GetService("TextChatService"),
}

local found = 0
local scanned = 0
for _, root in ipairs(ROOTS) do
	for _, instance in ipairs(root:GetDescendants()) do
		scanned += 1
		local names = PROPERTIES[instance.ClassName]
		if names then
			for _, name in ipairs(names) do
				local ok, value = pcall(function()
					return (instance :: any)[name]
				end)
				if ok and type(value) == "string" and string.find(value, ASSET_ID, 1, true) then
					found += 1
					print(("find_asset: %s (%s).%s = %s"):format(instance:GetFullName(), instance.ClassName, name, value))
				end
			end
		end
	end
end
print(("find_asset: %s found %d time(s) in %d instances"):format(ASSET_ID, found, scanned))
