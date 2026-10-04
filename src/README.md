# Source layout (Rojo)

- `shared/` → ReplicatedStorage.Shared: `types/`, `data/` (every number), `strings/` (every string), `Theme.luau`, `Net.luau`, `Capture.luau` (ticker math shared by server and client).
- `server/` → ServerScriptService.Server: `init.server.luau` bootstrap and `Services/*.luau`.
- `client/` → StarterPlayerScripts.Client: `init.client.luau` bootstrap, `UI/` (Builder, Hud, CaptureBar, Reveal) and `World/WildRenderer.luau`.

Run `rojo serve` in the repo, connect the Rojo plugin in Studio, press Play, and read the Output window.
