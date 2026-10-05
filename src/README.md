# Source layout (Rojo)

- `shared/` → ReplicatedStorage.Shared: `types/`, `data/` (every number, including `Camp.luau` for the camp layout), `strings/` (every string), `Theme.luau`, `Net.luau`, `Capture.luau` (ticker math shared by server and client), `Economy.luau` (work speed, station rates, assembly progress; shared so the client extrapolates exactly what the server computes), `Biomes.luau` (which biome a point is in).
- `server/` → ServerScriptService.Server: `init.server.luau` bootstrap and `Services/*.luau` (PlayerData, WorldClock, Meadow, Materials, Spawner, Economy, Catching).
- `client/` → StarterPlayerScripts.Client: `init.client.luau` bootstrap, `State.luau` (the profile mirror fed by server pushes), `UI/` (Builder, Hud, Screens, CaptureBar, Reveal, Toast, ShipScreen, AliensScreen, CodexScreen, NearbyPanel) and `World/` (WildRenderer, CampRenderer, NodeRenderer).

Run `rojo serve` in the repo, connect the Rojo plugin in Studio, press Play, and read the Output window. Test scripts per milestone are in `docs/TESTING.md`.
