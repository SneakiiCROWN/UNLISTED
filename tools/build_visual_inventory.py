"""Read-only reuse index and original-image gallery; no game/import/settings writes."""
from pathlib import Path
import collections,csv,hashlib,html,json,sys

G=Path(__file__).resolve().parents[1]
A=G.parent/'Checkpoints/20261026_full_forensic_audit'
O=Path(sys.argv[1]).resolve()
assert not O.exists(), 'Preserve previous inventories; choose a new output folder'
O.mkdir(parents=True)
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
edges=read(A/'resource_edges.json')
assets=read(A/'native_asset_report.json')['rows']
raw=read(A/'raw_library_hashes_and_archives.json')['rows']
rows=[]
for asset in assets:
    relative=asset['file'][6:];p=G/relative
    references=[f"{r['source']}:{r['line']}" for r in edges if r['resource']==asset['file']]
    # These are discovery pointers, not an inferred permission grant.
    notices=[]
    for parent in [p.parent,*p.parent.parents]:
        if parent==G:break
        for q in parent.iterdir():
            if q.is_file() and (q.name.lower().endswith('provenance.json') or any(s in q.name.lower() for s in ['license','licence','cc0'])):
                notices.append(q.relative_to(G).as_posix())
    row={'path':str(p),'resource':asset['file'],'kind':asset['class'],'bytes':p.stat().st_size,
         'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'direct_literal_references':references,
         'dependencies':asset['dependencies'],'statistics':asset['statistics'],
         'licence_review_pointers':sorted(set(notices)),
         'rights_status':'Existing project resource; consult retained provenance before new redistribution. No blanket rights approval.'}
    rows.append(row)
report={'scope':'275 imported resources, all raw-library files previously hashed. Exact direct literals only; dynamic references are not inferred. No new media copied or approved.',
        'runtime_resources':rows,'raw_library':raw,
        'render_config':{'engine':'4.7.2-stable ed1daf0bf','renderer':'Forward+ Vulkan','runtime_executable_sha256':'46ef067cb9efe11f311ed68bf6cd8bb3a56b7a9512051bd8f5ff8832e2068571'},
        'raw_library_root':str(G.parent/'Assets')}
(O/'visual_asset_inventory.json').write_text(json.dumps(report,indent=2),encoding='utf8')
with (O/'visual_asset_inventory.csv').open('w',newline='',encoding='utf-8-sig') as f:
    w=csv.writer(f);w.writerow(['Exact path','Kind','Bytes','SHA256','Direct source references','Licence review pointers'])
    for r in rows:w.writerow([r['path'],r['kind'],r['bytes'],r['sha256'],'; '.join(r['direct_literal_references']),'; '.join(r['licence_review_pointers'])])
I=A/'PrivateCandidate/IndependentExtract'
sections=[];images=[]
for name,size in [('baseline1080',(1920,1080)),('baseline1440',(2560,1440)),('baselinewide',(3440,1440))]:
    folder=I/'QA'/name
    for p in sorted(folder.glob('V*.png')):
        from PIL import Image
        with Image.open(p) as im:assert im.size==size,(p,im.size,size)
        images.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':size})
    cards=''.join('<figure><a href="'+html.escape(p.as_uri())+'"><img loading="lazy" src="'+html.escape(p.as_uri())+'"></a><figcaption>'+html.escape(p.stem)+'</figcaption></figure>' for p in sorted(folder.glob('V*.png')))
    sections.append('<h2>'+name+'</h2><div>'+cards+'</div>')
assert len(images)==36, 'Incomplete three-size baseline'
(O/'baseline_image_manifest.json').write_text(json.dumps(images,indent=2),encoding='utf8')
(O/'BASELINE_GALLERY.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED native baseline</title><style>body{background:#111;color:#ddd;font:16px sans-serif;margin:24px}div{display:grid;grid-template-columns:repeat(3,1fr);gap:15px}figure{margin:0}img{width:100%}a{color:#bde}</style><h1>Forensic02 — unmodified graphics baseline</h1><p>Original native Windows renders, powered placement fixture. These are not fresh movement-route tests or after-images. Three render sizes inside an isolated viewport; no physical ultrawide display claim. Weather/time animation is not deterministic.</p>'+''.join(sections),encoding='utf8')
print(json.dumps({'runtime_resources':len(rows),'raw_library_files':len(raw),'native_baseline_images':len(images),'output':str(O)}))
