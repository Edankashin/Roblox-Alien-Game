--!strict
-- StarterPlayerScripts.Client.World.LaunchSequence: the lift-off to the next world, pure presentation.
-- The server has already accepted Launch and fired Launched; this only shows it. From Play:
--   0 s       the launch music (MusicDirector.SetLaunch) and the Sounds.Launch hit (MusicDirector.Stinger, which
--             ducks the other beds), a Featured burst at the ship's base, the camera glides to the ship
--             (CameraDirector.PanTo: the director owns the camera) and the ship starts rising
--             (CampRenderer.LiftShip: Config.LaunchLiftStuds over Config.LaunchLiftSeconds, Quad In).
--   lift end  the LaunchFade ScreenGui (DisplayOrder 50, over the toasts) fades a black frame in over
--             Config.LaunchFadeSeconds with "Next stop: <world>" centred in white outlined Title text.
--   black     placeLive: stay black, the server's teleport takes over. Should nothing happen for
--             Config.LaunchHoldSeconds + Config.TeleportGraceSeconds, the camp comes back as a safety net.
--             not placeLive (Studio, or an unpublished place): hold Config.LaunchHoldSeconds, the
--             LAUNCH_NO_PLACE toast, and the camp comes back.
--   return    the ship is put back and the camera handed back while the screen is still black, then
--             the frame fades out over Config.LaunchFadeSeconds and onDone runs (the bootstrap restores
--             the HUD). IsPlaying is true from Play until onDone; a second Play meanwhile is ignored.
-- Nothing here decides anything: the server moves the player, this only draws the departure.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Toast = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Toast"))
local CameraDirector = require(script.Parent:WaitForChild("CameraDirector"))
local CampRenderer = require(script.Parent:WaitForChild("CampRenderer"))
local MusicDirector = require(script.Parent:WaitForChild("MusicDirector"))
local Vfx = require(script.Parent:WaitForChild("Vfx"))

local LaunchSequence = {}

local DISPLAY_ORDER = 50 -- above the toasts (40) and every panel
local LINE_WIDTH = 0.8 -- the "Next stop" line, in screen Scale
local LINE_HEIGHT = 0.14

local playing = false
local gui: ScreenGui? = nil
local black: Frame? = nil
local line: TextLabel? = nil
local lineStroke: UIStroke? = nil

-- Lookups ------------------------------------------------------------------

-- The next world's name from the strings table (WORLD_<id>), or the Worlds row, or the key itself.
local function worldName(worldId: number): string
	local key = "WORLD_" .. tostring(worldId)
	local text = Builder.text(key)
	if text ~= key then
		return text
	end
	local def = Worlds[worldId]
	return if def then def.name else key
end

-- The fade gui, built once and kept disabled between launches.
local function build()
	if gui then
		return
	end
	local root = Builder.screen("LaunchFade", DISPLAY_ORDER)
	root.Enabled = false
	local frame = Builder.frame({
		parent = root,
		name = "Black",
		color = Theme.Colors.Black,
		transparency = 1,
		size = UDim2.fromScale(1, 1),
	})
	local label = Builder.label({
		parent = frame,
		name = "NextStop",
		text = "",
		textSize = Theme.TextSize.Title,
		color = Theme.Colors.White,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(LINE_WIDTH, LINE_HEIGHT),
		anchor = Vector2.new(0.5, 0.5),
	})
	label.TextTransparency = 1
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 1
	end
	gui, black, line, lineStroke = root, frame, label, stroke
end

-- Steps ----------------------------------------------------------------------

-- Tweens the black frame and its line to `transparency` (0 is black) over Config.LaunchFadeSeconds and
-- yields until the frame's tween ends.
local function fade(transparency: number, direction: Enum.EasingDirection)
	local frame, label, stroke = black, line, lineStroke
	if not frame then
		return
	end
	local info = TweenInfo.new(Config.LaunchFadeSeconds, Enum.EasingStyle.Quad, direction)
	if label then
		TweenService:Create(label, info, { TextTransparency = transparency }):Play()
	end
	if stroke then
		TweenService:Create(stroke, info, { Transparency = transparency }):Play()
	end
	local tween = TweenService:Create(frame, info, { BackgroundTransparency = transparency })
	tween:Play()
	tween.Completed:Wait()
end

-- Puts the world back the way it was while the screen is still black: the ship on its slab and the
-- camera with the character (the pan has normally finished by now; Cancel covers reduced timings).
local function settle()
	CampRenderer.ResetShip()
	if CameraDirector.IsBusy() then
		CameraDirector.Cancel()
	end
end

-- Public API -------------------------------------------------------------

function LaunchSequence.IsPlaying(): boolean
	return playing
end

-- A plain fade of the LaunchFade screen for the Star Chart's Fly: to black (toBlack) or back up over
-- `seconds`, then onDone. Does nothing while a launch sequence owns the screen (onDone still runs).
function LaunchSequence.Fade(seconds: number, toBlack: boolean, onDone: (() -> ())?)
	build()
	local root, frame = gui, black
	if playing or not root or not frame then
		if onDone then
			onDone()
		end
		return
	end
	root.Enabled = true
	local info = TweenInfo.new(math.max(seconds, 0), Enum.EasingStyle.Quad, if toBlack then Enum.EasingDirection.In else Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, info, { BackgroundTransparency = if toBlack then 0 else 1 })
	tween.Completed:Once(function(state: Enum.PlaybackState)
		if state ~= Enum.PlaybackState.Completed then
			return -- a newer fade took over the frame
		end
		if not toBlack then
			root.Enabled = false
		end
		if onDone then
			onDone()
		end
	end)
	tween:Play()
end

-- Plays the departure for `nextWorldId`. With placeLive the screen stays black for the server's
-- teleport; without it the camp returns after the hold. onDone runs once the fade has lifted.
function LaunchSequence.Play(nextWorldId: number, placeLive: boolean, onDone: () -> ())
	if playing then
		return
	end
	playing = true
	build()
	local name = worldName(nextWorldId)
	local label = line
	if label then
		label.Text = Strings.LAUNCH_NEXT_STOP:format(name)
	end

	local shipAt = CampRenderer.ShipPosition()
	MusicDirector.SetLaunch(true) -- the launch cue takes the mix until the sequence ends
	MusicDirector.Stinger("Launch") -- the lift-off hit (Sounds.Launch)
	Vfx.ModuleBurst(shipAt, Theme.Colors.Featured)
	if CameraDirector.IsBusy() then
		CameraDirector.Cancel() -- the last module's pan may still be gliding; the launch takes its place
	end
	CameraDirector.PanTo(shipAt)

	CampRenderer.LiftShip(Config.LaunchLiftStuds, Config.LaunchLiftSeconds, function()
		task.spawn(function()
			local root = gui
			if root then
				root.Enabled = true
			end
			fade(0, Enum.EasingDirection.In)
			if placeLive then
				-- The teleport takes over from here; this thread dies with the place. Should the
				-- teleport never come, bring the camp back rather than leave the player in the dark.
				task.wait(Config.LaunchHoldSeconds + Config.TeleportGraceSeconds)
				print(("[%s] launch: no teleport after %d s, returning to the camp"):format(Config.WorkingTitle, Config.LaunchHoldSeconds + Config.TeleportGraceSeconds))
			else
				task.wait(Config.LaunchHoldSeconds)
				Toast.Show(Strings.LAUNCH_NO_PLACE:format(name), Theme.Colors.Featured)
			end
			settle()
			fade(1, Enum.EasingDirection.Out)
			if root then
				root.Enabled = false
			end
			playing = false
			MusicDirector.SetLaunch(false)
			onDone()
		end)
	end)
end

return LaunchSequence
