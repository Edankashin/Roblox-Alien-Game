#!/usr/bin/env python3
"""Measure compact-JSON profile growth and proposed storage policies; offline, no game edits.

Inputs: ProfileSchema, Types.Profile, live data, and balance.Model/Player catch rates.
Rebuilds the reviewed schema in Python (nil fields omitted); ASCII examples avoid Unicode
encoder differences. Numbers are estimates, not a replacement for Studio JSONEncode.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from luau_tables import load
from balance import Model, Player

ROOT = Path(__file__).resolve().parents[1]
LIMIT = 4194304
STAMP = 1800000000  # fixed ten-digit illustrative timestamp, not a game setting
UID = '00000000-0000-0000-0000-000000000000'


def size(value):
    return len(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode())


def template(config, jobs, settings):
    period = lambda: dict(period='', ids=[], progress={}, claimed={}, rerolls=0)
    return dict(version=15, scrap=0, aliens={},
        stations={job: dict(slots=config['StationStartSlots'], assigned=[]) for job in jobs['Order']},
        modules={}, world=dict(current=1, unlocked=[1], outposts={}), codex={},
        gear=dict(boots=False, hoverboard=False, glider=False, radar=0), companions=[], companionSlots=0,
        home=dict(unlocked=False, visits=0, items={}, habitatSettled=0, mail=[], visitors=[], waves=dict(day=0, sent=0, got=0)),
        quests=dict(daily=period(), weekly=period(), fieldNotes={}, progress={}),
        gifts=dict(daysPlayed=0, claimed={}, lastPlayDay=0), spins=dict(free=1, banked=0, lastFree=0), luck=dict(pity=0),
        purchases={}, shop=dict(receipts={}), buffs={}, inventory=dict(keyMaterials={}, lures={}, powerUps={}, items={}),
        stats=dict(catches=0, perfects=0, playSeconds=0), settings={r['key']:r['default'] for r in settings['Order']},
        tutorialStep=1, social=dict(sessions=0, groupClaimed=False, referredBy=0, referralClaimed=False, referralsRewarded=0, notifyAskedAt=0),
        codes={}, seasons={}, tutorialCounter=0, lastSeen=0, firstSeen=0)


def report(args):
    data = lambda name: load(ROOT / 'src/shared/data' / (name + '.luau'))
    config, mail, build, seasons = map(data, ('Config', 'Mail', 'HomeBuild', 'Seasons'))
    profile = template(config, data('Jobs'), data('Settings'))
    model = Model()
    players = [Player(model, seed, 30, False, 7).run() for seed in range(3)]
    rate = statistics.median(sum(p.catch_counts.values()) * 3600 / p.active for p in players)
    consumed = statistics.median(p.fodder / sum(p.catch_counts.values()) for p in players)
    species = max(model.species, key=lambda s:(len(s), s))
    alien = dict(uid=UID, species=species, level=1, overlay='None', caughtAt=STAMP, size='Normal', workedSeconds=0)
    codex = dict(count=1, bestOverlay='None', firstCaughtAt=STAMP)
    item_id = max((r['id'] for r in build['Items']), key=lambda s:(len(s), s))
    item = dict(uid=UID, itemId=item_id, cellX=0, cellZ=0, rotation=0)
    letter = dict(uid=UID, **{'from':'X'*20}, text='X'*mail['TextMaxChars'], rewards=[dict(kind='scrap', amount=mail['MaxScrap'])], sentAt=STAMP)
    visitor = dict(name='X'*20, at=STAMP)
    season = seasons['List'][0]
    track = dict(progress={r['id']:r['objective']['count'] for r in season['track']}, claimed={r['id']:True for r in season['track']})
    records = [('Alien map entry', {UID:alien}), ('Codex map entry', {species:codex}), ('House item map entry', {UID:item}),
               ('Letter array element', [letter]), ('Visitor array element', [visitor]), ('Receipt map entry', {UID:STAMP}), ('Season track map entry', {season['id']:track})]
    # Marginal entries include their separator; the first entry saves one byte.
    entry = lambda obj: size(obj)-1
    alien_bytes = entry({UID:alien})
    profile['codex'] = {sid:codex for sid in sorted(model.species)}
    profile['home']['items'] = {f'{i:036d}':dict(item, uid=f'{i:036d}') for i in range(sum(build['Caps'].values()))}
    profile['home']['mail'] = [letter] * mail['MaxLetters']
    profile['home']['visitors'] = [visitor] * mail['MaxVisitors']
    profile['shop']['receipts'] = {f'{i:036d}':STAMP for i in range(config['ReceiptMemory'])}
    profile['seasons'] = {row['id']:dict(progress={q['id']:q['objective']['count'] for q in row['track']}, claimed={q['id']:True for q in row['track']}) for row in seasons['List']}
    base = size(profile)
    receipt_save = max(0, config['ReceiptMemory']-args.receipt_cap)*entry({UID:STAMP})
    track_save = size(profile['seasons'])-2
    def total(day, hours, fraction=1, cap=None, savings=0):
        n = math.floor(day*hours*rate*fraction)
        if cap is not None:
            n = min(n, cap)
        return base - savings + max(0, n*alien_bytes-1)
    def limit_day(hours, fraction=1, cap=None, savings=0):
        if cap is not None and base-savings+cap*alien_bytes < LIMIT:
            return 'not reached (fixed catalog)'
        n = math.floor((LIMIT-base+savings+1)/alien_bytes)+1
        return str(math.ceil(n/(hours*rate*fraction)))
    # Stack representation is a proposal: one aggregate per species for eligible plain records.
    stack_bytes = size({sid:dict(count=999999, species=sid, level=1, overlay='None', size='Normal') for sid in sorted(model.species)})-2
    inputs = ['src/server/ProfileSchema.luau','src/shared/types/Types.luau','tools/balance.py'] + [str(p.relative_to(ROOT)) for p in sorted((ROOT/'src/shared/data').glob('*.luau'))]
    digest = hashlib.sha256(b''.join((ROOT/p).read_bytes() for p in inputs)).hexdigest()[:16]
    lines = ['# Save size budget', '', 'Generated by `python3 -I tools/save_budget.py --write` (override `--hours-per-day`, `--storage-cap`, `--receipt-cap`, `--stack-share`).', '',
        f'Inputs: ProfileSchema template, Types.Profile, all live data tables and balance.py. SHA-256 input fingerprint `{digest}`. [[Testing-Headless]] · [[Exploit-Review]].', '',
        '[Roblox documents a 4,194,304-byte per-key limit and JSONEncode measurement](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits). Compact UTF-8 JSON is modeled here; nil keys are omitted, dense arrays are arrays, dictionaries are objects. Empty arrays versus objects cost the same two bytes. Runtime float formatting/Unicode text can differ: validate with JSONEncode before setting a production safety margin.', '',
        f'Three seeded balance.py progression runs yield median **{rate:.2f} successful grants/hour** (includes progression gifts); fusion consumes **{100*consumed:.1f}%** of grants in that short progression sample. Main scenario retains every catch: fusion is optional, and extrapolating the short sample’s fusion fraction for a year is not a guarantee. No paid catches, search slowdown or future catalog additions are invented.', '',
        f'Reconstructed fresh template: **{size(template(config,data("Jobs"),data("Settings"))):,} bytes**. Heavy fixed reserve: **{base:,} bytes**, filling current codex, house caps (conservative even if footprints cannot coexist), mailbox, visitor book, receipt cap and current season tracks; other template fields remain initial. This is a scoped estimate, not a worst-case proof. Alien examples use the longest current species id `{species}`, a 36-character UID both as key and in the record, a ten-digit timestamp, level 1, Normal/None, no optional assignment. Assignments, grown workedSeconds, longer overlays and other accumulated fields increase bytes.', '',
        '| Record | Encoded container bytes | Marginal bytes incl. separator |', '| --- | ---: | ---: |']
    lines += [f'| {name} | {size(value)} | {entry(value)} |' for name,value in records]
    lines += ['', '| Days | Retained catches | Bytes | Limit used |', '| ---: | ---: | ---: | ---: |']
    for day in (1,7,30,90,365):
        count = math.floor(day*args.hours_per_day*rate)
        amount = total(day,args.hours_per_day)
        lines.append(f'| {day} | {count:,} | {amount:,} | {100*amount/LIMIT:.1f}% |')
    lines += ['', f'Options are independent proposals; modeled hours/day: **{args.hours_per_day:g}** and **10**. First integer day exceeding the limit:', '', '| Policy | Bytes saved/bounded | Default day | 10-hour day |', '| --- | --- | --- | --- |',
        f'| Current, no fusion | none | {limit_day(args.hours_per_day)} | {limit_day(10)} |',
        f'| Cap at {args.storage_cap:,} retained records + release for Scrap | alien bytes <= {args.storage_cap*alien_bytes:,} | {limit_day(args.hours_per_day,cap=args.storage_cap)} | {limit_day(10,cap=args.storage_cap)} |',
        f'| Stack {100*args.stack_share:g}% eligible plain copies | {stack_bytes:,}-byte stack reserve, remainder individual | {limit_day(args.hours_per_day,1-args.stack_share,savings=-stack_bytes)} | {limit_day(10,1-args.stack_share,savings=-stack_bytes)} |',
        f'| Reduce receipts {config["ReceiptMemory"]} → {args.receipt_cap} | {receipt_save:,} bytes | {limit_day(args.hours_per_day,savings=receipt_save)} | {limit_day(10,savings=receipt_save)} |',
        f'| Trim all finished current tracks | {track_save:,} bytes | {limit_day(args.hours_per_day,savings=track_save)} | {limit_day(10,savings=track_save)} |', '',
        'Release prices require a coordinator decision; no economy values are proposed or applied. Stacking requires redesigning UID references, caughtAt and workedSeconds semantics and excluding seated/following/displayed/unique copies. The stack share is an explicit scenario assumption, not measured prevalence. Pruning receipts already exists: shrinking the replay memory risks duplicate grants; no time-based guarantee is established by the code comment. Finished tracks need a durable claimed marker if an event returns.', '',
        '## Growth inventory', '', '| Profile field(s) | Current bound / growth |', '| --- | --- |',
        '| aliens | Unbounded UID map; Fuse deletes fodder, no inventory capacity or automatic release. |',
        '| seasons | One retained track per encountered season ID; no old-track pruning. Fixed for today’s catalog, unbounded with future seasons. |',
        '| codes | One key per redeemed code; no pruning; grows with future code catalog. |',
        '| codex | One row per species; counts grow in digits; keys bounded by current Species, grows with new species. |',
        '| modules, world.unlocked, world.outposts, quests.fieldNotes | Bound by current worlds/modules; retained across added worlds. |',
        '| quests.daily/weekly | Replaced each period; quest IDs from dealt pool; progress counters grow only in digits. |',
        '| quests.progress | Current Field Notes objectives; replaced on advancement. |',
        f'| home.items/mail/visitors | Kind caps {build["Caps"]}; mail {mail["MaxLetters"]}; visitors {mail["MaxVisitors"]}; claims remove letters. |',
        f'| shop.receipts | Newest {config["ReceiptMemory"]} receipt IDs retained by Monetization.pruneReceipts. |',
        '| stations, companions | Station/companion slot caps; UIDs refer to aliens. |',
        '| purchases, buffs, inventory | Catalog-keyed counts/timers; buffs expire. Current key space bounded; balances grow in digits. |',
        '| gifts.claimed, settings, gear, shop.starterSpecies | Current gift days/settings/catalog; no per-event append. |',
        '| version, scrap, companionSlots, stats, tutorialStep, tutorialCounter, social, gifts days/times, spins, luck, firstSeen, lastSeen, lock, home visits/waves/clocks, world.current | Fixed-shape scalar fields; counters can grow in numeric width, not record count. Lock holds one job ID/time. |', '',
        'Coordinator priorities: bound retained aliens with ample byte headroom; decide whether copies can lose individual identity when stacked; retain receipt safety and avoid treating catalog cleanup as a solution to catch growth.', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--hours-per-day', type=float, default=3)
    parser.add_argument('--storage-cap', type=int, default=5000)
    parser.add_argument('--receipt-cap', type=int, default=25)
    parser.add_argument('--stack-share', type=float, default=.9)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if not 0 < args.hours_per_day <= 24 or args.storage_cap < 1 or args.receipt_cap < 0 or not 0 <= args.stack_share < 1:
        parser.error('hours must be in (0,24], caps nonnegative (storage positive), stack share in [0,1)')
    content = report(args)
    if args.write:
        (ROOT/'docs/vault/04-roblox-engine/Save-Budget.md').write_text(content)
    print(content, end='')

if __name__ == '__main__':
    main()
