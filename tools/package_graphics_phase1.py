"""Private isolated graphics delivery; never modifies production or publishes releases."""
from pathlib import Path
import argparse,hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];C=G.parent
R=Path(r'C:\Users\Snkii\Documents\UNLISTED');B=C/'Build04';E=B/'Evidence'
S=C/'Package';I=C/'IndependentExtract'
Z=R/'Builds/UNLISTED-Windows-Rain-Soaked-Study-v0.10.9-dev-PRIVATE.zip'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  while b:=f.read(1024*1024):h.update(b)
 return h.hexdigest()
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def stage():
 assert not S.exists() and not Z.exists() and not I.exists()
 S.mkdir();shutil.copy2(B/'UNLISTED.exe',S/'UNLISTED.exe')
 previous=R/'Checkpoints/20261026_full_forensic_audit/PrivateCandidate/IndependentExtract'
 shutil.copytree(previous/'ThirdPartyNotices',S/'ThirdPartyNotices')
 for n in ['THIRD_PARTY.md','GRAPHICS_PHASE1.md']:shutil.copy2(G/n,S/n)
 profiles=['original','balanced','enhanced'];sizes=['1920','2560','3440'];images=[];results=[]
 for size in sizes:
  for profile in profiles:
   source=E/('visual_'+profile+size);result=read(source/'result.json');report=read(source/'graphics_report.json')
   assert result['exit_code']==0 and not result['script_errors'] and not result['warnings'] and result['owner_unchanged']
   assert all(c['passed'] for c in report['checks'])
   dest=S/'Comparisons'/(profile+size);dest.mkdir(parents=True)
   for p in sorted(source.glob('*.png')):
    shutil.copy2(p,dest/p.name);images.append({'file':(dest/p.name).relative_to(S).as_posix(),'sha256':sha(p)})
   for n in ['graphics_report.json','launch.json','result.json','owner_integrity.json']:shutil.copy2(source/n,dest/n)
   results.append({'case':source.name,'result':result})
 rows=[]
 for build in [C/'Build03',B]:
  for p in sorted((build/'Evidence').glob('perf_*/graphics_report.json')):
   result=read(p.parent/'result.json');launch=read(p.parent/'launch.json')
   assert result['exit_code']==0 and result['owner_unchanged']
   for m in read(p)['measurements']:
    assert m['focused_frames']>0 and m['excluded_unfocused']==0
    rows.append({'case':p.parent.name,'build':build.name,'profile':read(p)['profile'],'render_size':read(p)['render_size'],'fps_cap':launch['fps_cap'],**m})
 (S/'PERFORMANCE.json').write_text(json.dumps({'scope':'Five-second stationary focused native process-frame samples; no image readback; separate60fps-cap and uncapped/vsync-disabled cases. Build03 full matrix precedes final water-patch coordinate refinement; Build04 wide rechecks and capped case use final source. No GPU timestamp, sustained gameplay or minimum-spec claim.','rows':rows},indent=2),encoding='utf8')
 for profile in ['original','balanced','enhanced']:
  command='@echo off\r\ncd /d "%~dp0"\r\n"%~dp0UNLISTED.exe" --max-fps 60 -- --graphics-study-qa --graphics-profile='+profile+' --capture-size=1920x1080 --graphics-walk --foreground-profile --evidence="%~dp0Evidence\\Preview_%RANDOM%_%RANDOM%"\r\n'
  (S/('SHOW_'+profile.upper()+'.cmd')).write_text(command,encoding='ascii')
 (S/'START_HERE.txt').write_text('UNLISTED / PRIVATE MODERN PSX GRAPHICS STUDY\n\nExtract the ENTIRE ZIP into a new folder first.\nRun SHOW_BALANCED.cmd for the selected automated native showcase, SHOW_ORIGINAL.cmd for comparison, or SHOW_ENHANCED.cmd for SSAO/SSR.\nThe tour visits fixed player-eye views, walks the existing front path and exits. Physical game input is isolated. Captures go into a new local Evidence/Preview folder.\nThis is NOT an integrated playable release. Launching UNLISTED.exe alone uses the original menu/game, not experimental graphics. Owner idle crash remains unresolved.\nOpen COMPARISONS.html for native before/after images; source preferences and exposure remain matched. Weather/particle phases vary.\nNo artistic approval or permanent stability claim. No public release. Previous production game, saves, settings and forensic evidence remain untouched.\n',encoding='utf8')
 table='<h2>Measured costs</h2><p>Short stationary samples, no readback. Cap0 means requested uncapped with vsync disabled. Not a gameplay FPS guarantee. Build labels distinguish the final patch-position refinement.</p><table><tr><th>Build/case/view</th><th>Cap</th><th>Median ms</th><th>p95 ms</th><th>Draws</th></tr>'
 for r in rows:table+='<tr><td>'+html.escape(r['build']+'/'+r['case']+'/'+r['view'])+'</td><td>'+str(r['fps_cap'])+'</td><td>'+str(round(r['median_ms'],3))+'</td><td>'+str(round(r['p95_ms'],3))+'</td><td>'+str(int(r['median_draws']))+'</td></tr>'
 content='<!doctype html><meta charset="utf-8"><title>UNLISTED Phase1 native comparisons</title><style>body{background:#111;color:#ddd;font:16px sans-serif;margin:25px}a{color:#bcd}section{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}img{width:100%}figure{margin:0}td,th{padding:5px;text-align:left;border-bottom:1px solid #333}h2{margin-top:32px}</style><h1>UNLISTED — rain-soaked property study</h1><p>Original / Balanced / Enhanced native Windows renders. Same cameras, exposure and retro strength; rain/time phases differ. No production integration, human artistic approval or crash-fix claim. Probe studies were excluded for a remaining shutdown warning.</p>'
 for size in sizes:
  for view in ['P01_wet_approach','P02_puddle','V01_porch','V02_lounge','W01_window','V07_cellar','V08_lane']:
   content+='<h2>'+size+' / '+view+'</h2><section>'
   for profile in profiles:
    path='Comparisons/'+profile+size+'/'+view+'.png'
    assert (S/path).exists();content+='<figure><a href="'+path+'"><img loading="lazy" src="'+path+'"></a><figcaption>'+profile+'</figcaption></figure>'
   content+='</section>'
 content+=table+'</table>'
 (S/'COMPARISONS.html').write_text(content,encoding='utf8')
 for name in ['original','balanced']:
  movie=E/('record_'+name)/'native_walk.mp4'
  assert movie.exists();shutil.copy2(movie,S/('Native_'+name+'_walk.mp4'))
 receipt={'scope':'Private isolated study, not production release. Original owner idle crash unresolved.','runtime_source':git('rev-parse','7bf7923'),'build_executable_sha256':sha(B/'UNLISTED.exe'),'visual_results':results,'native_images':images,'performance_samples':rows,'original_production_head':git('rev-parse','HEAD',cwd=R/'Game'),'original_production_clean':not git('status','--porcelain',cwd=R/'Game')}
 assert receipt['original_production_head'].startswith('9e09084') and receipt['original_production_clean']
 (C/'STAGED_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
 with zipfile.ZipFile(Z,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in sorted(S.rglob('*')):
   if p.is_file():z.write(p,p.relative_to(S).as_posix())
 with zipfile.ZipFile(Z) as z:
  assert z.testzip() is None;z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(B/'UNLISTED.exe')
 print(json.dumps({'windows_zip':str(Z),'sha256':sha(Z),'independent_executable':str(I/'UNLISTED.exe')},indent=2))
def finalize():
 assert not git('status','--porcelain')
 result=read(I/'Verification/result.json');assert result['exit_code']==0 and not result['warnings'] and result['owner_unchanged']
 source=C/'UNLISTED_Graphics_Phase1_Complete_Private_Source.zip';assert not source.exists()
 assert not git('diff','7bf7923','HEAD','--','scripts','shaders','assets','scenes','themes','project.godot','export_presets.cfg')
 public=C/'PublicSource';tag='graphics-phase1-isolated-20261026'
 private_commit=git('rev-parse','HEAD');public_commit=git('rev-parse','HEAD',cwd=public)
 assert git('rev-parse',tag)==private_commit and git('rev-parse',tag,cwd=public)==public_commit
 remote=git('ls-remote','origin','refs/heads/graphics/rain-soaked-property','refs/tags/'+tag,cwd=public)
 assert len(remote.splitlines())==2 and all(r.startswith(public_commit+'\t') for r in remote.splitlines())
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (R/'Game/tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(R/'Game/tools/asset_sources').as_posix()
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,name in sorted(files.items()):z.write(p,name)
  z.writestr('PRIVATE_SOURCE_SCOPE.txt','Complete tracked experimental Game plus preserved original extracted art sources. Generated caches and historical QA media excluded. Raw Assets inbox, prior builds, forensic dumps and earlier backups remain preserved separately.\nPrivate commit '+private_commit+'\n')
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Graphics_Phase1_Private_History.bundle';assert not bundle.exists()
 subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True)
 subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 receipt=read(C/'STAGED_RECEIPT.json');receipt.update(private_source=private_commit,public_source=public_commit,development_tag=tag,windows_zip=str(Z),windows_sha256=sha(Z),complete_source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),independent_extracted_check=result,comparison_gallery=str(I/'COMPARISONS.html'),probe_warning='Seven Texture RIDs at shutdown in probe-enabled studies; retained separately, excluded from selected profiles',public_release='Unchanged; none published',human_artistic_approval='Pending')
 (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
 print(json.dumps({k:v for k,v in receipt.items() if k not in ['native_images','visual_results','performance_samples']},indent=2))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['stage','finalize']);a=p.parse_args()
 {'stage':stage,'finalize':finalize}[a.action]()
