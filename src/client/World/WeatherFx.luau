--!strict
-- StarterPlayerScripts.Client.World.WeatherFx: weather particles (Look plan pass L3). One emitter sheet
-- (rain, snow, fog...) follows the camera and is switched by the clock's weather name
-- (State.GetClock().weather, the server's WorldClock mirror). Every number a sheet needs is in
-- data/Weather.luau; this module only reads it. Each sheet is an invisible anchored part under a
-- client-created Workspace.WeatherFx folder (Instance.new on the client, so nothing here replicates),
-- sized span x 1 x span. A "fall" sheet (rain, snow) is a plane perpendicular to its direction, oriented
-- so the emitter's Top face points along it. A "drift" sheet (fog, haze) stays horizontal (Up = world
-- up) at its height over the camera, and an Acceleration along the direction pushes the wisps until drag
-- settles them at about the row's speed. A name with no sheet (Clear, or one the data does not know) means no weather particles. On a change the
-- old sheet's Rate ramps to 0 and the new one's from 0 over Weather.FadeSeconds. Pure presentation: the
-- clock and the weather are the server's.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Weather = require(Shared:WaitForChild("data"):WaitForChild("Weather"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local WeatherFx = {}

local FOLDER_NAME = "WeatherFx"
local DESTROY_SLACK = 0.25 -- seconds past the longest particle lifetime before a retired part is removed

type Live = {
	name: string,
	part: Part,
	emitter: ParticleEmitter,
	direction: Vector3, -- the sheet's emit direction, normalised
	drift: boolean, -- true: a horizontal sheet, false: a plane perpendicular to direction
	height: number,
	maxLifetime: number,
	tween: Tween?, -- the Rate ramp in flight
	followUntil: number, -- os.clock() until which the follow loop keeps re-centring this sheet
}

local started = false
local live: { Live } = {} -- the current sheet plus any that are still fading out
local current: Live? = nil -- the sheet the weather asks for now
local folderInstance: Folder? = nil

-- Helpers ----------------------------------------------------------------

-- Workspace.WeatherFx, created on first use (client-side only, never replicates).
local function folder(): Folder
	local existing = folderInstance
	if existing and existing.Parent then
		return existing
	end
	local found = Workspace:FindFirstChild(FOLDER_NAME)
	if found and found:IsA("Folder") then
		folderInstance = found
		return found
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folderInstance = created
	return created
end

-- A CFrame at `position` whose +Y (the emitter's Top direction) points along `up`.
local function frameWithUp(position: Vector3, up: Vector3): CFrame
	local axis = up.Unit
	local right = axis:Cross(Vector3.zAxis)
	if right.Magnitude < 1e-3 then
		right = Vector3.xAxis
	end
	return CFrame.fromMatrix(position, right.Unit, axis)
end

-- The sheet's frame at `position`: horizontal for a drift sheet, perpendicular to `direction` for a fall one.
local function sheetFrame(position: Vector3, direction: Vector3, drift: boolean): CFrame
	if drift then
		return CFrame.new(position)
	end
	return frameWithUp(position, direction)
end

-- The point `height` studs above the camera, or nil while there is no camera yet.
local function anchorPoint(height: number): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	return camera.CFrame.Position + Vector3.new(0, height, 0)
end

local function stopTween(entry: Live)
	local running = entry.tween
	if running then
		running:Cancel()
		entry.tween = nil
	end
end

-- Tweens the sheet's Rate to `target` over Weather.FadeSeconds.
local function rampTo(entry: Live, target: number)
	stopTween(entry)
	local tween = TweenService:Create(entry.emitter, TweenInfo.new(Weather.FadeSeconds, Enum.EasingStyle.Linear), { Rate = target })
	entry.tween = tween
	tween:Play()
end

local function remove(entry: Live)
	local index = table.find(live, entry)
	if index then
		table.remove(live, index)
	end
	stopTween(entry)
	entry.part:Destroy()
end

-- Builds a sheet's part and emitter from its data row. The emitter starts at Rate 0 (the caller ramps it).
local function build(name: string, sheet: Weather.Sheet): Live
	local direction = Vector3.new(sheet.direction[1] or 0, sheet.direction[2] or -1, sheet.direction[3] or 0)
	if direction.Magnitude < 1e-3 then
		direction = Vector3.new(0, -1, 0)
	end
	direction = direction.Unit

	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(sheet.span, 1, sheet.span)
	local drift = sheet.mode == "drift"
	part.CFrame = sheetFrame(anchorPoint(sheet.height) or Vector3.new(0, sheet.height, 0), direction, drift)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder()

	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = true
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(sheet.lifetime[1] or 1, sheet.lifetime[2] or sheet.lifetime[1] or 1)
	emitter.Speed = NumberRange.new(sheet.speed[1] or 0, sheet.speed[2] or sheet.speed[1] or 0)
	emitter.Size = NumberSequence.new(sheet.sizeStart, sheet.sizeEnd)
	emitter.Color = ColorSequence.new(Color3.fromHex(sheet.color))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, sheet.transparency),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(sheet.spread, sheet.spread)
	emitter.LightEmission = sheet.lightEmission
	emitter.Drag = sheet.drag
	if drift then
		-- Wisps start at about the row's speed and are pushed along the drift; drag balances the push at speed max.
		emitter.Acceleration = direction * (emitter.Speed.Max * sheet.drag)
	end
	emitter.RotSpeed = NumberRange.new(sheet.rotationSpeed[1] or 0, sheet.rotationSpeed[2] or sheet.rotationSpeed[1] or 0)
	if sheet.texture ~= 0 then
		emitter.Texture = "rbxassetid://" .. tostring(sheet.texture)
	end
	emitter.Parent = part

	return {
		name = name,
		part = part,
		emitter = emitter,
		direction = direction,
		drift = drift,
		height = sheet.height,
		maxLifetime = emitter.Lifetime.Max,
		tween = nil,
		followUntil = math.huge,
	}
end

-- Ramps a sheet out: Rate to 0 over the fade, then its part goes once the last particle has died.
local function retire(entry: Live)
	rampTo(entry, 0)
	entry.followUntil = os.clock() + Weather.FadeSeconds
	task.delay(Weather.FadeSeconds + entry.maxLifetime + DESTROY_SLACK, function()
		remove(entry)
	end)
end

-- Switches to the sheet for `weather` (or to none when the name has no sheet).
local function apply(weather: string)
	local sheet: Weather.Sheet? = Weather.Sheets[weather]
	local wanted: string? = if sheet then weather else nil
	local now = current
	if (now and now.name or nil) == wanted then
		return
	end
	if now then
		current = nil
		retire(now)
	end
	if sheet then
		local entry = build(weather, sheet)
		current = entry
		table.insert(live, entry)
		rampTo(entry, sheet.rate)
		local estimate = math.round(sheet.rate * (sheet.lifetime[2] or sheet.lifetime[1] or 1))
		print(("[%s] weather: %s sheet, about %d particles"):format(Config.WorkingTitle, weather, estimate))
		if estimate > Config.WeatherParticleMax then
			warn(("[%s] weather: %s sheet is about %d particles, over Config.WeatherParticleMax (%d)"):format(Config.WorkingTitle, weather, estimate, Config.WeatherParticleMax))
		end
	end
end

-- Re-centres every live sheet over the camera at its own height.
local function follow()
	local now = os.clock()
	for _, entry in ipairs(live) do
		if now <= entry.followUntil and entry.part.Parent then
			local point = anchorPoint(entry.height)
			if point then
				entry.part.CFrame = sheetFrame(point, entry.direction, entry.drift)
			end
		end
	end
end

-- Public ------------------------------------------------------------------

-- The weather name of the sheet that is on now, or nil when there is none (for tests).
function WeatherFx.Active(): string?
	local now = current
	if now then
		return now.name
	end
	return nil
end

function WeatherFx.Start()
	if started then
		return
	end
	started = true
	State.OnChanged("clock", function()
		apply(State.GetClock().weather)
	end)
	apply(State.GetClock().weather)
	task.spawn(function()
		while true do
			follow()
			task.wait(Weather.FollowSeconds)
		end
	end)
end

return WeatherFx
