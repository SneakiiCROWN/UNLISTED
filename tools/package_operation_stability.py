"""Private forensic delivery. Never treats a clean observation as a crash fix."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile
from package_phase5 import sha,archive
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_operation_stability'
P=C/'Package';I=C/'IndependentExtract';Z=U/'Builds/UNLISTED-Windows-Operation-Stability-v0.10.9-dev-PRIVATE.zip'
TAG='dev-operation-stability-20261028';RUNTIME='b530e0f'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True,encoding='utf8').strip()
def valid(path):
 r=read(path/'result.json');assert r['exit_code']==0 and not r['errors'] and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(t['failed']==0 for t in r['reports']),str(path)
 return r
def results():
 values={n:valid(C/'Acceptance01'/n) for n in ['sight1080','curtains1440','sight3440','impossible_native','endings']}
 values['root_late']=valid(C/'LateRoot07');values['lifecycle3440']=valid(C/'Lifecycle08')
 d=read(C/'GetterImpossible06/result.json');assert d['breakpoint_armed'] and not d['forced_timeout'] and not d['unhandled_native_av'] and not d['engine_errors'] and d['owner_unchanged'] and d['reports'] and all(t['failed']==0 for t in d['reports']);values['debugger_contact']=d
 return values
def stage():
 values=results();assert not P.exists() and not I.exists() and not Z.exists()
 assert not git('diff',RUNTIME,'HEAD','--','scripts','assets','shaders','scenes','themes','project.godot','export_presets.cfg')
 P.mkdir();shutil.copy2(C/'Candidate04/UNLISTED.exe',P/'UNLISTED.exe')
 shutil.copy2(G/'OPERATION_STABILITY_REPORT.md',P/'START_HERE.md');shutil.copy2(G/'THIRD_PARTY.md',P/'THIRD_PARTY.md')
 shutil.copytree(U/'Checkpoints/20261028_sightline_continuation/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
 (P/'CHANGED_FILES.txt').write_text(git('diff','--name-status','90be6a3','HEAD')+'\n',encoding='utf8')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED Operation Stability</title><style>body{background:#101416;color:#ddd;font:16px sans-serif;margin:24px}a{color:#ace}img,video{width:95%;max-width:1280px}</style><h1>Operation Stability — private diagnostic candidate</h1><p>PRIVATE QA — STABILITY NOT CLEARED. No native crash fix claimed. The particle error reproduced in ordinary foreground play. Existing game/character/graphics preserved. Logs distinguish injected controls, debugger timing and original failures.</p>'
 keep={'result.json','launch.json','native.log','stdout.log','godot.log','ordinary_game.log','report.json','repair_report.json','probe_report.json','threat_report.json','native_frame_timing.json','resource_lifecycle.jsonl','resource_samples.jsonl','particle_lifecycle.json','checks_live.jsonl','late_attach_result.json','observed_errors.jsonl','quit_action.json','particle_error_observation.json','control_result.json','commands.txt'}
 folders={n:C/'Acceptance01'/n for n in ['sight1080','curtains1440','sight3440','impossible_native','endings']}
 folders.update(root_late=C/'LateRoot07',lifecycle3440=C/'Lifecycle08',ordinary_foreground=C/'OrdinaryMenu01',debugger_ordinary=C/'GetterOrdinary03',corrected_contact=C/'GetterImpossible06/Native',failed_wall_clock_contact=C/'GetterImpossible04/Native',clean_armed_curtain=C/'GetterCapture02/Native',logger_control=C/'LoggerControl')
 for n,d in folders.items():
  out=P/'Evidence'/n;out.mkdir(parents=True)
  for f in d.iterdir():
   if f.suffix=='.png' or f.name in keep:shutil.copy2(f,out/f.name)
  page+='<h2>'+html.escape(n)+'</h2>'
  for f in sorted(out.glob('*.png')):page+='<p>'+html.escape(f.stem)+'</p><img loading="lazy" src="'+f.relative_to(P).as_posix()+'">'
 (P/'VERIFICATION.json').write_text(json.dumps(values,indent=2),encoding='utf8')
 import package_surveyor_assets as encoder
 encoder.C=C;encoder.video(C/'Acceptance01/impossible_native',P/'Native_Room_Recovery.mp4')
 page+='<h2>Actual exported room / capture / retry</h2><p>Placed prerequisites and automated input; sampled roughly6fps with wall-clock timing, repeated in30fps encode. Actual game-bus audio. Not a human investigation or fear/quality approval.</p><video controls src="Native_Room_Recovery.mp4"></video>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8');archive(P,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate04/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'status':'PRIVATE QA - STABILITY NOT CLEARED','runtime_source':git('rev-parse',RUNTIME),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'checks':values,'native_crash_fix':'None demonstrated','ordinary_error':'Reproduced without QA flags, recorder or handoff','private_dumps':'Retained in UnrelatedProcessEvidence and preceding Sightline CrashAnalysis; no process-memory dump bundled with playable ZIP'},indent=2),encoding='utf8');print(Z)
def recover():
 assert not git('status','--porcelain');private=git('rev-parse','HEAD');assert git('rev-parse',TAG+'^{}')==private
 extracted=valid(C/'ExtractedCheck');public=read(C/'PUBLIC_CHECKPOINT.json')
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for f in (G/'tools/asset_sources').rglob('*'):
  if f.is_file():files[f]='UNLISTED_Game/tools/asset_sources/'+f.relative_to(G/'tools/asset_sources').as_posix()
 source=C/'UNLISTED_Operation_Stability_Complete_Private_Source.zip'
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f,n in files.items():z.write(f,n)
  with zipfile.ZipFile(U/'Checkpoints/20261028_sightline_continuation/UNLISTED_Sightline_Continuity_Complete_Private_Source.zip') as old:
   for n in old.namelist():
    if n.startswith(('Private_Weatherhood_Study/','Private_Art_Revision/')):z.writestr(n,old.read(n))
  for f in (C/'EngineSource').iterdir():
   if f.is_file():z.write(f,'Pinned_Engine_References/'+f.name)
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked game and consumed media, ignored authoring sources and preserved editable art. Original raw Assets inbox, previous builds, player data and crash dumps remain separately preserved. Source '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Operation_Stability_Private_History.bundle';assert not bundle.exists();subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 d=read(C/'STAGED_DELIVERY.json');d.update(private_source=private,public_source=public,tag=TAG,complete_source=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,public_release='None',human_playtesting='Pending',all_three_native_faults='Unresolved; no common cause established',late_attach_trigger_exercised=read(C/'LateRoot07/result.json')['late_attach']['attempted'])
 (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in d.items() if k not in ['checks','extracted_verification']},indent=2))
if __name__=='__main__':{'stage':stage,'recover':recover}[sys.argv[1]]()
