"""Preserving private delivery; no release publication or raw-media push."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile
from package_phase5 import sha,archive
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_house_remembers'
P=C/'Package';I=C/'IndependentExtract';Z=U/'Builds/UNLISTED-Windows-House-Remembers-v0.10.9-dev-PRIVATE.zip';TAG='dev-house-remembers-20261028';RUNTIME='dbaaa024d04f4882118642242592cd74a2a46211'
def git(*args,cwd=G):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def valid(d):
 r=read(d/'result.json');assert r['exit_code']==0 and not r['errors'] and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),str(d)
 return r
def cases():
 names=['features1080','features1440','features3440','threat','impossible','ambient','endings','lifecycle3440','prebuilt_features1080','prebuilt_features1440','prebuilt_features3440','dread','prebuilt_impossible','prebuilt_endings','prebuilt_lifecycle3440','prebuilt_idle']
 return {n:valid(case_path(n)) for n in names}
def case_path(n):
 if n.startswith('prebuilt_features') or n=='prebuilt_impossible':return C/'Evidence12'/n.removeprefix('prebuilt_')
 if n.startswith('prebuilt_'):return C/'Evidence10'/n.removeprefix('prebuilt_')
 if n=='dread':return C/'Evidence10/dread'
 return C/'Evidence06'/n
def report():
 results=cases();rows=['| Exported native scope | Checks | Seconds |','|---|---:|---:|']
 for n,r in results.items():rows.append(f"| {n} | {sum(x['checks'] for x in r['reports'])} | {r['duration_seconds']:.2f} |")
 text='''# UNLISTED — The House Remembers / 28 October continuation

**PRIVATE QA — STABILITY NOT CLEARED.** Version remains v0.10.9-dev; public release and prior House Answers delivery are preserved. Gameplay source: fadfe75; QA initialization/fixture source: 694f600; final runtime including room-transform cover correction: dbaaa02. Recovery before edits: recovery/pre-house-remembers-20261028 -> 8c32536.

## Implemented in the ordinary game

1. **The curtains belong to the player too.** A small physical pull on the clear left side of the lounge window opens/closes the existing cloth with keyboard or controller interaction. A short eased movement respects pause and reduced motion. Manual choice is saved immediately; loading during movement restores its intended completed state. Legacy automatic closure still restores. The existing unseen closure cannot waste itself on already closed curtains, and once the player reopens the spent anomaly it does not silently close again. No new mandatory puzzle, journal or objective.
2. **Window perception matches the scene.** Existing transparent-glass metadata now distinguishes vision from the physical barrier. Only explicitly marked transparent panes are skipped by Surveyor player-visibility rays; opaque walls, frames and doors remain occluders. The actual UV-deformed curtain triangles block vision, including pleats and the real centre gap. Hearing, collision, navigation, solid attack rays and pursuit state rules retain their existing systems. This is not automatic invisibility or a switch that cancels a chase.
3. **The restored room answers movement.** After the impossible room has genuinely been witnessed and revisited, the established optional ceiling event can answer actual walking with up to four delayed contacts above the room. Standing still does not start a canned walking sequence; stopping can leave one already scheduled step, then silence. The sequence expires, yields to an encounter or departure, freezes on pause and is consumed safely on save/load without replay. It adds no actor or claim about identity and does not extend the game with chores.
4. **Connected physical/presentation repair.** Sewn tabs bridge the old gap from curtain cloth to its real pole and follow the same shader displacement. The pull was moved away from the reading-lamp silhouette after native inspection. The short prompt and optional 'Curtains rustle.' caption describe the actual action and existing positional cloth sound. The pull adds no floor obstacle and is disabled when the copied bedroom owns the room. All graphics profiles retain their rendering systems.

## Actual Windows verification

'''+ '\n'.join(rows)+'''

The feature fixtures use actual isolated engine interaction and movement input, physics, synthetic controller Start/B/X, legacy/manual saves and actual window rays. 1080p uses Balanced, 1440p Original and 3440x1440 Enhanced. Candidate06 checks the production gameplay change; Candidate09 retains that same gameplay and adds only optional QA initialization/diagnostics and the maintained aftermath fixture. Candidate10 changes only the old quiet-reservation fixture. Candidate11 corrects only the automatic window-click caption to match the actual tab-top curtain hardware; timed/route checks are retained rather than repeated for wording. Candidate12 corrects curtain sight to use the physically transformed room coordinates, adds positive/no-ghost-cover native checks at all three resolutions and repeats the affected impossible-room suite. Physical controller hardware is not tested. The prebuilt cases separately check that entry/context change rather than repeating the unaffected full investigation. These placed-state fixtures and direct optional-event requests are not a fresh investigation, a human first playthrough or proof of fear/comprehension. Native screenshots and sampled motion/audio are retained. Existing threat coverage checks perception, movement, pursuit, hiding, story mode, attack, death and retry. Impossible-room and ambient suites cover the changed surrounding systems. Both departures resume the preserved naturally earned Phase5 evidence checkpoint; this is segmented continuation, not a new uninterrupted full route. Unchanged radio/UV/lightbox/weight paths retain the previous baseline rather than being repeatedly re-run.

## Crash investigation — unresolved

The no-recorder hypothesis produced a **fresh failure**: the 330-second legacy-viewport menu observation emitted the same missing-particle error without installing an AudioEffectRecord. Its engine-error result is preserved and is not counted as passing merely because its menu assertions passed. This warning therefore does not require that QA recorder in this observed condition. The ordinary owner crash remains a separate unresolved failure.

The next bounded hypothesis concerns moving a live rendered game into the QA viewport. An opt-in alternative QA scene constructs the unchanged game directly inside its final sized private viewport/world. It avoids the live viewport handoff; normal New Game, main.tscn selection and ordinary world construction remain unchanged. Export templates refused a direct command-line scene override in Candidate08; that startup failure is preserved. Candidate09 instead reuses the existing deferred-diagnostic pattern behind an explicit QA-only flag, before world construction. Same-binary legacy/prebuilt observations, new polling-time error records and prebuilt input/save/room/ending checks are preserved. Clean prebuilt observations are not proof of an engine fix, an established cause, or ordinary foreground-owner stability. The same Candidate10 binary also passed a 30-second legacy-handoff control. That prevents attributing the intermittent warning solely to handoff. The 330-second prebuilt observation and relevant prebuilt recovery checks were clean; neither ordinary freeze-and-close reproduction nor a permanent engine fix was established. The new diagnostic entry remains explicit QA-only.

Twelve ultrawide ending/title/porch recovery cycles again trace GPU emitters, CPU mist and heightfield resources. Stable scene handles do not certify renderer-internal ownership. A review of the [Godot 4.7-family storage lookup](https://github.com/godotengine/godot/blob/4.7-stable/servers/rendering/renderer_rd/storage_rd/particles_storage.cpp) confirms that the named motion-vector-offset getter first looks up a particle owner and rejects a missing owner. This narrows what that warning means; it does not identify the offending RID or establish a matching fix in our exact 4.7.2 binary. The earlier owner null-execution dump, Vulkan read fault and guarded missing-particle log remain separate unresolved evidence. No engine, OS, driver, registry or BIOS changes were made.

## Surveyor art: bounded attempt rejected

Reviewed the previous native close-up, silhouette and preserved Blender construction. An editable new weatherhood removes the cap/peak/high collar, frames the existing aged face, adds weighted continuous hood/rolled edges and anatomy-local cloth folds. It retains 65 bones and exported existing animation clips. Static front/side/rear/face renders still show an ordinary hooded person, smooth coat, crude cuffs/boots and insufficient facial character. **FAILED STATIC ART GATE.** It was not inserted into the game and no native art integration/animation approval is claimed. A hood does not solve the deeper anatomical, garment-retopology, seam/UV and surface-detail deficiencies. The bounded study is preserved privately; no further small costume variations were attempted. Original active Surveyor and previous rejected studies remain intact.

## Failure evidence and corrections

- Candidate01: new tab-loop numeric inference caused a script parse failure. Fixed with an explicit float; retained exact-child script-abort evidence is not an owner crash.
- Candidate02: the TV table blocked the test's chosen line across the lounge; the fixture was moved to the real clear aisle. Its open-window check exposed the existing opaque sight treatment of physical glass.
- Candidate03: exact-name glass identification missed Godot's suffixed duplicate name; the first walking fixture also aimed only the camera rather than using the movement driver's body heading. Retained failed results are not counted as passes.
- Candidate04: the additional QA diagnostic needed an explicit Dictionary type. Candidate05 then demonstrated the exact ClosedWindowGlass2 obstruction. Candidate06 uses the existing transparent_glass metadata and the actual movement helper; relevant checks pass.

Candidate09's old aftermath fixture initially tried to replay during a saved quiet interval (25 passed / 2 failed). Candidate10 first proves that quiet blocks premature replay, then resets quiet only for each independent recovery/interruption fixture. No gameplay reservation was weakened. Its failed report remains preserved.

Original evidence directories and exports remain unchanged. No historical failures are erased. Artwork remains unapproved; subjective sound quality, artistic quality, human understanding/fear and 30–60 minute first-play duration remain unverified. Existing menus, arrival, canon, saves and both ending meanings are retained.

## Owner instructions and recovery

Extract the entire new private ZIP into a fresh folder and run UNLISTED.exe. Normal launch retains the original enemy and your existing settings/save compatibility. The new pull is beside the lounge window; interact to draw/open the curtains. Accessibility captions and reduced motion retain their settings. There is no new compulsory task and no request for owner testing before work can continue.

Open EVIDENCE.html for native state comparisons, the sampled Windows gameplay recording, failure logs and clearly labelled Blender static review. Current before/after curtain frames show actual interaction states, not a deterministic cross-build weather comparison. The preceding House Answers native captures and failed window-sight observations remain the cross-build baseline. DELIVERY.json records exact private/public commits, tag, executable/ZIP hashes, independently extracted checks and complete private source/history backup. Complete source includes the editable previous character files and new failed hood study; raw asset inbox and earlier builds remain separately preserved. No public release.
'''
 (G/'HOUSE_REMEMBERS_CONTINUATION.md').write_text(text,encoding='utf8');print('Native report written')
def stage():
 results=cases();assert not P.exists() and not I.exists() and not Z.exists()
 assert not git('diff',RUNTIME,'HEAD','--','assets','shaders','themes','project.godot','export_presets.cfg')
 assert not git('diff',RUNTIME,'HEAD','--','scripts','scenes'),'Runtime differs from selected export'
 P.mkdir();shutil.copy2(C/'Candidate12/UNLISTED.exe',P/'UNLISTED.exe');shutil.copy2(G/'HOUSE_REMEMBERS_CONTINUATION.md',P/'START_HERE.md');shutil.copy2(G/'THIRD_PARTY.md',P/'THIRD_PARTY.md')
 shutil.copytree(U/'Checkpoints/20261028_house_answers_integration/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
 (P/'CHANGED_FILES.txt').write_text(git('diff','--name-status','8c32536','HEAD')+'\n',encoding='utf8')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED House Remembers</title><style>body{background:#101416;color:#ddd;font:16px sans-serif;margin:25px}img,video{width:95%;max-width:1200px}a{color:#bcd}</style><h1>The House Remembers — private QA</h1><p>STABILITY NOT CLEARED. Placed/input-driven native fixtures, not human playtesting. Surveyor art remains unapproved.</p>'
 keep={'result.json','launch.json','native.log','report.json','repair_report.json','threat_report.json','particle_lifecycle.json','native_frame_timing.json','SCRIPT_ABORT.txt','observed_errors.jsonl'}
 for n in results:
  d=case_path(n);out=P/'Evidence'/n;out.mkdir(parents=True)
  for p in d.iterdir():
   if p.suffix=='.png' or p.name in keep:shutil.copy2(p,out/p.name)
  page+='<h2>'+n+'</h2><p><a href="Evidence/'+n+'/result.json">Actual native result</a></p>'
  for p in sorted(out.glob('*.png')):
   rel=p.relative_to(P).as_posix();page+='<p>'+html.escape(p.stem)+'</p><img loading="lazy" src="'+rel+'">'
 for i in range(1,6):
  d=C/('Evidence%02d'%i)
  for p in d.rglob('*'):
   if p.is_file() and (p.suffix=='.png' or p.name in keep):
    out=P/'PreservedFailures'/d.name/p.relative_to(d);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
 observations={}
 for name,d in [('Legacy_No_Recorder_330',C/'Evidence06/idle_no_recorder'),('Legacy_08_No_Recorder_30',C/'Evidence08/legacy30'),('Unsupported_Export_Scene_Override',C/'Evidence08/features1080'),('Legacy_Same_Binary_30',C/'Evidence10/legacy30'),('Old_Dread_Quiet_Fixture',C/'Evidence09/dread')]:
  observations[name]=read(d/'result.json')
  out=P/'PreservedObservations'/name;out.mkdir(parents=True)
  for p in d.iterdir():
   if p.name in keep or p.suffix=='.png':shutil.copy2(p,out/p.name)
 art=P/'FailedStaticArtReview';art.mkdir();shutil.copy2(C/'Weatherhood01/ART_SCOPE.json',art/'ART_SCOPE.json')
 comparison=P/'BeforeAfter';comparison.mkdir()
 shutil.copy2(C/'Evidence02/features1080/R02_drawn_cloth.png',comparison/'Before_Lamp_Obscured_Pull.png');shutil.copy2(case_path('prebuilt_features1080')/'R02_drawn_cloth.png',comparison/'After_Clear_Left_Pull.png')
 page+='<h2>Actual interaction-position repair</h2><p>Earlier right-hand pull was visually obstructed by the reading lamp. It now sits on the clear left side. These are player-eye views from the respective interaction positions, not an identical-camera render comparison.</p>'
 for p in sorted(comparison.glob('*.png')):page+='<p>'+p.stem+'</p><img loading="lazy" src="BeforeAfter/'+p.name+'">'
 page+='<h2>Rejected static Blender study — not game footage</h2><p>Fails the character-art standard. Not integrated or promoted.</p>'
 for p in sorted((C/'Weatherhood01').glob('*.png')):
  shutil.copy2(p,art/p.name);page+='<p>'+p.stem+'</p><img loading="lazy" src="FailedStaticArtReview/'+p.name+'">'
 import package_surveyor_assets as encoder
 encoder.C=C;encoder.video(case_path('prebuilt_features1080'),P/'Native_Curtains_And_Answering_Steps.mp4')
 page+='<h2>Native movement / interaction recording</h2><p>Sampled frames use their wall-clock durations; encoding at30fps repeats frames. Actual game-bus audio. Fixture placements are not authored gameplay teleports.</p><video controls src="Native_Curtains_And_Answering_Steps.mp4"></video>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8');archive(P,Z)
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate12/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'runtime_source':RUNTIME,'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'status':'PRIVATE QA - STABILITY NOT CLEARED','cases':results,'preserved_observations':observations,'bootstrap_headless_safety':read(C/'BootstrapRefusal/result.json')},indent=2),encoding='utf8');print(Z)
def recover():
 assert not git('status','--porcelain');extracted=valid(C/'ExtractedCheck');private=git('rev-parse','HEAD');public=read(C/'PUBLIC_CHECKPOINT.json');assert git('rev-parse',TAG)==private
 files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (G/'tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(G/'tools/asset_sources').as_posix()
 for p in (C/'Weatherhood01').iterdir():
  if p.is_file():files[p]='Private_Weatherhood_Study/'+p.name
 source=C/'UNLISTED_House_Remembers_Complete_Private_Source.zip'
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,n in files.items():z.write(p,n)
  oldpath=U/'Checkpoints/20261028_house_answers_integration/UNLISTED_House_Answers_Complete_Private_Source.zip'
  with zipfile.ZipFile(oldpath) as old:
   for n in old.namelist():
    if n.startswith('Private_Art_Revision/'):z.writestr(n,old.read(n))
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked game/consumed media, existing ignored art sources and preserved editable Blender studies. Raw asset inbox, player files, earlier builds and evidence remain separately untouched. Source '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_House_Remembers_Private_History.bundle';assert not bundle.exists();subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 d=read(C/'STAGED_DELIVERY.json');d.update(private_source=private,public_source=public,tag=TAG,source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,public_release='None',owner_menu_crash='Unresolved',null_particle_error='Unresolved',new_art='Failed static gate; private and not integrated',human_playtest='Pending')
 (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in d.items() if k not in ['cases','extracted_verification','preserved_observations','bootstrap_headless_safety']},indent=2))
if __name__=='__main__':{'report':report,'stage':stage,'recover':recover}[sys.argv[1]]()
