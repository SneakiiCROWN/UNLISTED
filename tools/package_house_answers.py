"""Private native delivery and complete recovery; never publishes a release."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile
from package_phase5 import sha,archive
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_house_answers_integration'
P=C/'Package';I=C/'IndependentExtract';Z=U/'Builds/UNLISTED-Windows-House-Answers-v0.10.9-dev-PRIVATE.zip'
TAG='dev-house-answers-20261028'
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def valid(d):
 r=read(d/'result.json');assert r['exit_code']==0 and not r['errors'] and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),str(d)
 return r
def cases():return {p.parent.name:valid(p.parent) for p in sorted((C/'Evidence03').glob('*/result.json'))}
def report():
 results=cases();required={'features1080','features1440','features3440','physical','weight','captions','endings','lifecycle3440','menu330','original','balanced','enhanced','ending3440'}
 assert required<=results.keys(),required-results.keys()
 rows=['| Native scope | Checks | Seconds |','|---|---:|---:|']
 for name,r in results.items():rows.append(f"| {name} | {sum(x['checks'] for x in r['reports'])} | {r['duration_seconds']:.2f} |")
 text='''# UNLISTED — House Answers / integrated production continuation

**PRIVATE QA — STABILITY NOT CLEARED.** v0.10.9-dev. Public v0.10.0, previous private builds, original asset inbox and owner saves/settings remain preserved. No public release or new approved character.

## Actual playable changes

- **Careful object placement:** the existing interaction now sets a carried prop upright on a reachable horizontal support when the complete upright start, swept path and destination are clear. Looking at a wall or unsupported space retains the normal drop. Throwing and rotation remain available. The prompt says Put down over a prospective surface. Actual obstruction can still refuse placement and drop the object; the prompt is a surface hint, not a guaranteed clearance preview.
- **Sound through architecture:** selected physical footsteps, doors, cloth and prop contacts receive a restrained 4 dB reduction and lower high-frequency cutoff across real solid walls. Clear nearby sources retain their authored levels. A bounded weak-reference owner updates only those one-shots; creature vocal replacements, music, rain, user bus settings and AI hearing are unchanged. No subjective listening approval or loudness/performance improvement is claimed.
- **A more coherent existing house response:** the handled-mug return now waits for competing encounters/quiet reservations, refuses moving or held objects, saves its once-only change immediately and reserves a short quiet aftermath with an actual positional contact. Its optional accessibility caption is tied to playback and distance. Existing endpoint visibility/clearance checks remain; this is refinement of the established event, not a new room or puzzle. No supernatural identity is asserted.
- **Cinematic rain correctness:** title, ending and arrival rain/shelter mixing now use the camera rendering that view instead of the inactive player. Ordinary gameplay retains its established foot-height shelter logic. Stationary anchors avoid redundant writes; no particle resources are replaced or removed.
- **No stale cue burst:** optional environmental cues dispatch in authored time order; cues more than 0.65 seconds late are discarded rather than clustered after a long simulation hitch. The bounded diagnostic records skipped cues. Direct dispatch fixtures exercise this policy, not a reproduced owner hitch.

Checkpoint validation additionally rejects malformed remembered-mug positions without invalidating legacy saves. Sound captions no longer describe 3D sources beyond their explicit maximum distance. Muting audio does not suppress accessibility captions. The native runner preserves fixed-path legacy caption reports and stops only its own child on script failure rather than waiting on a dead fixture.

## Windows evidence

'''+ '\n'.join(rows)+'''

The three new-feature runs exercise real interaction input, physics, save/load, actual architecture raycasts, the existing object response and its competing-event rules. Placed states and direct event dispatch are explicit fixtures, not a fresh human investigation. The physical suite covers carry/throw/noise, hand support, receiver and recorder recovery. Weight/support puzzles and caption layouts are relevant regressions. Caption coverage renders all three resolutions within its own native fixture.

Both endings resume discoveries from the preserved naturally earned Phase5 checkpoint, reset only placement/outcome and complete their physical finale. This is segmented earned-state verification, not a newly completed uninterrupted route. The additional ultrawide branch checks physical departure and ending layout. Original/Balanced/Enhanced startup runs include ordinary arrival, movement, gate/door interactions and save/recovery. Owner data hashes are checked by every runner.

Actual eye-height captures of title, mug placement and returned mug were reviewed. Multi-resolution native evidence is included in EVIDENCE.html. The motion video uses sampled frames at their actual wall-clock timing with recorded game-bus audio; 30fps encoding repeats frames. It is not full-frame-rate human footage or a listening review.

## Stability: unresolved

The retained forensic report distinguishes the owner idle-menu null execution, earlier Vulkan read fault and separately fixed QA recorder misuse. No new crash dump identifies the owner failure's caller. No OS, registry, BIOS, driver or speculative engine changes were made.

The 330-second isolated menu observation is longer than the reported five-minute window, but remains an off-screen native QA viewport with a recorder. It is not ordinary foreground-owner reproduction, and a clean bounded observation does not clear the crash. The high-level particle trace now includes CPU mist and heightfield collision in addition to the three GPU emitters, through twelve ending/title/porch recovery cycles. Stable opaque handles do not prove renderer-internal resource validity or identify the missing resource from the older null-particle error. Both historical failures remain unresolved and their evidence is preserved.

## Preserved failures and limits

Candidate01 failed due to an inferred Variant in the new QA script; Candidate02 failed because the new fixture used the wrong weather-node path. Both were corrected before Candidate03. Original logs and intentional exact-child cleanup markers remain under Evidence01/Evidence02; neither is counted as a passing run or ordinary owner crash. No failure history was rewritten.

The active Surveyor model and AI are preserved. The fantasy study and custom coat revision remain unapproved and development-only. Their art deficiencies are documented in SURVEYOR_ART_REVISION.md and the preserved Blender comparison delivery; no third costume experiment was inserted. The project is not declared polished, fear-effective, artistically approved or 30–60 minutes long. Human comprehension/fear, subjective audio and uninterrupted ordinary foreground stability remain pending. This milestone improves interactions and existing horror coherence rather than claiming a large content expansion.

## Use and recovery

Extract the entire private Windows ZIP into a new folder. UNLISTED.exe launches the existing ordinary game with the original Surveyor. It may use your existing save/settings; automated evidence checks isolate them. Settings > Display > Property atmosphere retains Original/Balanced/Enhanced; fully quit/relaunch after changing it. No owner playtesting is required for further development.

Exact hashes, source commits, backup locations and independent extracted-executable checks are recorded in DELIVERY.json beside this milestone. Complete private source includes consumed media, ignored art sources and the preserved editable Blender revision. Original raw asset archives, previous source/build ZIPs and saves remain separately untouched.
'''
 (G/'HOUSE_ANSWERS_INTEGRATION.md').write_text(text,encoding='utf8')
 print('Report written',len(results),'scopes')
def stage():
 results=cases();assert not P.exists() and not I.exists() and not Z.exists()
 assert not git('diff','29db4fb','HEAD','--','scripts','assets','shaders','scenes','themes','project.godot','export_presets.cfg'), 'Runtime changed since selected export'
 P.mkdir();shutil.copy2(C/'Candidate03/UNLISTED.exe',P/'UNLISTED.exe');shutil.copy2(G/'HOUSE_ANSWERS_INTEGRATION.md',P/'START_HERE.md');shutil.copy2(G/'THIRD_PARTY.md',P/'THIRD_PARTY.md')
 (P/'CHANGED_FILES.txt').write_text(git('diff','--name-status','519018d','HEAD')+'\n',encoding='utf8')
 shutil.copytree(U/'Checkpoints/20261028_surveyor_revision/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED House Answers</title><style>body{background:#101416;color:#ddd;font:16px sans-serif;margin:26px}img,video{width:95%;max-width:1200px}a{color:#bcd}</style><h1>House Answers — private integration</h1><p>STABILITY NOT CLEARED. Native placed/input-driven fixtures, not human playtesting. Current Surveyor unchanged.</p>'
 for name in results:
  source=C/'Evidence03'/name;dest=P/'Evidence'/name;dest.mkdir(parents=True)
  for p in source.iterdir():
   if p.suffix=='.png' or p.name in ['result.json','launch.json','native.log','repair_report.json','caption_report.json','particle_lifecycle.json','native_frame_timing.json']:shutil.copy2(p,dest/p.name)
  page+='<h2>'+html.escape(name)+'</h2><p><a href="Evidence/'+name+'/result.json">Native result</a></p>'
  for p in sorted(dest.glob('*.png')):
   rel=p.relative_to(P).as_posix();page+='<p>'+html.escape(p.stem)+'</p><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a>'
 before=U/'Checkpoints/20261027_phase5_integration/Evidence04/balanced1920/A00_ordinary_title.png'
 comparison=P/'BeforeAfter';comparison.mkdir();shutil.copy2(before,comparison/'Before_Phase5_Balanced_Title.png');shutil.copy2(C/'Evidence03/balanced/A00_ordinary_title.png',comparison/'After_House_Answers_Balanced_Title.png')
 page+='<h2>Preserved before / current after</h2><p>The same authored Balanced title composition from Phase5 and this candidate. Weather timing varies; these are not deterministic pixel comparisons. The camera-anchor correction is also checked with the inactive player deliberately indoors in the feature fixture.</p>'
 for p in sorted(comparison.glob('*.png')):page+='<p>'+p.stem+'</p><img loading="lazy" src="BeforeAfter/'+p.name+'">'
 shutil.copytree(C/'Evidence01',P/'PreservedFailures/Evidence01');shutil.copytree(C/'Evidence02',P/'PreservedFailures/Evidence02')
 import package_surveyor_assets as encoder
 encoder.C=C
 encoder.video(C/'Evidence03/features1080',P/'Native_house_interactions.mp4')
 page+='<h2>Actual interaction/save/response fixture</h2><p>Sampled frames with native wall-clock timing and actual recorded game-bus audio; fixture placement cuts are not gameplay events.</p><video controls src="Native_house_interactions.mp4"></video>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8');archive(P,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate03/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'runtime_source':git('rev-parse','29db4fb'),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'status':'PRIVATE QA - STABILITY NOT CLEARED','cases':results},indent=2),encoding='utf8')
 print(Z)
def recover():
 assert not git('status','--porcelain');extracted=valid(C/'ExtractedCheck');private=git('rev-parse','HEAD');public=read(C/'PUBLIC_CHECKPOINT.json')
 assert git('rev-parse',TAG)==private
 source=C/'UNLISTED_House_Answers_Complete_Private_Source.zip'
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (G/'tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(G/'tools/asset_sources').as_posix()
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,n in files.items():z.write(p,n)
  previous=U/'Checkpoints/20261028_surveyor_revision/UNLISTED_Custom_Surveyor_Complete_Private_Source.zip'
  with zipfile.ZipFile(previous) as old:
   for n in old.namelist():
    if n.startswith('Private_Art_Revision/'):z.writestr(n,old.read(n))
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked game/consumed media and existing ignored art sources. Preserved editable unapproved Blender studies included. Generated caches, old evidence and original asset inbox remain separately preserved. Source '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_House_Answers_Private_History.bundle';assert not bundle.exists();subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 d=read(C/'STAGED_DELIVERY.json');d.update(private_source=private,public_source=public,tag=TAG,source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,public_release='None',owner_menu_crash='Unresolved',null_particle_error='Unresolved',human_playtest='Pending')
 (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in d.items() if k not in ['cases','extracted_verification']},indent=2))
if __name__=='__main__':{'report':report,'stage':stage,'recover':recover}[sys.argv[1]]()
