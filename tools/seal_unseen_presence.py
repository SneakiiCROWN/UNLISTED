"""Seal the private Unseen Presence candidate without overwriting any release."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Unseen_Presence_06'
C=G.parent/'Checkpoints/20261026_unseen_presence_verified'
S=B.parent/'UNLISTED_Unseen_Presence_01/StaticStudy02'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assert not C.exists(),'Preserve prior delivery'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for name,h in fp.items():assert sha(G/name)==h,name
    reports={}
    for build,name,file in [('03','threat','threat_report.json'),('06','anomaly','repair_report.json'),('06','vent_reverse','repair_report.json')]:
        folder=B.parent/('UNLISTED_Unseen_Presence_'+build)
        r=read(folder/'QA'/name/file);assert r['failed']==0,(build,name)
        assert read(folder/(name+'_owner_integrity.json'))['unchanged']
        log=(folder/(name+'.log')).read_text();assert 'ERROR:' not in log and ' FAIL ' not in log
        reports[build+'/'+name]={'passed':r['passed'],'failed':r['failed']}
    profile=read(B/'QA/moving_performance/dynamic_foreground_profile.json')
    assert len(profile['results'])==9
    assert all(r['actual_displacement_m']>1 and r['focused_frames']>0 for r in profile['results'])
    C.mkdir();E=C/'Evidence';E.mkdir()
    source=C/'UNLISTED_Unseen_Presence_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        assert z.testzip() is None
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    with zipfile.ZipFile(source,'a',zipfile.ZIP_DEFLATED,6) as z:
        for p in S.iterdir():
            if p.is_file():z.write(p,'Private_Rejected_Static_Study/'+p.name)
        intake=G.parent/'Assets/Intake_20261021_MakeHuman'
        for n in ['base.obj','LICENSE.ASSETS.md','Selected/proxymeshes/male_generic/male_generic.obj','Selected/clothes/male_worksuit01/male_worksuit01.obj','Selected/clothes/male_worksuit01/male_worksuit01.mhclo']:
            z.write(intake/n,'Private_Rejected_Static_Study/Sources/'+n)
    cards=[]
    for p in sorted((B/'QA/anomaly').glob('*.png')):
        shutil.copy2(p,E/p.name);cards.append('<figure><img loading="lazy" src="'+p.name+'"><figcaption>Native anomaly fixture / '+html.escape(p.stem)+'</figcaption></figure>')
    A=B.parent/'UNLISTED_Unseen_Presence_05/QA/static_review'
    for p in sorted(A.glob('*.png')):
        target=E/('Art_'+p.name);shutil.copy2(p,target)
        cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>Static art gate / '+html.escape(p.stem)+' / candidate REJECTED</figcaption></figure>')
    for build,names in [('02',['static_review','anomaly']),('03',['threat','static_review']),('05',['static_review']),('06',['anomaly','vent_reverse','moving_performance'])]:
        folder=B.parent/('UNLISTED_Unseen_Presence_'+build)
        for name in names:
            for p in [folder/(name+'.log'),folder/(name+'_owner_integrity.json')]+list((folder/'QA'/name).glob('*.json')):
                if p.exists():shutil.copy2(p,E/(build+'_'+name+'_'+p.name))
    import validate_v051 as video
    movie=E/'Native_Impossible_Room_Verification.mp4'
    assert video.assemble(B/'QA/anomaly',movie)
    shutil.copy2(G/'UNSEEN_PRESENCE_VERIFICATION.md',E/'VERIFICATION.md')
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED Unseen Presence</title><style>body{background:#161b18;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>Unseen Presence / PRIVATE 0.10.4-dev</h1><p>The normal and inverted room are states of the same native test. The room inversion predates this milestone; new work strengthens visibility, ownership, recovery and positional sound. No new room geometry claim. The art study is rejected; the active character is retained. Earlier empty/misframed images remain in their original test folders and are not presented as accepted art.</p><p>Video uses real elapsed capture timestamps, sampled frames repeated at 30fps and actual game-bus audio. Segmented fixtures include deliberate save/load, staging and contact/retry; not an uninterrupted fresh investigation or human approval.</p><video controls src="Native_Impossible_Room_Verification.mp4"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Unseen-Presence-v0.10.4-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Living-Nightmare-v0.10.3-dev-PRIVATE.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','UNSEEN_PRESENCE_VERIFICATION.md','DEVELOPMENT_CHECKPOINT.json']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.4-dev / The Unseen Presence / PRIVATE\nExtract into a new folder and run UNLISTED.exe. Preserve previous builds and AppData/UNLISTED. Existing active Surveyor retained. No public release. Human art, fear and story approval pending.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.4-dev','milestone':'The Unseen Presence','complete_private_source_commit':commit,'development_tag':'dev-v0.10.4-unseen-presence-20261026','windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'source_runtime_fingerprint_matches':True,'checks':reports,'performance':profile,'independent_native':'PENDING','character_art':'Rejected static candidate preserved privately; active model unchanged','evidence_gallery':str(E/'INDEX.html'),'native_recording':str(movie),'public_release':'unchanged v0.10.0','human_approval':'pending'}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'private_source':commit,'windows':str(windows),'source':str(source),'evidence':str(E/'INDEX.html')}),flush=True)

if __name__=='__main__':main()
