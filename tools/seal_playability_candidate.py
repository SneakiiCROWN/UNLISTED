"""Seal a private candidate, with explicit earlier-binary regression scope. No upload."""
from pathlib import Path
import hashlib, html, json, shutil, subprocess, zipfile
import package_service_repair as prior

G = Path(__file__).resolve().parents[1]
B = G.parent / 'Builds/UNLISTED_Playability_Integration_05'
C = G.parent / 'Checkpoints/20261024_playability_candidate_01'
read = lambda p: json.loads(p.read_text(encoding='utf8'))
sha = prior.sha

def main():
    assert not C.exists(), 'Preserve existing checkpoints'
    assert not subprocess.check_output(['git', 'status', '--porcelain'], cwd=G, text=True).strip()
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=G, text=True).strip()
    fp = read(B/'runtime_fingerprint.json')
    for name, digest in fp.items():
        assert sha(G/name) == digest, name
    reports = {}
    # These binaries differ only in the repairs/presentation documented below.
    specs = [('02', 'human', 'report.json'), ('02', 'stamina', 'report.json'), ('02', 'reload', 'report.json'),
             ('04', 'support', 'report.json'), ('04', 'continuation', 'report.json'),
             ('04', 'threat', 'threat_report.json'), ('04', 'earned', 'repair_report.json'),
             ('04', 'layouts1440', 'report.json'), ('04', 'layoutswide', 'report.json'),
             ('05', 'tape', 'report.json'), ('05', 'views1080', 'report.json'),
             ('05', 'views1440', 'report.json'), ('05', 'viewswide', 'report.json')]
    for build, name, filename in specs:
        root = B.parent/('UNLISTED_Playability_Integration_'+build)
        d = read(root/'QA'/filename if name=='threat' else root/'QA'/name/filename)
        assert d['failed'] == 0, (build, name, d['failed'])
        log = (root/(name+'.log')).read_text(encoding='utf8', errors='replace')
        assert 'ERROR:' not in log and ' FAIL ' not in log, (build, name)
        reports[build+'/'+name] = {k:d[k] for k in ['passed', 'failed', 'scope'] if k in d}
    for number in ['02', '04', '05']:
        assert read(B.parent/('UNLISTED_Playability_Integration_'+number)/'owner_integrity.json')['unchanged']
    changed = [n for n,h in read(B.parent/'UNLISTED_Playability_Integration_04/runtime_fingerprint.json').items() if fp.get(n)!=h]
    assert set(changed) == {'scripts/field_tape.gd', 'scripts/house_polish.gd'}, changed
    C.mkdir()
    source = C/'UNLISTED_Playability_Complete_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:
        assert z.testzip() is None
        for n in fp:
            a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
            assert a==b or a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'), n
    E=B/'Evidence';E.mkdir()
    (E/'Reports').mkdir()
    for build,name,filename in specs:
        root=B.parent/('UNLISTED_Playability_Integration_'+build)
        report=root/'QA'/filename if name=='threat' else root/'QA'/name/filename
        shutil.copy2(report,E/'Reports'/(build+'_'+name+'.json'))
    cards=[]
    for root,name,label in [(B,'views1080','1080p'),(B,'views1440','1440p'),(B,'viewswide','3440x1440')]:
        for p in (root/'QA'/name).glob('*.png'):
            target=E/(label+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img src="'+html.escape(target.name)+'"><figcaption>'+label+' / '+html.escape(p.stem)+'</figcaption></figure>')
    for p in (B.parent/'UNLISTED_Playability_Integration_04/QA/continuation').glob('A*.png'):
        target=E/('ArrivalStudy04_'+p.name);shutil.copy2(p,target)
        cards.append('<figure><img src="'+html.escape(target.name)+'"><figcaption>Opt-in arrival study / preceding candidate 04</figcaption></figure>')
    for p in (B.parent/'UNLISTED_Playability_Integration_04/QA/continuation').glob('V0[3-7]*.png'):
        target=E/('Rooms04_'+p.name);shutil.copy2(p,target)
        cards.append('<figure><img src="'+html.escape(target.name)+'"><figcaption>Room review / preceding candidate 04; unchanged room geometry</figcaption></figure>')
    for name in ['layouts1440','layoutswide']:
        for p in (B.parent/'UNLISTED_Playability_Integration_04/QA'/name).glob('*.png'):
            target=E/(name+'_'+p.name);shutil.copy2(p,target)
            cards.append('<figure><img src="'+html.escape(target.name)+'"><figcaption>Native UI / '+name+'</figcaption></figure>')
    video=B.parent/'UNLISTED_Playability_Integration_04/UNLISTED_Playability_Earned_Continuation_native.mp4'
    assert video.exists()
    shutil.copy2(video,E/video.name)
    audio = prior.signal(B/'QA/tape/game_bus.wav')
    manifest=dict(version='0.10.1-dev',status='PRIVATE UNRELEASED CANDIDATE',private_source_commit=commit,
                  executable_sha256=sha(B/'UNLISTED.exe'),source_sha256=sha(source),reports=reports,
                  final_runtime_delta_from_04=changed,audio_signal=audio,human_playtested=False,
                  subjective_listening=False,public_release_unchanged='0.10.0 The Last Call',
                  route_scope='Earned saved-bay continuation through real escape and both endings on 04; final 05 changes only recorder presentation and reruns recorder interactions. Not a fresh full-route human playthrough.')
    (B/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    shutil.copy2(G/'PLAYABILITY_CANDIDATE_VERIFICATION.md',E/'VERIFICATION.md')
    shutil.copy2(B/'BUILD_MANIFEST.json',E/'BUILD_MANIFEST.json')
    (E/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED private candidate</title><style>body{background:#141918;color:#d6d8cc;font:17px system-ui;margin:30px}img,video{max-width:100%;height:auto}figure{margin:35px 0}</style><h1>Private playability candidate</h1><p>Unretouched exported screenshots. Automated fixtures; human art, story comprehension and subjective listening remain pending. Read VERIFICATION.md and BUILD_MANIFEST.json for exact test and binary scope.</p><p>Recorded earned-save continuation on 04, with native elapsed timing and sampled frames repeated at 30 fps. Not a human duration or performance benchmark.</p><video controls src="'+video.name+'"></video>'+''.join(cards),encoding='utf8')
    windows=B.parent/'UNLISTED-Windows-Playability-v0.10.1-dev-PRIVATE.zip'
    evidence=B.parent/'UNLISTED-Playability-Evidence-v0.10.1-dev-PRIVATE.zip'
    assert not windows.exists() and not evidence.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-The-Last-Call-v0.10.0.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for n,data in notices.items():z.writestr(n,data)
        for n in ['PLAYABILITY_CANDIDATE_VERIFICATION.md','THIRD_PARTY.md']:z.write(G/n,n)
        z.write(B/'BUILD_MANIFEST.json','BUILD_MANIFEST.json')
        z.writestr('START_HERE.txt','UNLISTED 0.10.1-dev PRIVATE CANDIDATE\nExtract into a new folder and run UNLISTED.exe. Existing saves stay in AppData/UNLISTED. Preserve previous builds.\nNot a public release or a human-approved finished game. Read verification for scope and remaining work.\n')
    with zipfile.ZipFile(evidence,'w',zipfile.ZIP_DEFLATED,6) as z:
        for p in E.rglob('*'):
            if p.is_file():z.write(p,'Evidence/'+p.relative_to(E).as_posix())
    for p in [windows,evidence]:
        with zipfile.ZipFile(p) as z:assert z.testzip() is None
    with zipfile.ZipFile(windows) as z:z.extractall(C/'extracted_windows')
    assert sha(C/'extracted_windows/UNLISTED.exe')==sha(B/'UNLISTED.exe')
    receipt=dict(private_checkpoint=commit,complete_source_zip=str(source),source_sha256=sha(source),windows_zip=str(windows),windows_sha256=sha(windows),evidence_zip=str(evidence),published=False)
    for root in [B,C]:(root/'PACKAGE_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps(receipt),flush=True)

if __name__=='__main__':main()
