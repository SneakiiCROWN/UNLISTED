"""Private integration packaging; never uploads binaries or licensed source."""
from pathlib import Path
import argparse,hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261027_phase5_integration';R=C/'Evidence04';S=C/'Package';I=C/'IndependentExtract'
Z=U/'Builds/UNLISTED-Windows-Phase5-Integrated-Playable-QA-v0.10.9-dev-PRIVATE.zip'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  while b:=f.read(1048576):h.update(b)
 return h.hexdigest()
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def archive(root,out):
 with zipfile.ZipFile(out,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in sorted(root.rglob('*')):
   if p.is_file():z.write(p,p.relative_to(root).as_posix())
 with zipfile.ZipFile(out) as z:assert z.testzip() is None
def valid(folder):
 r=read(folder/'result.json')
 known_render_failure=folder.name=='ending_balanced3440' and r['errors']==['ERROR: Parameter "particles" is null.']
 assert r['exit_code']==0 and (not r['errors'] or known_render_failure) and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),str(folder)
 if known_render_failure:
  r['rendering_acceptance']='FAILED: documented recurrence; retained unchanged, not a passing rendering case'
 return r
def stage():
 assert not S.exists() and not I.exists() and not Z.exists()
 cases={d.name:valid(d) for d in sorted(R.iterdir()) if d.is_dir()}
 assert len(cases)==20,len(cases)
 fresh=C/'Evidence02/fresh_balanced1080';cases['fresh_balanced1080']=valid(fresh)
 assert not git('diff','af2ba3f','HEAD','--','scripts','shaders','assets','scenes','themes','project.godot','export_presets.cfg',':(exclude)*.uid'),'Runtime changed after Candidate04'
 S.mkdir();shutil.copy2(C/'Candidate04/UNLISTED.exe',S/'UNLISTED.exe')
 shutil.copytree(U/'Checkpoints/20261027_graphics_phase4/IndependentExtract/ThirdPartyNotices',S/'ThirdPartyNotices')
 for name in ['THIRD_PARTY.md','PHASE5_CHECKPOINT.json','PHASE5_INTEGRATION.md','PHASE5_RESULTS.md','PHASE5_OWNER_GUIDE.md']:shutil.copy2(G/name,S/name)
 (S/'START_HERE.txt').write_text('UNLISTED - PHASE 5: INTEGRATED PLAYABLE QA\nPRIVATE QA - STABILITY NOT CLEARED\n\nExtract the entire ZIP into a new folder. Run UNLISTED.exe normally. This is the complete investigation.\n\nOriginal PSX is the default. Settings > Display > Property atmosphere saves Original/Balanced/Enhanced. Fully quit and launch again to apply a different atmosphere; returning to Main Menu is not sufficient. Existing owner preferences and saves are retained.\n\nRead PHASE5_OWNER_GUIDE.md and PHASE5_RESULTS.md. The original idle-menu crash is unresolved. This build has no stability-clearance or human artistic approval. No public release.\n\nOpen COMPARISONS.html for actual integrated screenshots. Videos use native sampled frames with wall-clock timing; they are not full-frame-rate recordings or proof of human playtime.\n',encoding='utf8')
 body='<!doctype html><meta charset="utf-8"><title>UNLISTED Phase 5</title><style>body{background:#101518;color:#ddd;font:16px sans-serif;margin:25px}section{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}img{width:100%}figure{margin:0}a{color:#cad}</style><h1>Phase 5: the actual integrated game</h1><p>PRIVATE QA — STABILITY NOT CLEARED. Same eye-height placements across Original, Balanced and Enhanced. Weather timing varies. These placed views are visual inspection; the separate fresh investigation uses actual movement and interactions.</p>'
 for size in ['1920','2560','3440']:
  for image in sorted((R/('original'+size)).glob('*.png')):
   body+='<h2>'+html.escape(size+' / '+image.stem)+'</h2><section>'
   for label in ['original','balanced','enhanced']:
    source=R/(label+size)/image.name;target=S/'Comparisons'/(label+size)/image.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    path=target.relative_to(S).as_posix();body+='<figure><a href="'+path+'"><img loading="lazy" src="'+path+'"></a><figcaption>'+label+'</figcaption></figure>'
   body+='</section>'
 for movie in (C/'Media').glob('*.mp4'):
  shutil.copy2(movie,S/movie.name);body+='<h2>'+html.escape(movie.stem)+'</h2><video controls width="960" src="'+movie.name+'"></video>'
 (S/'COMPARISONS.html').write_text(body,encoding='utf8')
 for name,case in cases.items():
  source=fresh if name=='fresh_balanced1080' else R/name;target=S/'Verification'/name;target.mkdir(parents=True)
  for p in source.iterdir():
   if p.suffix in ['.json','.log','.cfg'] and p.name not in ['input_trace.json','moving_samples.json','frames.json','checkpoint.json','earned_register_checkpoint.json'] and not p.name.endswith('_checkpoint.json'):shutil.copy2(p,target/p.name)
 failure=S/'PreservedFailures';failure.mkdir()
 shutil.copy2(C/'Evidence01/balanced1080/A01_settings.png',failure/'Candidate01_settings_overflow.png')
 for n in ['native.log','result.json','launch.json']:shutil.copy2(U/'Checkpoints/20261027_graphics_phase4/Evidence03/final_balanced2560'/n,failure/('Phase4_'+n))
 (failure/'SCOPE.txt').write_text('Candidate01 panel overflow was repaired. Earlier Phase4 renderer null-particle evidence is preserved; root cause remains unconfirmed. The ordinary owner idle-menu crash also remains unresolved. Current passing runs are bounded observations, not permanent fixes.',encoding='utf8')
 archive(S,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate04/UNLISTED.exe')
 receipt={'runtime_source':git('rev-parse','af2ba3f'),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'COMPARISONS.html'),'status':'PRIVATE QA - STABILITY NOT CLEARED; known renderer failure retained','rendering_acceptance':'NOT PASSED: null-particle error recurred during ultrawide ending recovery','cases':cases}
 (C/'STAGED_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in receipt.items() if k!='cases'},indent=2))
def finalize():
 assert not git('status','--porcelain')
 extracted=valid(I/'ExtractedLaunchCheck');assert read(I/'ExtractedLaunchCheck/launch.json')['exe_sha256']==sha(I/'UNLISTED.exe')
 d=C/'ordinary_menu_01';r=read(d/'result.json')
 assert r['target_duration_reached'] and r['owner_unchanged'] and (d/'INTENTIONAL_CLEANUP.txt').exists() and (d/'observed_start.png').exists()
 r['scope']='INCONCLUSIVE: ordinary launch observed, later foreground switched and human input detected. Exact launched process intentionally stopped; not normal Quit or a game-crash observation.'
 ordinary=[r,{'status':'Not run: foreground testing stopped to avoid interfering with human PC use'}]
 tag='dev-phase5-integrated-qa-20261027';private=git('rev-parse','HEAD');pub=C/'PublicSource';public=git('rev-parse','HEAD',cwd=pub)
 assert git('rev-parse',tag)==private and git('rev-parse',tag,cwd=pub)==public
 remote=git('ls-remote','origin','refs/heads/integration/playable-qa','refs/tags/'+tag,cwd=pub);assert len(remote.splitlines())==2 and all(x.startswith(public+'\t') for x in remote.splitlines())
 source=C/'UNLISTED_Phase5_Complete_Private_Source.zip';files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for f in (G/'tools/asset_sources').rglob('*'):
  if f.is_file():files[f]='UNLISTED_Game/tools/asset_sources/'+f.relative_to(G/'tools/asset_sources').as_posix()
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,name in sorted(files.items()):z.write(p,name)
  z.writestr('PRIVATE_SOURCE_SCOPE.txt','Complete tracked source/assets plus extracted art-source files; generated caches and historical QA captures excluded. The full original Assets inbox and all previous archives remain separately preserved. Private checkpoint '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Phase5_Private_History.bundle';assert not bundle.exists();subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 delivery=read(C/'STAGED_RECEIPT.json');delivery.update(private_source=private,public_source=public,tag=tag,complete_source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,ordinary_menu_observations=ordinary,foreground_idle_and_normal_quit='Pending: PC in active human use',owner_menu_crash='Unresolved',human_artistic_approval='Pending',public_release='None')
 (C/'DELIVERY.json').write_text(json.dumps(delivery,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in delivery.items() if k not in ['cases','ordinary_menu_observations','extracted_verification']},indent=2))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['stage','finalize']);{'stage':stage,'finalize':finalize}[p.parse_args().action]()
