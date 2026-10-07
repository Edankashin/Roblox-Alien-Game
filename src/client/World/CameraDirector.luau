--!strict
-- StarterPlayerScripts.Client.World.CameraDirector: the only module that takes the camera. Three
-- sequences, all pure presentation. PanTo is the "module complete" moment: the camera glides from
-- wherever it stands to a viewpoint Config.CameraPanDistance studs out from the target (on the side it
-- is already on, so it never swings through the ship) and Config.CameraPanHeight up, looking at the
-- target; rests Config.CameraPanHoldSeconds; glides back to the character at the offset it left from.
-- CrashLanding opens a brand-new profile: a dive from Config.CrashStartHeight studs above the camp to
-- a seat behind the character, a shake at touchdown, and the two CRASH_LINE banners (Toast.Banner).
-- FrameArea is the Build tray's view: the camera glides to look down on an area (the house plot) so all of it
-- sits in the part of the screen above the tray, and holds there until EndFrame glides it back.
-- Rumble is the Legendary opening's screen shake: the same jitter as the touchdown, for a length and amplitude the
-- caller gives (Config.LegendaryRumbleSeconds, LegendaryRumbleStuds), run before the catch bar opens.
-- The camera is Scriptable while a sequence runs, so the player cannot steer it (the character is not
-- frozen; the bootstrap hides the HUD), and goes back to Custom with the Humanoid as subject after.
-- Cancel stops whatever runs at once (a capture started, the player left) and still runs the pending
-- onDone. One generation counter retires every later step of a cancelled sequence. Reduced motion
-- (Prefs.ReducedMotion: the profile toggle or UserGameSettings.ReducedMotion) shortens the glides by Config.ReducedMotionFactor and skips the
-- shake. Nothing here decides anything: callers say when, and only one sequence runs at a time.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Toast = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Toast"))
local CampRenderer = require(script.Parent:WaitForChild("CampRenderer"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local CameraDirector = {}

-- Shape of the two sequences (studs and seconds that are not yet in data/Config).
local ROOT_WAIT_SECONDS = 10 -- CrashLanding gives the character this long to appear before giving up
local ROOT_POLL_SECONDS = 0.1
local CRASH_SEAT_BEHIND = 12 -- the dive ends this far behind the character
local CRASH_SEAT_ABOVE = 6 -- and this far above it
local CRASH_START_SIDE = 18 -- the start sits this far off the camp's column, so the look-down has a tilt
local CRASH_SHAKE_SECONDS = 0.5
local MIN_FLAT = 1e-3 -- a horizontal direction shorter than this has no usable heading

local localPlayer = Players.LocalPlayer
local random = Random.new()

local busy = false
local generation = 0 -- each sequence takes a number; Cancel retires it, so later steps do nothing
local pendingDone: (() -> ())? = nil
local activeTween: Tween? = nil
-- FrameArea's hold: the generation that holds it, and where EndFrame glides back to (the camera's offset from the
-- character and its rotation when the hold began).
local framedGeneration: number? = nil
local framedReturn: Vector3? = nil
local framedRotation: CFrame? = nil

-- Lookups ------------------------------------------------------------------

local function currentCamera(): Camera?
	return Workspace.CurrentCamera
end

local function rootPart(): BasePart?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function humanoid(): Humanoid?
	local character = localPlayer.Character
	local found = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if found and found:IsA("Humanoid") then
		return found
	end
	return nil
end

-- The player's reduced-motion preference (Prefs folds the profile toggle and the system switch together).
local function reducedMotion(): boolean
	return Prefs.ReducedMotion()
end

-- Unit XZ direction from `target` towards `from`, or nil when they share a vertical column.
local function flatDirection(from: Vector3, target: Vector3): Vector3?
	local delta = Vector3.new(from.X - target.X, 0, from.Z - target.Z)
	if delta.Magnitude < MIN_FLAT then
		return nil
	end
	return delta.Unit
end

-- Unit XZ direction the character has its back to; +Z when it faces straight up or down.
local function behindDirection(root: BasePart): Vector3
	local look = root.CFrame.LookVector
	local flat = Vector3.new(-look.X, 0, -look.Z)
	if flat.Magnitude < MIN_FLAT then
		return Vector3.new(0, 0, 1)
	end
	return flat.Unit
end

-- Steps ----------------------------------------------------------------------

-- Polls for the character's HumanoidRootPart for up to ROOT_WAIT_SECONDS. Nil when it never comes or
-- the sequence is retired while waiting.
local function waitForRoot(mine: number): BasePart?
	local deadline = os.clock() + ROOT_WAIT_SECONDS
	while generation == mine do
		local root = rootPart()
		if root then
			return root
		end
		if os.clock() >= deadline then
			return nil
		end
		task.wait(ROOT_POLL_SECONDS)
	end
	return nil
end

-- Tweens the camera to `target` (Quad, the given direction) over `seconds` and yields until the tween
-- ends. Answers false when the sequence was retired meanwhile (Cancel cancels the tween, which also
-- completes it).
local function glide(mine: number, cam: Camera, target: CFrame, seconds: number, direction: Enum.EasingDirection): boolean
	local tween = TweenService:Create(cam, TweenInfo.new(seconds, Enum.EasingStyle.Quad, direction), { CFrame = target })
	activeTween = tween
	tween:Play()
	tween.Completed:Wait()
	if activeTween == tween then
		activeTween = nil
	end
	return generation == mine
end

-- Jitters the camera around `base` in its own X and Y every RenderStepped for `seconds`, the amplitude
-- falling from `studs` to 0, then settles it on `base`. Stops at once when the sequence is retired.
local function shake(mine: number, cam: Camera, base: CFrame, seconds: number, studs: number)
	local started = os.clock()
	while generation == mine do
		local elapsed = os.clock() - started
		if elapsed >= seconds then
			break
		end
		local amplitude = studs * (1 - elapsed / seconds)
		cam.CFrame = base * CFrame.new(random:NextNumber(-amplitude, amplitude), random:NextNumber(-amplitude, amplitude), 0)
		RunService.RenderStepped:Wait()
	end
	if generation == mine then
		cam.CFrame = base
	end
end

-- Hands the camera back: Custom with the character's Humanoid as subject, so the default camera
-- resumes from where the sequence left it. The pending onDone runs with the director already idle, so
-- a callback may start the next sequence.
local function release()
	busy = false
	activeTween = nil
	local done = pendingDone
	pendingDone = nil
	local cam = currentCamera()
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		local subject = humanoid()
		if subject then
			cam.CameraSubject = subject
		end
	end
	if done then
		done()
	end
end

-- Public API -------------------------------------------------------------

function CameraDirector.IsBusy(): boolean
	return busy
end

-- The "module complete" moment: glide to a viewpoint over `target`, rest, glide back to the character
-- and hand the camera back, then onDone. Ignored (onDone not called) while another sequence runs.
function CameraDirector.PanTo(target: Vector3, onDone: (() -> ())?)
	if busy then
		return
	end
	local cam = currentCamera()
	if not cam then
		if onDone then
			onDone()
		end
		return
	end
	busy = true
	generation += 1
	local mine = generation
	pendingDone = onDone

	local saved = cam.CFrame
	local root = rootPart()
	-- The camera's offset from the character, re-applied to wherever the character stands at the end;
	-- keeping the saved rotation with it means the camera looks at the character exactly as it did.
	local returnOffset: Vector3? = if root then saved.Position - root.Position else nil
	-- Stay on the side the camera already stands, so the glide never cuts through the ship.
	local away = flatDirection(saved.Position, target)
		or (if root then flatDirection(root.Position, target) else nil)
		or Vector3.new(0, 0, 1)
	local viewpoint = target + away * Config.CameraPanDistance + Vector3.new(0, Config.CameraPanHeight, 0)
	local factor = if reducedMotion() then Config.ReducedMotionFactor else 1
	local seconds = Config.CameraPanSeconds * factor

	cam.CameraType = Enum.CameraType.Scriptable
	task.spawn(function()
		if not glide(mine, cam, CFrame.lookAt(viewpoint, target), seconds, Enum.EasingDirection.InOut) then
			return
		end
		task.wait(Config.CameraPanHoldSeconds) -- a rest, not motion: reduced motion leaves it alone
		if generation ~= mine then
			return
		end
		local back = rootPart()
		if back and returnOffset then
			local home = CFrame.new(back.Position + returnOffset) * saved.Rotation
			if not glide(mine, cam, home, seconds, Enum.EasingDirection.InOut) then
				return
			end
		end
		-- Without a character to return to, just hand the camera back.
		release()
	end)
end

-- The opening for a brand-new profile: wait for the character, dive from above the camp to a seat
-- behind it, shake at touchdown, and hand the camera back, with CRASH_LINE_1 at the start and
-- CRASH_LINE_2 at the end. Without a character within ROOT_WAIT_SECONDS it only calls onDone.
-- Ignored (onDone not called) while another sequence runs.
function CameraDirector.CrashLanding(onDone: (() -> ())?)
	if busy then
		return
	end
	busy = true
	generation += 1
	local mine = generation
	pendingDone = onDone

	task.spawn(function()
		local root = waitForRoot(mine)
		if generation ~= mine then
			return
		end
		local cam = currentCamera()
		if not root or not cam then
			release()
			return
		end
		local reduced = reducedMotion()
		local at = root.Position
		local behind = behindDirection(root)
		local camp: Vector3? = CampRenderer.ShipPosition()
		local over = camp or at
		local start = Vector3.new(over.X, over.Y + Config.CrashStartHeight, over.Z) + behind * CRASH_START_SIDE
		local seat = at + behind * CRASH_SEAT_BEHIND + Vector3.new(0, CRASH_SEAT_ABOVE, 0)
		local seatCFrame = CFrame.lookAt(seat, at)
		local seconds = Config.CrashCinematicSeconds * (if reduced then Config.ReducedMotionFactor else 1)

		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(start, at)
		Toast.Banner(Strings.CRASH_LINE_1, Theme.Colors.Close, Config.CrashLineSeconds)
		if not glide(mine, cam, seatCFrame, seconds, Enum.EasingDirection.In) then
			return
		end
		if not reduced then
			shake(mine, cam, seatCFrame, CRASH_SHAKE_SECONDS, Config.CrashShakeStuds)
			if generation ~= mine then
				return
			end
		end
		Toast.Banner(Strings.CRASH_LINE_2, Theme.Colors.Featured, Config.CrashLineSeconds)
		release()
	end)
end

-- The Legendary opening's rumble: the camera shakes around where it stands for `seconds`, the amplitude easing
-- from `studs` to 0, then is handed back. Answers true when it started (the caller then waits `seconds` before
-- opening the catch bar) and false when nothing happened: reduced motion (the shake is skipped, as at the crash
-- touchdown), another sequence running, no camera, or nothing to shake.
function CameraDirector.Rumble(seconds: number, studs: number): boolean
	if busy or reducedMotion() or seconds <= 0 or studs <= 0 then
		return false
	end
	local cam = currentCamera()
	if not cam then
		return false
	end
	busy = true
	generation += 1
	local mine = generation
	pendingDone = nil
	cam.CameraType = Enum.CameraType.Scriptable
	local base = cam.CFrame
	task.spawn(function()
		shake(mine, cam, base, seconds, studs)
		if generation == mine then
			release()
		end
	end)
	return true
end

-- The Build tray's view (milestone 42b): glide to look down on a flat area centred on `center` with half-diagonal
-- `radius` studs, so the whole area shows in the top `visibleTop` of the screen (the tray covers the rest and
-- swallows taps there), and hold until EndFrame. The camera stays on the side it already stands. The fit: the
-- area's centre is aimed at the middle of the visible band, by tilting the view down from the centre line by the
-- band's offset, and the distance makes the radius fill half the band's height with Config.BuildCameraFitMargin to
-- spare. Answers false (and holds nothing) while another sequence runs or there is no camera.
function CameraDirector.FrameArea(center: Vector3, radius: number, visibleTop: number): boolean
	if busy then
		return false
	end
	local cam = currentCamera()
	if not cam then
		return false
	end
	busy = true
	generation += 1
	local mine = generation
	pendingDone = nil

	local saved = cam.CFrame
	local root = rootPart()
	framedReturn = if root then saved.Position - root.Position else nil
	framedRotation = saved.Rotation
	framedGeneration = mine

	local halfFov = math.rad(cam.FieldOfView) / 2
	local band = math.clamp(visibleTop, 0.2, 1)
	-- Screen height maps linearly to the tangent of the angle off the centre line.
	local tilt = math.atan((1 - band) * math.tan(halfFov)) -- the band's middle sits this far above the centre
	local halfBand = math.atan(band * math.tan(halfFov)) -- half the band's height, as an angle
	local distance = radius * Config.BuildCameraFitMargin / math.tan(halfBand)
	local pitch = math.rad(Config.BuildCameraPitchDegrees)
	local away = flatDirection(saved.Position, center) or Vector3.new(0, 0, 1)
	local eye = center + away * (distance * math.cos(pitch)) + Vector3.new(0, distance * math.sin(pitch), 0)
	local view = CFrame.lookAt(eye, center) * CFrame.Angles(-tilt, 0, 0) -- looking lower lifts the area on screen
	local seconds = Config.BuildCameraSeconds * (if reducedMotion() then Config.ReducedMotionFactor else 1)

	cam.CameraType = Enum.CameraType.Scriptable
	task.spawn(function()
		glide(mine, cam, view, seconds, Enum.EasingDirection.InOut)
	end)
	return true
end

-- Ends FrameArea's hold: glide back to the character at the offset the camera left from and hand the camera
-- back. Nothing to do when the hold already ended (Cancel, a catch) or another sequence owns the camera.
function CameraDirector.EndFrame()
	if not busy or framedGeneration ~= generation then
		return
	end
	generation += 1
	local mine = generation
	framedGeneration = nil
	local tween = activeTween
	activeTween = nil
	if tween then
		tween:Cancel()
	end
	local cam = currentCamera()
	local back = rootPart()
	local offset, rotation = framedReturn, framedRotation
	if not cam or not back or not offset or not rotation then
		release()
		return
	end
	local seconds = Config.BuildCameraSeconds * (if reducedMotion() then Config.ReducedMotionFactor else 1)
	local home = CFrame.new(back.Position + offset) * rotation
	task.spawn(function()
		if glide(mine, cam, home, seconds, Enum.EasingDirection.InOut) then
			release()
		end
	end)
end

-- Stops any running sequence at once, hands the camera back and runs its pending onDone. The
-- bootstrap calls this when a capture starts or the player leaves. Nothing to do while idle.
function CameraDirector.Cancel()
	if not busy then
		return
	end
	generation += 1
	local tween = activeTween
	activeTween = nil
	if tween then
		tween:Cancel()
	end
	release()
end

return CameraDirector
