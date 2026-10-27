"""Package the opt-in Phase4 study without changing production or prior archives."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess,zipfile,html
G=Path(__file__).resolve().parents[1];R=Path(r'C:\Users\Snkii\Documents\UNLISTED');C=R/'Checkpoints/20261027_graphics_phase4';E=C/'Evidence04';B=C/'Candidate04'
S=C/'Package';I=C/'IndependentExtract';Z=R/'Builds/UNLISTED-Windows-Final-Atmosphere-v0.10.9-dev-PRIVATE.zip'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  while block:=f.read(1048576):h.update(block)
 return h.hexdigest()
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def valid(d):
 r=read(d/'result.json');p=read(d/'graphics_report.json')
 assert r['exit_code']==0 and not r['script_errors'] and not r['warnings'] and r['owner_unchanged'],str(d)
 assert all(x['passed'] for x in p['checks']),str(d)
 return p,r
def archive(root,dest):
 with zipfile.ZipFile(dest,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in sorted(root.rglob('*')):
   if p.is_file():z.write(p,p.relative_to(root).as_posix())
 with zipfile.ZipFile(dest) as z:assert z.testzip() is None
def stage():
 assert not S.exists() and not I.exists() and not Z.exists()
 S.mkdir();shutil.copy2(B/'UNLISTED.exe',S/'UNLISTED.exe')
 (S/'CHANGED_FILES.txt').write_text(git('diff','--name-status','dd6c678','HEAD')+'\n',encoding='utf8')
 shutil.copytree(R/'Checkpoints/20261027_graphics_phase2/IndependentExtract/ThirdPartyNotices',S/'ThirdPartyNotices')
 for n in ['THIRD_PARTY.md','GRAPHICS_PHASE4.md','GRAPHICS_PHASE4_RESULTS.md','GRAPHICS_INTEGRATION_RANKING.md','PHASE4_PARTICLE_OBSERVATION.md','REFLECTION_WARNING_FINDINGS.md']:shutil.copy2(G/n,S/n)
 for case in ['final_balanced2560','particle_recheck_2','particle_recheck_3']:
  valid(E/case)
  out=S/'ParticleRechecks'/case;out.mkdir(parents=True)
  for n in ['native.log','result.json','launch.json']:shutil.copy2(E/case/n,out/n)
 failure=S/'FailureEvidence';failure.mkdir()
 for n in ['native.log','result.json','launch.json']:shutil.copy2(C/'Evidence03/final_balanced2560'/n,failure/n)
 (failure/'SCOPE.txt').write_text('Rejected Candidate03 1440p run: renderer null-particle error, no native crash or owner-file change. Exact root cause unconfirmed. Candidate04 avoids a redundant live particle draw-mesh swap; bounded rechecks do not prove a permanent engine fix. Original owner menu crash remains unresolved.',encoding='utf8')
 cases=[];rows=[];images=[]
 for width in ['1920','2560','3440']:
  for prefix in ['before_balanced','final_original','final_balanced','final_enhanced']:
   name=prefix+width;d=(R/'Checkpoints/20261027_graphics_phase3/Evidence'/('final_balanced'+width)) if prefix=='before_balanced' else E/name;p,r=valid(d);out=S/'Comparisons'/name;out.mkdir(parents=True)
   for f in d.glob('*.png'):
    shutil.copy2(f,out/f.name);images.append({'file':str((out/f.name).relative_to(S)),'sha256':sha(f)})
   for n in ['graphics_report.json','launch.json','result.json','owner_integrity.json','native.log']:shutil.copy2(d/n,out/n)
   cases.append({'case':name,'checks':len(p['checks']),'result':r})
 for d in sorted(E.glob('perf_*')):
  p,r=valid(d);launch=read(d/'launch.json');out=S/'Performance'/d.name;out.mkdir(parents=True)
  for n in ['graphics_report.json','launch.json','result.json','owner_integrity.json','native.log']:shutil.copy2(d/n,out/n)
  for m in p['measurements']:
   assert m['focused_frames']>0 and m['excluded_unfocused']==0
   rows.append({'case':d.name,'resolution':p['render_size'],'fps_cap':launch['fps_cap'],**m})
 assert len(rows)==36
 (S/'PERFORMANCE.json').write_text(json.dumps({'scope':'Paired fixed-camera focused five-second uncapped/vsync-off native process intervals. Not GPU timings or sustained gameplay. Godot render memory is an engine counter, not total board VRAM. All cases retained.','rows':rows},indent=2),encoding='utf8')
 for label,profile,extra in [('BEFORE_BALANCED','balanced',' --atmosphere-baseline'),('ORIGINAL','original',''),('BALANCED','balanced',''),('ENHANCED','enhanced','')]:
  (S/('SHOW_'+label+'.cmd')).write_text('@echo off\r\ncd /d "%~dp0"\r\n"%~dp0UNLISTED.exe" --max-fps 60 -- --graphics-study-qa --graphics-phase2 --graphics-phase3 --graphics-phase4 --graphics-profile='+profile+' --capture-size=1920x1080 --graphics-walk --foreground-profile'+extra+' --evidence="%~dp0Evidence\\Preview_%RANDOM%_%RANDOM%"\r\n',encoding='ascii')
 (S/'START_HERE.txt').write_text('UNLISTED / PRIVATE FINAL ATMOSPHERE STUDY\n\nExtract the ENTIRE ZIP into a new folder. Run SHOW_BALANCED.cmd for the selected protected automated native tour. SHOW_BEFORE_BALANCED.cmd shows the previous landscape with matched Phase3 rendering. SHOW_ORIGINAL.cmd uses original rendering settings on the revised environment art; SHOW_ENHANCED.cmd adds optional heavier rendering.\n\nThis is an isolated environment study, not an integrated playable release. The tour hard-cuts between camera fixtures, stages the current actor for glass checks, walks the front approach and exits. Physical desktop input is isolated. Launching the EXE alone keeps ordinary original gameplay. The moving-window clips use real actor locomotion but deliberately controlled cameras, not new story encounters.\n\nOpen COMPARISONS.html and GRAPHICS_PHASE4_RESULTS.md. Owner saves/settings remain protected. E08 is a deliberately retained obstructed fence view, not woodland-quality proof.\n\nOriginal intermittent menu crash remains unresolved. No public release or owner artistic approval.\n',encoding='utf8')
 views=['E01_gate_arrival','P01_wet_approach','P02_puddle','E02_porch_outward','E03_kitchen_woodland','W01_window','E04_office_woodland','E05_rear_exit','E06_yard_shed','E07_shed_perimeter','E08_rear_woodland','E09_east_foundation','E10_car_departure','W02_actor_outside','W03_from_outside','W04_actor_inside','W05_actor_direct_control','V07_cellar','P03_walked_to_porch']
 body='<!doctype html><meta charset="utf-8"><title>UNLISTED Final Atmosphere</title><style>body{background:#111;color:#ddd;font:16px sans-serif;margin:24px}a{color:#bcd}section{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}img{width:100%}figure{margin:0}td,th{padding:5px;border-bottom:1px solid #333}h2{margin-top:35px}</style><h1>UNLISTED - The Final Atmosphere</h1><p>Matched native before/after environment views. Rain phases vary; camera/exposure/settings match. Before uses Phase3 Balanced. Original means original rendering settings on revised environment art. E08 is obstructed by an existing close fence and is not a landscape-quality control. These are camera placements; separate route checks use actual inputs. No production integration or crash-fix claim.</p>'
 for width in ['1920','2560','3440']:
  for view in views:
   label=view+' (existing office wall, not an exterior window)' if view=='E04_office_woodland' else view
   body+='<h2>'+width+' / '+label+'</h2><section>'
   for prefix in ['before_balanced','final_original','final_balanced','final_enhanced']:
    path='Comparisons/'+prefix+width+'/'+view+'.png'
    if not (S/path).exists():continue
    body+='<figure><a href="'+path+'"><img loading="lazy" src="'+path+'"></a><figcaption>'+prefix+'</figcaption></figure>'
   body+='</section>'
 body+='<h2>Short native performance samples</h2><p>All requested uncapped/vsync off. Five seconds/view; process intervals, not GPU timestamps. No sustained FPS guarantee.</p><table><tr><th>Case/view</th><th>Median ms</th><th>p95 ms</th><th>Draws</th><th>Spikes &gt;33ms</th></tr>'
 for r in rows:body+='<tr><td>'+html.escape(r['case']+'/'+r['view'])+'</td><td>'+str(round(r['median_ms'],3))+'</td><td>'+str(round(r['p95_ms'],3))+'</td><td>'+str(int(r['median_draws']))+'</td><td>'+str(r['spikes_over_33ms'])+'</td></tr>'
 body+='</table>'
 for name in ['approach','approach_original','approach_enhanced','window_inside','window_outside','window_ultrawide']:
  valid(E/('record_'+name));movie=E/('record_'+name)/'native_walk.mp4';assert movie.exists();shutil.copy2(movie,S/('Native_'+name+'.mp4'))
  body+='<h2>Native '+name+' recording</h2><video controls width="960" src="Native_'+name+'.mp4"></video>'
 (S/'COMPARISONS.html').write_text(body,encoding='utf8')
 archive(S,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(B/'UNLISTED.exe')
 receipt={'runtime_source':git('rev-parse','6d4162a'),'exe_sha256':sha(B/'UNLISTED.exe'),'visual_cases':cases,'native_images':images,'performance_samples':rows,'windows_zip':str(Z),'windows_sha256':sha(Z),'production_head':git('rev-parse','HEAD',cwd=R/'Game'),'production_clean':not git('status','--porcelain',cwd=R/'Game')}
 assert receipt['production_head'].startswith('9e09084') and receipt['production_clean']
 (C/'STAGED_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8');print('STAGED',Z,flush=True)
def finalize():
 assert not git('status','--porcelain')
 p,r=valid(I/'Verification')
 assert any(x['name']=='Phase4 first knock leaves actual door ajar' for x in p['checks'])
 assert any(x['name']=='Phase3 actual Surveyor traverses west corridor' for x in p['checks'])
 assert not git('diff','6d4162a','HEAD','--','scripts','shaders','assets','scenes','themes','project.godot','export_presets.cfg')
 pub=C/'PublicSource';tag='graphics-phase4-isolated-20261027';private=git('rev-parse','HEAD');public=git('rev-parse','HEAD',cwd=pub)
 assert git('rev-parse',tag)==private and git('rev-parse',tag,cwd=pub)==public
 remote=git('ls-remote','origin','refs/heads/graphics/final-atmosphere','refs/tags/'+tag,cwd=pub)
 assert len(remote.splitlines())==2 and all(x.startswith(public+'\t') for x in remote.splitlines())
 source=C/'UNLISTED_Graphics_Phase4_Complete_Private_Source.zip'
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for f in (R/'Game/tools/asset_sources').rglob('*'):
  if f.is_file():files[f]='UNLISTED_Game/tools/asset_sources/'+f.relative_to(R/'Game/tools/asset_sources').as_posix()
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f,n in sorted(files.items()):z.write(f,n)
  z.writestr('PRIVATE_SOURCE_SCOPE.txt','Complete tracked experimental source and existing extracted art sources; caches and historical QA media excluded. Raw Assets inbox and previous archives remain separately preserved. Private checkpoint '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Graphics_Phase4_Private_History.bundle';assert not bundle.exists()
 subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 receipt=read(C/'STAGED_RECEIPT.json');receipt.update(private_source=private,public_source=public,tag=tag,complete_source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=r,extracted_checks=len(p['checks']),gallery=str(I/'COMPARISONS.html'),human_artistic_approval='Pending',owner_menu_crash='Unresolved',public_release='None; original production untouched')
 (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in receipt.items() if k not in ['visual_cases','native_images','performance_samples']},indent=2))
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('action',choices=['stage','finalize']);{'stage':stage,'finalize':finalize}[a.parse_args().action]()
