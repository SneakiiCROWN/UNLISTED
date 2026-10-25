"""Private 0.10.5 package. No release API, raw-media publishing or overwrites."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds/UNLISTED_Horror_Character_06'
C=G.parent/'Checkpoints/20261026_horror_character_verified';S=B.parent/'UNLISTED_Horror_Character_01/MatchedStudy'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assert not C.exists(),'Preserve prior delivery'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for n,h in fp.items():assert sha(G/n)==h,n
    assert sha(G/'assets/original/surveyor_presence.glb')=='1bbfb311d83db53cf433948af5345f893f9160e1eb3c4d6c6782151f286f2bd6'
    reports={}
    for build,name in [('04','recorder'),('06','exterior_walk'),('06','recorder1440')]:
        folder=B.parent/('UNLISTED_Horror_Character_'+build)
        r=read(folder/'QA'/name/'repair_report.json');assert r['failed']==0,(build,name)
        assert read(folder/(name+'_owner_integrity.json'))['unchanged']
        log=(folder/(name+'.log')).read_text();assert 'ERROR:' not in log and ' FAIL ' not in log
        reports[build+'/'+name]={'passed':r['passed'],'failed':r['failed']}
    profile=read(B/'QA/shadow_route/property_route_profile.json');assert all(c['passed'] for c in profile['checks'])
    C.mkdir();E=C/'Evidence';E.mkdir()
    source=C/'UNLISTED_Horror_Character_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    with zipfile.ZipFile(source,'a',zipfile.ZIP_DEFLATED,6) as z:
        for p in S.rglob('*'):
            if p.is_file():z.write(p,'Private_Matched_Construction_Study/'+p.relative_to(S).as_posix())
        intake=G.parent/'Assets/Intake_20261021_MakeHuman'
        for n in ['base.obj','LICENSE.ASSETS.md','Selected/clothes/male_worksuit01/male_worksuit01.obj','Selected/clothes/male_worksuit01/male_worksuit01.mhclo']:
            z.write(intake/n,'Private_Matched_Construction_Study/Sources/'+n)
    cards=[]
    for stem in ['12_front_three_quarter','16_lane_toward_house','05_lounge_window','08_service_yard','11_yard_horizon','13_east_foundation']:
        for label,folder in [('Before_0104',B.parent/'UNLISTED_Horror_Character_01/QA/before_exterior'),('After_1080',B.parent/'UNLISTED_Horror_Character_05/QA/crown_views'),('After_1440',B/'QA/exterior1440'),('After_ultrawide',B/'QA/exteriorwide')]:
            p=folder/(stem+'.png');target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+html.escape(label+' / '+stem)+'</figcaption></figure>')
    for folder,label in [(B.parent/'UNLISTED_Horror_Character_04/QA/character_static','Character'),(B.parent/'UNLISTED_Horror_Character_04/QA/recorder','Recorder')]:
        for p in folder.glob('*.png'):
            target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>'+label+' / '+html.escape(p.stem)+'</figcaption></figure>')
    for build,names in [('03',['after_exterior']),('04',['recorder','shadow_route','character_static']),('05',['exterior_walk']),('06',['exterior_walk','shadow_route','recorder1440','exterior1440','exteriorwide'])]:
        folder=B.parent/('UNLISTED_Horror_Character_'+build)
        for name in names:
            for p in [folder/(name+'.log'),folder/(name+'_owner_integrity.json')]+list((folder/'QA'/name).glob('*.json')):
                if p.exists():shutil.copy2(p,E/(build+'_'+name+'_'+p.name))
    import validate_v051 as video
    assert video.assemble(B.parent/'UNLISTED_Horror_Character_04/QA/recorder',E/'Native_Recorder_Response.mp4')
    assert video.assemble(B/'QA/exterior_walk',E/'Native_Property_Traversal.mp4')
    shutil.copy2(G/'HORROR_CHARACTER_VERIFICATION.md',E/'VERIFICATION.md')
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED 0.10.5 private evidence</title><style>body{background:#171c19;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>Horror & Character Production / PRIVATE</h1><p>Native before/after uses matching player-height fixtures. Character is a non-promoted static construction foundation, not final art or an animation test. Videos are labelled automated fixtures, with original capture timestamps and game-bus audio; not human playtesting or a seamless fresh investigation.</p><video controls src="Native_Recorder_Response.mp4"></video><video controls src="Native_Property_Traversal.mp4"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Horror-Character-v0.10.5-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Unseen-Presence-v0.10.4-dev-PRIVATE.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','HORROR_CHARACTER_VERIFICATION.md','DEVELOPMENT_CHECKPOINT.json']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.5-dev / Horror & Character Production / PRIVATE\nExtract into a new folder, run UNLISTED.exe. Preserve old versions and AppData/UNLISTED. Active Surveyor retained; construction study is not promoted. No public release or human artistic approval.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.5-dev','private_complete_checkpoint':commit,'development_tag':'dev-v0.10.5-horror-character-20261026','windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'source_runtime_fingerprint_matches':True,'checks':reports,'performance':profile,'independent_native':'PENDING','character_art':'Cleaner canonical-source construction, not final design or rigged; original active model preserved','evidence_gallery':str(E/'INDEX.html'),'public_release':'unchanged v0.10.0','human_approval':'pending'}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'private_source':commit,'windows':str(windows),'source':str(source),'evidence':str(E/'INDEX.html')}),flush=True)

if __name__=='__main__':main()
