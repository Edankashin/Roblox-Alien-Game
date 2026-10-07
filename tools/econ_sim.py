#!/usr/bin/env python3
"""World 1 economy sanity check (docs/PRE_PRODUCTION.md section 3.3).

Runs a bot through World 1 using the real data tables (Config, Tiers, Species, Spawns, Modules,
KeyMaterials, Overlays, Jobs) and the same rules the server implements: tier roll by share, species by
biome and condition, auto-assign to one slot per station, Scrap per second from work speed, three gates
per module, assembly at player speed plus the matching station's crew. Reports the time each module
completes and how long the bot was blocked by Scrap, by key material, or by assembly.

Usage: python3 tools/econ_sim.py [--catch-every 30] [--slots 1] [--seeds 20]
"""
import argparse
import pathlib
import random
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from luau_tables import load  # noqa: E402

DATA = ROOT / "src/shared/data"
Config = load(DATA / "Config.luau")
Tiers = load(DATA / "Tiers.luau")
Species = {s["id"]: s for s in load(DATA / "Species.luau")["List"]}
Spawns = load(DATA / "Spawns.luau")["Biomes"]
Modules = load(DATA / "Modules.luau")["Worlds"][0]
KeyMaterials = load(DATA / "KeyMaterials.luau")
Overlays = load(DATA / "Overlays.luau")
Jobs = load(DATA / "Jobs.luau")
World = load(DATA / "Worlds.luau")[1]  # World 1's row by id (row 0 is the home place); weather.normal plus weather.special

TRAVEL_SECONDS = 40        # walking between biomes
CAPTURE_SECONDS = 8        # one capture encounter, start to reveal
COLLECT_SECONDS = 10       # walking node to node inside a biome
GOOD_HIT_RATE = 0.9        # the bot lands Good or Perfect on this share of sweeps
PERFECT_RATE = 0.15        # share of catches that land Perfect (pays Config.PerfectScrapMultiplier x catch Scrap)
NODES = {"WreckPlate": 6, "Glowroot": 4, "CaveCrystal": 3, "StormShard": 3}
WARDEN_ATTEMPT_SUCCESS = 0.4
WARDEN_COOLDOWN = 900
TRACE = False


def work_speed(species_id, overlay):
    tier = Tiers["Tiers"][Species[species_id]["tier"]]
    return tier["workSpeed"] * Overlays["Overlays"][overlay]["multiplier"]


class Clock:
    """Day/night and weather exactly as WorldClock: Rain wins over Night over Day."""

    def __init__(self, rng):
        self.rng = rng
        self.t = 0
        self.weather_until = 0
        self.weather = "Clear"
        self.roll_weather()

    def roll_weather(self):
        special = World["weather"]["special"]
        if self.weather != special["id"] and self.rng.random() < special["chance"]:
            self.weather = special["id"]
        else:
            choices = [w for w in World["weather"]["normal"] if w != self.weather] or World["weather"]["normal"]
            self.weather = self.rng.choice(choices)
        self.weather_until = self.t + self.rng.uniform(Config["WeatherMinSeconds"], Config["WeatherMaxSeconds"])

    def tick(self):
        self.t += 1
        if self.t >= self.weather_until:
            self.roll_weather()

    @property
    def is_night(self):
        return (self.t % (Config["DaySeconds"] + Config["NightSeconds"])) >= Config["DaySeconds"]

    @property
    def condition(self):
        if self.weather == World["weather"]["special"]["id"]:
            return self.weather
        return "Night" if self.is_night else "Day"


class Bot:
    def __init__(self, rng, catch_every, slots):
        self.rng = rng
        self.catch_every = catch_every
        self.clock = Clock(rng)
        self.scrap = 0.0
        self.aliens = []            # (species, overlay)
        self.codex = set()
        self.stations = {job: [] for job in Jobs["Order"]}
        self.slots = slots
        self.inventory = {}
        self.biome = "Meadow"
        self.busy_until = 0
        self.node_ready = {}        # (material, index) -> time available again
        self.module_index = 0
        self.module = {"scrapPaid": 0, "keyPaid": 0, "progress": 0.0, "started": False}
        self.module_start = 0
        self.blocked = []           # per module: dict(scrap, key, assembly, done_at)
        self.warden_ready_at = None
        self.warden_next_try = 0
        self.epic_in_rain = False
        self.log = []

    # camp --------------------------------------------------------------
    def rate(self):
        return sum(Config["BaseScrapPerSecond"] * work_speed(s, o) for job in self.stations for (s, o) in self.stations[job])

    def assembly_speed(self, job):
        return Config["AssemblyPlayerSpeed"] + sum(work_speed(s, o) for (s, o) in self.stations[job])

    def seat(self, species, overlay):
        jobs = sorted(Species[species]["jobs"], key=lambda j: -j["level"])
        speed = work_speed(species, overlay)
        for j in jobs:
            if len(self.stations[j["job"]]) < self.slots:
                self.stations[j["job"]].append((species, overlay))
                return
        # bump the slowest worker it beats
        slowest = None
        for j in jobs:
            for entry in self.stations[j["job"]]:
                if slowest is None or work_speed(*entry) < work_speed(*slowest[1]):
                    slowest = (j["job"], entry)
        if slowest and work_speed(*slowest[1]) < speed:
            self.stations[slowest[0]].remove(slowest[1])
            self.stations[slowest[0]].append((species, overlay))
            self.seat_open_only(*slowest[1])

    def seat_open_only(self, species, overlay):
        for j in sorted(Species[species]["jobs"], key=lambda j: -j["level"]):
            if len(self.stations[j["job"]]) < self.slots:
                self.stations[j["job"]].append((species, overlay))
                return

    # catching ------------------------------------------------------------
    def roll_tier(self):
        r = self.rng.uniform(0, 100)
        acc = 0
        for tier in Tiers["Order"]:
            if tier == "Common":
                continue
            acc += Tiers["Tiers"][tier]["share"]
            if r < acc:
                return tier
        return "Common"

    def available_species(self):
        table = Spawns[self.biome]
        out = list(table.get("Any", []))
        cond = self.clock.condition
        if cond != "Any":
            out += table.get(cond, [])
        return out

    def choose_species(self, tier):
        available = self.available_species()
        order = Tiers["Order"]
        for index in range(order.index(tier), -1, -1):
            wanted = order[index]
            candidates = [s for s in available if Species[s]["tier"] == wanted]
            if candidates:
                return self.rng.choice(candidates)
        return None

    def roll_overlay(self):
        r = self.rng.uniform(0, 100)
        acc = 0
        for name in Overlays["Order"]:
            acc += Overlays["Overlays"][name]["chance"]
            if r < acc:
                return name
        return "None"

    def try_catch(self):
        species = self.choose_species(self.roll_tier())
        if not species:
            return
        tier = Tiers["Tiers"][Species[species]["tier"]]
        p_sweep = GOOD_HIT_RATE * tier["catchChance"]
        caught = any(self.rng.random() < p_sweep for _ in range(Config["CaptureSweepsPerEncounter"]))
        self.busy_until = max(self.busy_until, self.clock.t + CAPTURE_SECONDS)
        if not caught:
            return
        overlay = self.roll_overlay()
        self.aliens.append((species, overlay))
        if species not in self.codex:
            self.codex.add(species)
            self.scrap += tier["codexScrap"]
        perfect = self.rng.random() < PERFECT_RATE
        self.scrap += tier["catchScrap"] * (Config["PerfectScrapMultiplier"] if perfect else 1)
        if TRACE:
            print(f"  t={self.clock.t:5d} caught {species} ({Species[species]['tier']}, {overlay}) scrap={self.scrap:.0f} rate={self.rate():.1f} biome={self.biome} cond={self.clock.condition}")
        if Species[species]["tier"] == "Epic" and self.clock.condition == "Rain":
            self.epic_in_rain = True
        self.seat(species, overlay)

    # materials -----------------------------------------------------------
    def node_available(self, material):
        cond = KeyMaterials[material]["condition"]
        if cond not in ("Any", self.clock.condition):
            return None
        for i in range(NODES.get(material, 0)):
            if self.node_ready.get((material, i), 0) <= self.clock.t:
                return i
        return None

    def collect(self, material):
        i = self.node_available(material)
        if i is None:
            return False
        self.node_ready[(material, i)] = self.clock.t + KeyMaterials[material]["respawnSeconds"]
        self.inventory[material] = self.inventory.get(material, 0) + KeyMaterials[material]["dropCount"]
        self.busy_until = self.clock.t + COLLECT_SECONDS
        return True

    def try_warden(self):
        # Field Notes stand-in: after an Epic caught in Rain, the Warden can be fought at night.
        if not self.epic_in_rain or not self.clock.is_night or self.clock.t < self.warden_next_try:
            return False
        self.busy_until = self.clock.t + CAPTURE_SECONDS * 3
        if self.rng.random() < WARDEN_ATTEMPT_SUCCESS:
            self.inventory["WardenCore"] = 1
            self.aliens.append(("Gaiabloom", "None"))
            self.codex.add("Gaiabloom")
            self.seat("Gaiabloom", "None")
            return True
        self.warden_next_try = self.clock.t + WARDEN_COOLDOWN
        return False

    # modules -------------------------------------------------------------
    def step(self):
        t = self.clock.t
        self.scrap += self.rate()
        if self.module_index >= len(Modules):
            return
        mdef = Modules[self.module_index]
        state = self.module
        if len(self.blocked) <= self.module_index:
            self.blocked.append({"scrap": 0, "key": 0, "assembly": 0, "done_at": None, "start": t})
        block = self.blocked[self.module_index]
        material = mdef["keyMaterial"]
        needed_keys = mdef["keyCount"] - state["keyPaid"]
        # pay gates whenever possible (the bot visits the ship when it is in the Meadow)
        if self.biome == "Meadow":
            if state["scrapPaid"] < mdef["scrap"] and self.scrap >= mdef["scrap"] - state["scrapPaid"]:
                self.scrap -= mdef["scrap"] - state["scrapPaid"]
                state["scrapPaid"] = mdef["scrap"]
                if TRACE:
                    print(f"  t={t:5d} paid {mdef['id']} scrap, {self.scrap:.0f} left")
            held = self.inventory.get(material, 0)
            if needed_keys > 0 and held > 0:
                move = min(needed_keys, held)
                self.inventory[material] = held - move
                state["keyPaid"] += move
                needed_keys -= move
                if TRACE:
                    print(f"  t={t:5d} added {move} {material} to {mdef['id']} ({state['keyPaid']}/{mdef['keyCount']})")
        gates = state["scrapPaid"] >= mdef["scrap"] and state["keyPaid"] >= mdef["keyCount"]
        if gates and not state["started"]:
            state["started"] = True
        if state["started"]:
            state["progress"] += self.assembly_speed(mdef["job"]) / mdef["assemblySeconds"]
            block["assembly"] += 1
            if state["progress"] >= 1:
                block["done_at"] = t
                self.log.append((mdef["id"], t, round(self.rate(), 1), len(self.aliens)))
                if TRACE:
                    print(f"  t={t:5d} DONE {mdef['id']} (speed {self.assembly_speed(mdef['job']):.1f})")
                self.module_index += 1
                self.module = {"scrapPaid": 0, "keyPaid": 0, "progress": 0.0, "started": False}
            return
        if state["keyPaid"] < mdef["keyCount"]:
            block["key"] += 1
        elif state["scrapPaid"] < mdef["scrap"]:
            block["scrap"] += 1

        # what the bot does with its hands
        if t < self.busy_until:
            return
        want_keys = needed_keys - self.inventory.get(material, 0) > 0
        if want_keys:
            if material == "WardenCore":
                if not self.epic_in_rain and self.biome != "Meadow":
                    self.travel("Meadow")
                elif not self.try_warden():
                    self.explore()
                return
            target = KeyMaterials[material]["biome"]
            if self.biome != target:
                self.travel(target)
                return
            if not self.collect(material):
                self.explore()
            return
        if state["scrapPaid"] >= mdef["scrap"] or self.scrap >= mdef["scrap"] - state["scrapPaid"]:
            if self.biome != "Meadow":
                self.travel("Meadow")
                return
        self.explore()

    def travel(self, biome):
        self.biome = biome
        self.busy_until = self.clock.t + TRAVEL_SECONDS

    def explore(self):
        # catch at the bot's pace; prefer the biome with uncaught species when nothing else is pressing
        self.busy_until = self.clock.t + max(CAPTURE_SECONDS, self.catch_every)
        self.try_catch()

    def run(self, limit_seconds):
        while self.clock.t < limit_seconds and self.module_index < len(Modules):
            self.step()
            self.clock.tick()
        return self


def fmt(seconds):
    if seconds is None:
        return "never"
    h, m = divmod(int(seconds) // 60, 60)
    return f"{h}h{m:02d}m" if h else f"{m}m"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--catch-every", type=float, default=30, help="seconds between catch attempts while exploring")
    ap.add_argument("--slots", type=int, default=Config["StationStartSlots"], help="slots per station")
    ap.add_argument("--seeds", type=int, default=20)
    ap.add_argument("--limit-hours", type=float, default=12)
    ap.add_argument("--trace", action="store_true", help="print one run's catches and gate payments")
    args = ap.parse_args()
    global TRACE
    if args.trace:
        TRACE = True
        Bot(random.Random(0), args.catch_every, args.slots).run(int(args.limit_hours * 3600))
        TRACE = False

    runs = [Bot(random.Random(seed), args.catch_every, args.slots).run(int(args.limit_hours * 3600)) for seed in range(args.seeds)]
    print(f"World 1, one catch attempt every {args.catch_every:g}s, {args.slots} slot(s) per station, median of {args.seeds} runs\n")
    print("| Module | Done at (play time) | Blocked by key | Blocked by Scrap | Assembling | Scrap/s at done | Aliens |")
    print("|---|---|---|---|---|---|---|")
    for index, mdef in enumerate(Modules):
        done = [r.blocked[index]["done_at"] for r in runs if index < len(r.blocked) and r.blocked[index]["done_at"] is not None]
        if not done:
            print(f"| {mdef['name']} | never in {args.limit_hours:g}h | | | | | |")
            continue
        med = lambda key: statistics.median(r.blocked[index][key] for r in runs if index < len(r.blocked))  # noqa: E731
        rates = [entry[2] for r in runs for entry in r.log if entry[0] == mdef["id"]]
        aliens = [entry[3] for r in runs for entry in r.log if entry[0] == mdef["id"]]
        finished = f"{len(done)}/{len(runs)} runs" if len(done) < len(runs) else ""
        print(f"| {mdef['name']} | {fmt(statistics.median(done))} {finished} | {fmt(med('key'))} | {fmt(med('scrap'))} | {fmt(med('assembly'))} | {statistics.median(rates):.1f} | {statistics.median(aliens):.0f} |")


if __name__ == "__main__":
    main()
