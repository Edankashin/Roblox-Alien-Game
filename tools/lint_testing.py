#!/usr/bin/env python3
"""Warn about unregistered TESTING.md commands and quoted UI wording that differs from en.luau."""
from pathlib import Path
import argparse
import difflib
import re
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from lint_data import ROOT,TableReader,uncomment

# Quotes are UI candidates in numbered steps, or prose explicitly naming a toast,
# banner, chip, hint, button or displayed text. Inline/fenced code is excluded.
# Skip whole known-gap paragraphs, explicit log/boot/analytics lines, code-ish
# identifiers and descriptive scare quotes. Ambiguous UI excerpts remain warnings.
UI_CUE=re.compile(r'\b(toast|reads?|says?|shows?|label(?:led)?|banner|chip|hint|button|text|screen|panel|card)\b',re.I)
LOG_CUE=re.compile(r'^(?:[^:]+: (?:Studio|[0-9])|analytics:|server started|client:|Launch:|Quests:|Monetization:|Settings:|Analytics:)',re.I)


def pattern(template):
    pieces=re.split(r'(%(?:\d+\$)?[sdg]|%%)',template)
    literal = ''.join(p for p in pieces if not p.startswith('%'))
    if not literal.strip() or (pieces.count('%s') > 1 and not re.search(r'[A-Za-z]', literal)):
        return None # Generic caller-supplied lines / '%s %s!' cannot verify wording.
    return re.compile('^'+''.join('%' if p=='%%' else '.+?' if re.fullmatch(r'%(?:\d+\$)?[sdg]',p) else re.escape(p) for p in pieces)+'$')


def audit(root=ROOT):
    strings=TableReader().read(root/'src/shared/strings/en.luau')
    patterns=[p for text in strings.values() if (p:=pattern(text))]
    registered=set()
    for file in ('Dev','Admin'):
        src=uncomment((root/f'src/server/Services/{file}.luau').read_text())
        registered.update('/'+s for s in re.findall(r'\bcommand\("([^"]+)"',src))
        registered.update(re.findall(r'\.PrimaryAlias\s*=\s*"(/[^"]+)"',src))
    findings=[];section='Introduction';fenced=False;checked=0;commands=set()
    for number,line in enumerate((root/'docs/TESTING.md').read_text().splitlines(),1):
        if line.startswith('```'):fenced=not fenced;continue
        if fenced:continue
        if line.startswith('## '):section=line[3:];continue
        for code in re.findall(r'`([^`]+)`',line):
            for cmd in re.findall(r'(?<!\w)/[A-Za-z][A-Za-z0-9_]*',code):
                commands.add(cmd)
                if cmd not in registered:findings.append((section,number,'command',cmd,''))
        text=re.sub(r'`[^`]*`','',line)
        if text.startswith('Known gaps') or not (re.match(r'^\d+\.',text) or UI_CUE.search(text)):continue
        for match in re.finditer(r'"([^"\n]+)"',text):
            quote=match[1]
            before=text[max(0,match.start()-90):match.start()]
            if re.search(r'\b(?:warns|prints|Output|Boot adds)\b', before):continue
            if LOG_CUE.search(quote) or re.fullmatch(r'[A-Za-z]+(?:[A-Z][a-z]+)+',quote):continue
            if not UI_CUE.search(before) and not re.search(r'\b(expect|with|or|and|then)\b',before,re.I):continue
            checked+=1
            if quote in strings.values() or any(p.fullmatch(quote) for p in patterns):continue
            closest=difflib.get_close_matches(quote,strings.values(),n=1,cutoff=.65)
            findings.append((section,number,'wording',quote,closest[0] if closest else ''))
    return dict(findings=findings,checked=checked,commands=sorted(commands))


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--root',type=Path,default=ROOT);a=p.parse_args()
    result=audit(a.root)
    for section,line,kind,value,near in result['findings']:
        print(f'warning: TESTING.md:{line} [{section}] {kind}: {value!r}'+(f' (nearest string: {near!r})' if near else ''))
    print(f'testing lint: {len(result["commands"])} command names, {result["checked"]} quoted UI candidates, {len(result["findings"])} warnings (advisory)')
    return 0

if __name__=='__main__':sys.exit(main())
