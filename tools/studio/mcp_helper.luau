-- tools/studio/mcp_helper.luau: the Studio MCP helper the Mac session uses in Play (Client datamodel). Paste it whole into one
-- execute_luau call; it installs _G.H with: cmd (a dev command through TextChatService in task.spawn, which does not yield the
-- MCP), tp (teleport the avatar), ground (raycast the ground height), find/bounds/facing (a wild alien by species), spawnAt,
-- cam/camOff (a camera lock the game camera script cannot override: RenderStepped plus BindToRenderStep after Last), reframe
-- (frame an alien from its front at a distance; parks the avatar behind the alien so the wild AI turns to face the camera),
-- shoot (spawn and frame), fps (frame-time sample; only meaningful while Studio is the frontmost app). Not part of the game;
-- never synced by Rojo. See docs/vault/08-log/2026-11-01.md for the lessons behind it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TCS = game:GetService("TextChatService")
local H = {}
_G.H = H
function H.cmd(text) task.spawn(function() TCS.TextChannels.RBXGeneral:SendAsync(text) end) end
function H.root() local c = Players.LocalPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
function H.tp(pos, lookDir)
	local r = H.root()
	r.CFrame = CFrame.lookAt(pos, pos + (lookDir or Vector3.new(0, 0, -1)))
	r.AssemblyLinearVelocity = Vector3.zero
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
function H.ground(x, z)
	params.FilterDescendantsInstances = { Players.LocalPlayer.Character, workspace:FindFirstChild("ClientWild"), workspace:FindFirstChild("ClientSpectacle"), workspace:FindFirstChild("WorldFx"), workspace:FindFirstChild("WeatherFx") }
	local r = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), params)
	return r and r.Position.Y or nil, r and r.Instance and r.Instance.Name or "?"
end
function H.find(species, near)
	local best, bestD
	for _, m in ipairs(workspace.ClientWild:GetChildren()) do
		if m.Name == species and m:GetAttribute("Shadowed") ~= true and #m:GetDescendants() > 0 then
			local p = m:GetPivot().Position
			local d = near and (p - near).Magnitude or 0
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end
function H.bounds(m)
	local cf, size = m:GetBoundingBox()
	if size.Magnitude < 0.1 then return m:GetPivot().Position, Vector3.new(2, 2, 2) end
	return cf.Position, size
end
function H.facing(m)
	local lv = -m:GetPivot().LookVector
	lv = Vector3.new(lv.X, 0, lv.Z)
	if lv.Magnitude < 0.01 then lv = Vector3.new(0, 0, 1) end
	return lv.Unit
end
function H.spawnAt(species, pos, lookDir)
	H.tp(pos, lookDir)
	task.wait(0.6)
	H.cmd("/spawn " .. species)
	local t0 = os.clock()
	local m
	repeat
		task.wait(0.25)
		m = H.find(species, pos)
		if m and (H.bounds(m) - pos).Magnitude > 25 then m = nil end
	until m or os.clock() - t0 > 10
	task.wait(1.5)
	return m
end
local camConn
function H.cam(pos, lookAt)
	H.camOff()
	local cam = workspace.CurrentCamera
	camConn = RunService.RenderStepped:Connect(function() cam.CFrame = CFrame.lookAt(pos, lookAt) end)
	RunService:BindToRenderStep("MCPCamLock", Enum.RenderPriority.Last.Value + 10, function() cam.CFrame = CFrame.lookAt(pos, lookAt) end)
end
function H.camOff()
	if camConn then camConn:Disconnect() camConn = nil end
	pcall(function() RunService:UnbindFromRenderStep("MCPCamLock") end)
end
function H.reframe(dist, up, yaw)
	local m = H.last
	local c = H.bounds(m)
	local f = H.facing(m)
	local dir = CFrame.Angles(0, math.rad(yaw or 0), 0):VectorToWorldSpace(f)
	local camPos = c + dir * (dist or 16) + Vector3.new(0, up or 5, 0)
	local behind = camPos + dir * 10
	local gy = H.ground(behind.X, behind.Z) or behind.Y
	H.tp(Vector3.new(behind.X, gy + 3.5, behind.Z), -dir)
	task.wait(0.7)
	c = H.bounds(m); f = H.facing(m)
	dir = CFrame.Angles(0, math.rad(yaw or 0), 0):VectorToWorldSpace(f)
	H.cam(c + dir * (dist or 16) + Vector3.new(0, up or 5, 0), c)
	return ("%s centre %s facing %s"):format(m.Name, tostring(c), tostring(f))
end
function H.shoot(species, spot, yaw)
	local gy = H.ground(spot.X, spot.Z) or spot.Y
	local m = H.spawnAt(species, Vector3.new(spot.X, gy + 3.5, spot.Z), Vector3.new(0, 0, -1))
	if not m then return nil, "not found" end
	H.last = m
	return m, H.reframe(16, 5, yaw)
end
function H.fps(seconds)
	local n, sum, mx, list = 0, 0, 0, {}
	local t0 = os.clock()
	while os.clock() - t0 < seconds do
		local dt = RunService.RenderStepped:Wait()
		n += 1; sum += dt; if dt > mx then mx = dt end; table.insert(list, dt)
	end
	table.sort(list)
	return ("frames %d avg %.1f ms p95 %.1f ms max %.1f ms"):format(n, sum / n * 1000, list[math.max(1, math.floor(#list * 0.95))] * 1000, mx * 1000)
end
return "helper installed"
