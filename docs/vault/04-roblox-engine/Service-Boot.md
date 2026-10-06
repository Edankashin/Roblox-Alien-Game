# Service boot: nothing yields on the boot thread

The server bootstrap (`src/server/init.server.luau`) calls every service's `Init` and then every `Start` in ORDER on one thread. Anything that yields there holds every service after it, and some calls never return.

## The one that bit (milestone 41, 2026-10-06)

`Admin.Start` called `MessagingService:SubscribeAsync` inline. On a published place it answers in a moment; on an unpublished place (a Studio build of `home.project.json`, PlaceId 0) it never returns, so Dev never started and the home place looked hung with no error. The fix: the subscribe runs in `task.spawn`, and the panel's commands apply locally until it answers.

## Rules

- A network API in `Init` or `Start` (`MessagingService`, `DataStoreService`, `TeleportService`, `HttpService`, `MarketplaceService`, `TextService`) goes in its own thread with a `pcall`, and the service works without it until it answers.
- Loops (`tick` every N seconds) start with `task.spawn`, never a `while` on the boot thread. Every service here already does this; copy `Events.Start`.
- A service prints one line at `Start` so a hang shows where the Output stops (the Mac reads the last line before the silence).
- Studio's "Enable Studio Access to API Services" makes these calls real in a published place's Studio session; an unpublished scratch place still has no API, so test with the local fallback in mind.
