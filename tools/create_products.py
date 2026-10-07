#!/usr/bin/env python3
"""Plan/create missing launch shop items; --dry-run is offline and the default.

Official references verified 2026-10-07:
https://create.roblox.com/docs/cloud/reference/features/game-passes
https://create.roblox.com/docs/cloud/reference/features/developer-products
POST /game-passes/v1/universes/{universeId}/game-passes (multipart;
name, description, price, isForSale, optional imageFile; game-pass:write).
GET same path + /creator (game-pass:read): gamePasses, nextPageToken.
POST /developer-products/v2/universes/{universeId}/developer-products
(same multipart fields; developer-product:write).
GET same path + /creator (developer-product:read): developerProducts, nextPageToken.
GET /universes/v1/places/{placeId}/universe resolves universeId.
All use https://apis.roblox.com; --apply uses ROBLOX_API_KEY only.
Self-tests use fake HTTP and temporary copies, never the environment key or network.
"""
import argparse
import contextlib
import io
import json
import mimetypes
import os
from pathlib import Path
import re
import ssl
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parent))
from luau_tables import load

ROOT = Path(__file__).resolve().parents[1]
API = 'https://apis.roblox.com'
KINDS = {'pass':('game-passes/v1','game-passes','gamePasses','gamePassId','passId'),
         'product':('developer-products/v2','developer-products','developerProducts','productId','productId')}


class ToolError(Exception):
    pass


def positive(value):
    if isinstance(value,bool) or not str(value).isdigit() or int(value)<=0:
        raise ToolError('expected a positive integer id')
    return int(value)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # Never forward x-api-key to a redirected host.


class HTTP:
    def __init__(self,key):
        if not key:raise ToolError('ROBLOX_API_KEY is required for --apply')
        self.key=key
        # Use the OS-maintained CA file when a framework Python has no installed default CA.
        context=ssl.create_default_context()
        if context.cert_store_stats()['x509_ca']==0 and Path('/etc/ssl/cert.pem').is_file():
            context.load_verify_locations('/etc/ssl/cert.pem')
        self.opener=urllib.request.build_opener(NoRedirect(),urllib.request.HTTPSHandler(context=context))

    def request(self,method,path,body=None,content_type=None):
        if not path.startswith('/') or path.startswith('//'):raise ToolError('invalid API path')
        headers={'x-api-key':self.key,'Accept':'application/json'}
        if content_type:headers['Content-Type']=content_type
        request=urllib.request.Request(API+path,data=body,headers=headers,method=method)
        try:
            with self.opener.open(request,timeout=30) as response:
                result=json.load(response)
            if not isinstance(result,dict):raise ToolError('unexpected API response shape')
            return result
        except urllib.error.HTTPError as exc:
            message='request refused'
            try:
                payload=json.loads(exc.read().decode('utf-8').replace(self.key,'[redacted]'))
                if isinstance(payload,dict):
                    message=payload.get('message') or '; '.join(str(e.get('message','')) for e in payload.get('errors',[]) if isinstance(e,dict)) or message
            except (ValueError,UnicodeError):pass
            message=str(message).replace(self.key,'[redacted]')
            message=' '.join(message.split())[:500]
            raise ToolError(f'HTTP {exc.code}: {message}') from None
        except (urllib.error.URLError,TimeoutError,OSError):
            raise ToolError('HTTPS transport failed; check connectivity and trusted CA configuration') from None
        except (ValueError,UnicodeError):
            raise ToolError('invalid JSON response') from None


def path_for(kind,universe):
    prefix,resource,*_=KINDS[kind]
    return f'/{prefix}/universes/{positive(universe)}/{resource}'


def source_place(root):
    worlds=load(root/'src/shared/data/Worlds.luau')
    for world in (1,2):
        place=worlds[world]['placeId']
        if place:return positive(place)
    raise ToolError('Worlds 1 and 2 both have placeId 0; supply --universe')


def resolve_universe(http,root,universe):
    return positive(universe) if universe else positive(http.request('GET',f'/universes/v1/places/{source_place(root)}/universe')['universeId'])


def plan(root=ROOT):
    shop=load(root/'src/shared/data/Shop.luau')
    strings=load(root/'src/shared/strings/en.luau')
    items={r['id']:r for r in shop['Items']}
    guide=(root/'docs/OWNER-GUIDE.md').read_text()
    icons={m[1]:m[2] for m in re.finditer(r'^\|\s*(\w+)\s*\|[^\n]*`~/Roblox-Alien-Game/(assets/[^`]+)`',guide,re.M)}
    out=[];seen=set()
    for section in shop['Launch']:
        for sid in section['items']:
            if sid in seen:raise ToolError('duplicate launch id: '+sid)
            seen.add(sid)
            row=items[sid];field=KINDS[row['kind']][4]
            if row.get(field)!=0:continue
            if sid not in icons:raise ToolError('owner guide has no icon mapping for '+sid)
            out.append(dict(id=sid,kind=row['kind'],name=strings['SHOP_ITEM_'+sid],
                            description=strings['SHOP_DESC_'+sid],price=row['robux'],icon=icons[sid]))
    return out


def multipart(row,root):
    boundary='RobloxAlienGameProvisionBoundary'
    chunks=[]
    for name,value in sorted(dict(name=row['name'],description=row['description'],price=str(row['price']),isForSale='true').items()):
        chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
    image=root/row['icon']
    if image.is_file():
        mime=mimetypes.guess_type(image.name)[0] or 'application/octet-stream'
        chunks += [f'--{boundary}\r\nContent-Disposition: form-data; name="imageFile"; filename="{image.name}"\r\nContent-Type: {mime}\r\n\r\n'.encode(),image.read_bytes(),b'\r\n']
    else:print('warning: missing icon, image omitted: '+row['icon'])
    chunks.append(f'--{boundary}--\r\n'.encode())
    return b''.join(chunks),'multipart/form-data; boundary='+boundary


def list_items(http,kind,universe):
    token='';seen=set();out=[]
    while True:
        query=urllib.parse.urlencode({'pageSize':50,**({'pageToken':token} if token else {})})
        response=http.request('GET',path_for(kind,universe)+'/creator?'+query)
        rows=response.get(KINDS[kind][2])
        if not isinstance(rows,list):raise ToolError('missing catalog list; refusing to create duplicates')
        if any(not isinstance(r,dict) or not isinstance(r.get('name'),str) for r in rows):raise ToolError('malformed catalog entry')
        out.extend(rows)
        token=response.get('nextPageToken') or ''
        if not token:return out
        if not isinstance(token,str) or token in seen:raise ToolError('invalid/repeated catalog page token')
        seen.add(token)


def replace_id(source,row,value):
    value=positive(value);field=KINDS[row['kind']][4]
    # Literal flat Shop.Items rows; multiline formatter output is supported, nested new shapes fail closed.
    items_start=source.index('local Items')
    items_end=source.index('\n}',items_start)+2
    matches=list(re.finditer(r'\{[^{}]*\bid\s*=\s*"'+re.escape(row['id'])+r'"[^{}]*\}',source[items_start:items_end]))
    if len(matches)!=1:raise ToolError('cannot uniquely locate shop row '+row['id'])
    block=matches[0]
    ids=list(re.finditer(r'\b'+field+r'\s*=\s*(\d+)\b',block[0]))
    if len(ids)!=1 or ids[0][1]!='0':raise ToolError('shop id changed; refusing write-back for '+row['id'])
    start=items_start+block.start()+ids[0].start(1);end=items_start+block.start()+ids[0].end(1)
    return source[:start]+str(value)+source[end:]


def apply(http,root,rows,universe,pause=lambda:None):
    shop=root/'src/shared/data/Shop.luau'
    # Validate every local edit before the first remote create; list BOTH kinds first.
    for row in rows:replace_id(shop.read_text(),row,1)
    existing={kind:list_items(http,kind,universe) for kind in KINDS}
    for row in rows:
        matches=[r for r in existing[row['kind']] if r['name']==row['name']]
        if len(matches)>1:raise ToolError('multiple existing items share name: '+row['name'])
        if matches:positive(matches[0].get(KINDS[row['kind']][3]))
    result=[]
    for row in rows:
        matches=[r for r in existing[row['kind']] if r['name']==row['name']]
        source=shop.read_text()
        replace_id(source,row,1)
        action='reused' if matches else 'created'
        if matches:
            record=matches[0]
            print('warning: reusing matching name; existing price/icon/config are unchanged: '+row['id'])
        else:
            pause()
            body,content_type=multipart(row,root)
            record=http.request('POST',path_for(row['kind'],universe),body,content_type)
        value=positive(record.get(KINDS[row['kind']][3]))
        if shop.read_text()!=source:raise ToolError('Shop changed during request; rerun to reuse the created item')
        updated=replace_id(source,row,value)
        # Atomic replace, so a stopped run never leaves half a Luau file. Each success is durable locally.
        with tempfile.NamedTemporaryFile('w',dir=shop.parent,prefix='.shop-',delete=False) as stream:
            stream.write(updated);temp=Path(stream.name)
        temp.chmod(shop.stat().st_mode);temp.replace(shop)
        existing[row['kind']].append(record) if not matches else None
        result.append((row['id'],value,action))
    return result


def self_test():
    # Exercise the complete launch catalog even after all real IDs have been filled.
    with tempfile.TemporaryDirectory() as folder:
        fixture_root=Path(folder)
        for relative in ('src/shared/data/Shop.luau','src/shared/strings/en.luau','docs/OWNER-GUIDE.md'):
            target=fixture_root/relative;target.parent.mkdir(parents=True,exist_ok=True)
            content=(ROOT/relative).read_text()
            if relative.endswith('Shop.luau'):
                content=re.sub(r'((?:passId|productId)\s*=\s*)\d+',r'\g<1>0',content)
            target.write_text(content)
        rows=plan(fixture_root)
    shop_data=load(ROOT/'src/shared/data/Shop.luau')
    expected={sid for section in shop_data['Launch'] for sid in section['items']}
    # Synthetic IDs live in this fixture; prices/names/descriptions come from current tables.
    fixture={row['id']:10000+i for i,row in enumerate(rows)}
    class Fake:
        def __init__(self,reuse=False):self.calls=[];self.reuse=reuse
        def request(self,method,path,body=None,content_type=None):
            self.calls.append((method,path))
            kind='pass' if '/game-passes/' in path else 'product'
            if method=='GET':
                catalog=[{'name':r['name'],KINDS[kind][3]:fixture[r['id']]} for r in rows if r['kind']==kind] if self.reuse else []
                return {KINDS[kind][2]:catalog,'nextPageToken':''}
            row=next(r for r in rows if r['name'].encode() in body)
            assert b'name="price"' in body and str(row['price']).encode() in body
            assert content_type.startswith('multipart/form-data;')
            return {KINDS[kind][3]:fixture[row['id']],'name':row['name']}
    checks=0
    assert {r['id'] for r in rows}==expected;checks+=1
    with tempfile.TemporaryDirectory() as folder,contextlib.redirect_stdout(io.StringIO()):
        root=Path(folder);shop=root/'src/shared/data/Shop.luau';shop.parent.mkdir(parents=True)
        original=re.sub(r'((?:passId|productId)\s*=\s*)\d+',r'\g<1>0',(ROOT/'src/shared/data/Shop.luau').read_text());shop.write_text(original)
        fake=Fake();results=apply(fake,root,rows,1);assert len(results)==len(rows);checks+=1
        restored=shop.read_text()
        for row in rows:
            restored=restored.replace(str(fixture[row['id']]),'0')
        assert restored==original;checks+=1
        assert len([c for c in fake.calls if c[0]=='POST'])==len(rows);checks+=1
        shop.write_text(original);fake=Fake(True);apply(fake,root,rows,1)
        assert not any(c[0]=='POST' for c in fake.calls);checks+=1
        try:HTTP('')
        except ToolError:checks+=1
        else:raise AssertionError('missing key accepted')
        try:replace_id(shop.read_text(),rows[0],fixture[rows[0]['id']])
        except ToolError:checks+=1
        else:raise AssertionError('nonzero overwrite accepted')
        body,_=multipart(rows[0],root);assert b'name="imageFile"' not in body;checks+=1
        missing=root/rows[0]['icon'];missing.parent.mkdir(parents=True);missing.write_bytes(b'fixture-image')
        body,_=multipart(rows[0],root);assert b'fixture-image' in body;checks+=1
        assert '\n' in original and replace_id(original.replace(', ', ',\n '),rows[0],fixture[rows[0]['id']]);checks+=1
    class Pages:
        def __init__(self):self.count=0
        def request(self,*args):
            self.count+=1
            return {'gamePasses':[], 'nextPageToken':'cursor' if self.count==1 else ''}
    pages=Pages();assert list_items(pages,'pass',1)==[] and pages.count==2;checks+=1
    class Repeated:
        def request(self,*args):return {'gamePasses':[], 'nextPageToken':'same'}
    try:list_items(Repeated(),'pass',1)
    except ToolError:checks+=1
    else:raise AssertionError('repeated token accepted')
    class ErrorOpener:
        def open(self,*args,**kwargs):
            raise urllib.error.HTTPError(API,403,'',{},io.BytesIO(b'{"message":"denied fake-fixture-secret"}'))
    http=HTTP('fake-fixture-secret');http.opener=ErrorOpener()
    try:http.request('GET','/fixture')
    except ToolError as exc:
        assert 'fake-fixture-secret' not in str(exc) and 'HTTP 403' in str(exc);checks+=1
    else:raise AssertionError('HTTP error swallowed')
    print(f'create products self-test: {checks} passed (fake HTTP, no network)')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    modes=parser.add_mutually_exclusive_group()
    modes.add_argument('--dry-run',action='store_true')
    modes.add_argument('--apply',action='store_true')
    modes.add_argument('--self-test',action='store_true')
    parser.add_argument('--universe',type=int)
    args=parser.parse_args()
    try:
        if args.self_test:self_test();return 0
        if args.universe is not None:positive(args.universe)
        rows=plan()
        print('id | name | Robux | kind | icon')
        for r in rows:
            print(f'{r["id"]} | {r["name"]} | {r["price"]} | {r["kind"]} | {r["icon"]}')
            if not (ROOT/r['icon']).is_file():print('warning: missing icon, image will be omitted: '+r['icon'])
        if not args.apply:
            print(f'dry-run: {len(rows)} launch items; no network or file changes; universe '+(str(args.universe) if args.universe else f'resolved on apply from place {source_place(ROOT)}'))
            return 0
        if not rows:print('nothing to create');return 0
        http=HTTP(os.environ.get('ROBLOX_API_KEY',''))
        universe=resolve_universe(http,ROOT,args.universe)
        print('id | returned id | action')
        for sid,value,action in apply(http,ROOT,rows,universe,pause=lambda:time.sleep(.4)):
            print(f'{sid} | {value} | {action}')
        return 0
    except (ToolError,OSError,KeyError,ValueError) as exc:
        # Only our controlled ToolError text is exposed. Never print request objects or raw exceptions.
        print(str(exc) if isinstance(exc,ToolError) else 'local data/file validation failed',file=sys.stderr)
        return 1

if __name__=='__main__':raise SystemExit(main())
