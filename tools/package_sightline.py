"""Private delivery with explicit native evidence and complete local recovery."""
from pathlib import Path
import html, json, shutil, subprocess, sys, zipfile
from package_phase5 import sha, archive

G=Path(__file__).resolve().parents[1]; U=G.parent
C=U/'Checkpoints/20261028_sightline_continuation'
P=C/'Package'; I=C/'IndependentExtract'
Z=U/'Builds/UNLISTED-Windows-Sightline-Continuity-v0.10.9-dev-PRIVATE.zip'
TAG='dev-sightline-continuity-20261028'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True,encoding='utf8').strip()
def valid(path,allow_particle_observation=False):
    r=read(path/'result.json')
    known=allow_particle_observation and r['errors']==['ERROR: Parameter "particles" is null.']
    assert r['exit_code']==0 and (not r['errors'] or known) and not r['warnings'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']),str(path)
    if known:r['rendering_acceptance']='FAILED: no-handoff particle error reproduced; included as an unresolved observation, not a passing rendering case'
    return r
def cases():
    names=['sight1080','sight1440','sight3440','threat','house_remembers','ambient','dread','endings']
    return {n:valid(C/('Evidence03' if n=='sight3440' else 'Evidence02')/n,allow_particle_observation=n=='house_remembers') for n in names}
def stage():
    results=cases()
    for n in ['legacy60_sequential','prebuilt60_sequential']:results[n]=valid(C/'Comparison03'/n)
    results['root150']=valid(C/'Evidence01/root150')
    assert not P.exists() and not I.exists() and not Z.exists()
    # Candidate02 differs from Candidate01 only in fixture views/assertions.
    assert not git('diff','2b00921','HEAD','--','scripts','assets','shaders','scenes','themes','project.godot','export_presets.cfg')
    P.mkdir();shutil.copy2(C/'Candidate03/UNLISTED.exe',P/'UNLISTED.exe')
    for name in ['SIGHTLINE_CONTINUATION.md','THIRD_PARTY.md']:shutil.copy2(G/name,P/('START_HERE.md' if name.startswith('SIGHTLINE') else name))
    shutil.copytree(U/'Checkpoints/20261028_house_remembers/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
    (P/'CHANGED_FILES.txt').write_text(git('diff','--name-status','543afb3','HEAD')+'\n',encoding='utf8')
    page='<!doctype html><meta charset="utf-8"><title>UNLISTED Sightline Continuity</title><style>body{background:#101416;color:#ddd;font:16px sans-serif;margin:25px}img,video{width:95%;max-width:1280px}a{color:#bcd}</style><h1>Sightline continuity — private QA</h1><p>STABILITY NOT CLEARED. Not a replacement verified build. The no-handoff curtain case reproduced the missing-particle renderer error; the broader impossible-room run CRASHED with a Vulkan-path access violation. These are failed acceptance observations. Owner menu crash remains unresolved. Native placed fixtures, not a human investigation. Existing Surveyor retained.</p>'
    keep={'result.json','launch.json','native.log','repair_report.json','report.json','threat_report.json','probe_report.json','particle_lifecycle.json','native_frame_timing.json','observed_errors.jsonl','TIMEOUT.txt','SCRIPT_ABORT.txt'}
    for n,r in results.items():
        source=C/'Evidence01/root150' if n=='root150' else C/'Comparison03'/n if n.endswith('_sequential') else C/('Evidence03' if n=='sight3440' else 'Evidence02')/n
        dest=P/'Evidence'/n;dest.mkdir(parents=True)
        for f in source.iterdir():
            if f.name in keep or f.suffix=='.png':shutil.copy2(f,dest/f.name)
        page+='<h2>'+html.escape(n)+'</h2><p><a href="Evidence/'+n+'/result.json">Native result</a></p>'
        for f in sorted(dest.glob('*.png')):page+='<p>'+html.escape(f.stem)+'</p><img loading="lazy" src="'+f.relative_to(P).as_posix()+'">'
    # Preserve the compromised simultaneous observations separately. Their clean
    # logs are not controlled-comparison evidence and are not silently erased.
    for n in ['legacy60','prebuilt60']:
        dest=P/'ExcludedComparison'/n;dest.mkdir(parents=True)
        for f in (C/'Evidence02'/n).iterdir():
            if f.name in keep:shutil.copy2(f,dest/f.name)
    (P/'ExcludedComparison/SCOPE.txt').write_text('Launcher replacement overlapped these two native cases. Retained as observations only, excluded from controlled comparison. Comparison03 is sequential; no passing case was retried to hunt a different renderer result.',encoding='utf8')
    failed=P/'PreservedFailures/UltrawideCoarseSweep';failed.mkdir(parents=True)
    for f in (C/'Evidence02/sight3440').iterdir():
        if f.name in keep:shutil.copy2(f,failed/f.name)
    failed=P/'PreservedFailures/NativeImpossibleRoomCrash';failed.mkdir(parents=True)
    for f in (C/'Evidence02/impossible').iterdir():
        if f.name in keep:shutil.copy2(f,failed/f.name)
    crash=read(C/'Evidence02/impossible/result.json')
    assert crash['exit_code']==3221225477 and crash['owner_unchanged'] and not crash['reports']
    shutil.copy2(C/'CrashAnalysis/CRASH_FINDINGS.md',failed/'CRASH_FINDINGS.md')
    import package_surveyor_assets as encoder
    encoder.C=C;encoder.video(C/'Evidence02/sight1080',P/'Native_Sightline_Continuity.mp4')
    page+='<h2>Native visual/audio recording</h2><p>Roughly six sampled images per second, wall-clock timing, repeated frames in a 30fps file; actual game-bus audio. Direct fixture placements are verification setup, not newly authored teleports. No subjective listening or human fear claim.</p><video controls src="Native_Sightline_Continuity.mp4"></video>'
    (P/'EVIDENCE.html').write_text(page,encoding='utf8')
    archive(P,Z)
    with zipfile.ZipFile(Z) as z:z.extractall(I)
    assert sha(I/'UNLISTED.exe')==sha(C/'Candidate03/UNLISTED.exe')
    (C/'STAGED_DELIVERY.json').write_text(json.dumps({'status':'PRIVATE QA - STABILITY NOT CLEARED / NATIVE ACCEPTANCE FAILED','runtime_source':'2b00921','gameplay_source':'5689571','windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'cases':results,'native_crash':crash,'crash_scope':'Impossible-room actor-recovery scenario; preserved dump is private in CrashAnalysis, not bundled into the playable ZIP. No cause or fix established.'},indent=2),encoding='utf8')
    print(Z)
def recover():
    assert not git('status','--porcelain')
    extracted=valid(C/'ExtractedCheck'); private=git('rev-parse','HEAD');public=read(C/'PUBLIC_CHECKPOINT.json')
    assert git('rev-parse',TAG)==private
    source=C/'UNLISTED_Sightline_Continuity_Complete_Private_Source.zip'
    files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
    for f in (G/'tools/asset_sources').rglob('*'):
        if f.is_file():files[f]='UNLISTED_Game/tools/asset_sources/'+f.relative_to(G/'tools/asset_sources').as_posix()
    with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for f,n in files.items():z.write(f,n)
        with zipfile.ZipFile(U/'Checkpoints/20261028_house_remembers/UNLISTED_House_Remembers_Complete_Private_Source.zip') as old:
            for n in old.namelist():
                if n.startswith(('Private_Weatherhood_Study/','Private_Art_Revision/')):z.writestr(n,old.read(n))
        z.writestr('PRIVATE_SCOPE.txt','Complete tracked playable source and consumed media, ignored asset-authoring sources, preserved editable art studies. Original raw Assets inbox, saves, previous builds and evidence remain separately untouched. Private source '+private)
    with zipfile.ZipFile(source) as z:assert z.testzip() is None
    bundle=C/'UNLISTED_Sightline_Continuity_Private_History.bundle';assert not bundle.exists()
    subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True)
    subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
    data=read(C/'STAGED_DELIVERY.json');data.update(private_source=private,public_source=public,tag=TAG,complete_source=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=extracted,public_release='None',owner_menu_crash='Unresolved',null_particle_error='Unresolved',human_playtest='Pending',character_art='Unchanged; no candidate promoted')
    (C/'DELIVERY.json').write_text(json.dumps(data,indent=2),encoding='utf8')
    print(json.dumps({k:v for k,v in data.items() if k not in ['cases','extracted_verification']},indent=2))
if __name__=='__main__':{'stage':stage,'recover':recover}[sys.argv[1]]()
