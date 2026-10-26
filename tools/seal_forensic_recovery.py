"""Private recovery archive/receipt only. Requires completed ordinary observations."""
from pathlib import Path
import hashlib,json,subprocess,sys,zipfile

G=Path(__file__).resolve().parents[1];R=G.parent
O=R/'Checkpoints/20261026_full_forensic_audit'
I=O/'PrivateCandidate/IndependentExtract'
P=Path(r'C:\Users\Snkii\Documents\Codex\2026-10-20\sneakiicrown-temporary-public-releases\work\public\UNLISTED')
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        while b:=f.read(1024*1024):h.update(b)
    return h.hexdigest()
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()

assert not git('status','--porcelain'), 'Commit complete source first'
assert not git('diff','4d6e32c','HEAD','--','scripts','assets','scenes','themes','shaders','project.godot','export_presets.cfg'), 'Runtime changed since export; do not mislabel it'
tag=sys.argv[1]
private=git('rev-parse','HEAD');public=git('rev-parse','HEAD',cwd=P)
assert git('rev-parse',tag)==private
assert git('rev-parse',tag,cwd=P)==public
remote=git('ls-remote','origin','refs/heads/main','refs/tags/'+tag,cwd=P)
assert all(line.startswith(public+'\t') for line in remote.splitlines()) and len(remote.splitlines())==2, 'Remote checkpoint/tag not verified'
delivery=read(O/'PrivateCandidate/DELIVERY.json')
windows=Path(delivery['windows_zip'])
assert sha(windows)==delivery['windows_sha256'] and sha(I/'UNLISTED.exe')==delivery['executable_sha256']
with zipfile.ZipFile(windows) as z:assert z.testzip() is None
ordinary=[]
for name in ['ordinary_repair_01','ordinary_repair_02']:
    folder=O/name;result=read(folder/'result.json')
    assert result['exit_code']==0 and result['target_duration_reached'] and result['owner_unchanged']
    assert (folder/'observed_start.png').is_file() and (folder/'observed_end.png').is_file()
    samples=[json.loads(line) for line in (folder/'heartbeats.jsonl').read_text().splitlines()]
    values=[r['process_counters'] for r in samples if r['seconds']>=120 and r.get('process_counters',{}).get('available')]
    stats={k:{'first':values[0][k],'last':values[-1][k],'minimum':min(r[k] for r in values),'maximum':max(r[k] for r in values)} for k in ['working_set_bytes','private_commit_bytes','handles']}
    summary={'scope':'External process counters after120s warmup, not VRAM/FPS or proof of no leak.','samples':len(values),'statistics':stats}
    (folder/'counter_summary.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
    ordinary.append({'evidence':str(folder),'result':result,'counters':summary})
checks={}
repair=read(R/'Builds/UNLISTED_Forensic_Repair_02/QA/forensic/forensic_report.json')
assert repair['failed']==0
checks['focused_save_audio_repair']={'passed':repair['passed'],'failed':repair['failed'],'evidence':str(R/'Builds/UNLISTED_Forensic_Repair_02/QA/forensic')}
negative=read(R/'Builds/UNLISTED_Forensic_Repair_02/QA/missing_recorder/result.json')
assert negative['controlled_rejection'] and negative['actual_exit']==92 and negative['owner_unchanged'] and not negative['native_access_violation'] and not negative['script_errors']
for name,file in [('forensic_threat','threat_report.json'),('forensic_recorder_recovery','repair_report.json'),('forensic_ending_a','repair_report.json'),('forensic_ending_b_story','repair_report.json')]:
    report=read(I/'QA'/name/file);assert report['failed']==0
    integrity=read(I/(name+'_owner_integrity.json'));assert integrity['unchanged']
    checks[name]={'passed':report['passed'],'failed':report['failed'],'evidence':str(I/'QA'/name)}
source=O/'UNLISTED_Forensic_Complete_Private_Source.zip'
assert not source.exists(), 'Never overwrite a previous recovery'
names=git('ls-files','-z').split('\0')
# git() strips whitespace, not the NUL terminator; paths are repository tracked.
files={G/n:'UNLISTED_Game/'+n.replace('\\','/') for n in names if n and (G/n).is_file()}
for p in (G/'tools/asset_sources').rglob('*'):
    if p.is_file():files[p]='UNLISTED_Game/'+p.relative_to(G).as_posix()
manifest={'private_commit':private,'public_commit':public,'tag':tag,'scope':'Complete tracked Game source/runtime licensed assets plus preserved extracted tools/asset_sources. Generated import cache, historical QA captures and .git excluded. Raw9.7GB asset inbox, builds and original dumps remain separately preserved locally, not duplicated.','files':[{'path':name,'bytes':p.stat().st_size,'sha256':sha(p)} for p,name in sorted(files.items())]}
with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p,name in sorted(files.items()):z.write(p,name)
    z.writestr('PRIVATE_SOURCE_MANIFEST.json',json.dumps(manifest,indent=2))
    z.write(O/'raw_library_hashes_and_archives.json','PRESERVED_RAW_LIBRARY_INDEX.json')
with zipfile.ZipFile(source) as z:assert z.testzip() is None
bundle=O/'UNLISTED_Forensic_History.bundle'
assert not bundle.exists()
subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True)
subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
delivery.update(private_source=private,public_source=public,development_tag=tag,runtime_source='4d6e32c92ba14573cb6b119997cf3a02622ddbc6',ordinary_idle=ordinary,focused_extracted_checks=checks,negative_recorder_fixture=negative,complete_private_source_zip=str(source),source_sha256=sha(source),source_files=len(files),private_history_bundle=str(bundle),history_bundle_sha256=sha(bundle),graphics_baseline=str(O/'GraphicsBaseline01/BASELINE_GALLERY.html'),owner_crash='Unresolved; two ordinary repaired observations are not proof of a fix',public_release='Unchanged; no release published')
(O/'PrivateCandidate/DELIVERY.json').write_text(json.dumps(delivery,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in delivery.items() if k not in ['ordinary_idle','focused_extracted_checks']},indent=2))
