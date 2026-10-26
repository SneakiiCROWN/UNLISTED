"""Private 0.10.6 delivery; no release API or raw-media publishing."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile,wave,array,math
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Surveyor_Identity_04'
C=G.parent/'Checkpoints/20261026_surveyor_identity_verified'
S=B.parent/'UNLISTED_Surveyor_Identity_01/Concepts'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
TAG='dev-v0.10.6-surveyor-identity-20261026'

def main():
    assert not C.exists(),'Preserve previous deliveries'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for n,h in fp.items():assert sha(G/n)==h,n
    assert sha(G/'assets/original/surveyor_presence.glb')=='1bbfb311d83db53cf433948af5345f893f9160e1eb3c4d6c6782151f286f2bd6'
    reports={}
    for name in ['latch','ambient','exterior_walk','latch1440','latchwide','recorder','vent_reverse','ending_b']:
        folder=B/'QA'/name
        report=read(folder/('report.json' if name=='ambient' else 'repair_report.json'))
        assert report['failed']==0,name
        assert read(B/(name+'_owner_integrity.json'))['unchanged'],name
        log=(B/(name+'.log')).read_text();assert 'ERROR:' not in log and ' FAIL ' not in log,name
        reports[name]={'passed':report['passed'],'failed':report['failed']}
    profile=read(B/'QA/profile/property_route_profile.json')
    assert all(c['passed'] for c in profile['checks'])
    assert all(r['focused_frames']>1000 and r['median_ms'] is not None for r in profile['results'])
    C.mkdir();E=C/'Evidence';E.mkdir()
    source=C/'UNLISTED_Surveyor_Identity_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    with zipfile.ZipFile(source,'a',zipfile.ZIP_DEFLATED,6) as z:
        for p in S.rglob('*'):
            if p.is_file():z.write(p,'Private_Character_Concepts/'+p.relative_to(S).as_posix())
    shutil.copytree(S,E/'Concepts')
    cards=[]
    folders=[('Before_0105',G.parent/'Checkpoints/20261026_horror_character_verified/Evidence','After_1080_'),('After_1080',B.parent/'UNLISTED_Surveyor_Identity_03/QA/leaf_views',''),('After_1440',B/'QA/views1440',''),('After_ultrawide',B/'QA/viewswide','')]
    for stem in ['12_front_three_quarter','16_lane_toward_house','05_lounge_window','08_service_yard','11_yard_horizon','13_east_foundation']:
        for label,folder,prefix in folders:
            p=folder/(prefix+stem+'.png');target=E/(label+'_'+stem+'.png');shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+html.escape(label+' / '+stem)+'</figcaption></figure>')
    for label in ['latch','latch1440','latchwide']:
        for p in (B/'QA'/label).glob('*.png'):
            target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+html.escape(label+' / '+p.stem)+'</figcaption></figure>')
    for name in ['latch','ambient','exterior_walk','profile','views1440','viewswide','latch1440','latchwide','recorder','vent_reverse','ending_b']:
        for p in [B/(name+'.log'),B/(name+'_owner_integrity.json')]+list((B/'QA'/name).glob('*.json')):
            if p.exists():shutil.copy2(p,E/(name+'_'+p.name))
    failures=E/'PreservedFailures';failures.mkdir()
    for build,name in [('02','latch'),('03','latch')]:
        folder=B.parent/('UNLISTED_Surveyor_Identity_'+build)
        for p in [folder/(name+'.log'),folder/(name+'_owner_integrity.json'),folder/'QA'/name/'repair_report.json']:
            if p.exists():shutil.copy2(p,failures/(build+'_'+p.name))
    import validate_v051 as video
    assert video.assemble(B/'QA/latch',E/'Native_Door_Fixtures_Raw.mp4')
    # The fixture enables bus recording after setup. Align audio to the first
    # recording physics tick (within one 60 Hz tick), not to process launch.
    trace=read(B/'QA/latch/input_trace.json');offset=max(0,float(trace[0]['seconds'])-1/60)
    ffmpeg=r'C:\Program Files\Jellyfin\Server\ffmpeg.exe'
    subprocess.run([ffmpeg,'-y','-i',str(E/'Native_Door_Fixtures_Raw.mp4'),'-vf','null','-af',f'adelay={round(offset*1000)}:all=1','-t','9','-c:v','libx264','-crf','18','-preset','fast','-c:a','aac',str(E/'Native_Utility_Door_Response.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    (E/'door_video_scope.json').write_text(json.dumps({'scope':'First eligible-event fixture, not a fresh investigation. Native timestamped frames, no speed changes or generated frames. Optional sound captions visible.','audio_setup_offset_seconds':offset,'alignment_precision':'first recording physics tick, approximately 16.7ms','duration':9},indent=2),encoding='utf8')
    with wave.open(str(B/'QA/latch/game_bus.wav')) as w:
        assert w.getsampwidth()==2
        samples=array.array('h',w.readframes(w.getnframes()))
        peak=max(abs(v) for v in samples)/32768;rms=math.sqrt(sum(float(v)*v for v in samples)/len(samples))/32768
    audio={'peak_dbfs':20*math.log10(max(peak,1e-12)),'rms_dbfs':20*math.log10(max(rms,1e-12)),'non_silent':peak>.001,'scope':'Mixed game Master bus, not isolated footsteps or subjective listening quality.'}
    assert audio['non_silent']
    (E/'captured_audio_signal.json').write_text(json.dumps(audio,indent=2),encoding='utf8')
    for n in ['SURVEYOR_IDENTITY_VERIFICATION.md','SURVEYOR_IDENTITY_DESIGN.md']:shutil.copy2(G/n,E/n)
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED 0.10.6 private evidence</title><style>body{background:#181d1a;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>The Surveyor Identity / PRIVATE</h1><p>Concept paintings are proposals, not screenshots or 3D models. Active Surveyor unchanged. Video shows an eligible native fixture, not human playtesting. Before/after images use matching player-height views.</p><h2>Unapproved character directions</h2><img src="Concepts/Surveyor_Three_Directions.png"><p>Observer silhouette provisionally preferred. Follow-up remains too ordinary to promote.</p><h2>Actual native door response</h2><video controls src="Native_Utility_Door_Response.mp4"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Surveyor-Identity-v0.10.6-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Horror-Character-v0.10.5-dev-PRIVATE.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','SURVEYOR_IDENTITY_VERIFICATION.md','SURVEYOR_IDENTITY_DESIGN.md','DEVELOPMENT_CHECKPOINT.json']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.6-dev / The Surveyor Identity / PRIVATE\nExtract into a new folder, run UNLISTED.exe. Preserve previous builds and AppData/UNLISTED. Active Surveyor retained; concept art is not promoted. No public release or human artistic approval.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.6-dev','private_complete_checkpoint':commit,'development_tag':TAG,'windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'source_runtime_fingerprint_matches':True,'checks':reports,'performance':profile,'captured_audio':audio,'independent_native':'PENDING','character_art':'Three private painted concepts; no new 3D model or promotion. Observer silhouette provisional, face treatment unresolved.','evidence_gallery':str(E/'INDEX.html'),'public_release':'unchanged v0.10.0','human_approval':'pending'}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'private_source':commit,'windows':str(windows),'source':str(source),'evidence':str(E/'INDEX.html')}),flush=True)

if __name__=='__main__':main()
