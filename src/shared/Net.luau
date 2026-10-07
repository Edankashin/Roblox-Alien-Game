--!strict
-- Thin wrapper over RemoteEvents and RemoteFunctions. The server creates them; the client waits for them.
-- Server handlers must validate every argument and never trust the client.
local RunService = game:GetService("RunService")

local Net = {}
local FOLDER_NAME = "Remotes"

local function folder(): Folder
	local shared = script.Parent :: Instance
	if RunService:IsServer() then
		local existing = shared:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing :: Folder
		end
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		created.Parent = shared
		return created
	end
	return shared:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.event(name: string): RemoteEvent
	local f = folder()
	if RunService:IsServer() then
		local existing = f:FindFirstChild(name)
		if existing then
			return existing :: RemoteEvent
		end
		local created = Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = f
		return created
	end
	return f:WaitForChild(name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	local f = folder()
	if RunService:IsServer() then
		local existing = f:FindFirstChild(name)
		if existing then
			return existing :: RemoteFunction
		end
		local created = Instance.new("RemoteFunction")
		created.Name = name
		created.Parent = f
		return created
	end
	return f:WaitForChild(name) :: RemoteFunction
end

-- Server-side rate limiting: allow at most maxPerSecond calls per player per name.
local buckets: { [Player]: { [string]: { count: number, windowStart: number } } } = {}

-- Every server handler calls Net.allow first, so a call from a player is the server's one sign that they are using the
-- game. The Afk service registers a listener here (the player and the remote's name) so resting knows when a player is
-- back. Server only in practice: the client never sets it, and it never runs on the client.
local activityListener: ((Player, string) -> ())? = nil

function Net.SetActivityListener(listener: ((Player, string) -> ())?)
	activityListener = listener
end

function Net.allow(player: Player, name: string, maxPerSecond: number): boolean
	local listener = activityListener
	if listener then
		listener(player, name) -- before the rate check: a call that is refused for its rate is still a call
	end
	local now = os.clock()
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local bucket = perPlayer[name]
	if not bucket or now - bucket.windowStart >= 1 then
		perPlayer[name] = { count = 1, windowStart = now }
		return true
	end
	bucket.count += 1
	return bucket.count <= maxPerSecond
end

function Net.forget(player: Player)
	buckets[player] = nil
end

return Net
