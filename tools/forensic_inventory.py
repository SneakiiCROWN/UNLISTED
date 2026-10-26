"""Read-only mechanical coverage. Findings are candidates, never crash diagnoses."""
from pathlib import Path
import ast,collections,hashlib,json,re,struct,subprocess,zipfile
G=Path(__file__).resolve().parents[1];R=G.parent
O=R/'Checkpoints/20261026_full_forensic_audit';O.mkdir(exist_ok=True)
def write(name,value):
    (O/name).write_text(json.dumps(value,indent=2,ensure_ascii=False),encoding='utf8')
def digest(p,algorithm='sha256'):
    h=hashlib.new(algorithm)
    with p.open('rb') as f:
        while block:=f.read(1024*1024):h.update(block)
    return h.hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True)
tracked=[G/n for n in git('ls-files').splitlines() if (G/n).is_file()]
write('source_manifest.json',{'commit':git('rev-parse','HEAD').strip(),'files':[{'path':p.relative_to(G).as_posix(),'size':p.stat().st_size,'sha256':digest(p)} for p in tracked]})
library=[p for p in (R/'Assets').rglob('*') if p.is_file()]
write('asset_library_inventory.json',{'scope':'All existing library files indexed; contents not all artistically reviewed. No extraction/mutation.','count':len(library),'bytes':sum(p.stat().st_size for p in library),'files':[{'path':p.relative_to(R/'Assets').as_posix(),'size':p.stat().st_size} for p in library]})
texts=[p for folder in ['scripts','scenes','shaders','themes','tools'] for p in (G/folder).rglob('*') if p.is_file() and p.suffix in ['.gd','.gdshader','.tscn','.tres','.py']]
patterns={'free':r'\b(?:queue_free|free|remove_child)\s*\(', 'async':r'\b(?:await|create_timer|call_deferred|CONNECT_DEFERRED)\b','signals':r'\.connect\s*\(', 'thread':r'\b(?:Thread|WorkerThreadPool|load_threaded_request|Mutex|Semaphore)\b','always':r'PROCESS_MODE_ALWAYS','allocations':r'\b(?:new|instantiate|duplicate)\s*\(','settings':r'\b(?:save_game|save_file|checkpoint_path|user://)\b'}
coverage=[];edges=[];missing=[];risks=collections.defaultdict(list);python_errors=[]
for p in sorted(texts):
    rel=p.relative_to(G).as_posix();text=p.read_text(encoding='utf-8-sig',errors='strict');lines=text.splitlines()
    coverage.append({'path':rel,'lines':len(lines),'kind':'qa' if p.stem.endswith('_qa') or '_views' in p.stem else ('tool' if p.parts[len(G.parts)]=='tools' else 'production_or_study'),'mechanical_scan':True,'manual_review':'pending'})
    for i,line in enumerate(lines,1):
        for m in re.finditer(r'["\'](res://[^"\'\n]*)["\']',line):
            resource=m.group(1);target=G/resource[6:];exists=target.exists();dynamic=any(c in resource for c in ['%','{','*'])
            item={'source':rel,'line':i,'resource':resource,'exists':exists,'dynamic_pattern':dynamic,'directory':target.is_dir()}
            edges.append(item)
            if not exists and not dynamic:missing.append(item)
        if p.suffix=='.gd':
            for label,pattern in patterns.items():
                if re.search(pattern,line):risks[label].append({'file':rel,'line':i,'text':line.strip()})
    if p.suffix=='.py':
        try:ast.parse(text,filename=rel)
        except SyntaxError as e:python_errors.append({'file':rel,'line':e.lineno,'error':str(e)})
write('code_coverage.json',coverage);write('resource_edges.json',edges);write('literal_missing_candidates.json',missing);write('lifecycle_candidates.json',risks);write('python_syntax.json',{'parsed':sum(p.suffix=='.py' for p in texts),'errors':python_errors})
imports=[]
for p in (G/'assets').rglob('*.import'):
    text=p.read_text(encoding='utf8');source=re.search(r'^source_file="res://([^"]+)"',text,re.M)
    paths=re.findall(r'^path(?:\.[^=]+)?="res://([^"]+)"',text,re.M)
    raw=G/source[1] if source else None
    row={'file':p.relative_to(G).as_posix(),'source':source[1] if source else None,'source_exists':bool(raw and raw.exists()),'destinations':[{'path':n,'exists':(G/n).exists()} for n in paths]}
    md5file=next(iter(p for p in (G/'.godot/imported').glob((raw.name if raw else '')+'-*.md5')),None)
    if raw and raw.exists() and md5file:
        # Same basename can occur in several folders; verify the .import's own hash stem.
        if paths:md5file=(G/paths[0]).with_suffix('.md5')
        if md5file.exists():
            m=re.search(r'source_md5="([0-9a-f]+)"',md5file.read_text());row['source_md5_matches']=bool(m and digest(raw,'md5')==m[1])
    imports.append(row)
write('import_integrity_before.json',imports)
models=[]
for p in (G/'assets').rglob('*.glb'):
    row={'file':p.relative_to(G).as_posix(),'bytes':p.stat().st_size,'errors':[]}
    try:
        data=p.read_bytes();magic,version,length=struct.unpack_from('<III',data)
        assert magic==0x46546c67 and version==2 and length==len(data),'GLB header/length'
        pos=12;doc=None;bins=[]
        while pos<len(data):
            size,kind=struct.unpack_from('<II',data,pos);pos+=8;assert pos+size<=len(data),'chunk bounds'
            chunk=data[pos:pos+size];pos+=size
            if kind==0x4e4f534a:doc=json.loads(chunk.decode('utf8').rstrip('\0 '))
            elif kind==0x004e4942:bins.append(chunk)
        assert doc is not None,'missing JSON'
        nodes=doc.get('nodes',[]);views=doc.get('bufferViews',[]);buffers=doc.get('buffers',[])
        for view in views:
            assert view['buffer']<len(buffers),'buffer index'
            assert view.get('byteOffset',0)+view['byteLength']<=buffers[view['buffer']]['byteLength'],'buffer view bounds'
        for skin in doc.get('skins',[]):assert all(0<=n<len(nodes) for n in skin['joints']),'skin joint index'
        for node in nodes:assert all(0<=n<len(nodes) for n in node.get('children',[])),'child node index'
        for anim in doc.get('animations',[]):
            for channel in anim['channels']:
                assert channel['sampler']<len(anim['samplers']),'animation sampler'
                if 'node' in channel['target']:assert channel['target']['node']<len(nodes),'animation node'
        row.update(nodes=len(nodes),meshes=len(doc.get('meshes',[])),skins=len(doc.get('skins',[])),animations=len(doc.get('animations',[])),images=len(doc.get('images',[])))
    except Exception as e:row['errors'].append(str(e))
    models.append(row)
write('glb_container_audit.json',models)
refs=[('0.10.6','cfd79af'),('0.10.7','7dc6c29'),('0.10.8','248b3aa'),('0.10.9','c4710ce'),('diagnostics',git('rev-parse','HEAD').strip())]
history=[]
for (old,base),(new,tip) in zip(refs,refs[1:]):
    changes=[]
    for line in git('diff','--numstat',base,tip).splitlines():
        added,removed,path=line.split('\t',2)
        kind='test_tool' if path.startswith('tools/') or path.endswith('_qa.gd') else 'asset' if path.startswith('assets/') else 'shader' if path.startswith('shaders/') else 'config' if path in ['project.godot','export_presets.cfg'] else 'gameplay_scene' if path.startswith(('scripts/','scenes/')) else 'documentation'
        changes.append({'file':path,'added':added,'removed':removed,'category':kind})
    history.append({'from':old,'to':new,'base':git('rev-parse',base).strip(),'tip':git('rev-parse',tip).strip(),'changes':changes,'commits':git('log','--format=%H %aI %s',base+'..'+tip).splitlines()})
write('milestone_change_map.json',history)
(O/'all_git_history.txt').write_text(git('log','--reverse','--date=iso','--format=commit %H %ad %s','--name-status'),encoding='utf8')
summary={'scripts':sum(p.suffix=='.gd' for p in texts),'shaders':sum(p.suffix=='.gdshader' for p in texts),'scenes':sum(p.suffix=='.tscn' for p in texts),'tools_python':sum(p.suffix=='.py' for p in texts),'literal_edges':len(edges),'missing_literal_candidates':len(missing),'import_descriptors':len(imports),'missing_import_destinations':sum(not d['exists'] for r in imports for d in r['destinations']),'stale_source_md5':sum(r.get('source_md5_matches') is False for r in imports),'glb_models':len(models),'glb_container_errors':[r for r in models if r['errors']],'python_errors':python_errors,'total_git_commits':int(git('rev-list','--count','HEAD')),'library_files':len(library),'library_bytes':sum(p.stat().st_size for p in library)}
write('inventory_summary.json',summary);print(json.dumps(summary,indent=2))
