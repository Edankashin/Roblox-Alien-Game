#!/usr/bin/env python3
"""Inventory frame connections and estimate data-derived scene/particle budgets; report only.

Connection discovery is lexical; loop/call-path descriptions are reviewed annotations.
Unknown connections are explicitly flagged for review. No Studio or network access.
"""
from pathlib import Path
import argparse
import hashlib
import math
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import ROOT, TableReader, uncomment

BUDGET_PARTS = 4000
BUDGET_PARTICLES = 2000
BUDGET_LOOP = 200
CONNECT = re.compile(r'\b(RenderStepped|Heartbeat|Stepped)\s*:\s*Connect\s*\(')


def report(root=ROOT, players=8):
    reader = TableReader()
    def data(name):
        return reader.read(root / 'src/shared/data' / (name + '.luau'))
    sources = {p.relative_to(root).as_posix(): uncomment(p.read_text())
               for p in sorted((root / 'src').rglob('*.luau'))}
    def const(path, name):
        match = re.search(r'\blocal\s+' + re.escape(name) + r'\s*=\s*([\d.]+)\b', sources[path])
        if not match:
            raise ValueError(f'Review required: missing numeric constant {path}:{name}')
        return float(match[1])
    def loc(path, needle):
        source = sources[path]
        at = source.find(needle)
        if at < 0:
            raise ValueError(f'Review required: missing evidence {path}:{needle}')
        return f'{path}:{source.count(chr(10), 0, at) + 1}'
    cfg, layouts, camp = data('Config'), data('Layouts'), data('Camp')
    comp, hb, habitats = data('Companions'), data('HomeBuild'), data('Habitats')
    weather, spawns, nodes = data('Weather'), data('Spawns'), data('KeyMaterials')
    modules, jobs, sight = data('Modules')['Worlds'], data('Jobs'), data('Sightings')
    compass, spins = data('Compass'), data('Spins')
    wild = players * cfg['SpawnDensityTarget']
    followers = players * comp['MaxSlots']
    drawn = min(followers, comp['MaxRendered'])
    workers = len(camp['Stations']) * cfg['StationMaxSlots']
    displays = hb['Caps']['habitat'] * max(row.get('capacity') or 0 for row in hb['Items'].values())
    max_nodes = max(sum(row['nodes'] for row in nodes.values() if row['world'] == wid) for wid in layouts)
    max_modules = max(map(len, modules.values()))
    max_biome = max(sum(len(ids) for ids in row.values()) for row in spawns['Biomes'].values())
    cp = 'src/client/World/CompanionRenderer.luau'
    wp = 'src/client/World/WildRenderer.luau'
    init = 'src/client/init.client.luau'
    compass_path = 'src/client/UI/Compass.luau'
    ticks = sum(b % const(compass_path, 'CARDINAL_STEP') != 0
                for b in range(0, int(const(compass_path, 'FULL_TURN')), int(compass['TickEveryDegrees']))) + 4
    # Values describe each pass, not a misleading sum of unlike loops.
    annotations = {
        'World/CompanionRenderer.luau': (f'{players} owners; {followers} follower records checked, at most {drawn} visible moved/raycast',
            'Grows with players; MaxSlots per owner, MaxRendered for drawing only',
            f'every frame; culling every {const(cp, "EVALUATE_SECONDS"):g}s',
            'YES every active frame: excluded={} and GetPlayers(); culling allocates drawn/candidates/rows',
            'Cache character/folder exclusions on membership changes; reuse culling buffers.'),
        'World/HomeRenderer.luau': (f'up to {displays} displayed aliens for ONE viewed home', 'Data cap; not multiplied by visitors',
            'every frame at home', 'No recurring table allocation found in onRender/placeDisplay', 'Keep habitat caps; profile imported models.'),
        'World/SightingRenderer.luau': ('1 live Warden record', 'Server single active sighting', 'every frame',
            'YES on trail steps: dropPuff creates two tween-property tables, Part and light',
            'Pool trail parts/lights and reuse immutable tween goals.'),
        'World/CampRenderer.luau': (f'up to {workers} seated workers', 'One local camp; station count × StationMaxSlots',
            'every frame', 'No recurring table allocation found', 'Keep worker cap; profile mesh PivotTo cost.'),
        'World/WildRenderer.luau': (f'S tracked spawns; density scenario {wild}; Blizzard also S × H heater tests on evaluation',
            f'Grows with records; H up to {players * cfg["HeaterMaxActive"]} active heaters; NO hard S cap',
            f'every frame; visibility every {const(wp, "EVALUATE_SECONDS"):g}s',
            'YES at Blizzard evaluation: GetChildren() + one heater record per heater',
            'Bound global spawns and skip hidden/distant bob/PivotTo; cache heater membership.'),
        'World/NodeRenderer.luau': (f'0 at home, {max_nodes} material records per wild world', 'Data node sum',
            'every frame', 'No recurring table allocation found', 'Keep count data-driven; distance-cull if expanded.'),
        'init.client.luau': (f'nearest wild S ({wild} scenario), nodes ≤{max_nodes}; ship modules ≤{max_modules}; home displays ≤{displays}',
            'Wild grows; other passes data-bounded',
            f'action {const(init, "ACTION_POLL_SECONDS"):g}s, ship {const(init, "SHIP_POLL_SECONDS"):g}s, biome {const(init, "BIOME_POLL_SECONDS"):g}s, shower {const(init, "SHOWER_POLL_SECONDS"):g}s',
            'Polling callback; no unconditional per-frame table-building loop found', 'Share nearest-target index with wild/radar scans.'),
        'UI/PeddlerScreen.luau': ('1 countdown label', 'Fixed', 'countdown every ' + str(const('src/client/UI/PeddlerScreen.luau', 'REFRESH_SECONDS')) + 's while open',
            'No recurring table-building loop found', 'Keep timer gated.'),
        'UI/NearbyPanel.luau': (f'≤{max_biome} biome species entries across condition lists; display rows capped',
            'Data-bounded; reads Spawns lists, not live wild records', f'every {cfg["NearbyRefreshSeconds"]:g}s',
            'YES on poll: temporary ids/seen/absent/condition tables', 'Reuse scratch buffers; refresh on biome/weather/codex changes.'),
        'UI/GiftsScreen.luau': (f'{len(spins["Segments"])} wheel labels', 'Spins.Segments fixed', 'every frame only during spin',
            'No recurring table-building loop found', 'Keep temporary connection disconnected after spin.'),
        'UI/Compass.luau': (f'{ticks} ticks/letters + {len(compass["Markers"])} markers', 'Data-bounded passes',
            f'every {compass["UpdateSeconds"]:g}s', 'Existing shown tables cleared/reused', 'Keep marker count bounded.'),
        'UI/CodexScreen.luau': ('1 selected model/part', 'Fixed; grid is not rotated each frame', 'every frame while open',
            'No recurring table-building loop found', 'Keep rotation limited to selected detail.'),
        'UI/ShipScreen.luau': (f'≤{max_modules} module rows and their button children', 'Module count fixed; UI children source-built',
            f'every {const("src/client/UI/ShipScreen.luau", "REFRESH_SECONDS"):g}s while open',
            'YES on poll: recolorButton calls GetChildren()', 'Cache button text descendants when rows are built.'),
        'UI/Reveal.luau': ('1 reveal model', 'Fixed', 'every frame while reveal model exists',
            'No recurring table-building loop found', 'Keep connection teardown on close.'),
        'UI/Radar.luau': (f'S wild children ({wild} scenario), pooled blips at retained high-water count', 'Grows with spawns/blips',
            f'heading every frame; blips every {cfg["RadarRefreshSeconds"]:g}s; ping pass on beat',
            'YES on poll: GetChildren(); YES on beat: one tween goal table per visible secret ping',
            'Cache wild membership; reuse ping animation objects; trim oversized idle blip pool.'),
        'UI/CaptureBar.luau': ('1 ticker, fixed zone positions and countdown', 'Fixed', 'every frame while capture active',
            'No recurring table-building loop found', 'Keep fixed-size capture updates.'),
    }
    connections = []
    for path, source in sorted(sources.items()):
        if not path.startswith(('src/client/', 'src/server/')):
            continue
        for m in CONNECT.finditer(source):
            key = path.removeprefix('src/client/')
            note = annotations.get(key, ('UNKNOWN', 'REVIEW', 'REVIEW', 'REVIEW', 'Inspect callback and add reviewed annotation.'))
            connections.append((f'{path}:{source.count(chr(10), 0, m.start()) + 1}', m[1], *note))
    digest = hashlib.sha256(b''.join((root / path).read_bytes() for path in sorted(sources))).hexdigest()[:16]
    lines = ['# Performance budget inventory', '',
        'Regenerate: `python3 -I tools/perf_report.py --write` (default eight players; `--players N` changes the scenario).', '',
        f'Inputs: all src Luau (fingerprint `{digest}`); Layouts → Home/Meadow/Frostbyte, Config, Camp, Jobs, Modules, Spawns, KeyMaterials, Companions, HomeBuild, Habitats, Weather, Sightings, Compass and Spins. Uses the C2 table reader in lint_data.py. Source constants and reviewed construction formulas supply part multipliers; no Roblox execution, assets downloaded, or game changes.', '',
        'Connection discovery scans comment-stripped source for direct event `:Connect` calls. Descriptions trace current callbacks and their helpers manually; this is not a Luau call-graph proof. New unannotated connections are flagged; changed callback behavior requires annotation review. Counts describe one client at the stated player count, not the sum across clients.', '',
        f'## Frame connections ({len(connections)})', '',
        '| Source | Event | Work / scenario | Bound | Cadence | Allocation evidence | Suggestion |',
        '| --- | --- | --- | --- | --- | --- | --- |']
    lines += ['| ' + ' | '.join(str(x).replace('|', '\\|') for x in row) + ' |' for row in connections]
    server_count = sum(row[0].startswith('src/server/') for row in connections)
    lines += ['', f'Server frame connections: **{server_count}**. Server spawning is a {cfg["SpawnTickSeconds"]:g}s task loop, not a frame connection. CameraDirector also uses RenderStepped:Wait during its camera sequence (one camera per waiting frame). WeatherFx follows sheets every {weather["FollowSeconds"]:g}s in a task loop.', '',
        '## Scene parts', '',
        'Fallback geometry scenario: no imported models, max worker slots and visible companion budget, one viewed home. BasePart counts include SpawnLocation; they exclude folders, UI, constraints and lights. The scoped estimate is not a bound on the complete live scene: avatars/accessories, imported meshes, reserved/retained spawns, heaters, hangar trophies, peddler, temporary VFX and editor additions are itemized separately below.', '',
        '| World | Trees / rocks / cones | Region patches / roofs / walls | Shrine fallback | Hero placements (import only) | Static fallback parts | Nodes | Wild density scenario | Camp parts | Visible companions | Home items + displays | Scoped parts estimate |',
        '| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
    estimates = []
    builder = 'src/server/Services/Meadow.luau'
    cone_tiers = int(const(builder, 'CONE_TIERS'))
    pads = int(const(builder, 'HANGAR_PAD_COUNT'))
    for wid, layout in sorted(layouts.items()):
        regions = layout['Regions'].values()
        trees = layout['TreeCount'] + sum(r['treeCount'] for r in regions)
        rocks = layout['RockCount'] + sum(r['rockCount'] for r in regions)
        cones = sum(r.get('coneCount') or 0 for r in regions)
        patches = len(layout['Regions'])
        roofs = sum(bool(r.get('roofHeight')) for r in regions)
        walls = sum((r.get('wallCount') or 0) for r in regions if r.get('roofHeight'))
        shrine = layout['Shrine']['stoneCount'] + 2 if wid else 0
        home_base = (1 if layout.get('PlotCells') else 0) + (pads if layout.get('HangarCenterZ') is not None else 0) + bool(layout.get('Kiosk')) + bool(layout.get('Mailbox'))
        static = 3 + trees * 2 + rocks + cones * cone_tiers + patches + roofs + walls + shrine + home_base
        node_count = sum(r['nodes'] for r in nodes.values() if r['world'] == wid)
        density = wild if wid in spawns['LiveBiomes'] else 0
        station_count = sum(job in camp['Stations'] and jobs['Jobs'][job]['unlockWorld'] <= max(1, wid) for job in jobs['Order'].values())
        module_parts = sum(r['id'] in camp['Modules'] for r in modules.get(wid, {}).values())
        camp_parts = 1 + module_parts + station_count * (1 + cfg['StationMaxSlots'])
        home_parts = (hb['Caps']['room'] + hb['Caps']['furniture'] + hb['Caps']['habitat'] * (1 + 4 * max(1, habitats['PostsPerSide'] - 1)) + displays) if wid == 0 else 0
        estimate = static + node_count + density + camp_parts + drawn + home_parts
        estimates.append((wid, estimate))
        lines.append(f'| {wid} | {trees} / {rocks} / {cones} | {patches} / {roofs} / {walls} | {shrine} | {len(layout.get("Landmarks") or {})} | {static} | {node_count} | {density} | {camp_parts} | {drawn} | {home_parts} | {estimate} |')
    trail = math.ceil(sight['SpeedStudsPerSecond'] * sight['CatchUpScale'] / sight['TrailStepStuds'] * sight['TrailLifeSeconds']) + 1
    lines += ['', f'Formula: floor + camp pad + spawn = 3; tree = trunk + leaves = 2; rock = 1; cone = {cone_tiers} tiers; region = patch + optional roof + wallCount; shrine = stoneCount + pedestal + glow. Home adds plot + {pads} pads + kiosk + mailbox. Sources: {loc(builder, "local function buildTree")}, {loc(builder, "local function buildRegion")}, {loc(builder, "local function buildShrine")}.', '',
        f'Camp = slab + module ids present in Camp.Modules + one station anchor and up to {cfg["StationMaxSlots"]} workers per unlocked job. World 2 module ids currently have no Camp.Modules entries, so its fallback module part count is zero. Home uses module world 0 here; a transitioning profile may retain a different ship. Home items use independent caps (conservative; grid packing may lower the result): room + furniture + habitat × [1 pad + 4 × (PostsPerSide−1) posts], plus {displays} displayed aliens. Only one viewed plot/camp is drawn per client.', '',
        f'Additional countable parts: up to {pads * 2} fallback trophy parts at home (hull + pilot per pad), 2 peddler ship parts while present, and during a sighting 1 server anchor + 1 client body + up to approximately {trail} trail puffs including one boundary puff, derived from ceil(speed × CatchUpScale / TrailStepStuds × TrailLifeSeconds)+1. Trail puffs also have one PointLight each. Weather and Shower each add one emitter anchor while active; fading weather sheets can overlap. Heaters add player-dependent geometry, and decorating adds a preview. None of these substitutes for measuring the imported scene.', '',
        f'**Spawn bound is unresolved.** {players} × SpawnDensityTarget({cfg["SpawnDensityTarget"]}) = {wild} is a fresh separated-player density scenario, not a cap. SpawnRadius={cfg["SpawnRadius"]}, SpawnCullDistance={cfg["SpawnCullDistance"]}; records outside density range but inside cull range persist while new ones are added. SpawnAt/reserved spawns bypass density/cull. No global record ceiling is enforced in Spawner.tick. S is therefore a runtime variable; the {BUDGET_LOOP}-item budget cannot be certified from density alone.', '',
        'Imported scenery replaces fallback trees/rocks/cones; heroes add models and can replace the shrine ring; station/ship/alien imports retain anchors. Layout data does not contain each imported model’s BasePart count. The 4,000-part test applies to the scoped fallback estimates only; the actual imported scene remains unverified. Count live Workspace descendants in an authorized Studio pass before declaring it within budget.', '',
        '## Weather and Shower particles', '',
        '| Weather sheet | Emitted / second | Max lifetime seconds | Conservative steady alive (rate × max lifetime) |',
        '| --- | ---: | ---: | ---: |']
    particle_values = []
    for name, row in sorted(weather['Sheets'].items()):
        life = max(row['lifetime'].values())
        alive = row['rate'] * life
        particle_values.append(alive)
        lines.append(f'| {name} | {row["rate"]:g} | {life:g} | {alive:g} |')
    shower_rate = cfg['VfxShowerStreaksPerSecond']
    shower_life = const('src/client/World/Vfx.luau', 'SHOWER_LIFETIME')
    shower_alive = shower_rate * shower_life
    rain = weather['Sheets']['Rain']
    rain_alive = rain['rate'] * max(rain['lifetime'].values())
    peak_rate, peak_alive = rain['rate'] + shower_rate, rain_alive + shower_alive
    lines += ['', f'Shower adds {shower_rate:g}/s × {shower_life:g}s = {shower_alive:g} alive. **Requested Shower + Rain scenario: {peak_rate:g} particles/s, approximately {math.ceil(peak_alive)} steady alive** (unrounded rate×lifetime estimate {peak_alive:g}). These sheets are local, so eight players do not multiply the count on one device.', '',
        f'Largest steady sheet + Shower = {max(particle_values) + shower_alive:g} alive. Two worst sheets overlapping on one transition + Shower give a deliberately conservative {sum(sorted(particle_values)[-2:]) + shower_alive:g}, still below {BUDGET_PARTICLES}. WeatherParticleMax={cfg["WeatherParticleMax"]} is a warning threshold, NOT an enforced clamp. Repeated forced weather changes can retain several retiring sheets; one-shots (catch/module/dust) add burst particles. Those event rates are not bounded by the weather table, so this is not a global particle ceiling.', '',
        '## Budget flags and decisions', '',
        '| Check | Result | Fix / next step |', '| --- | --- | --- |']
    for wid, estimate in estimates:
        lines.append(f'| World {wid}, >{BUDGET_PARTS} scoped parts | {"OVER" if estimate > BUDGET_PARTS else "Within scoped estimate"}: {estimate} | Measure imported models, avatars and transient instances; use mesh/LOD budgets if total exceeds limit. |')
    lines += [f'| Shower + Rain, >{BUDGET_PARTICLES} alive | {"OVER" if peak_alive > BUDGET_PARTICLES else "Within scenario"}: {math.ceil(peak_alive)} | Bound retiring sheets/bursts before claiming a global ceiling. |',
        f'| >{BUDGET_LOOP} items in one frame loop | {"OVER density scenario" if wild > BUDGET_LOOP else "Not proven exceeded in density scenario"}; actual S has no hard cap | Add a global spawn ceiling and a visible animation budget; test moving eight players. |',
        '| Recurring frame table allocation | FLAG: CompanionRenderer.refreshFilter allocates every active frame | Update and reuse the exclusion list on character/folder changes. |',
        '| Conditional frame-loop allocation | FLAG: sighting trail step and radar ping beat create tween goal tables | Pool effects/reuse goals; profile before/after. |',
        '| Polled frame-callback allocations | Advisory: companion culling, Blizzard heaters, Radar, Nearby, Ship UI | Cache membership and reuse scratch buffers; preserve current poll cadence. |',
        '| Imported full-world parts / aggregate particles | UNVERIFIED; inputs lack a global bound | Runtime instance/particle sampling with imported assets is required. |']
    for row in connections:
        if row[2] == 'UNKNOWN':
            lines.append(f'| Unknown connection | FLAG: {row[0]} | Inspect callback and update annotations. |')
    for label, count in [('companion records', followers), ('visible companions', drawn), ('workers', workers), ('home displays', displays), ('material nodes', max_nodes), ('wheel labels', len(spins['Segments'])), ('compass items', ticks + len(compass['Markers']))]:
        if count > BUDGET_LOOP:
            lines.append(f'| {label} | OVER: {count} > {BUDGET_LOOP} | Cap/time-slice this pass before increasing data counts. |')
    lines += ['', '## Top three coordinator actions', '',
        '1. Cache companion raycast exclusions; it is the clear recurring allocation on the active per-frame path.',
        '2. Enforce a global spawn/visible-animation budget. Density is not a cap; hidden wild models still receive bob/PivotTo updates, and radar/nearest-target scans grow with the same records.',
        '3. Measure the imported eight-player scene, including sighting trail lights and weather transitions, before the visual pass. Pool trail effects and set explicit imported-part/burst budgets from that measurement.', '',
        'This report makes no FPS or device-memory claim. A static count cannot establish those; no Studio session was run.', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT, help='repository root to inspect')
    parser.add_argument('--players', type=int, default=8, help='player-count scenario (default: 8; not a server cap)')
    parser.add_argument('--write', action='store_true', help='write docs/vault/04-roblox-engine/Performance.md')
    args = parser.parse_args()
    if args.players < 1:
        parser.error('--players must be positive')
    content = report(args.root, args.players)
    if args.write:
        (args.root / 'docs/vault/04-roblox-engine/Performance.md').write_text(content)
    print(content, end='')
    return 0


if __name__ == '__main__':
    sys.exit(main())
