"""Private stability candidate; raw dumps never enter the public checkout."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,zipfile
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds/UNLISTED_Stability_Terror_03'
C=G.parent/'Checkpoints/20261026_stability_terror_candidate'
X=B.parent/'UNLISTED_Stability_Terror_01/CrashEvidence'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
TAG='dev-v0.10.8-stability-terror-20261026'
def main():
    assert not C.exists(),'Preserve deliveries'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    fp=read(B/'runtime_fingerprint.json')
    for n,h in fp.items():assert sha(G/n)==h,n
    old=read(B.parent/'UNLISTED_Dread_Within_08/runtime_fingerprint.json')
    assert all(fp[n]==h for n,h in old.items() if n.startswith(('assets/','shaders/','scenes/','themes/')))
    matrix=B.parent/'UNLISTED_Stability_Terror_02';results=read(matrix/'matrix_results.json')
    assert len(results)==6 and all(r['passed'] for r in results)
    matrix_sha=sha(matrix/'UNLISTED.exe')
    for name in ['fixed_1080']+[r['case'] for r in results]:
        assert read(matrix/(name+'_launch.json'))['executable_sha256']==matrix_sha
        assert read(matrix/(name+'_owner_integrity.json'))['unchanged']
        assert read(matrix/'QA'/name/'probe_report.json')['completed']
    assert read(B.parent/'UNLISTED_Stability_Terror_01/preserved_route_owner_integrity.json')['unchanged']
    profiles={};reports={}
    for name in ['normal_root','safe_profile_1080','safe_profile_1440','safe_profile_wide','aftermath','impossible','ending_b']:
        text=(B/(name+'.log')).read_text();assert 'ERROR:' not in text and ' FAIL ' not in text
        assert read(B/(name+'_owner_integrity.json'))['unchanged']
        if name=='normal_root':
            r=read(B/'QA'/name/'probe_report.json');assert r['completed'] and all(c['passed'] for c in r['checks']);reports[name]={'passed':len(r['checks']),'failed':0}
        elif name.startswith('safe_profile'):
            p=read(B/'QA'/name/'cellar_route_profile.json');assert len(p['results'])==1 and all(c['passed'] for c in p['checks']);profiles[name]=p
        else:
            r=read(B/'QA'/name/'repair_report.json');assert r['failed']==0;reports[name]={'passed':r['passed'],'failed':r['failed']}
    C.mkdir();E=C/'Evidence';E.mkdir()
    crash=E/'CrashEvidence';crash.mkdir()
    for p in X.iterdir():
        if p.is_file():shutil.copy2(p,crash/p.name)
    (crash/'SHA256.json').write_text(json.dumps({p.name:sha(p) for p in crash.iterdir() if p.is_file()},indent=2),encoding='utf8')
    source=C/'UNLISTED_Stability_Terror_Complete_Private_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes();assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'),n
    with zipfile.ZipFile(source,'a',zipfile.ZIP_DEFLATED,6) as z:
        for p in crash.iterdir():z.write(p,'Private_Crash_Evidence/'+p.name)
    for build,names in [('01',['preserved_route','original_fixed_1080']),('02',['fixed_1080']+[r['case'] for r in results]),('03',['normal_root','safe_profile_1080','safe_profile_1440','safe_profile_wide','aftermath','impossible','ending_b'])]:
        folder=B.parent/('UNLISTED_Stability_Terror_'+build)
        for name in names:
            for p in [folder/(name+'.log'),folder/(name+'_launch.json'),folder/(name+'_owner_integrity.json')]+list((folder/'QA'/name).glob('*.json')):
                if p.exists():shutil.copy2(p,E/(build+'_'+name+'_'+p.name))
    cards=[]
    for name in ['aftermath','impossible']:
        for p in (B/'QA'/name).glob('*.png'):
            target=E/(name+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img loading="lazy" src="'+target.name+'"><figcaption>Fresh verification / '+html.escape(name+' / '+p.stem)+'</figcaption></figure>')
    import validate_v051 as video
    assert video.assemble(B/'QA/aftermath',E/'Native_Retained_Horror_Verification.mp4')
    shutil.copy2(G/'STABILITY_TERROR_VERIFICATION.md',E/'VERIFICATION.md')
    (E/'INDEX.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED 0.10.8 stability evidence</title><style>body{background:#171d1a;color:#dce0d5;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:28px 0}</style><h1>Stability &amp; Terror / PRIVATE QA CANDIDATE</h1><p><strong>Root cause unresolved. Passing comparisons are not a proven crash fix.</strong> <a href="VERIFICATION.md">Investigation, exact scope, risks and owner checklist</a>. Raw memory dumps remain private in CrashEvidence.</p><p>Fresh native verification of retained 0.10.7 horror. No new art/visual-overhaul claim or human approval. Automated fixtures include deliberate placements and save/load tests.</p><video controls src="Native_Retained_Horror_Verification.mp4"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Stability-Terror-v0.10.8-dev-PRIVATE.zip';assert not windows.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Dread-Within-v0.10.7-dev-PRIVATE.zip') as z:notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['THIRD_PARTY.md','STABILITY_TERROR_VERIFICATION.md','DEVELOPMENT_CHECKPOINT.json']:z.write(G/n,n)
        z.writestr('START_HERE.txt','UNLISTED 0.10.8-dev / PRIVATE QA CANDIDATE\nExtract into a new folder, run UNLISTED.exe. Preserve previous builds and AppData/UNLISTED. Intermittent native crash remains unresolved; controlled tests pass but do not prove a fix. Safer profiling and improved failure evidence; normal gameplay/art retained. No system changes or public release. Keep verified0.10.6 rollback.\n')
    for p in [source,windows]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'IndependentExtract')
    assert sha(C/'IndependentExtract/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt={'version':'0.10.8-dev','status':'Private QA candidate; native root cause remains unconfirmed','private_complete_checkpoint':commit,'development_tag':TAG,'windows_zip':str(windows),'windows_sha256':sha(windows),'executable_sha256':sha(B/'UNLISTED.exe'),'complete_source_zip':str(source),'source_sha256':sha(source),'assets_shaders_scenes_themes_match_0107':True,'instrumented_comparison_executable_sha256':matrix_sha,'controlled_matrix':results,'final_checks':reports,'fixed_resolution_profiles':profiles,'independent_native':'PENDING','evidence_gallery':str(E/'INDEX.html'),'public_release':'unchanged','human_approval':'pending','root_cause':'unresolved','system_modifications':'none; only explicit child-process layer filter in one comparison'}
    (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'source':str(source),'windows':str(windows),'evidence':str(E/'INDEX.html'),'private_commit':commit}),flush=True)
if __name__=='__main__':main()
