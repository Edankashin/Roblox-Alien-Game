--!strict
-- ReplicatedStorage.Shared.data.Props: how each imported prop (ReplicatedStorage.Models.Props.<Name>, the names in
-- data/ModelAssets.PropNames) collides. Shared/Props.Place reads it through Shared/ModelInstall.CollisionPlan and sets every
-- clone's CanCollide and every MeshPart's CollisionFidelity from it; the import never set the fidelity, so every mesh took
-- the engine's Default (X-Posts take 2, docs/vault/06-art-pipelines/Map-Dressing.md "Collision"). One row per prop, and
-- tools/lint_data.py keeps the rows and PropNames the same set with a valid value in each.
--
--   Box      decor the player never walks on or past closely: trees (the trunk and the crown are separate MeshParts, so each
--            gets its own box), the standing stone, the spire, the cone. The cheapest shape to collide with.
--   Hull     a prop the player hops onto or brushes against, where the silhouette matters: rocks (the avatar jumps 7.2 studs),
--            the pedestal, the ship pad, the wreck, the vent mound.
--   Precise  a prop with a gap to walk through, which a box or a hull would plug: the two cave mouths (an arch the player enters
--            the cave by) and the Shrine (a ring of stones round the pedestal the player walks up to). Costlier, and only on these.
--   None     purely visual: CanCollide off whatever the caller passes. The three stations stand on an invisible block that
--            keeps the collision (CampRenderer.buildStations), so the mesh on top of it must not collide twice.
-- A caller that passes `collide = false` (the heater lamp on its disc, the hangar trophy) turns collision off for any row, and
-- that part takes Box, the cheapest fidelity, since nothing touches it.
--
-- The Shrine also holds a glowing orb, the GeyserVent a steam column, the CrashWreck embers and the cave mouths crystals: those
-- slots collide with the rest of their prop today; a per-slot override would be a field on the row if it ever matters.

local Types = require(script.Parent.Parent.types.Types)

local Rows: { [string]: Types.PropRow } = {
	BuildStation = { collision = "None" },
	CaveMouth = { collision = "Precise" },
	CrashWreck = { collision = "Hull" },
	GatherStation = { collision = "None" },
	GeyserCone = { collision = "Box" },
	GeyserVent = { collision = "Hull" },
	HeaterLamp = { collision = "Box" },
	IceCaveMouth = { collision = "Precise" },
	IceRock = { collision = "Hull" },
	IceRockB = { collision = "Hull" },
	IceSpire = { collision = "Box" },
	MeadowRock = { collision = "Hull" },
	MeadowRockB = { collision = "Hull" },
	MeadowTree = { collision = "Box" },
	MeadowTreeB = { collision = "Box" },
	Pedestal = { collision = "Hull" },
	ShipHull = { collision = "Hull" },
	Shrine = { collision = "Precise" },
	ShrineStone = { collision = "Box" },
	SnowPine = { collision = "Box" },
	SparkStation = { collision = "None" },
}

return {
	Rows = Rows,
}
