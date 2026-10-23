"""Seal an accepted candidate without changing previous releases or player data."""
from pathlib import Path
import hashlib,json,subprocess,sys,zipfile
import package_service_repair as prior
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds'/sys.argv[1]
C=G.parent/'Checkpoints/20261023_other_way_out_release'
assert not C.exists(),'Never overwrite a sealed checkpoint'
assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip(),'Commit reviewed source first'
paths=[p for folder in ['scripts','assets','scenes','shaders','themes'] for p in (G/folder).rglob('*') if p.is_file() and p.suffix!='.uid' and not p.name.endswith('_qa.gd')]+[G/'project.godot',G/'export_presets.cfg']
actual={str(p.relative_to(G)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
assert actual==json.loads((B/'runtime_fingerprint.json').read_text()),'Export/source mismatch'
assert actual==json.loads((G.parent/'Builds/UNLISTED_ServiceExit_09/runtime_fingerprint.json').read_text()),'Layout runtime mismatch'
def clean(p):
    d=json.loads(p.read_text());assert d['failed']==0,p
    return {k:d[k] for k in ['passed','failed','duration_seconds'] if k in d}
reports={'fresh_both_endings':clean(B/'QA/continuous/repair_report.json'),'new_mechanics_death_retry_story':clean(G.parent/'Builds/UNLISTED_ServiceExit_08/QA/exit/report.json'),'layout1080':clean(B/'QA/exit1080/report.json'),'layout1440':clean(G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exit1440/report.json'),'layout_ultrawide':clean(G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exituw/report.json')}
assert 'QA_QUIT_CALLBACK actual title Quit button' in (B/'continuous.log').read_text()
for p in B.glob('*.log'):
    text=p.read_text(encoding='utf8',errors='replace');assert 'ERROR:' not in text and ' FAIL ' not in text,p
for p in B.glob('player_data_integrity_exit_*.json'):assert json.loads(p.read_text())['unchanged']
assert (B/'UNLISTED_Other_Way_Out_native.mp4').exists()
assert (B/'Evidence/index.html').exists()
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
C.mkdir();source=C/'UNLISTED_Other_Way_Out_Complete_Source.zip'
subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
with zipfile.ZipFile(source) as z:assert z.testzip() is None
manifest=dict(version='0.9.1',title='The Other Way Out',private_source_commit=commit,executable_sha256=prior.sha(B/'UNLISTED.exe'),complete_private_source_sha256=prior.sha(source),reports=reports,source_and_export_match=True,focused_delta='ServiceExit_08 mechanics match final except the evidence prose and powered-contact eligibility. Final native layouts and the fresh route exercise those changes.',human_playtested=False,subjective_listening=False,human_duration_claim=False,surveyor_model_changed=False,audio=prior.signal(B/'QA/continuous/game_bus.wav'),player_data_preserved=True)
(B/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf8');(C/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
archive=B.parent/'UNLISTED-Windows-Other-Way-Out-Test.zip';assert not archive.exists()
with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Inspection-Test.zip') as z:notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,6) as z:
    z.write(B/'UNLISTED.exe','UNLISTED.exe')
    for name,data in notices.items():z.writestr(name,data)
    for name in ['OTHER_WAY_OUT_RELEASE_NOTES.md','OTHER_WAY_OUT_VERIFICATION.md','KNOWN_LIMITATIONS.md','THIRD_PARTY.md']:z.write(G/name,name)
    z.write(B/'BUILD_MANIFEST.json','BUILD_MANIFEST.json')
    z.writestr('START_HERE.txt','UNLISTED 0.9.1 / The Other Way Out\nExtract into a NEW folder, then open UNLISTED.exe.\nPreserve previous builds and your AppData/UNLISTED profile.\nExisting saves retain their clues and puzzle answers. Start New Game to experience the complete new discovery sequence.\nF cycles flashlight modes; B checks charge; T changes packs. Hold T for emergency winding when empty.\nOptional guidance, captions, motion/flicker reduction and story mode remain in Settings.\nThe Surveyor character art and the larger game remain unfinished.\n')
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
receipt=dict(private_checkpoint=commit,source_zip=str(source),source_sha256=prior.sha(source),windows_zip=str(archive),windows_zip_sha256=prior.sha(archive),windows_zip_bytes=archive.stat().st_size,published=False)
for folder in [B,C]:(folder/'PACKAGE_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
assets=[archive,B.parent/'UNLISTED-Other-Way-Out-Evidence.zip',B/'UNLISTED_Other_Way_Out_native.mp4',B/'BUILD_MANIFEST.json',G/'OTHER_WAY_OUT_RELEASE_NOTES.md']
(B/'SHA256SUMS.txt').write_text(''.join(prior.sha(p)+'  '+p.name+'\n' for p in assets),encoding='utf8')
print(json.dumps(receipt),flush=True)
