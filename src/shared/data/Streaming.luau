--!strict
-- Workspace streaming (StreamingEnabled) for the phones: the numbers and the list of server containers the client scans.
-- default.project.json, home.project.json and world2.project.json carry the Workspace properties below, because Rojo cannot read
-- this table; tools/lint_data.py refuses any of the three that disagrees with it, and a MinRadius under Config.SpawnRadius or a
-- TargetRadius past the world's half diagonal (nothing further exists). The server compares the live Workspace with this table at
-- boot (Shared/StreamingMath.Mismatch) and warns if the place was not synced. Why and how: docs/vault/04-roblox-engine/Performance.md
-- "Streaming (2026-10-26)".
--
-- WHAT STREAMS AND WHAT NEVER DOES. Streamed (by distance from the character): the generated ground in Ground/Chunk_* models
-- (Default), every scattered prop (Atomic: a tree is whole or absent), the loose camp parts (floor cap, plot, spawn pad, edge walls).
-- Never streamed out (Persistent models): the Landmarks the compass reads, and the containers named under `Persistent`, which are the
-- server data the client scans by name and expects to see at any distance: Wild (the invisible spawn parts the radar, the nearby panel,
-- the tutorial and the renderers read; at most Config.SpawnMaxWild), Materials (the 16 nodes the waypoint and the node renderer read),
-- Heaters and Sightings (a few parts). They are Models, not Folders, because only a Model has a streaming mode; ModelStreamingMode
-- is set by Shared/WorldContainer.

local Streaming = {
	-- by world id (data/Worlds): the home planet is one 200 x 200 stud floor and a handful of parts, so it does not stream
	Enabled = { [0] = false, [1] = true, [2] = true } :: { [number]: boolean },
	-- studs around the character that are always loaded (the engine never shrinks below this to save memory): Config.SpawnRadius (90)
	-- is where wild aliens are placed around a player, and the camp, its plot and the ship stand inside it
	MinRadius = 128,
	-- studs around the character the engine loads when memory allows. A world is 400 x 400 studs with the camp in the middle, whose
	-- farthest corner is 283 away, so 280 reaches the whole map from the camp: a desktop loads it all, a phone loads what its memory
	-- budget allows, between the two radii
	TargetRadius = 280,
	-- Enum.StreamingIntegrityMode name: the client pauses if the character is ever outside the loaded area (a fast mount
	-- or a long fall past the minimum radius), so nobody falls through ground that has not arrived yet
	IntegrityMode = "PauseOutsideLoadedArea",
	-- server containers (Workspace.World.<name>) made as Persistent Models; Shared/WorldContainer.Get
	Persistent = { "Wild", "Materials", "Heaters", "Sightings" } :: { string },

	-- The arrival cinematic's camera flies far from the character, and the camera does not move the streaming focus: before a moment
	-- plays, the client asks the server to stream around up to this many shot positions that lie farther than MinRadius from the
	-- character (Player:RequestStreamAroundAsync), each waiting at most RequestTimeoutSeconds. Presentation only.
	CinematicRequests = 3,
	RequestTimeoutSeconds = 4,

	-- The phone budget, loaded BaseParts and memory on a low-end phone at the streamed minimum, TARGETS to verify on the Mac
	-- (Performance.md "Streaming (2026-10-26)" says how to read each in Studio): unverified until job 71 measures them.
	PhoneBudget = { Parts = 4000, DrawCalls = 1800, MemoryMB = 700 },
}

return Streaming
