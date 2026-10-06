#!/usr/bin/env python3
"""Reproducible two-world economy scenarios, reading live Luau literals only."""
from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import hashlib
import math
from pathlib import Path
import random
import statistics
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import ROOT, TableReader


@dataclass
class Alien:
    species: str
    overlay: str
    worked: float = 0.0
    level: int = 1
    size: str = "Normal"
    uid: int = 0


class Model:
    def __init__(self, root=ROOT):
        reader = TableReader()
        names = ('Config', 'Tiers', 'Species', 'Spawns', 'Modules', 'KeyMaterials',
                 'Growth', 'Sizes', 'Gifts', 'Worlds', 'Jobs', 'Overlays', 'Gear', 'Layouts',
                 'Fusion', 'Companions', 'Habitats', 'HomeBuild', 'CatchRush', 'Weekly', 'Outposts')
        self.data = {name: reader.read(root / 'src/shared/data' / f'{name}.luau') for name in names}
        self.config = self.data['Config']
        self.tiers = self.data['Tiers']['Tiers']
        self.order = list(self.data['Tiers']['Order'].values())
        self.species = self.data['Species']['ById']
        self.modules = self.data['Modules']['Worlds']
        self.materials = self.data['KeyMaterials']
        self.growth = list(self.data['Growth']['Stages'].values())
        self.jobs = list(self.data['Jobs']['Order'].values())
        self.world_ids = sorted(self.modules)
        # The card covers the two implemented module worlds, not placeholder worlds.
        if len(self.world_ids) != 2:
            raise ValueError('expected exactly two implemented module worlds')
        files = sorted(reader.cache)
        self.digest = hashlib.sha256(b''.join(p.read_bytes() for p in files)).hexdigest()[:16]

    def speed(self, alien):
        tier = self.tiers[self.species[alien.species]['tier']]
        overlay = self.data['Overlays']['Overlays'][alien.overlay]['multiplier']
        stage = self.growth[0]
        for candidate in self.growth:
            if alien.worked >= candidate['workedSeconds']:
                stage = candidate
        return tier['workSpeed'] * overlay * (1 + stage['speedBonus']) * (1 + self.config['LevelSpeedStep'] * (alien.level - 1))

    def encounter(self, species, rng):
        """60% Good, 15% Perfect per tap; Perfect wins, Good rolls catchChance."""
        tier = self.tiers[self.species[species]['tier']]
        duration, all_perfect = 0.0, True
        for _ in range(tier['rounds']):
            won = False
            for _ in range(self.config['CaptureSweepsPerEncounter']):
                # Expected first outward pass to the uniformly rolled zone center.
                mean_center = (self.config['CaptureZoneCenterMin'] + self.config['CaptureZoneCenterMax']) / 2
                duration += self.config['CaptureSweepLeadSeconds'] + mean_center / (2 * tier['tickerSpeed'])
                roll = rng.random()
                perfect = roll < 0.15
                if perfect or (roll < 0.75 and rng.random() < tier['catchChance']):
                    all_perfect = all_perfect and perfect
                    won = True
                    break
            if not won:
                return False, False, duration
        return True, all_perfect, duration + self.config['VfxCatchBurstSeconds']


class Player:
    def __init__(self, model, seed, session_minutes, daily, limit_days):
        self.m, self.c = model, model.config
        self.rng = random.Random(seed)
        self.daily = daily
        self.session = session_minutes * 60
        self.limit = limit_days * self.c['GiftDaySeconds']
        self.t = self.active = self.scrap = self.passive = 0.0
        self.next_sleep = self.session
        self.aliens = []
        self.stations = {job: [] for job in model.jobs}
        self.slots = self.c['StationStartSlots']
        self.inventory, self.codex, self.claimed = Counter(), set(), set()
        self.days_played = 1
        self.results, self.arrivals = {}, {}
        self.catches, self.attempts, self.seated = Counter(), Counter(), set()
        self.catch_counts = Counter()
        self.offline_scrap = 0
        self.fodder = self.fusions = 0
        self.entry_rates = {}
        self.entry_scrap = {}
        self.sources = Counter()

    def jobs(self, alien):
        entries = self.m.species[alien.species]['jobs'].values()
        return [row['job'] for row in sorted(entries, key=lambda row: -row['level'])
                if self.m.data['Jobs']['Jobs'][row['job']]['unlockWorld'] <= self.world]

    def seat(self, alien, open_only=False):
        jobs = self.jobs(alien)
        for job in jobs:
            if len(self.stations[job]) < self.slots:
                self.stations[job].append(alien)
                self.seated.add((self.world, self.m.species[alien.species]['tier']))
                return
        if not open_only:
            candidates = [(self.m.speed(a), job, a) for job in jobs for a in self.stations[job]]
            if candidates:
                speed, job, slow = min(candidates, key=lambda row: row[0])
                if speed < self.m.speed(alien):
                    self.stations[job].remove(slow)
                    self.seat(alien, True)
                    self.seat(slow, True)

    def optimize(self):
        # A player clicks Optimize after a slot unlock; no fusion or paid slots.
        self.stations = {job: [] for job in self.m.jobs}
        for alien in sorted(self.aliens, key=self.m.speed, reverse=True):
            self.seat(alien, True)

    def rates(self):
        speeds = {job: sum(self.m.speed(a) for a in crew) for job, crew in self.stations.items()}
        rate = sum(speeds.values()) * self.c['BaseScrapPerSecond'] * (1 + self.passive)
        assembly = self.c['AssemblyPlayerSpeed'] + speeds[self.module['job']] * (1 + self.passive)
        return rate, assembly

    def advance_weather(self):
        while self.t >= self.weather_until:
            special = self.world_data['weather']['special']
            if self.weather != special['id'] and self.rng.random() < special['chance']:
                self.weather = special['id']
            else:
                normal = list(self.world_data['weather']['normal'].values())
                self.weather = self.rng.choice([name for name in normal if name != self.weather] or normal)
            self.weather_until += self.rng.uniform(self.c['WeatherMinSeconds'], self.c['WeatherMaxSeconds'])

    def conditions(self):
        cycle = self.c['DaySeconds'] + self.c['NightSeconds']
        conditions = {'Any', 'Night' if (self.t + self.phase) % cycle >= self.c['DaySeconds'] else 'Day'}
        conditions.add(self.weather)
        if (self.t + self.shower_phase) % self.c['ShowerIntervalSeconds'] < self.c['ShowerDurationSeconds']:
            conditions.add('Shower')
        return conditions

    def snapshot(self):
        rate, _ = self.rates()
        crew = Counter(self.m.species[a.species]['tier'] for rows in self.stations.values() for a in rows)
        grown = sum(a.worked >= self.m.data['Growth']['ById']['Grown']['workedSeconds']
                    for rows in self.stations.values() for a in rows)
        return dict(wall=self.t-self.entry_t, active=self.active-self.entry_active,
                    rate=rate*60, crew=crew, grown=grown, slots=self.slots)

    def complete(self):
        module = self.module
        self.slots = min(self.c['StationMaxSlots'], max(self.slots, module.get('unlocksSlots', self.slots)))
        self.optimize()
        self.results[self.world, module['id']] = self.snapshot()
        self.module_index += 1
        self.started, self.progress = False, 0.0
        if self.module_index < len(self.module_defs):
            self.module = self.module_defs[self.module_index]
        self.claim_gifts()

    def grow(self, seconds):
        for rows in self.stations.values():
            for alien in rows:
                alien.worked += seconds

    def advance(self, seconds):
        # IncomeTickSeconds resolves growth and assembly in the same order as the server.
        remaining = seconds
        while remaining > 1e-9:
            dt = min(self.c['IncomeTickSeconds'], remaining)
            rate, speed = self.rates()
            self.scrap += rate * dt
            self.sources["stations"] += rate * dt
            self.t += dt
            self.active += dt
            if self.started:
                self.progress += speed * dt / self.module['assemblySeconds']
                if self.progress >= 1:
                    self.complete()
            self.grow(dt)
            self.advance_weather()
            remaining -= dt

    def sleep(self):
        away = self.c['GiftDaySeconds'] - self.session
        rate, speed = self.rates()
        counted = min(away, self.c['OfflineCapSeconds'])
        gain = math.floor(rate * self.c['OfflineRate'] * counted)
        self.scrap += gain
        self.offline_scrap += gain
        self.t += away
        # Only the already-started module assembles away. Gates cannot pay offline.
        completed_key = None
        if self.started:
            completed_key = (self.world, self.module['id'])
            self.progress += speed * away / self.module['assemblySeconds']
            if self.progress >= 1:
                self.complete()  # observed at rejoin, as on the server
        if self.m.data['Growth']['OfflineCountsWhileSeated']:
            self.grow(counted)
        if completed_key is not None and completed_key in self.results:
            self.results[completed_key] = self.snapshot()
        self.advance_weather()
        self.days_played += 1
        self.claim_gifts()
        self.next_sleep = self.active + self.session

    def weighted(self, rows, field):
        roll = self.rng.uniform(0, 100)
        for key, row in rows:
            roll -= row[field]
            if roll < 0:
                return key
        return None

    def grant(self, species, perfect=False):
        row = self.m.species[species]
        tier = self.m.tiers[row['tier']]
        overlay_data = self.m.data['Overlays']
        overlay = self.weighted([(name, overlay_data['Overlays'][name]) for name in overlay_data['Order'].values()], 'chance') or 'None'
        band_key = self.weighted(list(self.m.data['Sizes']['Bands'].items()), 'odds')
        band = self.m.data['Sizes']['Bands'][band_key]
        pay = math.floor(tier['catchScrap'] * band['scrapMultiplier'] + 0.5)
        self.scrap += pay * (self.c['PerfectScrapMultiplier'] if perfect else 1)
        if species not in self.codex:
            self.scrap += tier['codexScrap']
            self.codex.add(species)
        self.sources["catch"] += pay * (self.c["PerfectScrapMultiplier"] if perfect else 1)
        alien = Alien(species, overlay, size=band["id"], uid=sum(self.catch_counts.values()))
        self.aliens.append(alien)
        self.passive += tier['passive']
        self.seat(alien)
        self.catch_counts[self.world] += 1
        self.catches[self.world, row['tier']] += 1
        self.fuse(species)

    def fuse(self, species):
        data = self.m.data['Fusion']
        overlays = list(self.m.data['Overlays']['Order'].values())
        def key(a):
            rank = overlays.index(a.overlay) + 1 if a.overlay in overlays else 0
            scale = self.m.data['Sizes']['ById'][a.size]['scale']
            return (-a.level, -rank, -scale, -a.worked, str(a.uid))
        while True:
            copies = sorted((a for a in self.aliens if a.species == species), key=key)
            if len(copies) < data['DuplicatesPerLevel'] + 1:
                return
            kept = next((a for a in copies if a.level < 1 + data['MaxFusionLevels']), None)
            if kept is None:
                return
            others = [a for a in reversed(copies) if a is not kept and a.level <= kept.level]
            if len(others) < data['DuplicatesPerLevel']:
                return
            seated = {id(a) for crew in self.stations.values() for a in crew}
            if data['ConsumeRestingFirst']:
                others.sort(key=lambda a: id(a) in seated)
            consumed = others[:data['DuplicatesPerLevel']]
            consumed_ids = {id(a) for a in consumed}
            self.aliens = [a for a in self.aliens if id(a) not in consumed_ids]
            self.passive -= sum(self.m.tiers[self.m.species[a.species]['tier']]['passive'] for a in consumed)
            kept.level += 1
            self.fodder += len(consumed)
            self.fusions += 1
            if consumed_ids & seated:
                self.optimize()

    def claim_gifts(self):
        # Day-one Scrap is deliberately held for the first module payoff.
        if not self.results:
            return
        for gift in self.m.data['Gifts'].values():
            if gift['day'] > self.days_played or gift['day'] in self.claimed:
                continue
            reward = gift['reward']
            if reward['kind'] == 'scrap':
                self.scrap += reward['amount']
            elif reward['kind'] == 'egg':
                candidates = [sid for sid, row in self.m.species.items()
                              if row['world'] == self.world and row['tier'] == reward['tier']]
                if candidates:
                    self.grant(self.rng.choice(candidates))
            # Lures, powers and spins are banked, not consumed in this baseline.
            self.claimed.add(gift['day'])

    def travel(self, target):
        regions = self.layout['Regions']
        def point(biome):
            row = regions.get(biome, {})
            return row.get('x', 0), row.get('z', 0)
        x, z = point(self.biome)
        tx, tz = point(target)
        self.advance(math.hypot(tx-x, tz-z) / self.m.data['Gear']['BaseWalkSpeed'])
        self.biome = target

    def choose_species(self):
        conditions = self.conditions()
        table = self.m.data['Spawns']['Biomes'][self.biome]
        available = [sid for condition, ids in table.items() if condition in conditions for sid in ids.values()]
        weights = {name: self.m.tiers[name]['share'] for name in self.m.order if name != 'Common'}
        if 'Shower' in conditions:
            weights['Cosmic'] += self.c['ShowerCosmicShare']
        weights['Common'] = max(0, 100 - sum(weights.values()))
        rolled = self.weighted([(name, {'share': weights[name]}) for name in self.m.order], 'share') or 'Common'
        for name in reversed(self.m.order[:self.m.order.index(rolled)+1]):
            candidates = [sid for sid in available if self.m.species[sid]['tier'] == name]
            if candidates:
                return self.rng.choice(candidates)
        raise ValueError(f'no available spawn in {self.biome}')

    def catch(self, warden=False):
        if not warden:
            ready = min(self.spawn_ready)
            if ready > self.t:
                self.advance(min(ready-self.t, self.c['SpawnTickSeconds']))
                return
        species = self.world_data['warden'] if warden else self.choose_species()
        spawn_conditions = self.conditions()
        won, perfect, seconds = self.m.encounter(species, self.rng)
        self.attempts[self.world] += 1
        if not warden:
            slot = self.spawn_ready.index(min(self.spawn_ready))
            self.spawn_ready[slot] = self.t + seconds + self.rng.uniform(self.c['SpawnRespawnMinSeconds'], self.c['SpawnRespawnMaxSeconds'])
            seconds += self.c['SpawnRadius'] / math.sqrt(self.c['SpawnDensityTarget']) / self.m.data['Gear']['BaseWalkSpeed']
        self.advance(seconds)
        if won:
            self.grant(species, perfect)
            if species == self.world_data['weather']['special']['speciesId'] and self.world_data['weather']['special']['id'] in spawn_conditions:
                self.special_caught = True
            if warden:
                self.inventory[self.module['keyMaterial']] += self.m.materials[self.module['keyMaterial']]['dropCount']
        elif warden:
            self.warden_retry = self.t + self.c['WardenRetreatSeconds']

    def step(self):
        if self.daily and self.active >= self.next_sleep:
            self.sleep()
            return
        material = self.module['keyMaterial']
        definition = self.m.materials[material]
        need_keys = not self.started and self.inventory[material] < self.module['keyCount']
        if not self.started and not need_keys and self.scrap >= self.module['scrap']:
            if self.biome != self.base:
                self.travel(self.base)
                return
            self.scrap -= self.module['scrap']
            self.inventory[material] -= self.module['keyCount']
            self.started = True
        if need_keys:
            target = definition['biome']
            if self.biome != target:
                self.travel(target)
                return
            if definition['nodes'] == 0:
                if self.special_caught and 'Night' in self.conditions() and self.t >= self.warden_retry:
                    self.catch(warden=True)
                    return
            elif definition['condition'] in self.conditions():
                ready = self.nodes[material]
                if min(ready) <= self.t:
                    index = ready.index(min(ready))
                    ready[index] = self.t + definition['respawnSeconds']
                    self.advance(self.layout['NodeMinSeparation'] / self.m.data['Gear']['BaseWalkSpeed'] + self.c['IncomeTickSeconds'])
                    self.inventory[material] += definition['dropCount']
                    return
        self.catch()
        if not need_keys:
            self.travel(self.biomes[(self.biomes.index(self.biome)+1) % len(self.biomes)])

    def run(self):
        for world in self.m.world_ids:
            self.world = world
            self.world_data = self.m.data['Worlds'][world]
            self.layout = self.m.data['Layouts'][world]
            self.biomes = list(self.m.data['Spawns']['LiveBiomes'][world].values())
            self.base = self.biome = self.layout['BaseBiome']
            self.module_defs = list(self.m.modules[world].values())
            self.module_index, self.module = 0, self.module_defs[0]
            self.started, self.progress = False, 0.0
            self.entry_t, self.entry_active = self.t, self.active
            self.arrivals[world] = self.t
            self.weather = self.world_data['weather']['normal'][1]
            self.weather_until = self.t + self.rng.uniform(self.c['WeatherMinSeconds'], self.c['WeatherMaxSeconds'])
            self.phase = self.rng.uniform(0, self.c['DaySeconds'] + self.c['NightSeconds'])
            self.shower_phase = self.rng.uniform(0, self.c['ShowerIntervalSeconds'])
            self.spawn_ready = [self.t] * self.c['SpawnDensityTarget']
            self.nodes = {name: [self.t]*row['nodes'] for name, row in self.m.materials.items() if row['world'] == world and row['nodes']}
            self.special_caught, self.warden_retry = False, self.t
            self.entry_scrap[world] = self.scrap
            self.entry_rates[world] = self.rates()[0] * 60
            self.optimize()  # World 2 carries the real inventory/crew/slots from World 1.
            while self.module_index < len(self.module_defs) and self.t < self.limit:
                self.step()
            if self.module_index < len(self.module_defs):
                break
        return self


def median(rows):
    return statistics.median(rows) if rows else math.inf


def summary(players, world, module, field):
    # Missing completions remain infinity: never silently report survivor medians.
    return median([p.results.get((world, module), {}).get(field, math.inf) for p in players])


def fmt(number):
    return 'not reached' if not math.isfinite(number) else f'{number:.1f}'


def report(model, continuous, daily, args):
    c = model.config
    lines = ['# Economy balance report', '',
             f'Generated by `python3 tools/balance.py --runs {args.runs} --session-minutes {args.session_minutes:g} --limit-days {args.limit_days:g}`. Input fingerprint: `{model.digest}`.', '',
             '## Scope and assumptions', '',
             f'Medians over {args.runs} reproducible seeds (0 through {args.runs-1}), running World 1 then World 2. World 2 inherits aliens, growth, unlocked slots, leftover Scrap and claimed gifts. Table times restart at entry to each world; offline wall time includes the absence. The comparison is continuous play versus one {args.session_minutes:g}-minute active session per day followed by an absence of {c["GiftDaySeconds"]/60-args.session_minutes:g} minutes. A session finishes its current action before leaving. Results are scenario estimates, not measured player telemetry.', '',
             f'Catch inputs: 60% Good, 15% Perfect and 25% Miss per sweep. Good rolls each tier’s catchChance; Perfect succeeds. Each round has {c["CaptureSweepsPerEncounter"]} tries and all rounds must win. Each tap takes CaptureSweepLeadSeconds plus the mean zone-center travel time on the outward triangle wave. Catch reveal uses VfxCatchBurstSeconds. Walking uses Gear.BaseWalkSpeed and layout region centers; local search distance is SpawnRadius / sqrt(SpawnDensityTarget). Density/respawn timers cap supply. This omits manual decision time and collision/pathfinding, so it is an optimistic movement model.', '',
             'Spawn tiers follow shares with Common as the remainder, falling back down the ladder when the current biome/conditions have no species. Day/night, special-weather chance/duration (no consecutive special weather), shower windows, size odds, half-up catch payouts, first-catch codex rewards, overlays, passive income, growth and module slot unlocks use live tables. The player optimizes seating after module completions and on entering a world, otherwise uses server-style newcomer replacement. Fusion runs after every catch using the same level-first ranking, size/worked-time tie breaks, cap and resting-first fodder rule as Economy. No paid boosts, friends, pity/luck bonuses, seasonal events or spending on shop goods. The additional-system snapshot below is reported separately from progression, without double-counting its income.', '',
             f'Offline Scrap uses the departure rate × {c["OfflineRate"]:g} × min(away, {c["OfflineCapSeconds"]:g}s); worked time is capped the same way. Only an already-paid module assembles offline at departure speed, and its completion is observed on rejoin. New gates require active play. Day-one gift Scrap is claimed after the first module; later Scrap gifts and eggs are claimed on eligible rejoin days. Lure/power/spin gifts are banked without use, consistent with fixed hit rates and no buffs.', '',
             'Key nodes use live conditions, counts, drops and respawns. **Quest-core approximation:** the final core requires catching the special-weather signature, then winning the actual multi-round warden encounter at night; failed attempts use WardenRetreatSeconds. The full ordered Field Notes/crafting/reward circuit is not simulated. This can materially understate endgame time; treat results as an economy floor, not a launch forecast. Worlds placeId=0 is ignored for this hypothetical progression scenario.', '',
             f'All unfinished runs count as infinity in medians after a {args.limit_days:g}-day horizon. Input tables: Config, Tiers, Species, Spawns, Modules, KeyMaterials, Growth, Sizes, Gifts, Worlds, Jobs, Overlays, Gear, Layouts (including Meadow/Frostbyte), Fusion, Companions, Habitats, HomeBuild, CatchRush, Weekly and Outposts, parsed by C2’s TableReader. No data is changed.', '']
    outliers = []
    for world in model.world_ids:
        rows = list(model.modules[world].values())
        lines += [f'## World {world} — {model.data["Worlds"][world]["name"]}', '',
                  '| Module | Scrap needed | Active-play minutes (continuous) | Wall minutes (daily offline) | Active minutes in daily scenario | Continuous Scrap/min at completion | Daily Scrap/min at rejoin/completion |',
                  '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
        for row in rows:
            key = row['id']
            values = [summary(continuous, world, key, 'active')/60, summary(daily, world, key, 'wall')/60,
                      summary(daily, world, key, 'active')/60, summary(continuous, world, key, 'rate'), summary(daily, world, key, 'rate')]
            lines.append(f'| {row["name"]} | {row["scrap"]:,} | ' + ' | '.join(fmt(x) for x in values) + ' |')
        last = rows[-1]['id']
        complete = sum((world, last) in p.results for p in continuous)
        complete_daily = sum((world, last) in p.results for p in daily)
        lines += ['', f'Completed: continuous {complete}/{len(continuous)}; daily {complete_daily}/{len(daily)}. Rates include growth and camp passives; each value is a marginal median, not one selected run.', '',
                  '| Tier | Configured wild share % | Caught mix % (continuous, pooled) | Median final seats (continuous / daily) |',
                  '| --- | ---: | ---: | ---: |']
        catch_total = sum(p.catch_counts[world] for p in continuous)
        for tier in model.order:
            share = model.tiers[tier]['share'] if tier != 'Common' else 100-sum(model.tiers[t]['share'] for t in model.order if t != 'Common')
            count = sum(p.catches[world, tier] for p in continuous)
            def seats(players):
                return median([p.results.get((world, last), {}).get('crew', {}).get(tier, 0) for p in players])
            lines.append(f'| {tier} | {share:g} | {100*count/max(1, catch_total):.2f} | {seats(continuous):g} / {seats(daily):g} |')
            if not any((world, tier) in p.seated for p in continuous+daily):
                reason = 'zero-share/quest-only availability, not proof of weak work speed' if share == 0 else 'stronger carried/replacement crew; a sampled result, not impossibility'
                outliers.append((0, f'World {world}: {tier} never seats in either sampled scenario ({reason}).'))
        elapsed = sum(p.results[world, last]['active'] for p in continuous if (world, last) in p.results)
        finished = [p for p in continuous if (world, last) in p.results]
        attempts = sum(p.attempts[world] for p in finished)
        catches = sum(p.catch_counts[world] for p in finished)
        grown = summary(daily, world, last, 'grown')
        lines += ['', f'Measured continuous pace: {60*attempts/max(1,elapsed):.2f} encounters/min and {60*catches/max(1,elapsed):.2f} catches/min including walking, material collection and waiting. Final daily-scenario crew with Grown-or-later worked time: median {fmt(grown)}. Slots per station at successive completions: ' + ', '.join(f'{row["id"]} {summary(continuous, world, row["id"], "slots"):g}' for row in rows) + '.', '']
        for previous, current in zip(rows, rows[1:]):
            ratio = current['scrap']/previous['scrap']
            if ratio > 3:
                outliers.append((ratio, f'World {world}: {current["name"]} needs {ratio:.2f}× the previous module’s Scrap ({previous["scrap"]:,} → {current["scrap"]:,}).'))
            previous_time = summary(continuous, world, previous['id'], 'active')
            current_time = summary(continuous, world, current['id'], 'active')
            ratio_time = current_time/previous_time if previous_time > 0 else math.inf
            if ratio_time > 3:
                outliers.append((ratio_time, f'World {world}: cumulative time to {current["name"]} is {ratio_time:.2f}× the previous completion ({previous_time/60:.2f} → {current_time/60:.2f} minutes).'))
    lines += ['## Outliers', '']
    for _, text in sorted(outliers, key=lambda row: -row[0]):
        lines.append('- ' + text)
    w1, w2 = model.world_ids
    first = list(model.modules[w1].values())[0]
    last = list(model.modules[w1].values())[-1]
    first_minutes = summary(continuous, w1, first['id'], 'active')/60
    ship_minutes = summary(continuous, w1, last['id'], 'active')/60
    daily_ship = summary(daily, w1, last['id'], 'wall')/60
    ratios_scrap = [b['scrap']/a['scrap'] for a,b in zip(model.modules[w1].values(),model.modules[w2].values())]
    ratios_assembly = [b['assemblySeconds']/a['assemblySeconds'] for a,b in zip(model.modules[w1].values(),model.modules[w2].values())]
    ratios_match = all(math.isclose(n, 1.6) for n in ratios_scrap) and all(math.isclose(n, 1.5) for n in ratios_assembly)
    lines += ['', '## Comparison with the plan and suggested review', '',
              f'The first module takes {fmt(first_minutes)} active minutes: ' + ('inside' if first_minutes < 5 else 'outside') + ' the five-minute target. World 1’s ship takes ' + f'{fmt(ship_minutes)} continuous minutes, equivalent to {fmt(ship_minutes/args.session_minutes)} {args.session_minutes:g}-minute sessions before offline gains; the daily scenario takes {fmt(daily_ship)} wall minutes. Compare the plan’s “few sessions” and 2–3-hour target with this optimistic floor before retuning.', '',
              f'World 2’s per-module Scrap ratios are {", ".join(f"{n:g}×" for n in ratios_scrap)} and assembly ratios are {", ".join(f"{n:g}×" for n in ratios_assembly)}. The live tables {"match" if ratios_match else "do not match"} the 1.6× Scrap / 1.5× assembly target. Completion times need not scale by those factors: the carried crew, slots, growth, savings and the weather/core gates change throughput.', '',
              'Suggested coordinator review: validate the early cost jumps against first-session telemetry; compare the complete Field Notes path with the core proxy before lowering any final-module cost; check whether carried crew/savings make World 2’s opening too short; inspect zero-seat tiers separately from ordinary crew replacement. Keep live balance unchanged until a cold playtest supplies search/decision time and quest pacing.', '']
    return '\n'.join(lines)


def extended_report(model, players, daily, args):
    import copy
    data, c = model.data, model.config
    day, hour = c['GiftDaySeconds'], 3600
    lines = ['\n## C7: additional systems and source concentration', '',
             'Progression above now includes immediate fusion. The following is a **steady-state snapshot at the second launch**, not additional money injected into those progression times. Station rate is the median final rate; catches use each run’s measured total catch Scrap / active hours. Select one median-strength resting alien per available first job as followers (up to Config.CompanionSlots), then three remaining same-world resting aliens for a habitat. Missing eligible copies leave slots empty. Fixed Good/Perfect rates mean zone/luck/radar perks are reported but not converted into guessed catch-rate improvements. Income from visitors, quests, seasonal tracks, paid items and consumed spins remains excluded.', '',
             f'Median fusions: **{median([p.fusions for p in players]):g}**; median consumed copies: **{median([p.fodder for p in players]):g}**; median share of all caught copies consumed: **{median([100*p.fodder/max(1,sum(p.catch_counts.values())) for p in players]):.1f}%**. Each fusion spends {data["Fusion"]["DuplicatesPerLevel"]} copies, capped at level {1+data["Fusion"]["MaxFusionLevels"]}; passive bonuses of consumed aliens are removed.', '',
             '| Growth stage | Seated hours | Speed bonus |', '| --- | ---: | ---: |']
    for stage in model.growth:
        lines.append(f'| {stage["id"]} | {stage["workedSeconds"]/hour:g} | {100*stage["speedBonus"]:g}% |')
    perks, habitat_rates = [], []
    habitat_count = next(row['capacity'] for row in data['HomeBuild']['Items'].values() if row['kind'] == 'habitat')
    for p in players:
        seated = {id(a) for crew in p.stations.values() for a in crew}
        resting = [a for a in p.aliens if id(a) not in seated]
        followers = []
        totals = Counter()
        for job in model.jobs[:c['CompanionSlots']]:
            group = sorted((a for a in resting if model.species[a.species]['jobs'][1]['job'] == job), key=lambda a:(model.speed(a),a.uid))
            if group:
                chosen = group[len(group)//2]
                followers.append(chosen)
                perk = data['Companions']['PerkByJob'][job]
                totals[perk['kind']] += perk['amount']*data['Companions']['TierFactor'][model.species[chosen.species]['tier']]
        perks.append({kind:min(totals[kind], cap) for kind,cap in data['Companions']['PerkCap'].items()})
        follower_ids = {id(a) for a in followers}
        eligible = sorted((a for a in resting if id(a) not in follower_ids and model.species[a.species]['world'] == model.world_ids[0]), key=lambda a:(model.speed(a),a.uid))
        middle = max(0, (len(eligible)-habitat_count)//2)
        shown = eligible[middle:middle+habitat_count]
        habitat_rates.append(sum(data['Habitats']['ScrapPerHourByTier'][model.species[a.species]['tier']] for a in shown))
    lines += ['', f'Companions: up to **{c["CompanionSlots"]}** resting followers. Median capped perk sums: ' + ', '.join(f'{kind} **{100*median([p[kind] for p in perks]):g}%**' for kind in sorted(data['Companions']['PerkCap'])) + '.', '',
              f'| Habitat tier ({habitat_count} displayed) | Scrap/hour | Scrap/day at cap |', '| --- | ---: | ---: |']
    for tier, rate in data['Habitats']['ScrapPerHourByTier'].items():
        lines.append(f'| {tier} | {rate*habitat_count:g} | {rate*habitat_count*min(day,data["Habitats"]["CollectCapSeconds"])/hour:g} |')
    rush = data['CatchRush']
    cycle = math.lcm(int(rush['IntervalSeconds']),int(c['ShowerIntervalSeconds']))
    starts = range(0,cycle,int(rush['IntervalSeconds']))
    runs = sum(not rush['SkipDuringShower'] or t % c['ShowerIntervalSeconds'] >= c['ShowerDurationSeconds'] for t in starts)
    rounds_hour = runs*hour/cycle
    reward = lambda rows:sum(row['amount'] for row in rows.values() if row['kind']=='scrap')
    lines += ['', f'Catch Rush: **{rounds_hour:g} eligible rounds/hour**, counting epoch-aligned starts and skipping those inside a Shower. Assumes at least {rush["MinCatches"]} catch and a stable rank each eligible round. Spins remain non-Scrap inventory.', '', '| Rank | Scrap/round | Scrap/hour |', '| --- | ---: | ---: |']
    for rank, rows in rush['Rewards'].items():
        lines.append(f'| {rank} | {reward(rows):g} | {reward(rows)*rounds_hour:g} |')
    participation = reward(rush['Participation'])
    lines.append(f'| Participation | {participation:g} | {participation*rounds_hour:g} |')
    lines += ['', f'Weekly drop: **{100*data["Weekly"]["SpawnChance"]:g}%** of spawn attempts in its world while that drop is current; the table below reports spawn allocation, not a guaranteed caught fraction. No independent Scrap grant is attached to the weekly system.', '', '| Rotation species | World | Limited | Spawn share |', '| --- | ---: | --- | ---: |']
    for row in data['Weekly']['Rotation'].values():
        lines.append(f'| {row["species"]} | {row["worldId"]} | {row["limited"]} | {100*data["Weekly"]["SpawnChance"]:g}% |')
    lines += ['', '| Outpost level (per away world) | Scrap/hour | Scrap/day at cap | Materials/day at cap |', '| --- | ---: | ---: | ---: |']
    outpost_hours = min(day,data['Outposts']['CollectCapSeconds'])/hour
    for level,row in data['Outposts']['Levels'].items():
        lines.append(f'| {level} | {row["scrapPerHour"]:g} | {row["scrapPerHour"]*outpost_hours:g} | {row["materialsPerHour"]*outpost_hours:g} |')
    station_hour = median([p.rates()[0]*hour for p in players])
    catch_hour = median([p.sources['catch']*hour/p.active for p in players])
    companion_hour = median([p.sources['catch']*hour/p.active*perk['catchScrap'] for p,perk in zip(players,perks)])
    habitat = median(habitat_rates)
    outpost = data['Outposts']['Levels'][1]['scrapPerHour'] # one level-one away world while based on World 2
    active = {'Stations':station_hour,'Catches (base)':catch_hour,'Companion catch bonus':companion_hour,
              'Habitats':habitat,'Catch Rush participation':participation*rounds_hour,'One level-one outpost':outpost}
    offline = {'Stations':station_hour*c['OfflineRate']*min(day,c['OfflineCapSeconds'])/hour,
               'Catches (base)':0,'Companion catch bonus':0,'Habitats':habitat*min(day,data['Habitats']['CollectCapSeconds'])/hour,
               'Catch Rush participation':0,'One level-one outpost':outpost*outpost_hours}
    lines += ['', 'Source concentration scenario: based on World 2, one away World 1 outpost at level one; habitat and outpost totals assume eventual collection. Active and full-day-away figures are alternative scenarios, not additive. Snapshot station income already includes fusion/growth/passives; their bonuses are not counted again. Catch Rush uses participation; rank alternatives are above.', '',
              '| Source | Scrap/active hour | Active share | Scrap/full day away | Offline share | >30% flag |', '| --- | ---: | ---: | ---: | ---: | --- |']
    for name in active:
        a,b=active[name]/sum(active.values()),offline[name]/sum(offline.values())
        flags=[]
        if a > .30: flags.append('active')
        if b > .30: flags.append('offline')
        lines.append(f'| {name} | {active[name]:.1f} | {100*a:.1f}% | {offline[name]:.1f} | {100*b:.1f}% | {", ".join(flags) or "—"} |')
    # Fit only the report's copied model. Use representative seeds for a bounded offline tool runtime.
    w1,w2=model.world_ids
    last1=list(model.modules[w1].values())[-1]['id'];last2=list(model.modules[w2].values())[-1]['id']
    target=summary(players,w1,last1,'active')*1.5
    carried=median([p.entry_rates[w2] for p in players])
    costs=[r['scrap'] for r in model.modules[w2].values()]
    # Increasing income-time budgets smooth the opening; carried savings pay only the first gate.
    weights=list(range(1,len(costs)+1))
    shares=[v/sum(weights) for v in weights]
    carried_scrap=median([p.entry_scrap[w2] for p in players])
    proposal=copy.deepcopy(model)
    def apply(minutes):
        pool=carried*minutes
        for index,(row,share) in enumerate(zip(proposal.modules[w2].values(),shares)):
            row['scrap']=max(1,round(pool*share + (carried_scrap if index == 0 else 0)))
    low,high=0.0,target/60*16
    calibration=min(3,args.runs)
    for _ in range(7):
        mid=(low+high)/2;apply(mid)
        trial=[Player(proposal,seed,args.session_minutes,False,args.limit_days).run() for seed in range(calibration)]
        if summary(trial,w2,last2,'active') < target: low=mid
        else: high=mid
    apply((low+high)/2)
    proposed=[Player(proposal,seed,args.session_minutes,False,args.limit_days).run() for seed in range(args.runs)]
    total=summary(proposed,w2,last2,'active')
    lines += ['', '## Proposed World 2 curve (not applied)', '',
              f'Live fusion-aware World 1 completion **{target/1.5/60:.1f} min**; World 2 **{summary(players,w2,last2,"active")/60:.1f} min**. Target **{target/60:.1f} min** (1.5× World 1). Carried median station income is **{carried:.1f} Scrap/min**. Proposed cost pool = that carried income × **{(low+high)/2:.2f} income-minutes**, distributed in increasing weights 1 through the module count, plus **{carried_scrap:.0f} carried Scrap** on the first gate so savings do not erase the opening; assembly and every other data value remain live. Seven bisection steps on {calibration} seeds fit the cost pool, then all {args.runs} seeds validate the fit on the full sample (which includes those calibration seeds).', '',
              '| Module | Live Scrap | Proposed Scrap | Live cumulative minutes | Proposed cumulative minutes |', '| --- | ---: | ---: | ---: | ---: |']
    for live,new in zip(model.modules[w2].values(),proposal.modules[w2].values()):
        lines.append(f'| {live["name"]} | {live["scrap"]:,} | {new["scrap"]:,} | {summary(players,w2,live["id"],"active")/60:.1f} | {summary(proposed,w2,new["id"],"active")/60:.1f} |')
    lines += ['', f'Validated proposal: **{total/60:.1f} min**, **{total/(target/1.5):.2f}× World 1** ({100*(total/target-1):+.1f}% from target). This is a cold-playtest candidate, not an approved balance change. The largest uncertainty remains the unmodeled ordered Field Notes route and human search/decision time; automated fusion is also an optimistic choice. Default sample count is {args.runs} to keep the full simulation plus proposal fit below the ten-second tooling budget on this Mac.', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runs', type=int, default=11)
    parser.add_argument('--session-minutes', type=float, default=30)
    parser.add_argument('--limit-days', type=float, default=7)
    parser.add_argument('--output', type=Path, default=ROOT/'docs/vault/01-game-design/Balance-Report.md')
    args = parser.parse_args()
    model = Model()
    if args.runs < 1 or not 0 < args.session_minutes*60 < model.config['GiftDaySeconds'] or args.limit_days <= 0:
        parser.error('use positive runs/horizon and a session shorter than one day')
    continuous = [Player(model, seed, args.session_minutes, False, args.limit_days).run() for seed in range(args.runs)]
    daily = [Player(model, seed, args.session_minutes, True, args.limit_days).run() for seed in range(args.runs)]
    content = report(model, continuous, daily, args) + extended_report(model, continuous, daily, args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content)
    print(content, end="")
    return 0


if __name__ == '__main__':
    sys.exit(main())
