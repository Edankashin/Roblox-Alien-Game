--!strict
-- Radar tiers (docs/GAME_DESIGN.md section 6): the free Nearby panel, then Scrap-bought tiers. Mk1 is the minimap;
-- Mk2 (milestone 40) widens it, shows a Secret-tier alien in range as a "???" ping with a heartbeat that quickens as
-- the player nears it (Mk1 shows nothing for a secret: nothing is told), and lists in the Nearby panel the rares of
-- this biome that are not out right now with the condition they need. Mk3 waits on World 3. Every number here.
return {
	[0] = { name = "Nearby Panel", range = 0, scrap = 0 },
	[1] = { name = "Radar Mk1", range = 120, scrap = 1500, unlock = "FieldNotes2" },
	[2] = { name = "Radar Mk2", range = 250, scrap = 8000, unlock = "World2" },
	[3] = { name = "Radar Mk3", range = 10000, scrap = 25000, unlock = "World3" },
	Mk2 = {
		Tier = 2, -- the radar tier from which the secret ping and the absent-rares list are shown
		SecretPingFarSeconds = 1.2, -- heartbeat interval at the edge of the range
		SecretPingNearSeconds = 0.4, -- heartbeat interval within SecretNearStuds
		SecretNearStuds = 20,
		SecretPulseScale = 1.5, -- the "???" ping swells to this on each beat
		AbsentRows = 3, -- Nearby panel rows given to rares not out right now (after the present species, within MAX rows)
		AbsentMinTier = "Rare", -- only species of this tier and up are listed as absent
	},
}
