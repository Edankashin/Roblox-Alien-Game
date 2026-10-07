--!strict
-- StarterPlayerScripts.Client.UI.CinematicBars: the letterbox bars and the Skip button of a cinematic moment
-- (CameraDirector.PlayShots), pure presentation. One ScreenGui "Cinematic" (DisplayOrder 35: over the HUD, the panels and
-- the Reveal, under the toasts at 40 and the launch fade at 50) holds two black frames, one hugging the top edge and one
-- the bottom, that slide in to Cinematics.Letterbox.barHeight of the screen over Letterbox.fadeSeconds and slide out the
-- same way, and a chunky Skip button (string SKIP, the button's own click sound) at the lower right above the bottom
-- bar, hidden until ShowSkip. Everything is Scale. The director owns the timing: Show when a moment starts, ShowSkip
-- Cinematics.SkipAfterSeconds later, Hide when the camera is handed back; Hide with nothing shown does nothing. The
-- button only calls the callback Show was given; ending the moment is the director's job.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Cinematics = require(Shared:WaitForChild("data"):WaitForChild("Cinematics"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent:WaitForChild("Builder"))

local CinematicBars = {}

local DISPLAY_ORDER = 35
local SKIP_SIZE = UDim2.fromScale(0.2, 0.12) -- about 130 x 45 px on an iPhone SE held sideways
local SKIP_GAP = 0.01 -- and its bottom edge rests this far above the lower bar's top edge
local SKIP_POSITION = UDim2.fromScale(0.98, 1 - Cinematics.Letterbox.barHeight - SKIP_GAP)

local gui: ScreenGui? = nil
local topBar: Frame? = nil
local bottomBar: Frame? = nil
local skipButton: Frame? = nil
local onSkipTap: (() -> ())? = nil
local shown = false
local barsOn = false
local token = 0 -- each Show and Hide takes a number, so a finished slide-out never disables a newer Show

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Cinematic", DISPLAY_ORDER)
	root.Enabled = false
	topBar = Builder.frame({
		parent = root,
		name = "TopBar",
		color = Theme.Colors.Black,
		position = UDim2.fromScale(0, 0),
		size = UDim2.fromScale(1, 0),
	})
	bottomBar = Builder.frame({
		parent = root,
		name = "BottomBar",
		color = Theme.Colors.Black,
		position = UDim2.fromScale(0, 1),
		size = UDim2.fromScale(1, 0),
		anchor = Vector2.new(0, 1),
	})
	local button = Builder.button({
		parent = root,
		name = "Skip",
		text = Strings.SKIP,
		color = Theme.Colors.Select,
		position = SKIP_POSITION,
		size = SKIP_SIZE,
		anchor = Vector2.new(1, 1),
		zIndex = 3,
	}, function()
		local callback = onSkipTap
		if callback then
			callback()
		end
	end)
	button.Visible = false
	skipButton = button
	gui = root
end

-- Slides both bars to `height` of the screen over Letterbox.fadeSeconds.
local function slide(height: number)
	local info = TweenInfo.new(Cinematics.Letterbox.fadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, bar in ipairs({ topBar, bottomBar }) do
		if bar then
			TweenService:Create(bar, info, { Size = UDim2.fromScale(1, height) }):Play()
		end
	end
end

-- Starts the bars sliding in (when `withBars`) and remembers `onSkip` for the button, which stays hidden until ShowSkip.
function CinematicBars.Show(withBars: boolean, onSkip: (() -> ())?)
	build()
	token += 1
	shown = true
	barsOn = withBars
	onSkipTap = onSkip
	local root, button = gui, skipButton
	if root then
		root.Enabled = true
	end
	if button then
		button.Visible = false
	end
	if withBars then
		slide(Cinematics.Letterbox.barHeight)
	end
end

-- Makes the Skip button appear (a pop). Nothing happens when no moment is shown or none gave a callback.
function CinematicBars.ShowSkip()
	local button = skipButton
	if not shown or onSkipTap == nil or not button then
		return
	end
	button.Visible = true
	Builder.pop(button)
end

-- Slides the bars out, hides the button at once, and switches the gui off when the slide ends.
function CinematicBars.Hide()
	if not shown then
		return
	end
	shown = false
	onSkipTap = nil
	token += 1
	local mine = token
	local button = skipButton
	if button then
		button.Visible = false
	end
	if not barsOn then
		local root = gui
		if root then
			root.Enabled = false
		end
		return
	end
	barsOn = false
	slide(0)
	task.delay(Cinematics.Letterbox.fadeSeconds, function()
		local root = gui
		if root and token == mine then
			root.Enabled = false
		end
	end)
end

return CinematicBars
