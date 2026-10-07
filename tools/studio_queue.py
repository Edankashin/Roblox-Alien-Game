#!/usr/bin/env python3
"""Check that STUDIO-QUEUE.md matches pending PRE_PRODUCTION statuses and TESTING steps.

--write regenerates the offline, deterministic run sheet. Completed historical re-checks
are not pending. Reviewed step subsets narrow old milestones; unknown pending milestones
include every step rather than silently disappearing. No Studio or network access.
"""
import argparse
import hashlib
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GROUPS = ('World 1 place', 'World 2 place', 'Home place', 'Two-player test', 'Real saves', 'Published game')
# Status prose identifies these incomplete subsets. Sets contain original TESTING numbers.
SUBSETS = {'14':{7}, '15':{4}, '18':{5}, '19':{3,6}, '20':{3,4}, '23':{2,3,4,5},
           '25':{1,4}, '27':{6}, '28':{5}, '30':{2,3}, '31':{2,3,4,5},
           '34':{4,7}, '36':{5,6}, '37':{5,6}, '41':{4}, '42a':{2,4},
           '42b':{5}, '42e':{3,4,5,6}, '43':{3}}
# Multiple prerequisites stay on one entry (never duplicate a milestone across groups).
OVERRIDES = {'14':'Published game','15':'World 1 place','18':'World 1 place',
             '19':'Real saves','20':'Real saves','23':'Two-player test','24':'World 2 place',
             '34':'Two-player test','36':'Real saves','37':'Real saves','41':'Published game',
             '42a':'Real saves','42b':'Home place','42e':'Published game','46':'World 1 place'}


def pending(status):
    # Keep unresolved verbs; exclude historical re-check / re-checked mentions on passed work.
    return bool(re.search(r'\b(?:queued|waits?\b|needs?\b|not sampled|check after|last visual pass|re-check required|re-check pending)', status, re.I))


def generate(root=ROOT):
    plan = (root/'docs/PRE_PRODUCTION.md').read_text()
    tests = (root/'docs/TESTING.md').read_text()
    section = re.search(r'^## 5b\..*?\n(.*?)(?=^## |\Z)', plan, re.M|re.S)
    if not section:
        raise ValueError('missing PRE_PRODUCTION section 5b')
    statuses = {}
    for line in section[1].splitlines():
        match = re.match(r'^\|\s*(\d+[a-z]?)\s*\|', line)
        if match:
            status = line.rsplit('|', 2)[1].strip()
            if pending(status):
                statuses[match[1]] = status
    headings = list(re.finditer(r'^## (.+)$', tests, re.M))
    blocks = {}
    for index, heading in enumerate(headings):
        milestone = re.match(r'Milestone (\d+[a-z]?):', heading[1])
        if milestone:
            body = tests[heading.end():headings[index+1].start() if index+1<len(headings) else len(tests)].strip()
            steps = {int(m[1]):m[2].strip() for m in re.finditer(r'^(\d+)\. (.*?)(?=^\d+\. |^Known gaps|^Decision |\Z)',body,re.M|re.S)}
            blocks[milestone[1]] = (heading[1],body,steps)
    entries=[]
    for milestone,status in statuses.items():
        key='15c' if milestone=='15' else milestone
        if key not in blocks:raise ValueError(f'pending milestone {milestone} has no TESTING section')
        title,body,steps=blocks[key]
        selected=SUBSETS.get(milestone,set(steps))
        if not selected <= steps.keys():
            raise ValueError(f'milestone {milestone}: requested missing steps {sorted(selected-steps.keys())}')
        group=OVERRIDES.get(milestone, 'Real saves' if 'real saves' in status else 'World 1 place')
        commands=sorted(set(re.findall(r'`(/[^`\n]+)`',body)))
        projects=['home.project.json'] if milestone.startswith('42') else ['world2.project.json','default.project.json'] if milestone=='24' else ['default.project.json']
        if milestone=='42a':projects.insert(0,'default.project.json')
        entries.append((group,milestone,title,status,steps,selected,commands,projects))
    digest=hashlib.sha256((plan+'\0'+tests).encode()).hexdigest()[:16]
    lines=['# Studio run queue','',f'Generated from `PRE_PRODUCTION.md` §5b and `TESTING.md`; input fingerprint `{digest}`.',
        'Regenerate: `python3 -I tools/studio_queue.py --write`. Check: `python3 -I tools/studio_queue.py` (also in `tools/lint.sh`).','',
        f'**{len(entries)} pending milestones; {sum(len(e[5]) for e in entries)} numbered steps; each milestone appears once.** Do the place-only blocks first, then multiplayer, persistence and published-server checks. Multi-requirement milestones stay together in the strongest prerequisite block; keep each project open for adjacent entries. Empty groups mean no independent pending check.','',
        'Owner/Mac session only: stop Play before changing Rojo project, reconnect, then Play. Two-player means Test → Clients and Servers; friendship/cap checks may need additional real friends. Real saves require Studio API access and the coordinator-approved test save setup (`Config.UseDataStoreInStudio`); do not change production data for this sheet. Published checks use the published universe and actual accounts; Dev-only commands are setup in Studio, not promises of live availability.','',
        'Run the selected original step numbers below. Commands are extracted from the milestone as setup references, not a sequence to execute blindly. Known stale source wording (zero place IDs, memory-profile persistence, retired passes and old toasts) is reproduced as evidence, never treated as authority over code. Return the observed behavior for coordinator correction.','',
        'For every entry send: commit/build, project and WorldId, player count, original step number, pass/fail, exact first Output error, and a screenshot or short clip for UI failures. Include balances/counts before and after for rewards; record device/viewport for layout checks. No secrets.','']
    for group in GROUPS:
        lines += ['## '+group,'']
        grouped=[e for e in entries if e[0]==group]
        if not grouped:lines+=['No independent pending entry in the status table.','']
        for _,milestone,title,status,steps,selected,commands,projects in sorted(grouped,key=lambda e:(int(re.match(r'\d+',e[1])[0]),e[1])):
            lines += ['### '+title,'', '**Pending status:** '+status,'',
                '**Setup projects:** '+', '.join('`rojo serve '+p+'`' for p in projects)+'.',
                '**Dev/setup references:** '+(', '.join('`'+c+'`' for c in commands) or 'none; follow the prerequisites in the step')+'.','',
                '**Send back:** standard evidence above; original steps '+', '.join(map(str,sorted(selected)))+'.','']
            for step in sorted(selected):
                lines += [f'**TESTING step {step}.** '+steps[step],'']
    return '\n'.join(lines),len(entries)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--write',action='store_true')
    p.add_argument('--root',type=Path,default=ROOT,help='checkout to check (supports isolated fixtures)')
    args=p.parse_args()
    try:content,count=generate(args.root)
    except (ValueError,OSError) as exc:
        print('studio queue: '+str(exc));return 1
    path=args.root/'docs/STUDIO-QUEUE.md'
    if args.write:path.write_text(content)
    elif not path.exists() or path.read_text()!=content:
        print('studio queue: stale; run python3 -I tools/studio_queue.py --write');return 1
    print(f'studio queue: clean ({count} milestones)');return 0

if __name__=='__main__':raise SystemExit(main())
