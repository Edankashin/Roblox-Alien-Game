--!strict
-- ReplicatedStorage.Shared.data.Props: how each imported prop (ReplicatedStorage.Models.Props.<Name>, the names in
-- data/ModelAssets.PropNames) collides. Shared/Props.Place reads it through Shared/ModelInstall.CollisionPlan and sets every
-- clone's CanCollide and every MeshPart's CollisionFidelity from it; the import never set the fidelity, so every mesh took
-- the engine's Default (X-Posts take 2, docs/vault/06-art-pipelines/Map-Dressing.md "Collision"). One row per prop: every name in
-- ModelAssets.PropNames (uploaded) and every block-cell prop exported to assets/models/props/<Name>/ but not yet uploaded (Decision
-- B44; tools/blocky/export_models.py --props, the 39 spec notes in docs/vault/07-alien-game/Props/, whose `collision` this row must
-- match). tools/lint_data.py checks the set and a valid value in each. A block-cell prop is one MeshPart per colour slot (Body,
-- BodyDark, Accessory, Trim, Glow), so a tree's trunk (BodyDark) and crown (Body) still box apart.
--
--   Box      decor the player never walks on or past closely: trees (the trunk and the crown are separate MeshParts, so each
--            gets its own box), the standing stone, the spire, the cone. The cheapest shape to collide with.
--   Hull     a prop the player hops onto or brushes against, where the silhouette matters: rocks (the avatar jumps 7.2 studs),
--            the pedestal, the ship pad, the wreck, the vent mound.
--   Precise  a prop with a gap to walk through, which a box or a hull would plug: the two cave mouths (an arch the player enters
--            the cave by) and the Shrine (a ring of stones round the pedestal the player walks up to). Costlier, and only on these.
--   None     purely visual: CanCollide off whatever the caller passes. The three stations stand on an invisible block that
--            keeps the collision (CampRenderer.buildStations), so the mesh on top of it must not collide twice. Also the small
--            scatter players run through: flowers, reeds, lily pads, snow drifts and the icicle fringe.
-- A caller that passes `collide = false` (the heater lamp on its disc, the hangar trophy) turns collision off for any row, and
-- that part takes Box, the cheapest fidelity, since nothing touches it.
--
-- `slots` (Types.PropRow) overrides the collision for one colour slot of a block-cell prop, matched by the MeshPart's name
-- (ModelInstall.SlotCollision; the note's `collision_slots`, checked by tools/lint_data.py). The Starhollow Forest props
-- (Decision B48) use it: a giant glowcap's stem (BodyDark) boxes while its cap, gills, rim and moss never collide; the
-- arched bridge's deck (Body) is one walkable hull while its rails and posts (BodyDark) stay out of it (a box or a hull of
-- both rails would wall the deck in); the moon pool ring is Precise so the pool stays open; light (Glow) never collides.
--
-- The home planet's nine props (the house grid's rooms, furniture and habitats, data/HomeBuild `prop`; Decision B49) are block-cell
-- props too: a room hulls or boxes as one shape to walk round, a habitat is Precise so its pen stays open, and banners, water,
-- flowers and glow never collide.
--
-- The Shrine also holds a glowing orb, the GeyserVent a steam column, the CrashWreck embers and the cave mouths crystals: those
-- slots collide with the rest of their prop today; a per-slot override would be a field on the row if it ever matters.
--
-- `origin` (the note's frontmatter `origin`, checked by tools/lint_data.py) places a prop by another point than its mesh's bottom centre:
-- that point from it, studs at scale 1 in the spec note's axes, which Shared/Props.Place turns into the model's pivot. The camp's sights
-- signpost arms (SignArmHigh, Mid, Low; World 2's IceSignArm*) hang at their post's foot, so the layout's yaw swings each about the post;
-- the CampFlag stands by its pole. The camp pieces and the grotto crystals replaced the last block placeholders (Studio 2026-10-22).

local Types = require(script.Parent.Parent.types.Types)

local Rows: { [string]: Types.PropRow } = {
	ArchBridge = { collision = "Hull", slots = { BodyDark = "None", Accessory = "None", Glow = "None", Trim = "None" } },
	Bench = { collision = "Box", slots = { Accessory = "None" } },
	BlossomTree = { collision = "Box" },
	Boulder = { collision = "Hull" },
	BuildStation = { collision = "None" },
	Bush = { collision = "Hull" },
	CampCrate = { collision = "Box", slots = { Accessory = "None", Trim = "None" } },
	Campfire = { collision = "Box", slots = { Body = "None", Glow = "None" } },
	CampFlag = { collision = "Box", slots = { Body = "None", Accessory = "None", Glow = "None" }, origin = { -1.5, 0, 0 } },
	CaveMouth = { collision = "Precise" },
	CrashWreck = { collision = "Hull" },
	Fence = { collision = "Box" },
	Flag = { collision = "Box", slots = { Body = "None", Accessory = "None", Glow = "None" } },
	FlowerPatch = { collision = "None" },
	Fountain = { collision = "Hull", slots = { Trim = "None", Glow = "None", Accessory = "None" } },
	FrozenLog = { collision = "Hull" },
	GatherStation = { collision = "None" },
	GeyserCone = { collision = "Box" },
	GeyserVent = { collision = "Hull" },
	GlowcapGiant = { collision = "Box", slots = { Body = "None", Accessory = "None", Glow = "None", Trim = "None" } },
	GlowcapGiantBlue = { collision = "Box", slots = { Body = "None", Accessory = "None", Glow = "None", Trim = "None" } },
	GlowcapGiantPink = { collision = "Box", slots = { Body = "None", Accessory = "None", Glow = "None", Trim = "None" } },
	GlowcapSmall = { collision = "None" },
	GlowFern = { collision = "None" },
	GrottoCrystal = { collision = "Hull" },
	HabitatFrostbyte = { collision = "Precise", slots = { Accessory = "None", Trim = "None", Glow = "None" } },
	HabitatVerdant = { collision = "Precise", slots = { Accessory = "None", Trim = "None", Glow = "None" } },
	HeaterLamp = { collision = "Box" },
	IceCaveMouth = { collision = "Precise" },
	IceCrystalCluster = { collision = "Hull" },
	IceLantern = { collision = "Box" },
	IceRock = { collision = "Hull" },
	IceRockB = { collision = "Hull" },
	IceSignArmHigh = { collision = "None", origin = { -2.125, -4.375, 0 } },
	IceSignArmLow = { collision = "None", origin = { -2.125, -2.125, 0 } },
	IceSignArmMid = { collision = "None", origin = { -2.125, -3.25, 0 } },
	IceSpire = { collision = "Box" },
	Icicles = { collision = "None" },
	Lantern = { collision = "Box" },
	LilyPad = { collision = "None" },
	Log = { collision = "Hull" },
	MeadowRock = { collision = "Hull" },
	MeadowRockB = { collision = "Hull" },
	MeadowTree = { collision = "Box" },
	MeadowTreeB = { collision = "Box" },
	MoonPoolRing = { collision = "Precise", slots = { Accessory = "None", Trim = "None", Glow = "None" } },
	MoonTree = { collision = "Box", slots = { Glow = "None", Trim = "None" } },
	MoonTreeB = { collision = "Box", slots = { Glow = "None", Trim = "None" } },
	MossStone = { collision = "Hull", slots = { Glow = "None" } },
	Mushroom = { collision = "Hull" },
	PathLantern = { collision = "Box", slots = { Accessory = "None" } },
	Pedestal = { collision = "Hull" },
	Planter = { collision = "Box", slots = { Accessory = "None", Trim = "None", Glow = "None" } },
	Reeds = { collision = "None" },
	RoomCabin = { collision = "Hull", slots = { Glow = "None" } },
	RoomDome = { collision = "Hull", slots = { Glow = "None", Accessory = "None" } },
	RoomTower = { collision = "Box", slots = { Accessory = "None", Glow = "None" } },
	ShipHull = { collision = "Hull" },
	Shrine = { collision = "Precise" },
	ShrineStone = { collision = "Box" },
	SightPost = { collision = "Box", slots = { Glow = "None" } },
	SignArmHigh = { collision = "None", origin = { -2.125, -4.375, 0 } },
	SignArmLow = { collision = "None", origin = { -2.125, -2.125, 0 } },
	SignArmMid = { collision = "None", origin = { -2.125, -3.25, 0 } },
	Signpost = { collision = "Box" },
	SnowBush = { collision = "Hull" },
	SnowDrift = { collision = "None" },
	SnowPine = { collision = "Box" },
	SnowPineB = { collision = "Box" },
	SparkStation = { collision = "None" },
	StarIsland = { collision = "Hull", slots = { Glow = "None", Accessory = "None" } },
	SteppingStone = { collision = "Hull", slots = { Accessory = "None" } },
}

return {
	Rows = Rows,
}
