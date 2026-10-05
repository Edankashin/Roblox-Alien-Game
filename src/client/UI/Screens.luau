--!strict
-- StarterPlayerScripts.Client.UI.Screens: one modal at a time. Every full-screen panel (Ship, Aliens,
-- Codex, later Shop and Quests) registers its Open / Close / IsOpen here; opening one closes whatever
-- else is up, and the bootstrap asks IsAnyOpen before it offers Catch!, Collect or Build.

local Screens = {}

export type Screen = { Open: () -> (), Close: () -> (), IsOpen: () -> boolean }

local registry: { [string]: Screen } = {}
local order: { string } = {}

function Screens.Register(name: string, screen: Screen)
	if not registry[name] then
		table.insert(order, name)
	end
	registry[name] = screen
end

function Screens.Get(name: string): Screen?
	return registry[name]
end

function Screens.IsOpen(name: string): boolean
	local screen = registry[name]
	return screen ~= nil and screen.IsOpen()
end

function Screens.IsAnyOpen(): boolean
	for _, name in ipairs(order) do
		if registry[name].IsOpen() then
			return true
		end
	end
	return false
end

function Screens.CloseAll()
	for _, name in ipairs(order) do
		local screen = registry[name]
		if screen.IsOpen() then
			screen.Close()
		end
	end
end

-- Opens `name`, closing any other screen first.
function Screens.Open(name: string)
	local screen = registry[name]
	if not screen then
		return
	end
	for _, other in ipairs(order) do
		if other ~= name and registry[other].IsOpen() then
			registry[other].Close()
		end
	end
	if not screen.IsOpen() then
		screen.Open()
	end
end

function Screens.Toggle(name: string)
	local screen = registry[name]
	if not screen then
		return
	end
	if screen.IsOpen() then
		screen.Close()
	else
		Screens.Open(name)
	end
end

return Screens
