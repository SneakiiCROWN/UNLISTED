"""Seal the verified inspection milestone; raw project media stays local."""
from pathlib import Path
import json, os, shutil, subprocess, zipfile
import package_service_repair as prior

G = Path(__file__).resolve().parents[1]
B = G.parent / 'Builds/UNLISTED_Inspection_12'
R = G.parent / 'Builds/UNLISTED_Inspection_11'
S = G.parent / 'Builds/UNLISTED_Inspection_10'
C = G.parent / 'Checkpoints/20261023_inspection_release'

def main():
    assert not C.exists(), 'Preserve sealed recovery points'
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    reports = {}
    final = {'inspection':'inspection/report.json', 'story':'story_clarity/report.json', 'prerequisite_edges':'edges/report.json'}
    route = {'fresh_both_endings':'continuous/repair_report.json', 'chapter':'chapter/report.json',
             'systems':'systems_report.json',
             'threat':'threat_report.json','underfloor':'underfloor/repair_report.json',
             'impossible':'impossible/repair_report.json'}
    for scope,folder,entries in [('final',B,final),('integrated',R,route),('targeted',S,{'storage_risks':'storage/report.json'})]:
        for name,path in entries.items():reports[name] = dict(prior.report(folder/'QA'/path),build=folder.name,scope=scope)
    # Final candidate changes only one comparison status sentence after the full route.
    a=json.loads((R/'runtime_fingerprint.json').read_text());b=json.loads((B/'runtime_fingerprint.json').read_text())
    assert set(a)==set(b)
    assert [name for name in a if a[name]!=b[name]]==['scripts/presentation.gd']
    assert not [name for name,h in b.items() if prior.sha(G/name)!=h]
    old_edges=json.loads((R/'QA/edges/report.json').read_text())
    assert old_edges['failed']==1 and [row['name'] for row in old_edges['checks'] if not row['passed']]==['live feed blocks even correct frequency']
    for folder in [B,R]:
        for file in folder.glob('*.log'):
            text=file.read_text(encoding='utf-8',errors='replace')
            assert 'ERROR:' not in text,file
            if file!=R/'edges.log':assert ' FAIL ' not in text,file
        for file in folder.glob('player_data_integrity*.json'):assert json.loads(file.read_text())['unchanged']
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    C.mkdir();backup=C/'Preserved_Player_Data';backup.mkdir()
    for name in ['checkpoint.json','settings.cfg']:
        p=Path(os.environ['APPDATA'])/'UNLISTED'/name
        if p.exists():shutil.copy2(p,backup/name)
    source=C/'UNLISTED_Inspection_Complete_Source.zip'
    subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
    with zipfile.ZipFile(source) as z:assert z.testzip() is None
    manifest={'version':'0.9.0','title':'Inspection','private_source_commit':commit,
        'source_sha256':prior.sha(source),'executable_sha256':prior.sha(B/'UNLISTED.exe'),
        'reports':reports,'final_delta':'One comparison status sentence; final native UI/inspection verified. Full gameplay runtime otherwise matches Inspection_11.',
        'preserved_rejected_test':'Inspection_11 edges 13/1 retained. The live-feed fixture searched for uppercase INTERFERENCE after the visible wording became ordinary sentence case. State and lower-case visible feedback rechecked in final edges fixture; no gameplay change.',
        'human_playtested':False,'subjective_listening':False,'duration_target_achieved':False,
        'surveyor_model_changed':False,'audio_signal':prior.signal(R/'QA/continuous/game_bus.wav')}
    for folder in [B,C]:(folder/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    archive=B.parent/'UNLISTED-Windows-Inspection-Test.zip';assert not archive.exists()
    with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Spare-Place-Test.zip') as z:
        notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,6) as z:
        z.write(B/'UNLISTED.exe','UNLISTED.exe')
        for name,data in notices.items():z.writestr(name,data)
        for name in ['INSPECTION_RELEASE_NOTES.md','INSPECTION_VERIFICATION.md','THIRD_PARTY.md']:z.write(G/name,name)
        z.write(B/'BUILD_MANIFEST.json','BUILD_MANIFEST.json')
        z.writestr('START_HERE.txt','UNLISTED 0.9.0 / Inspection\nExtract into a NEW folder, then open UNLISTED.exe.\nKeep previous builds and AppData/UNLISTED.\nF cycles light; B checks charge; T changes packs.\nWith no spares and low charge, hold T to wind the backup.\nThe inspection head is in the shed. Follow observed clues.\nStill an alpha; human story/art/fear/listening approval pending.\n')
    with zipfile.ZipFile(archive) as z:assert z.testzip() is None
    receipt={'private_checkpoint':commit,'windows_zip':str(archive),'windows_zip_sha256':prior.sha(archive),
        'windows_zip_bytes':archive.stat().st_size,'private_source_zip':str(source),'source_sha256':prior.sha(source)}
    for folder in [B,C]:(folder/'PACKAGE_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    (B/'SHA256SUMS.txt').write_text(receipt['windows_zip_sha256']+'  '+archive.name+'\n',encoding='utf-8')
    print(json.dumps(receipt),flush=True)

if __name__=='__main__':main()
