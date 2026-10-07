--!strict
-- StarterPlayerScripts.Client.World.Haptics: the phone (or controller) rumble, pure presentation. One pulse of the
-- Small motor through HapticService, for the Legendary opening's screen rumble (Config.LegendaryHaptic*). It does
-- nothing where the device or the platform has no vibration or no Small motor, and nothing under reduced motion
-- (Prefs.ReducedMotion: the profile toggle or the system switch), the same rule that skips the camera shake. Every
-- HapticService call runs under pcall: support differs per device and the service can refuse. A newer pulse retires
-- an older pulse's stop, so back-to-back pulses never cut each other short.

local HapticService = game:GetService("HapticService")

local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local Haptics = {}

local INPUT = Enum.UserInputType.Gamepad1 -- HapticService addresses a device by a Gamepad type; whether a phone answers here is the open device check
local MOTOR = Enum.VibrationMotor.Small
local OFF = 0

local pulseId = 0

-- Whether this device can vibrate the Small motor.
local function isSupported(): boolean
	local ok, supported = pcall(function(): boolean
		return HapticService:IsVibrationSupported(INPUT) and HapticService:IsMotorSupported(INPUT, MOTOR)
	end)
	return ok and supported == true
end

-- Vibrates for `seconds` at `strength` (0..1). Returns true when a pulse started.
function Haptics.Pulse(seconds: number, strength: number): boolean
	if Prefs.ReducedMotion() or seconds <= 0 or strength <= 0 or not isSupported() then
		return false
	end
	local started = pcall(function()
		HapticService:SetMotor(INPUT, MOTOR, math.clamp(strength, 0, 1))
	end)
	if not started then
		return false
	end
	pulseId += 1
	local mine = pulseId
	task.delay(seconds, function()
		if pulseId == mine then
			pcall(function()
				HapticService:SetMotor(INPUT, MOTOR, OFF)
			end)
		end
	end)
	return true
end

return Haptics
