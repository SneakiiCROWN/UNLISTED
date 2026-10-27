"""Private Next Nightmare delivery. Safe source publishing is a separate explicit step."""
from pathlib import Path
import argparse,html,json,shutil,subprocess,zipfile
from package_phase5 import archive,sha
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261027_next_nightmare';S=C/'Package';I=C/'IndependentExtract'
Z=U/'Builds/UNLISTED-Windows-Next-Nightmare-v0.10.9-dev-PRIVATE.zip';TAG='dev-next-nightmare-20261027'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def cases():
 paths=[C/'Evidence03'/n for n in ['features1080','features1440','features3440','input_report1080','surveyor_regression','lifecycle3440']]+[C/'Evidence04/physical_regression']+[C/'Evidence05'/n for n in ['ambient_regression','weight_and_support','endings1080','lifecycle_original','menu_idle_original','recording_distraction']]
 result={}
 for d in paths:
  r=valid(d);result[d.relative_to(C).as_posix()]=r
 return result
def valid(d):
 r=read(d/'result.json');assert r['exit_code']==0 and not r['errors'] and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),str(d)
 return r
def report():
 results=cases();rows=['| Native case | Checks | Seconds |','|---|---:|---:|']
 for name,r in results.items():rows.append('| '+name+' | '+str(sum(x['checks'] for x in r['reports']))+' | '+str(round(r['duration_seconds'],2))+' |')
 text='''# UNLISTED — The Next Nightmare / private production pass

**PRIVATE QA — STABILITY NOT CLEARED.** Version remains v0.10.9-dev; public v0.10.0 and previous private builds are preserved.

## Player-visible changes

1. **Carried-object recovery:** saving with a mug, fitting or tool in hand records its actual pose and identity. Loading reacquires it only when it is within reach and clear of walls, actors and other objects. Unsafe/remote placements remain physical objects rather than being pulled through the house. Legacy saves without this field retain their previous dropped-object behaviour. Grip, rotation, release and throw physics remain the existing system.
2. **Surveyor listening:** a newly heard sound receives a short 0.65-second listening/turning pause before approach. Nearby repeated contacts do not continually restart that pose; a weaker competing noise cannot immediately erase a stronger recent source. Visible-player detection still wins. Noise never cancels an active pursuit. Hiding, attack warning, story mode, death/retry and the current model remain intact.
3. **Horror aftermath:** existing window taps, utility steps, overhead sounds and physical-object events reserve a brief quiet interval. The existing score fades down around their actual positional sounds and aftermath; weather and SFX remain audible and user bus settings are unchanged. Pause freezes the interval. Save/load preserves its remainder without replaying a spent event. Other optional responses wait rather than crowding the beat.

## Actual defects corrected

- Carried props previously serialized their original home, losing transported-object progress on loading. Reach/clearance checks now preserve safe carry continuity.
- Malformed nested physical data could reach typed array/vector operations. The checkpoint validator now rejects invalid prop containers, transform shapes, nonnumeric values and invalid carried identity types before live mutation. Physical restoration also tolerates bad direct fixture data safely. Valid and legacy saves remain accepted; this does not certify every possible future narrative field.
- Input-isolation QA now honours --evidence directly and writes its actual report there. The wrapper retains compatibility with older fixed-path builds. The new 14-check run confirms this without replaying the full investigation.

## Native verification

'''+ '\n'.join(rows)+'''

These are actual Windows exports with isolated inputs/settings and protected owner data. Candidate03 covers the new features at 1080p, 1440p and 3440x1440, plus hearing/hiding/attack regression and particle tracing. Candidate04 changes only the obsolete carry-home assertion and dependent bench fixture. Candidate05 changes only ambient test scheduling to respect the new quiet interval. Production code is unchanged across those three candidates. Native animation, physics, controller events, files and screenshots are exercised; these are segmented fixtures, not human playtesting or a fresh uninterrupted investigation.

The earlier Phase5 fresh 428-check investigation remains the route baseline. Both endings are rechecked here from that naturally earned checkpoint, including receipts, car departure, pause/save recovery and View Ending. Rendering geometry/shaders/profiles are unchanged; previous moving-performance samples are retained rather than claiming a new benchmark or gain. Sampled QA frame timing includes capture overhead.

## Failure evidence retained

- Candidate02's drop-distance assertion mistook normal falling for failed release. Its original 18-pass/1-fail result remains. The corrected test checks actual release into physics.
- Candidate03's old physical suite expected a carried tool to return home on load; its dependent bench fixture consequently began from the wrong location (46 pass/2 fail). Updated coverage positively checks the retained tool/grip and independently resets the bench collision fixture.
- Candidate04's old ambient suite attempted back-to-back events during the newly preserved quiet interval (43 pass/4 fail). The corrected fixture first proves the reservation blocks that request, then waits the real interval before testing the next event and physical tin fall.
- None of those historical results is rewritten or counted as a passing run. Older Phase5 renderer failures, dumps, bundles and owner-crash evidence remain preserved.

## Stability investigation and limits

The retained forensic report distinguishes owner Crash C (null execution after approximately 110 seconds), the earlier Vulkan read fault and the separately repaired QA recorder fault. No new dump establishes the owner crash's caller. No engine, driver, Windows, registry, BIOS or overlay change was made.

The new diagnostic takes 38 particle snapshots around twelve completed-ending/title/earned-porch recovery cycles. In the Balanced ultrawide run, the same three live nodes (far rain, near rain, title mist), their base handles and draw meshes survived unchanged. Original is checked separately. The trace is high-level ownership evidence, not proof that an opaque RID still has valid renderer-internal storage. It does not identify the missing RID from the earlier native error or establish an upstream fix. Known particle failure remains unresolved even when these runs are clean. No weather system is removed as a guess.

The 150-second title observation is isolated/off-screen. It is not an uninterrupted ordinary foreground owner test. Foreground idle, physical Alt-Tab/quit and real controller hardware remain pending because prior foreground automation encountered active human PC use. Actual in-game Quit callbacks are used by the native tests. A nonreproduction is not a permanent stability fix.

## Owner guide and remaining work

Extract the entire private ZIP into a new folder and run UNLISTED.exe. It is the ordinary full game: no test actors, automatic puzzle solutions or forced overlays on normal launch. Settings > Display > Property atmosphere retains Original as default; choose Balanced or Enhanced and fully quit/relaunch to apply it. Use Settings > Input for current controls. Previous saves/settings and accessibility options remain available. No manual testing is requested as a prerequisite for continued development.

Human fear, artistic quality, story comprehension and first-playthrough duration remain unverified. Highest remaining priorities: resolve the two intermittent stability faults with reproducible evidence; obtain uninterrupted foreground coverage when feasible; continue first-player narrative/environment review and the separately approved character-art work without inserting rejected studies. This pass refines existing content rather than claiming a completed full game or longer human playtime.

Exact file changes, hashes, source checkpoints, the complete private source ZIP and Git history bundle are recorded in the private delivery folder. No public Windows release.
'''
 (G/'NEXT_NIGHTMARE.md').write_text(text,encoding='utf8');print('NEXT_NIGHTMARE.md written')
def stage():
 results=cases();assert not S.exists() and not I.exists() and not Z.exists();assert not git('diff','66fd021','HEAD','--','scripts','assets','shaders','scenes','themes','project.godot','export_presets.cfg',':(exclude)*.uid')
 S.mkdir();shutil.copy2(C/'Candidate05/UNLISTED.exe',S/'UNLISTED.exe');shutil.copy2(G/'NEXT_NIGHTMARE.md',S/'START_HERE.md');shutil.copy2(G/'THIRD_PARTY.md',S/'THIRD_PARTY.md')
 shutil.copytree(U/'Checkpoints/20261027_phase5_integration/IndependentExtract/ThirdPartyNotices',S/'ThirdPartyNotices')
 (S/'CHANGED_FILES.txt').write_text(git('diff','--name-status','3e16535','HEAD')+'\n',encoding='utf8')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED Next Nightmare</title><style>body{background:#111;color:#ddd;font:16px sans-serif;margin:25px}img{width:95%;max-width:1200px}a{color:#bcd}</style><h1>The Next Nightmare — private QA</h1><p>STABILITY NOT CLEARED. Actual native segmented fixtures, not a human playthrough or character-art approval. Test placements/warps are not ordinary gameplay.</p>'
 for name,r in results.items():
  d=C/name;out=S/'Evidence'/name;out.mkdir(parents=True)
  for p in d.iterdir():
   if p.suffix=='.png' or p.name in ['result.json','launch.json','report.json','repair_report.json','threat_report.json','native.log','particle_lifecycle.json','native_frame_timing.json']:shutil.copy2(p,out/p.name)
  for p in sorted(out.glob('*.png')):
   rel=p.relative_to(S).as_posix();page+='<h2>'+html.escape(name+' / '+p.stem)+'</h2><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a>'
 # Preserve all failed logs/reports; never replace them with later passes.
 for name in ['Evidence02/features1080','Evidence03/physical_regression','Evidence04/ambient_regression']:
  out=S/'PreservedFailures'/name;out.mkdir(parents=True)
  for n in ['native.log','result.json','repair_report.json','report.json']:
   if (C/name/n).exists():shutil.copy2(C/name/n,out/n)
 d=C/'Evidence05/recording_distraction';frames=[f for f in read(d/'frames.json') if f['seconds']>=.7];lines=['ffconcat version 1.0']
 spans=[b['seconds']-a['seconds'] for a,b in zip(frames,frames[1:])];assert min(spans)>0
 for i,f in enumerate(frames):lines.extend(["file '"+(d/f['file']).as_posix()+"'",'duration '+str(spans[i] if i<len(spans) else spans[-1])])
 lines.append("file '"+(d/frames[-1]['file']).as_posix()+"'");concat=C/'native_features.ffconcat';concat.write_text('\n'.join(lines)+'\n',encoding='utf8')
 with (C/'encoding.log').open('w',encoding='utf8') as log:subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-f','concat','-safe','0','-i',str(concat),'-ss',str(frames[0]['seconds']),'-i',str(d/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-threads','4','-preset','fast','-crf','23','-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-shortest','-movflags','+faststart',str(S/'Native_recording_escape.mp4')],stdout=log,stderr=subprocess.STDOUT,check=True)
 page+='<h2>Native checkpoint-resumed recording distraction, escape and departure</h2><p>Resumed from naturally earned bay evidence, not a fresh investigation or human playtest. Sampled roughly6fps, real wall-clock durations;30fps encoding repeats frames. Game bus audio, not subjective listening approval.</p><video controls width="960" src="Native_recording_escape.mp4"></video>'
 (S/'EVIDENCE.html').write_text(page,encoding='utf8');archive(S,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate05/UNLISTED.exe')
 (C/'STAGED_RECEIPT.json').write_text(json.dumps({'runtime_source':git('rev-parse','66fd021'),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'cases':results,'status':'PRIVATE QA - STABILITY NOT CLEARED'},indent=2),encoding='utf8');print('Staged and extracted',Z)
def finalize():
 assert not git('status','--porcelain');extracted=valid(I/'ExtractedLaunchCheck');private=git('rev-parse','HEAD');pub=C/'PublicSource';public=git('rev-parse','HEAD',cwd=pub)
 assert git('rev-parse',TAG)==private and git('rev-parse',TAG,cwd=pub)==public
 remote=git('ls-remote','origin','refs/heads/production/next-nightmare','refs/tags/'+TAG,cwd=pub);assert len(remote.splitlines())==2 and all(x.startswith(public+'\t') for x in remote.splitlines())
 source=C/'UNLISTED_Next_Nightmare_Complete_Private_Source.zip';files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (G/'tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(G/'tools/asset_sources').as_posix()
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,n in sorted(files.items()):z.write(p,n)
  z.writestr('PRIVATE_SOURCE_SCOPE.txt','Complete tracked project/consumed assets and extracted art sources. Generated caches/old evidence excluded. Entire original Assets inbox, earlier archives and player data separately preserved. Checkpoint '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Next_Nightmare_Private_History.bundle';assert not bundle.exists();subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 r=read(C/'STAGED_RECEIPT.json');r.update(private_source=private,public_source=public,tag=TAG,source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,owner_menu_crash='Unresolved',particle_error='Unresolved; bounded lifecycle observations did not reproduce it',foreground_testing='Pending; isolated observation only',human_playtesting='Pending',public_release='None')
 (C/'DELIVERY.json').write_text(json.dumps(r,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in r.items() if k not in ['cases','extracted_verification']},indent=2))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['report','stage','finalize']);{'report':report,'stage':stage,'finalize':finalize}[p.parse_args().action]()
