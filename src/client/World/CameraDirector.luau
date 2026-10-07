--!strict
-- StarterPlayerScripts.Client.World.CameraDirector: the only module that takes the camera. Its
-- sequences are all pure presentation. PanTo is the "module complete" moment: the camera glides from
-- wherever it stands to a viewpoint Config.CameraPanDistance studs out from the target (on the side it
-- is already on, so it never swings through the ship) and Config.CameraPanHeight up, looking at the
-- target; rests Config.CameraPanHoldSeconds; glides back to the character at the offset it left from.
-- CrashLanding opens a brand-new profile: a dive from Config.CrashStartHeight studs above the camp to
-- a seat behind the character, a shake at touchdown, and the two CRASH_LINE banners (Toast.Banner).
-- FrameArea is the Build tray's view: the camera glides to look down on an area (the house plot) so all of it
-- sits in the part of the screen above the tray, and holds there until EndFrame glides it back.
-- Rumble is the Legendary opening's screen shake: the same jitter as the touchdown, for a length and amplitude the
-- caller gives (Config.LegendaryRumbleSeconds, LegendaryRumbleStuds), run before the catch bar opens.
-- PlayShots plays a cinematic moment from Shared/data/Cinematics (milestone 47): the first arrival in a place, the Legendary
-- push-in. Letterbox bars and a Skip button (UI/CinematicBars), then one segment per shot: the camera's CFrame and
-- FieldOfView tween from where the last shot left them to the next view with the shot's easing, while a DepthOfField effect
-- this module creates under the Camera, and destroys when the camera is handed back, follows the shot's blur. A shot's view is
-- its anchor Part in the place's camera rig, else the fallback rule computed from the layout (Shared/CinematicMath). Reduced
-- motion cuts to the last shot's view for a moment instead (or plays nothing, for a moment that says so). Skip cuts to
-- the end. A moment can bring a music cue: its stinger plays through the music director when it starts.
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
local Cinematics = require(Shared:WaitForChild("data"):WaitForChild("Cinematics"))
local CinematicMath = require(Shared:WaitForChild("CinematicMath"))
local Place = require(Shared:WaitForChild("Place"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Toast = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Toast"))
local CinematicBars = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("CinematicBars"))
local CampRenderer = require(script.Parent:WaitForChild("CampRenderer"))
local MusicDirector = require(script.Parent:WaitForChild("MusicDirector"))
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
-- PlayShots' state, cleared by release(): the end-now step Skip runs, the depth-of-field effect and its blur tween, and
-- the field of view the camera had at the start.
local skipNow: (() -> ())? = nil
local depthEffect: DepthOfFieldEffect? = nil
local blurTween: Tween? = nil
local startFov: number? = nil

local EASING_STYLES: { [string]: Enum.EasingStyle } = { Quad = Enum.EasingStyle.Quad, Sine = Enum.EasingStyle.Sine }
local EASING_DIRECTIONS: { [string]: Enum.EasingDirection } = {
	In = Enum.EasingDirection.In,
	Out = Enum.EasingDirection.Out,
	InOut = Enum.EasingDirection.InOut,
}

-- What a caller can tell a moment: `target` is the point it is about (the alien a Legendary push-in moves toward).
export type ShotContext = { target: Vector3? }

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
-- resumes from where the sequence left it. A cinematic moment's leftovers go with it: the depth-of-field effect is
-- destroyed, the field of view put back and the letterbox bars slid out. The pending onDone runs with the director
-- already idle, so a callback may start the next sequence.
local function release()
	busy = false
	activeTween = nil
	skipNow = nil
	local blur = blurTween
	blurTween = nil
	if blur then
		blur:Cancel()
	end
	local effect = depthEffect
	depthEffect = nil
	if effect then
		effect:Destroy()
	end
	CinematicBars.Hide()
	local done = pendingDone
	pendingDone = nil
	local cam = currentCamera()
	if cam then
		local fov = startFov
		if fov then
			cam.FieldOfView = fov
		end
		cam.CameraType = Enum.CameraType.Custom
		local subject = humanoid()
		if subject then
			cam.CameraSubject = subject
		end
	end
	startFov = nil
	if done then
		done()
	end
end

-- Cinematic moments ----------------------------------------------------------

-- The anchor Part `name` in the place's camera rig (Cinematics.RigFolder under the first of RigParents that has it).
local function rigAnchor(name: string): BasePart?
	for _, parentName in ipairs(Cinematics.RigParents) do
		local parent = Workspace:FindFirstChild(parentName)
		local rig = if parent then parent:FindFirstChild(Cinematics.RigFolder) else nil
		local part = if rig then rig:FindFirstChild(name) else nil
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function toVec(v: Vector3): CinematicMath.Vec
	return { x = v.X, y = v.Y, z = v.Z }
end

-- Everything the fallback rules read, as it stands now: the camp and the layout's biome centres (the world is flat, so
-- they share the camp's ground height), the character, the camera, and the moment's target.
local function buildContext(cam: Camera, extra: ShotContext?): CinematicMath.Context
	local camp = CampRenderer.ShipPosition()
	local biomes: { [string]: CinematicMath.Vec } = {}
	for name, region in pairs(Place.Layout().Regions) do
		biomes[name] = { x = region.x, y = camp.Y, z = region.z }
	end
	local root = rootPart()
	local target = if extra then extra.target else nil
	return {
		camp = toVec(camp),
		biomes = biomes,
		character = if root then toVec(root.Position) else nil,
		characterBack = if root then toVec(behindDirection(root)) else nil,
		camera = toVec(cam.CFrame.Position),
		cameraLook = toVec(cam.CFrame.LookVector),
		target = if target then toVec(target) else nil,
	}
end

-- The camera's view for a shot: its anchor Part's CFrame when the rig has one, else the fallback rule's. nil when
-- neither gives a usable view (the shot is skipped).
local function viewFor(shot: Cinematics.Shot, cam: Camera, extra: ShotContext?): CFrame?
	local anchorName = shot.anchor
	if anchorName ~= nil then
		local part = rigAnchor(anchorName)
		if part then
			return part.CFrame
		end
	end
	local pose = CinematicMath.Fallback(shot.fallback, buildContext(cam, extra))
	if not pose then
		return nil
	end
	local eye = Vector3.new(pose.eye.x, pose.eye.y, pose.eye.z)
	local focus = Vector3.new(pose.focus.x, pose.focus.y, pose.focus.z)
	if (focus - eye).Magnitude < MIN_FLAT then
		return nil
	end
	return CFrame.lookAt(eye, focus)
end

-- Plays a tween of `goals` on `instance` and yields until it ends. Answers false when the sequence was retired
-- meanwhile (Cancel and Skip cancel the tween, which also completes it).
local function runTween(mine: number, instance: Instance, goals: { [string]: any }, info: TweenInfo): boolean
	local tween = TweenService:Create(instance, info, goals)
	activeTween = tween
	tween:Play()
	tween.Completed:Wait()
	if activeTween == tween then
		activeTween = nil
	end
	return generation == mine
end

-- Sets the depth-of-field effect to the intensities `blur` stands for (0 none .. 1 full), at once or, with `info`, as a
-- tween that runs beside the camera's own. Nothing when the moment made no effect.
local function setBlur(blur: number, info: TweenInfo?)
	local effect = depthEffect
	if not effect then
		return
	end
	local near, far = CinematicMath.BlurIntensities(blur)
	local previous = blurTween
	blurTween = nil
	if previous then
		previous:Cancel()
	end
	if info then
		local tween = TweenService:Create(effect, info, { NearIntensity = near, FarIntensity = far })
		blurTween = tween
		tween:Play()
	else
		effect.NearIntensity = near
		effect.FarIntensity = far
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

-- Plays the cinematic moment `momentId` (Shared/data/Cinematics): the camera takes the shots one after another, each
-- tweening from where the last left off, the letterbox bars frame it and a Skip button appears after
-- Cinematics.SkipAfterSeconds. onDone runs once the camera is handed back (also when Cancel or Skip ends the moment early;
-- a caller that waits on it must allow for it running before PlayShots returns). Answers true when it started and false
-- when nothing happened: another sequence running, an unknown moment, no camera, or reduced motion on a moment that
-- skips under it (then onDone is not called). `context` says what the moment is about (the alien a push-in moves
-- toward). Reduced motion otherwise cuts to the last shot's view for Cinematics.ReducedMotionHoldSeconds (data:
-- ReducedMotionCut) and hands the camera back. A place with no character within ROOT_WAIT_SECONDS only calls onDone.
function CameraDirector.PlayShots(momentId: string, onDone: (() -> ())?, context: ShotContext?): boolean
	local moment = Cinematics.Moments[momentId]
	if busy or not moment or currentCamera() == nil then
		return false
	end
	local reduced = reducedMotion()
	if reduced and moment.skipOnReducedMotion then
		return false
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
		local shots = moment.shots
		local last = shots[#shots]
		local baseFov = cam.FieldOfView
		startFov = baseFov
		cam.CameraType = Enum.CameraType.Scriptable
		local stinger = moment.stinger
		if stinger then
			MusicDirector.Stinger(stinger)
		end

		if reduced and Cinematics.ReducedMotionCut then
			local view = viewFor(last, cam, context)
			if view then
				cam.CFrame = view
			end
			task.wait(Cinematics.ReducedMotionHoldSeconds) -- a rest, not motion
			if generation == mine then
				release()
			end
			return
		end

		for _, shot in ipairs(shots) do
			if shot.blur > 0 then
				local effect = Instance.new("DepthOfFieldEffect")
				effect.Name = "CinematicDepthOfField"
				effect.FocusDistance = Cinematics.DepthOfField.FocusDistance
				effect.InFocusRadius = Cinematics.DepthOfField.InFocusRadius
				effect.NearIntensity = 0
				effect.FarIntensity = 0
				effect.Parent = cam
				depthEffect = effect
				break
			end
		end
		-- Skip cuts to the last shot's view and hands the camera back; the generation bump retires this thread.
		skipNow = function()
			generation += 1
			local tween = activeTween
			activeTween = nil
			if tween then
				tween:Cancel()
			end
			local view = viewFor(last, cam, context)
			if view then
				cam.CFrame = view
			end
			release()
		end
		local onSkipTap: (() -> ())? = nil
		if moment.skippable then
			onSkipTap = function()
				local skip = skipNow
				if generation == mine and skip then
					skip()
				end
			end
			task.delay(Cinematics.SkipAfterSeconds, function()
				if generation == mine then
					CinematicBars.ShowSkip()
				end
			end)
		end
		if moment.letterbox or moment.skippable then
			CinematicBars.Show(moment.letterbox, onSkipTap)
		end

		for index, shot in ipairs(shots) do
			if generation ~= mine then
				return
			end
			local view = viewFor(shot, cam, context)
			if view == nil and RunService:IsStudio() then
				warn(("[%s] Cinematics: %s shot %d has no view (anchor missing and the fallback rule needs something this place lacks)"):format(Config.WorkingTitle, momentId, index))
			end
			local fov = shot.fov or baseFov
			if index == 1 then
				-- The opening frame: placed at once, then it rests for its seconds.
				if view then
					cam.CFrame = view
				end
				cam.FieldOfView = fov
				setBlur(shot.blur, nil)
				if shot.seconds > 0 then
					task.wait(shot.seconds)
				end
			else
				local style, direction = CinematicMath.Easing(shot.easing)
				local info = TweenInfo.new(shot.seconds, EASING_STYLES[style or ""] or Enum.EasingStyle.Quad, EASING_DIRECTIONS[direction or ""] or Enum.EasingDirection.InOut)
				setBlur(shot.blur, info)
				local goals: { [string]: any } = { FieldOfView = fov }
				if view then
					goals.CFrame = view
				end
				if not runTween(mine, cam, goals, info) then
					return
				end
			end
		end
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
