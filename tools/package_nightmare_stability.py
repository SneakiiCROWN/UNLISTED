"""Private forensic checkpoint. No public binaries, private memory or raw media uploads."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile
from package_phase5 import sha,archive
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_nightmare_stability'
P=C/'Package';I=C/'IndependentExtract';Z=U/'Builds/UNLISTED-Windows-Nightmare-Stability-v0.10.9-dev-PRIVATE.zip'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True,encoding='utf8').strip()
def good(name):
 r=read(C/name/'result.json')
 assert r['exit_code']==0 and not r['errors'] and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),name
 return r
def stage():
 assert not P.exists() and not I.exists() and not Z.exists()
 room=good('MutedRoom03');idle=good('MutedLateCapture04')
 P.mkdir();shutil.copy2(C/'Candidate01/UNLISTED.exe',P/'UNLISTED.exe')
 for name in ['NIGHTMARE_STABILITY_REPORT.md','THIRD_PARTY.md']:shutil.copy2(G/name,P/name)
 shutil.copytree(U/'Checkpoints/20261028_operation_stability/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
 (P/'START_HERE.txt').write_text('PRIVATE QA - STABILITY NOT CLEARED. Extract the whole ZIP. Launch UNLISTED.exe normally for gameplay. No native crash cure is claimed. Existing saves/settings remain in their normal location; this build does not reset them. Diagnostic sessions used copied data and were muted at the owner request; ordinary player audio settings are unchanged. No personal playtest is requested. See NIGHTMARE_STABILITY_REPORT.md and EVIDENCE.html. Do not redistribute licensed assets or private diagnostic memory.\n',encoding='utf8')
 page='<meta charset="utf-8"><title>Nightmare Stability</title><style>body{background:#101416;color:#ddd;font:16px sans-serif;margin:24px}a{color:#acf}img{max-width:1280px;width:95%}</style><h1>PRIVATE QA - STABILITY NOT CLEARED</h1><p>Real late-attach particle rejection captured. No native crash repair proven. New hidden-window checks muted at owner request, with MW4 running concurrently; no audio or performance clearance.</p>'
 names=['OrdinaryCapture01','OrdinaryCapture02','MutedRoom03','MutedLateCapture04']
 allowed={'result.json','launch.json','status.json','game.log','stdout.log','native.log','engine_errors_live.jsonl','native_hold.json','late_attach_result.json','repair_report.json','report.json','checks_live.jsonl','native_frame_timing.json','resource_lifecycle.jsonl','quit_action.json'}
 for name in names:
  src=C/name;out=P/'Evidence'/name;out.mkdir(parents=True)
  for f in src.iterdir():
   if f.suffix=='.png' or f.name in allowed:shutil.copy2(f,out/f.name)
  page+='<h2>'+html.escape(name)+'</h2>'
  for f in sorted(out.glob('*.png')):page+='<p>'+html.escape(f.stem)+'</p><img loading="lazy" src="'+f.relative_to(P).as_posix()+'">'
  if (out/'result.json').exists():page+='<p><a href="'+(out/'result.json').relative_to(P).as_posix()+'">Actual result</a></p>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8')
 (P/'CHANGED_FILES.txt').write_text(git('diff','--name-status','0b297c4','HEAD')+'\n',encoding='utf8')
 archive(P,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate01/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'status':'PRIVATE QA - STABILITY NOT CLEARED','windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'runtime_provenance':'Candidate01 export of the diagnostic changes subsequently checkpointed as 286bfa4; later changes are comments, host capture tools and documentation. No game-rendering repair.','room_check':room,'idle_check':idle,'ordinary_failure':read(C/'OrdinaryCapture01/result.json'),'second_ordinary_observation':read(C/'OrdinaryCapture02/result.json'),'public_release':'None','human_playtesting':'Pending'},indent=2),encoding='utf8')
 print(Z)
def recover():
 assert not git('status','--porcelain')
 private=git('rev-parse','HEAD');extracted=good('ExtractedCheck');public=read(C/'PUBLIC_CHECKPOINT.json')
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for f in (G/'tools/asset_sources').rglob('*'):
  if f.is_file():files[f]='UNLISTED_Game/tools/asset_sources/'+f.relative_to(G/'tools/asset_sources').as_posix()
 source=C/'UNLISTED_Nightmare_Stability_Complete_Private_Source.zip'
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f,n in files.items():z.write(f,n)
  with zipfile.ZipFile(U/'Checkpoints/20261028_operation_stability/UNLISTED_Operation_Stability_Complete_Private_Source.zip') as old:
   for n in old.namelist():
    if n.startswith(('Private_Weatherhood_Study/','Private_Art_Revision/','Pinned_Engine_References/')):z.writestr(n,old.read(n))
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked game and consumed licensed media, ignored authoring sources, preserved private editable art and pinned engine references. Original raw Assets inbox, owner data, previous builds and process-memory dumps remain separately preserved, not copied to public GitHub. Source '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Nightmare_Stability_Private_History.bundle';assert not bundle.exists()
 subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 d=read(C/'STAGED_DELIVERY.json');d.update(private_source=private,public_source=public,complete_source=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,all_three_native_faults='Unresolved; no common cause established')
 (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in d.items() if k not in ['room_check','idle_check','ordinary_failure','second_ordinary_observation','extracted_verification']},indent=2))
if __name__=='__main__':{'stage':stage,'recover':recover}[sys.argv[1]]()
