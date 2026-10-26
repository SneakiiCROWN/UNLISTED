"""Private 0.10.7 delivery. Preserve older builds; no public release API."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds/UNLISTED_Dread_Within_08'
C=G.parent/'Checkpoints/20261026_dread_within_candidate'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
TAG='dev-v0.10.7-dread-within-20261026'

def main():
    assert not C.exists(),'Never overwrite a delivery'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for n,h in fp.items():assert sha(G/n)==h,n
    assert sha(G/'assets/original/surveyor_presence.glb')=='1bbfb311d83db53cf433948af5345f893f9160e1eb3c4d6c6782151f286f2bd6'
    cases=[('04','threat','threat_report.json'),('05','cellar','repair_report.json')]+[('08',n,'report.json' if n=='ambient' else 'repair_report.json') for n in ['aftermath','aftermath1440','aftermathwide','ambient','impossible','ending_b','vent','recorder']]
    reports={};component_matches={}
    for build,name,report in cases:
        folder=B.parent/('UNLISTED_Dread_Within_'+build)
        result=read(folder/'QA'/name/report);assert result['failed']==0,(build,name)
        assert read(folder/(name+'_owner_integrity.json'))['unchanged']
        text=(folder/(name+'.log')).read_text();assert 'ERROR:' not in text and ' FAIL ' not in text
        reports[build+'/'+name]={'passed':result['passed'],'failed':result['failed']}
        if build!='08':
            relevant={'threat':['scripts/surveyor_threat.gd','scripts/surveyor_actor.gd','scripts/surveyor_gaze.gd','scripts/surveyor_capture.gd'], 'cellar':['scripts/cellar_envelope.gd','shaders/cellar_concrete.gdshader','scripts/world.gd','scripts/player.gd','scripts/physical_props.gd','scripts/surveyor_threat.gd'], 'impossible':['scripts/impossible_room.gd','scripts/living_rooms.gd','shaders/curtain_canvas.gdshader','scripts/world.gd']}[name]
            previous=read(folder/'runtime_fingerprint.json')
            assert all(previous[n]==fp[n] for n in relevant),(build,name)
            component_matches[build+'/'+name]=relevant
    profile_build=B
    profile=read(profile_build/'QA/profile_repeat/cellar_route_profile.json')
    assert read(B/'profile_repeat_owner_integrity.json')['unchanged']
    repeat_log=(B/'profile_repeat.log').read_text();assert 'ERROR:' not in repeat_log and ' FAIL ' not in repeat_log
    profile_fp=read(profile_build/'runtime_fingerprint.json')
    assert all(profile_fp[n]==fp[n] for n in ['scripts/cellar_envelope.gd','shaders/cellar_concrete.gdshader','scripts/world.gd','scripts/player.gd'])
    assert all(c['passed'] for c in profile['checks'])
    assert all(r['focused_frames']>500 for r in profile['results'])
    C.mkdir();E=C/'Evidence';E.mkdir()
    source=C/'UNLISTED_Dread_Within_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    cards=[]
    for label,folder in [('Before_0106',B.parent/'UNLISTED_Dread_Within_01/QA/before_rooms'),('After_1080',B/'QA/rooms1080'),('After_1440',B/'QA/rooms1440'),('After_ultrawide',B/'QA/roomswide')]:
        for stem in ['V02_lounge','V04_office','V07_cellar','V08_lane']:
            p=folder/(stem+'.png');target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+html.escape(label+' / '+stem)+'</figcaption></figure>')
    for label in ['aftermath','aftermath1440','aftermathwide']:
        for p in (B/'QA'/label).glob('*.png'):
            target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+html.escape(label+' / '+p.stem)+'</figcaption></figure>')
    for build,name,_ in cases+[('08','profile_repeat',''),('08','rooms1080',''),('08','rooms1440',''),('08','roomswide','')]:
        folder=B.parent/('UNLISTED_Dread_Within_'+build)
        for p in [folder/(name+'.log'),folder/(name+'_owner_integrity.json')]+list((folder/'QA'/name).glob('*.json')):
            if p.exists():shutil.copy2(p,E/(build+'_'+name+'_'+p.name))
    failures=E/'Preserved_Visual_Rejects';failures.mkdir()
    for build in ['06','07']:
        folder=B.parent/('UNLISTED_Dread_Within_'+build)
        shutil.copy2(folder/'QA/aftermath/D02_curtains_after_return.png',failures/(build+'_frame_intersection.png'))
        if (folder/'shadow_experiment.patch').exists():shutil.copy2(folder/'shadow_experiment.patch',failures/'07_shadow_experiment.patch')
    crash=E/'Preserved_Native_Crash';crash.mkdir()
    for name in ['profile.log','profile_owner_integrity.json','profile_windows_crash.json']:shutil.copy2(B/name,crash/name)
    import validate_v051 as video
    assert video.assemble(B/'QA/aftermath',E/'Native_Aftermath_Fixtures.mp4')
    checks=read(B/'QA/aftermath/repair_report.json')['checks']
    start=next(c['seconds'] for c in checks if c['name']=='hidden room offers eligible dressing change')
    end=next(c['seconds'] for c in checks if c['name']=='spent overhead response cannot replay after load')
    ffmpeg=r'C:\Program Files\Jellyfin\Server\ffmpeg.exe'
    subprocess.run([ffmpeg,'-y','-i',str(E/'Native_Aftermath_Fixtures.mp4'),'-ss',str(start),'-t',str(end-start),'-c:v','libx264','-crf','18','-preset','fast','-c:a','aac',str(E/'Native_Lounge_Return.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    (E/'video_scope.json').write_text(json.dumps({'scope':'Automated eligible-event fixture: actual hall walk back to changed curtains, entry into restored lounge and overhead sound. Includes explicit save/load checks. No human playtest, artificial speedup or generated frames.','start':start,'duration':end-start,'audio':'Actual simultaneous game Master bus recording, same capture origin.'},indent=2),encoding='utf8')
    for n in ['DREAD_WITHIN_VERIFICATION.md']:shutil.copy2(G/n,E/n)
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED 0.10.7 private evidence</title><style>body{background:#171d1a;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>The Dread Within / PRIVATE</h1><p>Actual exported screenshots. Cellar before/after uses matching player-height fixtures. Video shows an eligible scripted test with real movement and sound, not a fresh investigation or human playtest. Active Surveyor art retained.</p><video controls src="Native_Lounge_Return.mp4"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Dread-Within-v0.10.7-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Surveyor-Identity-v0.10.6-dev-PRIVATE.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','DREAD_WITHIN_VERIFICATION.md','DEVELOPMENT_CHECKPOINT.json']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.7-dev / The Dread Within / PRIVATE QA CANDIDATE\nExtract into a new folder, run UNLISTED.exe. Preserve older builds and AppData/UNLISTED. Two rare restored-lounge aftermaths, supported cellar structure and Surveyor floor contacts. Active character art unchanged. Known issue: one native NVIDIA-module access violation during foreground profiling; root cause unresolved. See DREAD_WITHIN_VERIFICATION.md. Human review pending. No public release.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.7-dev','status':'Private QA candidate; intermittent native crash unresolved','private_complete_checkpoint':commit,'development_tag':TAG,'windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'source_runtime_fingerprint_matches':True,'checks':reports,'reused_component_source_matches':component_matches,'performance_repeat':profile,'independent_native':'PENDING','evidence_gallery':str(E/'INDEX.html'),'public_release':'unchanged v0.10.0','human_approval':'pending','native_failure':{'exit_code':3221225477,'exception':'0xC0000005','windows_fault_module':'nvoglv64.dll','root_cause':'unresolved; fault module is not proof of responsibility','original_profile':'failed before report; preserved separately'}}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'private_source':commit,'windows':str(windows),'source':str(source),'evidence':str(E/'INDEX.html')}),flush=True)

if __name__=='__main__':main()
