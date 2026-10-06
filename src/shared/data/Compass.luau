--!strict
-- The compass strip (docs/GAME_DESIGN.md "Compass strip", UI Playbook "Event banner and compass"): a thin
-- band at the top centre of the HUD with the cardinal letters, tick marks, the heading in a small pill, and
-- a coloured diamond per marker that is in front of the camera, plus one line under it naming the marker
-- the player is heading for and its distance. It pulls players across the map toward the things the
-- world builder stands far away (the shrine, a cave mouth, the Peddler's ship). Pure presentation: the
-- client reads positions it already renders. Every number here, never in code.

export type MarkerKind = "camp" | "landmark" | "peddler" | "waypoint" | "target"

export type Marker = {
	id: string,
	kind: MarkerKind, -- camp: the ship; landmark: a LandmarkId under Workspace.World.Landmarks; peddler: the visiting ship;
	-- waypoint: the tutorial or Field Notes marker (World/Waypoint); target: the alien marked from the radar
	landmarkId: string?, -- for kind landmark
	labelKey: string, -- strings key for the line under the strip
	color: string, -- Theme.Colors or Theme.Rarity key for the diamond
	minDistance: number, -- hidden when the player is closer than this (studs), so the marker is not in your face
	maxDistance: number, -- hidden when farther than this; 0 means never hidden by distance
	priority: number, -- lower wins the line under the strip when several markers are shown
}

local Markers: { Marker } = {
	{ id = "waypoint", kind = "waypoint", labelKey = "COMPASS_WAYPOINT", color = "Featured", minDistance = 6, maxDistance = 0, priority = 1 },
	{ id = "target", kind = "target", labelKey = "COMPASS_TARGET", color = "Select", minDistance = 6, maxDistance = 0, priority = 2 },
	{ id = "peddler", kind = "peddler", labelKey = "COMPASS_PEDDLER", color = "Featured", minDistance = 14, maxDistance = 0, priority = 3 },
	{ id = "camp", kind = "camp", labelKey = "COMPASS_CAMP", color = "Confirm", minDistance = 30, maxDistance = 0, priority = 4 },
	{ id = "shrine", kind = "landmark", landmarkId = "Shrine", labelKey = "COMPASS_SHRINE", color = "Legendary", minDistance = 20, maxDistance = 0, priority = 5 },
	{ id = "cave", kind = "landmark", landmarkId = "CaveMouth", labelKey = "COMPASS_CAVE", color = "Codex", minDistance = 20, maxDistance = 0, priority = 6 },
	{ id = "icecave", kind = "landmark", landmarkId = "IceCaveMouth", labelKey = "COMPASS_ICECAVE", color = "Codex", minDistance = 20, maxDistance = 0, priority = 6 },
	{ id = "vent", kind = "landmark", landmarkId = "GreatVent", labelKey = "COMPASS_VENT", color = "Close", minDistance = 20, maxDistance = 0, priority = 7 },
}

return {
	Markers = Markers,
	FieldOfViewDegrees = 180, -- the strip shows bearings within this much of the camera's heading (90 each side)
	UpdateSeconds = 0.05, -- how often the markers and the heading are re-placed (20 times a second is smooth enough for a strip)
	EdgeFade = 0.15, -- a marker within this fraction of the strip's end fades toward transparent
	MarkerFadeMax = 0.6, -- the most a marker fades at the very edge
	LabelHoldSeconds = 0.5, -- the line under the strip keeps its marker this long before switching, so it does not flicker between two at equal distance
	TickEveryDegrees = 15, -- a tick mark this often between the letters
	MajorTickEveryDegrees = 45,
	SameSpotStuds = 1, -- a target this close to the waypoint's point is the same thing: one diamond, not two
}
