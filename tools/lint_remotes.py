#!/usr/bin/env python3
"""Check client/server remote contracts; audit handler guards; --write regenerates Remotes.md."""
from pathlib import Path
from collections import defaultdict
import argparse
import re
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from lint_data import ROOT, uncomment

NET = re.compile(r'Net\.(event|func)\(\s*"([^"]+)"\s*\)')
FUNC = re.compile(r'^(?:local\s+)?function\s+(\w+(?:\.\w+)?)\(([^\n]*?)\)[^\n]*\n(.*?)^end\b',re.M|re.S)


def functions(source):
    return {m[1]:(m[2],m[3],m.start()) for m in FUNC.finditer(source)}


def inventory(root=ROOT):
    rows=defaultdict(lambda:dict(kinds=set(),server=set(),client=set(),listeners=set(),fires=set(),handlers=[]))
    failures=[];warnings=[]
    for side in ('server','client'):
        for path in sorted((root/'src'/side).rglob('*.luau')):
            source=uncomment(path.read_text());file=path.relative_to(root).as_posix()
            funcs=functions(source)
            def add(name,kind,offset):
                row=rows[name];row['kinds'].add(kind);row[side].add(f'{file}:{source.count(chr(10),0,offset)+1}')
                return row
            aliases={}
            for match in NET.finditer(source):
                row=add(match[2],match[1],match.start())
                tail=source[match.end():]
                if re.match(r'\s*\.OnClientEvent',tail):row['listeners'].add(file)
                if re.match(r'\s*:Fire(?:Client|AllClients)',tail):row['fires'].add(file)
                before=source[max(0,source.rfind('\n',0,match.start())):match.start()]
                alias=re.search(r'local\s+(\w+)(?:\s*:[^=]+)?\s*=\s*$',before)
                if alias:aliases[alias[1]]=match[2]
            for alias,name in aliases.items():
                if re.search(r'\b'+alias+r'\.OnClientEvent',source):rows[name]['listeners'].add(file)
                if re.search(r'\b'+alias+r':Fire(?:Client|AllClients)',source):rows[name]['fires'].add(file)
            # Literal arrays in initialization loops create every listed event.
            loop=re.compile(r'for\s+_,\s*(\w+)\s+in\s+ipairs\(\{([^}]+)\}\)\s+do\s+Net\.(event|func)\(\1\)',re.S)
            resolved_dynamic=set()
            for match in loop.finditer(source):
                for name in re.findall(r'"([^"]+)"',match[2]):add(name,match[3],match.start())
                resolved_dynamic.add(match[1])
            # Remote-name wrappers (ask/invoke) are resolved from literal call sites.
            for fname,(params,body,offset) in funcs.items():
                dyn=re.search(r'Net\.(event|func)\(\s*(\w+)\s*\)',body)
                if not dyn:continue
                arguments=[p.split(':')[0].strip() for p in params.split(',')]
                if dyn[2] not in arguments:continue
                index=arguments.index(dyn[2])
                if index != 0:
                    failures.append(f'{file}: unsupported dynamic remote parameter position in {fname}');continue
                calls=list(re.finditer(r'\b'+re.escape(fname)+r'\(\s*"([^"]+)"',source))
                if not calls:failures.append(f'{file}: unresolved remote-name wrapper {fname}')
                for call in calls:add(call[1],dyn[1],call.start())
                resolved_dynamic.add(dyn[2])
            for match in re.finditer(r'Net\.(?:event|func)\(\s*(\w+)\s*\)',source):
                if match[1] not in resolved_dynamic:
                    failures.append(f'{file}: unresolved dynamic remote {match[1]}')
            if side!='server':continue
            binding=re.compile(r'Net\.(event|func)\("([^"]+)"\)\.(?:OnServerInvoke\s*=\s*|OnServerEvent:Connect\(\s*)(\w+)')
            for match in binding.finditer(source):
                name,handler=match[2],match[3]
                if handler=='function':
                    inline=re.match(r'\(([^\n]*?)\)[^\n]*\n(.*?)^\tend',source[match.end():],re.M|re.S)
                    if not inline:
                        failures.append(f'{file}: cannot parse inline handler for {name}');continue
                    params,body=inline[1],inline[2]
                elif handler in funcs:
                    params,body,_=funcs[handler]
                else:
                    failures.append(f'{file}: cannot resolve handler {handler}');continue
                allow=re.search(r'Net\.allow\(',body)
                profile=re.search(r'PlayerData\.(?:Get|Update|Peek)\(',body)
                rate='missing' if not allow else 'after profile read' if profile and profile.start()<allow.start() else 'before profile / no direct profile read'
                # Guards may be delegated to named helpers. Include only helpers actually called
                # by this handler; argument order/dataflow still requires manual review.
                expanded=body
                for fn,(_,helper,_) in funcs.items():
                    if fn!=handler and re.search(r'\b'+re.escape(fn)+r'\(',body):expanded+='\n'+helper
                args=[]
                for param in params.split(',')[1:]:
                    arg=param.split(':')[0].strip()
                    if not arg:continue
                    checked=bool(re.search(r'(?:type|typeof)\(\s*'+re.escape(arg)+r'\s*\)',expanded))
                    if not checked:
                        # A guard helper called with this argument (e.g. validWorld(worldId)).
                        for fn,(hp,hb,_) in funcs.items():
                            if re.search(r'\b'+re.escape(fn)+r'\(\s*'+re.escape(arg)+r'\b',body):
                                first=hp.split(',')[0].split(':')[0].strip()
                                checked=checked or bool(re.search(r'(?:type|typeof)\(\s*'+re.escape(first)+r'\s*\)',hb))
                    numeric=bool(re.search(r'\b'+re.escape(arg)+r'\s*(?:~=|==)\s*'+re.escape(arg)+r'\b|math\.(?:floor|ceil)\(\s*'+re.escape(arg),expanded))
                    enum = bool(re.search(r'\b'+re.escape(arg)+r'\s*(?:~=|==)\s*"[^"\n]*"', expanded))
                    status = 'type guard' if checked else 'literal enum check/normalization' if enum else 'REVIEW missing type guard'
                    args.append(f'{arg}: '+status+('; numeric check' if numeric else ''))
                info=dict(file=file,handler=handler,rate=rate,args=args)
                rows[name]['handlers'].append(info)
                if rate in ('missing','after profile read'):warnings.append(f'{name}: {rate} rate limit ({file}, {handler})')
                for arg in args:
                    if 'REVIEW' in arg:warnings.append(f'{name}: {arg} ({file})')
    for name,row in sorted(rows.items()):
        if row['client'] and not row['server']:failures.append(f'{name}: client uses remote with no server creation')
        if len(row['kinds'])>1:failures.append(f'{name}: conflicting event/function kinds')
        if row['server'] and not row['client']:warnings.append(f'{name}: server creates remote with no client user')
        if row['fires'] and not row['listeners']:warnings.append(f'{name}: server fires event with no client listener')
    return dict(rows=dict(rows),failures=sorted(set(failures)),warnings=sorted(set(warnings)))


def render(result):
    lines=['# Remote contracts and handler audit','','Generated by `python3 -I tools/lint_remotes.py --write`. Inputs: all src/server and src/client Luau files. Literal Net calls, initializer arrays, local aliases and literal callers of remote-name wrappers are resolved. Unresolved dynamic names and missing server creations fail; unused remotes and guard findings are advisory.','','Guard inspection is lexical: named/inline handlers and one layer of called helpers. A type guard does not prove correct control flow or full validation; numeric checks are reported separately. Engine-supplied Player is trusted. Direct profile-read ordering is checked. Review ownership, finite ranges and delegation manually.','','| Remote | Kind | Created/referenced in server | Client users | Rate limit | Argument checks |','| --- | --- | --- | --- | --- | --- |']
    for name,row in sorted(result['rows'].items()):
        rates='; '.join(h['handler']+': '+h['rate'] for h in row['handlers']) or 'server → client'
        args='; '.join(', '.join(h['args']) or 'no client arguments' for h in row['handlers']) or '—'
        lines.append('| '+' | '.join([name,', '.join(sorted(row['kinds'])), '<br>'.join(sorted(row['server'])), '<br>'.join(sorted(row['client'])),rates,args])+' |')
    lines+=['','## Findings','']+['- '+w for w in result['failures']+result['warnings']]
    if not result['warnings'] and not result['failures']:lines.append('None.')
    lines+=['',f'Totals: {len(result["rows"])} remotes; {sum(len(r["handlers"]) for r in result["rows"].values())} handlers; {len(result["failures"])} contract failures; {len(result["warnings"])} advisory findings.','']
    return '\n'.join(lines)


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--root',type=Path,default=ROOT);p.add_argument('--write',action='store_true');a=p.parse_args()
    result=inventory(a.root)
    if a.write:(a.root/'docs/vault/04-roblox-engine/Remotes.md').write_text(render(result))
    for f in result['failures']:print(f)
    for w in result['warnings']:print('warning: '+w)
    print(f'remote lint: {len(result["rows"])} remotes, {sum(len(r["handlers"]) for r in result["rows"].values())} handlers')
    print('remote lint: clean' if not result['failures'] else f'remote lint: {len(result["failures"])} failure(s)')
    return int(bool(result['failures']))

if __name__=='__main__':sys.exit(main())
