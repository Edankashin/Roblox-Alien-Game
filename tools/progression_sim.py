#!/usr/bin/env python3
"""World 1 progression by days played, with every freebie, the time away and resting.

Plays the econ_sim bot (the same catch, station, gate and assembly rules as the server, free slot growth
included) in one session a day, then the rest of the day away, and adds everything the game hands out for
free, read from the data tables:
  - Welcome Week (data/Gifts): the day-N gift at the start of day N, eggs as a random World 1 alien of the tier.
  - Promo codes with no expiry (data/Codes) and the group gift (data/Social.GroupReward) on day 1.
  - The free daily spin (data/Spins.FreePerDay), rolled on the wheel's odds; a Double Shift doubles station
    income for its seconds; other power-ups and lures are counted, not applied (they make catching easier,
    not Scrap faster).
  - Daily quests (data/DailyQuests): DailyCount a day, dealt at random from the non-friend quests, claimed
    when the session lasts at least DAILY_MINUTES; weekly quests on day 7, 14, ... when the week's catches
    reach each weekly catch count (friend quests left out: a solo player).
  - Away time: offline Scrap as Economy settles it (rate x Config.OfflineRate x away, capped at
    Config.OfflineCapSeconds); assembly keeps running on the wall clock for the whole time away.
  - Resting (--rest-hours): that many hours after the session left in the game, station income x
    data/Afk.IncomeScale and assembly running, before the offline stretch.
  - Playtime gifts (--playtime, a PROPOSAL not in the game): PLAYTIME_GIFTS below, at minutes played per day.
Not modelled: the Peddler (a Scrap trade, not a gift), Catch Rush and Meteor Shower payouts (server events),
the Friend Boost, growth stages, fusion, companions, and anything bought with Robux.

Usage: python3 tools/progression_sim.py [--seeds 10] [--days 30]
       python3 tools/progression_sim.py --minutes 45 [--rest-hours 8] [--playtime] [--no-freebies]
With no --minutes it prints the standard table: four play patterns, with and without playtime gifts, plus
the regular player resting overnight.
"""
import argparse
import pathlib
import random
import statistics
import sys
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import econ_sim as E  # noqa: E402
from luau_tables import load  # noqa: E402

DATA = ROOT / "src/shared/data"
Config = E.Config
Gifts = load(DATA / "Gifts.luau")
DailyQuests = load(DATA / "DailyQuests.luau")
Spins = load(DATA / "Spins.luau")
Codes = load(DATA / "Codes.luau")["Codes"]
Social = load(DATA / "Social.luau")
Afk = load(DATA / "Afk.luau")
PowerUps = load(DATA / "PowerUps.luau")

DAY_SECONDS = 86400
DAILY_MINUTES = 15  # a session this long finishes the day's small quests (catch 5, two at night, ...)
WEEKLY_MINUTES = 30  # a player on this many minutes a day finishes every solo weekly quest
# The proposal under test (PRE_PRODUCTION decision 5c-1): minutes played today -> reward.
PLAYTIME_GIFTS = [
    (5, {"kind": "scrap", "amount": 150}),
    (10, {"kind": "lure", "id": "Lure1", "amount": 1}),
    (20, {"kind": "powerUp", "id": "SpeedBurst", "amount": 1}),
    (30, {"kind": "spin", "amount": 1}),
    (45, {"kind": "powerUp", "id": "LuckyCharm", "amount": 1}),
    (60, {"kind": "egg", "tier": "Rare", "amount": 1}),
]
WORLD1_BIOMES = E.World["biomes"]


def world1_species(tier):
    seen = []
    for biome in WORLD1_BIOMES:
        for ids in E.Spawns.get(biome, {}).values():
            for sid in ids:
                if E.Species[sid]["tier"] == tier and sid not in seen:
                    seen.append(sid)
    return seen


class DayBot(E.Bot):
    def __init__(self, rng, catch_every, freebies, playtime):
        super().__init__(rng, catch_every, Config["StationStartSlots"])
        self.freebies = freebies
        self.playtime = playtime
        self.income_scale = 1.0
        self.double_until = -1
        self.ledger = defaultdict(float)  # where Scrap came from
        self.items = defaultdict(int)  # (kind, id) granted for free
        self.week_catches = 0
        self.done_day = {}  # module id -> day it finished
        self.day = 0
        self.minutes = 0
        self.active_seconds = 0

    # income --------------------------------------------------------------
    def income(self):
        mult = self.income_scale * (PowerUps["DoubleShift"]["value"] if self.clock.t < self.double_until else 1)
        amount = self.rate() * mult
        self.ledger["stations (playing)"] += amount
        return amount

    def try_catch(self):
        before, scrap = len(self.aliens), self.scrap
        super().try_catch()
        self.ledger["catches"] += self.scrap - scrap
        if len(self.aliens) > before:
            self.week_catches += 1

    def finish_module(self, mdef, t):
        self.done_day[mdef["id"]] = self.day
        super().finish_module(mdef, t)

    # free rewards --------------------------------------------------------
    def grant(self, source, reward):
        kind, amount = reward["kind"], reward.get("amount", 1)
        if kind == "scrap":
            self.scrap += amount
            self.ledger["free: " + source] += amount
        elif kind == "spin":
            for _ in range(amount):
                self.spin(source)
        elif kind == "egg":
            for _ in range(amount):
                self.egg(source, reward["tier"])
        else:
            self.items[(kind, reward.get("id"))] += amount
            if kind == "powerUp" and reward.get("id") == "DoubleShift":
                self.double_until = max(self.double_until, self.clock.t) + PowerUps["DoubleShift"]["seconds"] * amount

    def spin(self, source):
        self.items[("spin", None)] += 1
        segments = Spins["Segments"]
        r = self.rng.uniform(0, sum(s["odds"] for s in segments))
        for segment in segments:
            r -= segment["odds"]
            if r < 0:
                self.grant(source + " spin", segment["reward"])
                return

    def egg(self, source, tier):
        self.items[("egg", tier)] += 1
        pool = world1_species(tier)
        if not pool:
            return
        species = self.rng.choice(pool)
        overlay = self.roll_overlay()
        self.aliens.append((species, overlay))
        if species not in self.codex:
            self.codex.add(species)
            self.scrap += E.Tiers["Tiers"][tier]["codexScrap"]
            self.ledger["free: " + source + " (egg codex)"] += E.Tiers["Tiers"][tier]["codexScrap"]
        self.seat(species, overlay)

    def start_of_day(self, minutes):
        if not self.freebies:
            return
        for row in Gifts:
            if row["day"] == self.day:
                self.grant("Welcome Week", row["reward"])
        if self.day == 1:
            for code in sorted(Codes):
                if Codes[code]["expiresAt"] == 0:
                    for reward in Codes[code]["rewards"]:
                        self.grant("codes", reward)
            for reward in Social["GroupReward"]:
                self.grant("group gift", reward)
        for _ in range(Spins["FreePerDay"]):
            self.spin("daily free")
        if minutes >= DAILY_MINUTES:
            solo = [q for q in DailyQuests["Daily"] if q["objective"]["kind"] != "catchWithFriend"]
            for quest in self.rng.sample(solo, DailyQuests["DailyCount"]):
                for reward in quest["rewards"]:
                    self.grant("daily quests", reward)

    def end_of_week(self):
        if not self.freebies:
            return
        # A player on at least WEEKLY_MINUTES a day finishes every solo weekly quest; below that, only the
        # catch count (checked) and the daily-claims one (five days of dailies) count.
        for quest in DailyQuests["Weekly"]:
            objective = quest["objective"]
            if objective["kind"] == "catchWithFriend":
                continue
            done = self.minutes >= WEEKLY_MINUTES
            if objective["kind"] == "catchCount":
                done = self.week_catches >= objective["count"]
            elif objective["kind"] == "dailyClaims":
                done = self.minutes >= DAILY_MINUTES
            if done:
                for reward in quest["rewards"]:
                    self.grant("weekly quests", reward)
        self.week_catches = 0

    # time away -----------------------------------------------------------
    def assemble_for(self, seconds):
        # Wall-clock assembly while not playing: only a module whose gates are paid moves.
        if self.module_index >= len(E.Modules) or not self.module["started"]:
            return
        mdef = E.Modules[self.module_index]
        self.module["progress"] += self.assembly_speed(mdef["job"]) / mdef["assemblySeconds"] * seconds
        if self.module["progress"] >= 1:
            if len(self.blocked) <= self.module_index:
                self.blocked.append({"scrap": 0, "key": 0, "assembly": 0, "done_at": None, "start": self.clock.t})
            self.finish_module(mdef, self.clock.t)

    def away(self, seconds, rest_seconds):
        rest = min(rest_seconds, seconds)
        if rest > 0:
            gain = self.rate() * Afk["IncomeScale"] * rest
            self.scrap += gain
            self.ledger["resting in game"] += gain
            self.assemble_for(rest)
        offline = seconds - rest
        if offline >= Config["OfflineMinSeconds"]:
            gain = self.rate() * Config["OfflineRate"] * min(offline, Config["OfflineCapSeconds"])
            self.scrap += gain
            self.ledger["offline"] += gain
        self.assemble_for(offline)

    # one day -------------------------------------------------------------
    def play_day(self, minutes, rest_hours):
        self.day += 1
        self.minutes = minutes
        self.node_ready = {}  # a day away respawns every node
        self.warden_next_try = 0
        self.busy_until = self.clock.t
        self.start_of_day(minutes)
        gifts = list(PLAYTIME_GIFTS) if self.playtime else []
        session_end = self.clock.t + int(minutes * 60)
        started = self.clock.t
        while self.clock.t < session_end and self.module_index < len(E.Modules):
            while gifts and (self.clock.t - started) >= gifts[0][0] * 60:
                self.grant("playtime gifts", gifts.pop(0)[1])
            self.step()
            self.clock.tick()
        self.active_seconds += self.clock.t - started
        if self.day % 7 == 0:
            self.end_of_week()
        if self.module_index < len(E.Modules):
            self.away(DAY_SECONDS - minutes * 60, rest_hours * 3600)

    def run_days(self, minutes, rest_hours, days):
        while self.day < days and self.module_index < len(E.Modules):
            self.play_day(minutes, rest_hours)
        return self


def run(minutes, rest_hours, playtime, freebies, seeds, days, catch_every):
    bots = [DayBot(random.Random(seed), catch_every, freebies, playtime).run_days(minutes, rest_hours, days) for seed in range(seeds)]
    finished = [b for b in bots if b.module_index >= len(E.Modules)]
    launch_day = statistics.median(b.day for b in finished) if len(finished) * 2 > len(bots) else None
    hours = statistics.median(b.active_seconds / 3600 for b in finished) if len(finished) * 2 > len(bots) else None
    per_module = {}
    for mdef in E.Modules:
        got = [b.done_day[mdef["id"]] for b in bots if mdef["id"] in b.done_day]
        per_module[mdef["id"]] = statistics.median(got) if len(got) * 2 > len(bots) else None
    ledger = defaultdict(list)
    for b in bots:
        for key in set(b.ledger) | {"stations (playing)"}:
            ledger[key].append(b.ledger.get(key, 0))
    items = defaultdict(list)
    for b in bots:
        for key, count in b.items.items():
            items[key].append(count)
    return {
        "launch_day": launch_day, "hours": hours, "finished": len(finished), "bots": len(bots),
        "modules": per_module, "ledger": {k: statistics.median(v) for k, v in ledger.items()},
        "items": {k: sum(v) / len(bots) for k, v in items.items()},
    }


def fmt_day(day):
    return "not in time" if day is None else f"day {day:g}"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--minutes", type=float, help="minutes played per day (one session); omit for the standard table")
    ap.add_argument("--rest-hours", type=float, default=0, help="hours left resting in the game after each session")
    ap.add_argument("--playtime", action="store_true", help="add the proposed playtime gifts")
    ap.add_argument("--no-freebies", action="store_true", help="leave out every free reward")
    ap.add_argument("--seeds", type=int, default=10)
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--catch-every", type=float, default=30)
    args = ap.parse_args()

    if args.minutes is not None:
        r = run(args.minutes, args.rest_hours, args.playtime, not args.no_freebies, args.seeds, args.days, args.catch_every)
        print(f"{args.minutes:g} min/day, rest {args.rest_hours:g} h, playtime gifts {'on' if args.playtime else 'off'}, freebies {'off' if args.no_freebies else 'on'}: "
              f"World 1 launched {fmt_day(r['launch_day'])} ({r['finished']}/{r['bots']} runs), {r['hours'] or 0:.1f} h played")
        for mid, day in r["modules"].items():
            print(f"  {mid}: {fmt_day(day)}")
        total = sum(r["ledger"].values())
        print("  Scrap by source (median per run, until launch or the day limit):")
        for key, value in sorted(r["ledger"].items(), key=lambda kv: -kv[1]):
            print(f"    {key}: {value:,.0f} ({value / total:.0%})" if total else f"    {key}: 0")
        print("  Free items (mean per run): " + ", ".join(f"{k[0]} {k[1] or ''}".strip() + f" {v:.1f}" for k, v in sorted(r["items"].items(), key=lambda kv: str(kv[0]))))
        return

    patterns = [("Casual", 20, 0), ("Regular", 45, 0), ("Regular, rests 8 h overnight", 45, 8), ("Engaged", 120, 0), ("Marathon", 480, 0)]
    print(f"World 1 to launch, one session a day, median of {args.seeds} runs (catch every {args.catch_every:g} s)\n")
    print("| Player | Minutes a day | Launch day, no freebies | Launch day, today's freebies | Hours played | Launch day, + playtime gifts | Hours played | Free Scrap share |")
    print("|---|---|---|---|---|---|---|---|")
    for name, minutes, rest in patterns:
        bare = run(minutes, rest, False, False, args.seeds, args.days, args.catch_every)
        now = run(minutes, rest, False, True, args.seeds, args.days, args.catch_every)
        gifts = run(minutes, rest, True, True, args.seeds, args.days, args.catch_every)
        total = sum(now["ledger"].values())
        free = sum(v for k, v in now["ledger"].items() if k.startswith("free"))
        print(f"| {name} | {minutes:g} | {fmt_day(bare['launch_day'])} | {fmt_day(now['launch_day'])} | {now['hours'] or 0:.1f} | "
              f"{fmt_day(gifts['launch_day'])} | {gifts['hours'] or 0:.1f} | {free / total:.0%} |")


if __name__ == "__main__":
    main()
