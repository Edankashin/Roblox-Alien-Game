--!strict
-- ReplicatedStorage.Shared.LaunchLatch: the hold the camp draws behind while the ship lifts off. Pure logic, no
-- Roblox types; CampRenderer owns one (the headless spec runs the same module).
--
-- Why it exists: the server moves the profile to the next world the moment a launch is accepted and pushes the
-- new world and its empty modules at once (Launched first, then WorldChanged and ModulesChanged). The camp is drawn
-- from that mirror, so the push rebuilt the camp for the next world in the same frame the lift began: the rising
-- ship was destroyed, its tweens cancelled and the fade started at once. The latch closes before the lift starts;
-- a state offered while it is closed is not drawn but remembered (the newest replaces the older one, since each
-- state is the whole picture the mirror holds by then); opening it hands back that newest state once, to be drawn
-- while the screen is black.
--
-- Begin closes the latch (closing a closed one changes nothing, the pending state stays). Offer(state) answers the
-- state to draw now, or nil when it was held back. Release opens the latch and answers the pending state, or nil when
-- nothing was held back or the latch was already open.

local LaunchLatch = {}

export type Latch<T> = {
	Begin: () -> (),
	IsHeld: () -> boolean,
	Offer: (state: T) -> T?,
	Release: () -> T?,
}

function LaunchLatch.new<T>(): Latch<T>
	local held = false
	local pending: T? = nil
	local latch: Latch<T> = {
		Begin = function()
			held = true
		end,
		IsHeld = function(): boolean
			return held
		end,
		Offer = function(state: T): T?
			if not held then
				return state
			end
			pending = state
			return nil
		end,
		Release = function(): T?
			held = false
			local last = pending
			pending = nil
			return last
		end,
	}
	return latch
end

return LaunchLatch
