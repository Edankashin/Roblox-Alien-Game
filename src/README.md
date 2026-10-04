# Source layout (Rojo)

- `shared/` → ReplicatedStorage.Shared: `types/`, `data/` (every number), `strings/` (every string), `Theme.luau`, `Net.luau`.
- `server/` → ServerScriptService.Server: `init.server.luau` bootstrap and `Services/*.luau`.
- `client/` → StarterPlayerScripts.Client: `init.client.luau` bootstrap; HUD and screens arrive in later milestones.

Run `rojo serve` in the repo, connect the Rojo plugin in Studio, press Play, and read the Output window.
