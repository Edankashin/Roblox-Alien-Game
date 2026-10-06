#!/usr/bin/env python3
"""Check dynamic translation families, unknown prefixes and missing keys; warn on unused keys."""
from pathlib import Path
import argparse
import re
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import ROOT, TableReader, uncomment, walk, tokens

# Every dynamic family declares its input source here. Special selectors below
# reflect the values actually passed by consumers, not the existing string keys.
FAMILIES = {
    'TIER_': 'Tiers.Tiers', 'TIER_A_': 'Tiers.Tiers', 'LURE_': 'Lures.Lures',
    'SEASON_': 'Seasons.ById', 'OVERLAY_': 'Overlays.Overlays', 'OVERLAY_A_': '@overlay_articles',
    'MATERIAL_': 'KeyMaterials', 'WORLD_': '@built_worlds', 'WEATHER_': '@weather',
    'POWERUP_': 'PowerUps', 'POWERUP_DESC_': 'PowerUps', 'BIOME_': '@Biome',
    'COND_PHRASE_': '@Condition', 'CONDITION_': '@node_conditions',
    'JOB_': 'Jobs.Jobs', 'STATION_': 'Jobs.Jobs', 'STAGE_': 'Growth.ById',
    'SIZE_': 'Sizes.ById', 'OBJ_': '@objectives', 'MODULE_': '@modules',
    'FN_': '@field_notes', 'SHOP_DESC_': '@launch', 'SHOP_ITEM_': '@launch',
    'SHOP_TAB_': '@shop_tabs', 'SHOP_SECTION_': '@shop_sections', 'SEGMENT_': '@segments',
    'HOME_ITEM_': 'HomeBuild.ById', 'BUILD_KIND_': 'HomeBuild.Caps',
    'MENU_': '@menus', 'MENU_GLYPH_': '@menus', 'SHAPE_': '@shapes',
    'REWARD_': '@rewards', 'GEAR_': '@gear', 'ITEM_': '@items',
    'SETTINGS_': '@settings', 'SETTINGS_LEVEL_': '@setting_levels',
    'PERK_': 'Companions.PerkCap', 'OFFER_': '@offers', 'PEDDLER_KIND_': '@offer_kinds',
    'LANDMARK_': '@landmarks', 'GIFT_LABEL_': '@gift_labels',
    'COND_SHORT_': '@Condition', # optional override; consumer falls back to COND_PHRASE_
}


def family_ids(tables, source, types):
    def union(name):
        match = re.search(r'export\s+type\s+' + name + r'\s*=\s*((?:"[^"]+"\s*\|?\s*)+)', types)
        if not match:
            raise ValueError('missing type union ' + name)
        return set(re.findall(r'"([^"]+)"', match[1]))
    all_rows = [row for t in tables.values() for _,_,v,_ in walk(t) if isinstance(v,dict) for row in [v]]
    objectives = {row['kind'] for row in all_rows if 'kind' in row and 'count' in row}
    rewards = {r['kind'] for row in all_rows for r in (row.get('rewards') or {}).values()}
    reward_rows = [r for row in all_rows for r in (row.get('rewards') or {}).values()]
    launch = {sid for section in tables['Shop']['Launch'].values() for sid in section['items'].values()}
    weather = {r['weather']['special']['id'] for r in tables['Worlds'].values()}
    weather |= {w for r in tables['Worlds'].values() for w in r['weather']['normal'].values()}
    weather |= {r['weather'] for group in ('Rotation','Overrides') for r in tables['Weekly'][group].values() if r.get('weather')}
    tabs = re.search(r'local\s+TABS[^=]*=\s*\{([^}]+)\}', source)
    menus = set(re.findall(r'Hud\.Add(?:Menu|Top)Button\(\s*"([^"]+)"',source))
    special = {
        'overlay_articles': set(tables['Overlays']['Order'].values()),
        'built_worlds': {str(k) for k,r in tables['Worlds'].items() if r.get('built')},
        'weather': weather - {''}, 'Biome': union('Biome'), 'Condition': union('Condition'),
        'node_conditions': {r['condition'] for r in tables['KeyMaterials'].values() if r['nodes'] > 0 and r['condition'] != 'Any'},
        'objectives': objectives, 'modules': {r['id'] for world in tables['Modules']['Worlds'].values() for r in world.values()},
        'field_notes': {r['id']+suffix for world in tables['Quests']['FieldNotes'].values() for r in world.values() for suffix in ('_TITLE','_LEGEND')},
        'launch': launch, 'shop_tabs': set(re.findall(r'"([^"]+)"', tabs[1])) if tabs else set(),
        'shop_sections': {r['section'] for r in tables['Shop']['Launch'].values()},
        'segments': {r['id'] for r in tables['Spins']['Segments'].values()}, 'menus': menus,
        'shapes': {r['placeholder']['shape'] for r in tables['Species']['List'].values()}, 'rewards': rewards,
        'gear': {k for k,v in tables['Gear'].items() if isinstance(v,dict)} | {'Radar'+str(k) for k in tables['Radar'] if type(k) is int and k>0},
        'items': {r['id'] for r in reward_rows if r['kind']=='item'},
        'settings': {r['key'] for r in tables['Settings']['Order'].values()},
        'setting_levels': {str(i-1) for r in tables['Settings']['Order'].values() if r.get('levels') and not r.get('levelKeys') for i in r['levels']},
        'offers': {r['id'] for r in tables['Peddler']['Pool'].values() if r['kind'] not in ('lure','powerUp')},
        'offer_kinds': {r['kind'] for r in tables['Peddler']['Pool'].values()},
        'gift_labels': {re.sub(r'\s+', '', r['label']) for r in tables['Gifts'].values() if r['reward']['kind'] not in ('lure','powerUp')},
        'landmarks': {'Shrine'} | {r['landmarkId'] for layout in tables['Layouts'].values() for r in (layout.get('Landmarks') or {}).values() if r.get('landmarkId')},
    }
    result = {}
    for prefix, selector in FAMILIES.items():
        if selector.startswith('@'):
            result[prefix] = special[selector[1:]]
        else:
            value = tables
            for part in selector.split('.'):
                value = value[part]
            result[prefix] = set(value)
    return result


def audit(root=ROOT):
    reader=TableReader()
    tables={p.stem:reader.read(p) for p in sorted((root/'src/shared/data').glob('*.luau'))}
    strings=reader.read(root/'src/shared/strings/en.luau')
    files=sorted((root/'src/client').rglob('*.luau'))+sorted((root/'src/server').rglob('*.luau'))
    source='\n'.join(uncomment(p.read_text()) for p in files)
    types=uncomment((root/'src/shared/types/Types.luau').read_text())
    # Include conditional-prefix arguments inside Builder.text and formatted families.
    found=set(re.findall(r'Builder\.text\(\s*"([A-Z][A-Z_]*_)"\s*\.\.',source))
    found.update(re.findall(r'\(\s*"([A-Z][A-Z_]*_)%s"\s*\)\s*:\s*format',source))
    for expr in re.findall(r'Builder\.text\(\((.*?)\)\s*\.\.',source,re.S):
        found.update(re.findall(r'"([A-Z][A-Z_]*_)"',expr))
    for variable,prefix in re.findall(r'local\s+(\w+)\s*=\s*"([A-Z][A-Z_]*_)"\s*\.\.', source):
        if re.search(r'Builder\.text\(\s*'+re.escape(variable)+r'\s*\)',source):
            found.add(prefix)
    families=family_ids(tables,source,types)
    failures=[f'unknown dynamic prefix: {p}' for p in sorted(found-set(FAMILIES))]
    required={prefix+str(sid) for prefix,ids in families.items() if prefix != 'COND_SHORT_' for sid in ids}
    failures.extend('missing string: '+key for key in sorted(required-strings.keys()))
    # Include shared/data literal references (keys in fields, aliases and static Builder.text)
    # and all Strings.KEY accesses. This is a conservative source audit, not reachability proof.
    all_source='\n'.join(uncomment(p.read_text()) for p in sorted((root/'src').rglob('*.luau')) if p != root/'src/shared/strings/en.luau')
    used=set(re.findall(r'\b(?:Strings|strings)\.([A-Za-z_]\w*)',all_source))
    used.update(t[1:-1] for t in tokens(all_source) if t.startswith(('"',"'")))
    used.update('COND_SHORT_'+str(sid) for sid in families['COND_SHORT_'])
    unused=sorted(strings.keys()-(used|required))
    return dict(failures=failures,unused=unused,found=sorted(found),families=families,required=sorted(required))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=ROOT)
    args=parser.parse_args()
    try:
        result=audit(args.root)
    except (OSError,ValueError,KeyError,TypeError) as exc:
        print('string lint: cannot validate: '+str(exc));return 1
    for line in result['failures']: print(line)
    for key in result['unused']: print('warning: unused string candidate: '+key)
    print(f'string lint: {len(result["found"])} dynamic families, {len(result["required"])} keys checked, {len(result["unused"])} unused candidates')
    print('string lint: clean' if not result['failures'] else f'string lint: {len(result["failures"])} failure(s)')
    return int(bool(result['failures']))

if __name__=='__main__':
    sys.exit(main())
