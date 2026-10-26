"""Private owner-playtest candidate. Never uploads media, dumps or licensed assets."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds/UNLISTED_Player_Experience_06'
T=B.parent/'UNLISTED_Player_Experience_05'
C=G.parent/'Checkpoints/20261026_player_experience_candidate'
TAG='dev-v0.10.9-player-experience-20261026'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def reports():
    result={}
    for name in ['experience','threat','recorder_recovery','arrival','after1440','afterwide','ending_b','vent']:
        build=B if name in ['experience','after1440','afterwide'] else T
        report=build/'QA'/name/('threat_report.json' if name=='threat' else 'repair_report.json')
        r=read(report);assert r['failed']==0,(name,r['failed'])
        assert read(build/(name+'_owner_integrity.json'))['unchanged'],name
        log=(build/(name+'.log')).read_text();assert 'ERROR:' not in log and ' FAIL ' not in log,name
        assert read(build/(name+'_launch.json'))['executable_sha256']==sha(build/'UNLISTED.exe'),name
        result[name]={'passed':r['passed'],'failed':r['failed'],'report':str(report),'executable_sha256':sha(build/'UNLISTED.exe'),'build':build.name}
    return result
def main():
    checks=reports()
    assert not C.exists(),'Never overwrite a delivery'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for n,h in fp.items():assert sha(G/n)==h,n
    old=read(B.parent/'UNLISTED_Stability_Terror_03/runtime_fingerprint.json')
    assert all(fp[n]==h for n,h in old.items() if n.startswith(('assets/','scenes/','shaders/','themes/')))
    prior=read(T/'runtime_fingerprint.json')
    assert {n for n,h in fp.items() if prior.get(n)!=h}=={'scripts/presentation.gd','scripts/horror_director.gd'}
    for name in ['scripts/presentation.gd','scripts/horror_director.gd']:
        original=subprocess.check_output(['git','show','4bbc645:'+name],cwd=G,text=True)
        current=(G/name).read_text()
        if name.endswith('horror_director.gd'):
            current=current.replace('"TAPE RECORDER",motor','"RECORDER "+channel,motor').replace('"TAPE RECORDER",player_,true','"RECORDER "+audition,player_,true')
        else:
            old_line=next(l for l in original.splitlines() if 'label(card_body,"A: "+state_a' in l)
            new_line=next(l for l in current.splitlines() if 'label(card_body,"Recording: "+state_a' in l)
            current=current.replace(new_line,old_line)
        assert current==original,name+' must have only the verified UI/caption string changes'
    C.mkdir();E=C/'Evidence';E.mkdir();cards=[]
    before=B.parent/'UNLISTED_Player_Experience_01'
    shutil.copytree(before/'FailedEvidence',E/'Failed_Baseline_Crash')
    for n in ['before.log','before_launch.json','before_owner_integrity.json']:shutil.copy2(before/n,E/'Failed_Baseline_Crash'/n)
    crash=E/'Failed_Baseline_Crash'
    (crash/'SHA256.json').write_text(json.dumps({p.name:sha(p) for p in crash.iterdir() if p.is_file()},indent=2),encoding='utf8')
    for name in checks:
        build=B if name in ['experience','after1440','afterwide'] else T
        for p in [build/(name+'.log'),build/(name+'_launch.json'),build/(name+'_owner_integrity.json')]+list((build/'QA'/name).glob('*.json')):
            if p.exists():shutil.copy2(p,E/(name+'_'+p.name))
    for build in ['02','03']:
        folder=B.parent/('UNLISTED_Player_Experience_'+build)
        for p in [folder/'experience.log',folder/'QA/experience/repair_report.json']:
            if p.exists():shutil.copy2(p,E/('Failed_'+build+'_'+p.name))
    for name in ['P01_office_entry','P02_transport','P03_cellar','P04_cellar_aisle']:
        for label,origin in [('before',before/'QA/before'),('after',B/'QA/experience')]:
            p=origin/(name+'.png');dest=E/(label+'_'+p.name);shutil.copy2(p,dest)
            cards.append('<figure><img loading="lazy" src="'+dest.name+'"><figcaption>'+label+' / matching1080 / '+html.escape(name)+'</figcaption></figure>')
    for name in ['after1440','afterwide','experience','threat']:
        dest=E/name;dest.mkdir()
        build=T if name=='threat' else B
        for p in (build/'QA'/name).glob('*.png'):shutil.copy2(p,dest/p.name)
    import validate_v051 as video
    assert video.assemble(B/'QA/experience',E/'Native_Player_Experience_Fixtures.mp4')
    frames=read(B/'QA/experience/frames.json');start=next(f['seconds'] for f in frames if f['phase']=='interact audition_return');end=next(f['seconds'] for f in frames if f['phase']=='interact audition_source')
    ff=r'C:\Program Files\Jellyfin\Server\ffmpeg.exe'
    with (E/'Native_Recorder_Comparison.encode.log').open('w') as log:
        subprocess.run([ff,'-y','-i',str(E/'Native_Player_Experience_Fixtures.mp4'),'-ss',str(start),'-t',str(end-start),'-c:v','libx264','-preset','fast','-crf','20','-c:a','aac',str(E/'Native_Recorder_Comparison.mp4')],stdout=log,stderr=subprocess.STDOUT,check=True)
    (E/'video_scope.json').write_text(json.dumps({'scope':'Native exported automated fixtures with timestamped viewport readback and simultaneous game bus audio. Recording, paused comparison, historical reel, hidden search and actual room traversal. Not a fresh investigation or human playtest.','excerpt_start':start,'excerpt_end':end,'sampling':read(E/'Native_Player_Experience_Fixtures.capture.json'),'no_speedup':True},indent=2),encoding='utf8')
    docs=['OWNER_PLAYTEST_v0.10.9.md','PLAYER_EXPERIENCE_VERIFICATION.md','DEVELOPMENT_CHECKPOINT.json','THIRD_PARTY.md']
    for n in docs:shutil.copy2(G/n,E/n)
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED / The Player Experience</title><style>body{background:#171d1a;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:24px 0}</style><h1>v0.10.9-dev / PRIVATE QA CANDIDATE</h1><p>Intermittent native crashes remain unresolved. <a href="PLAYER_EXPERIENCE_VERIFICATION.md">Actual changes and limits</a> / <a href="OWNER_PLAYTEST_v0.10.9.md">Spoiler-light owner guide</a>. Matching player-eye fixtures; world/camera positions unchanged. Baseline captured before a failed run ended; not a passed baseline. Human approval pending.</p><h2>Real recorder response</h2><video controls src="Native_Recorder_Comparison.mp4"></video><p>Automated source sampling and original audio clock; no generated frames or speedup. Full fixture recording: <a href="Native_Player_Experience_Fixtures.mp4">video</a>.</p>'+''.join(cards)+'<h2>Other resolutions</h2><p><a href="after1440/P01_office_entry.png">Office1440</a> / <a href="afterwide/P01_office_entry.png">Office3440</a> / <a href="afterwide/P03_cellar.png">Cellar3440</a></p>',encoding='utf8')
    source=C/'UNLISTED_Player_Experience_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes();assert a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    with zipfile.ZipFile(source,'a',zipfile.ZIP_DEFLATED,6) as z:
        for p in crash.iterdir():z.write(p,'Private_Failed_Evidence/'+p.name)
    windows=B.parent/'UNLISTED-Windows-Player-Experience-v0.10.9-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Stability-Terror-v0.10.8-dev-PRIVATE.zip') as z:notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in docs:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.9-dev / The Player Experience / PRIVATE QA CANDIDATE\nExtract to a NEW folder and run UNLISTED.exe. Read OWNER_PLAYTEST_v0.10.9.md first; the verification report contains spoilers. Preserve older builds and saves. Known intermittent native crashes remain unresolved; keep verified0.10.6 rollback. No driver/system changes needed. Public Windows release unchanged.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.9-dev','status':'Private owner-playtest QA candidate; native instability unresolved','private_complete_checkpoint':commit,'development_tag':TAG,'windows_zip':str(windows),'windows_sha256':sha(windows),'complete_source_zip':str(source),'source_sha256':sha(source),'executable_sha256':sha(B/'UNLISTED.exe'),'focused_checks':checks,'independent_native':'PENDING','evidence_gallery':str(E/'INDEX.html'),'resources_match_0108':True,'reused_05_tests':'All runtime fingerprints identical except two files with exactly three verified UI/caption string-line changes. Final06 repeats changed recorder/input/save and three-resolution UI checks. No unchanged full-suite inflation.','public_playable':'unchanged v0.10.0','fresh_412_baseline':'preserved; not rerun','human_comprehension_fear_art_controller':'pending','new_native_failure':'01 baseline after all four screenshots; UNLISTED.exe +0x24662f5; not assumed same as original NVIDIA failure','system_changes':'none','new_performance_benchmark':False}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps(receipt,indent=2),flush=True)
if __name__=='__main__':main()
