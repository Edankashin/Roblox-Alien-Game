#!/usr/bin/env python3
"""Report unreferenced public APIs and unused data candidates; never edit game code/data."""
from pathlib import Path
from collections import Counter
import argparse
import hashlib
import re
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from lint_data import ROOT,TableReader,uncomment,tokens
from lint_strings import audit as strings_audit
from lint_remotes import inventory


def report(root=ROOT):
    files=sorted((root/'src').rglob('*.luau'))
    sources={p:uncomment(p.read_text()) for p in files}
    stripped={p:re.sub(r'\bfunction\s+\w+\.\w+\s*\(', 'function(',s) for p,s in sources.items()}
    findings=[]
    def add(kind,item,evidence,suggestion):findings.append((kind,item,evidence,suggestion))
    for path,source in sources.items():
        rel=path.relative_to(root).as_posix()
        if not any(rel.startswith(prefix) for prefix in ('src/server/Services/','src/client/UI/','src/client/World/')):continue
        returned=re.findall(r'^return\s+(\w+)\s*$',source,re.M)
        for m in re.finditer(r'\bfunction\s+(\w+)\.(\w+)\s*\(',source):
            if returned and m[1]!=returned[-1]:continue
            # Conservative: any external property reference with this method name
            # counts, even under an alias. Passed callbacks count too. Init/Start are
            # explicitly dispatched through svc by the server bootstrap.
            pattern=re.compile(r'[.:]\s*'+re.escape(m[2])+r'\b')
            if any(pattern.search(text) for p,text in stripped.items() if p!=path):continue
            line=source.count('\n',0,m.start())+1
            add('Public API',rel+':'+str(line)+' '+m[1]+'.'+m[2],
                'No external dot/colon reference to this member name.',
                'Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller.')
    reader=TableReader()
    shop=reader.read(root/'src/shared/data/Shop.luau')
    launch={sid for r in shop['Launch'].values() for sid in r['items'].values()}
    for row in shop['Items'].values():
        if row['id'] not in shop['Grants'] and row['id'] not in launch:
            live=row['id']=='CompanionSlot4'
            add('Shop catalog',row['id'],'No Grants row and absent from Launch.'+(' Companions reads this pass live; it is not dead behavior.' if live else ''),
                'Keep for milestone 36 companions; decide whether to expose the existing pass in Launch.' if live else 'Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure.')
    icons=reader.read(root/'src/shared/data/Icons.luau')
    outside='\n'.join(s for p,s in sources.items() if p.name!='Icons.luau')
    all_tokens=set(tokens(outside));literals={t[1:-1] for t in all_tokens if t.startswith(('"',"'"))}
    # Data ids feed dynamic icon keys. Aliases count as references to their targets.
    referenced=all_tokens|literals|set(icons['Aliases'].values())
    for key in sorted(icons['Icons']):
        if key not in referenced:add('Icon',key,'No symbolic id/key or literal reference outside Icons.', 'Keep for milestones 31–32 icon integration only if a surface is planned; otherwise delete the unused icon entry and matching asset together.')
    sounds=reader.read(root/'src/shared/data/Sounds.luau')
    for key,value in sounds.items():
        if isinstance(value,str) and not re.search(r'\bSounds\.'+re.escape(key)+r'\b',outside):
            add('Sound',key,'No Sounds.'+key+' reference in source.', 'Wire the cue during milestone 11 audio work, or delete if the action uses another cue.')
        elif isinstance(value,dict) and key!='Volume':
            if not re.search(r'\bSounds\.'+re.escape(key)+r'\b',outside):
                for child in sorted(value):add('Sound',key+'.'+child,'No reader of this Sounds group.','Wire the group during milestone 11 audio work.')
    sr=strings_audit(root)
    for key in sr['unused']:add('String',key,'C8 unused-string candidate; no direct or mapped family reference.','Delete only after checking intended UI and translation compatibility; otherwise wire the intended label.')
    remotes=inventory(root)
    for name,row in sorted(remotes['rows'].items()):
        if row['server'] and not row['client']:add('Remote',name,'C9: server creates it, no client user.','Wire the intended client consumer or delete the unused endpoint and its sender together.')
    inputs=files+[root/'docs/PRE_PRODUCTION.md']
    digest=hashlib.sha256(b''.join(p.read_bytes() for p in inputs)).hexdigest()[:16]
    counts=Counter(row[0] for row in findings)
    lines=['# Dead code and data candidates','','Regenerate: `python3 -I tools/deadcode.py --write`. Inputs: all src Luau, Shop/Icons/Sounds data, C8 string families, C9 remote inventory, and milestone names from docs/PRE_PRODUCTION.md. Input fingerprint: `'+digest+'`.','','This is a conservative lexical inventory, not a deletion plan. Public members are flagged only when no other file references their member name at all; same-named unrelated members can hide candidates. Dynamic dispatch and external Studio/plugin callers require human review. Icon references include data ids and aliases, so “no candidate” does not prove every icon is rendered. Sound id 0 means not uploaded, not unused. No game code or data changed.','','## Counts','','| Category | Candidates |','| --- | ---: |']
    for kind in ('Public API','Shop catalog','Icon','Sound','String','Remote'):lines.append(f'| {kind} | {counts[kind]} |')
    lines+=['','## Findings','','| Category | Item / source | Evidence | Suggested disposition |','| --- | --- | --- | --- |']
    for row in sorted(findings):lines.append('| '+' | '.join(s.replace('|','\\|') for s in row)+' |')
    lines+=['','## Coordinator priorities','','1. Resolve catalog rows with no grant/Launch route before exposing more purchases; CompanionSlot4 is a live-reader exception, not an unused pass implementation.','2. Review public APIs without external references; remove obsolete wrappers only after checking manual Studio and callback use.','3. Review the C8 string candidates alongside the UI polish pass; retain future-world labels until the world plan is settled.','','Every finding above includes a delete, keep or wire-up suggestion. Counts are candidates, not proven removable assets.','']
    return '\n'.join(lines),counts


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--root',type=Path,default=ROOT);p.add_argument('--write',action='store_true');a=p.parse_args()
    content,counts=report(a.root)
    if a.write:(a.root/'docs/vault/02-how-we-work/Dead-Code.md').write_text(content)
    print(content,end='')
    return 0

if __name__=='__main__':sys.exit(main())
