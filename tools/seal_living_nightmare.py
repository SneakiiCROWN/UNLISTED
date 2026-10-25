"""Private package only. Refuses overwrites and checks the complete runtime source."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile

G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Living_Nightmare_06'
C=G.parent/'Checkpoints/20261026_living_nightmare_verified'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf8'))

def main():
    assert not C.exists(),'Preserve existing delivery'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for name,digest in fp.items():assert sha(G/name)==digest,name
    reports={}
    for build,name,file in [('04','room_interactions','report.json'),('05','vent_normal','repair_report.json'),('05','endingA','repair_report.json'),('05','endingB_story','repair_report.json'),('06','room_tour','repair_report.json')]:
        folder=B.parent/('UNLISTED_Living_Nightmare_'+build)
        report=read(folder/'QA'/name/file);assert report['failed']==0,(build,name)
        assert read(folder/(name+'_owner_integrity.json'))['unchanged']
        text=(folder/(name+'.log')).read_text(encoding='utf8');assert 'ERROR:' not in text and ' FAIL ' not in text
        reports[build+'/'+name]={'passed':report['passed'],'failed':report['failed']}
    # Final 06 only extends the QA helper; 05 has the final room materials.
    delta=[n for n,h in read(B.parent/'UNLISTED_Living_Nightmare_05/runtime_fingerprint.json').items() if fp.get(n)!=h]
    assert delta==['scripts/production_views.gd'],delta
    profile=read(B/'QA/foreground_performance/foreground_profile.json')
    assert len(profile['results'])==12
    C.mkdir();E=C/'Evidence';E.mkdir()
    source=C/'UNLISTED_Living_Nightmare_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        assert z.testzip() is None
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    cards=[]
    for room in ['V02_lounge','V04_office','V07_cellar']:
        for label,folder in [('Before_0102',B.parent/'UNLISTED_Living_Nightmare_01/QA/before_rooms'),('After_1080',B.parent/'UNLISTED_Living_Nightmare_05/QA/rooms1080'),('After_1440',B.parent/'UNLISTED_Living_Nightmare_05/QA/rooms1440'),('After_ultrawide',B.parent/'UNLISTED_Living_Nightmare_05/QA/roomswide')]:
            target=E/(label+'_'+room+'.png');shutil.copy2(folder/(room+'.png'),target)
            cards.append('<figure><figcaption>'+html.escape(label+' / '+room)+'</figcaption><a href="'+target.name+'"><img loading="lazy" src="'+target.name+'"></a></figure>')
    for build,names in [('03',['room_interactions']),('04',['room_interactions']),('05',['vent_normal','endingA','endingB_story']),('06',['room_tour','foreground_performance'])]:
        folder=B.parent/('UNLISTED_Living_Nightmare_'+build)
        for name in names:
            for filename in ['report.json','repair_report.json','foreground_profile.json','native_frame_timing.json']:
                p=folder/'QA'/name/filename
                if p.exists():shutil.copy2(p,E/(build+'_'+name+'_'+filename))
            for suffix in ['.log','_owner_integrity.json']:
                p=folder/(name+suffix)
                if p.exists():shutil.copy2(p,E/(build+'_'+name+suffix))
    import validate_v051 as video
    movie=E/'Native_Room_Walk.mp4'
    assert video.assemble(B/'QA/room_tour',movie)
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED Living Nightmare</title><style>body{background:#171c19;color:#dbdfd3;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>Living Nightmare / private 0.10.3-dev</h1><p>Unedited native exported screenshots. Before/after use matching powered camera fixtures. These are not human art approval. The video is an isolated powered-room movement fixture with enemy disabled, not a fresh investigation. Timing and captured game-bus audio are preserved; sampled frames are repeated at 30fps.</p><video controls src="Native_Room_Walk.mp4"></video>'+''.join(cards),encoding='utf8')
    shutil.copy2(G/'LIVING_NIGHTMARE_VERIFICATION.md',E/'VERIFICATION.md')
    windows=B.parent/'UNLISTED-Windows-Living-Nightmare-v0.10.3-dev-PRIVATE.zip'
    assert not windows.exists()
    prior=B.parent/'UNLISTED-Windows-Property-Continuation-v0.10.2-dev-PRIVATE.zip'
    with zipfile.ZipFile(prior) as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','LIVING_NIGHTMARE_VERIFICATION.md']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.3-dev / Living Nightmare / PRIVATE\nExtract into a new folder and run UNLISTED.exe. Preserve old builds and AppData/UNLISTED. No public release. Human artistic/story/audio approval remains pending.\n')
    with zipfile.ZipFile(windows) as z:
        assert z.testzip() is None;z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.3-dev','private_source':commit,'windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'evidence_gallery':str(E/'INDEX.html'),'native_room_recording':str(movie),'checks':reports,'performance':profile,'independent_native':'PENDING','public_release':'unchanged v0.10.0','human_approval':'pending','source_matches_runtime':True}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'private_source':commit,'windows_zip':str(windows),'source_zip':str(source),'evidence':str(E/'INDEX.html')}),flush=True)

if __name__=='__main__':main()
