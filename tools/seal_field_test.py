"""Seal only an accepted native Field Test candidate; never publish private media."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile,hashlib
import package_service_repair as prior

G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds'/sys.argv[1]
C=G.parent/'Checkpoints/20261023_field_test_release'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
assert not C.exists(),'Preserve sealed checkpoints'
assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip(),'Commit reviewed source first'
paths=[p for folder in ['scripts','assets','scenes','shaders','themes'] for p in (G/folder).rglob('*') if p.is_file() and p.suffix!='.uid' and not p.name.endswith('_qa.gd')]+[G/'project.godot',G/'export_presets.cfg']
fingerprint={p.relative_to(G).as_posix():prior.sha(p) for p in paths}
assert fingerprint==read(B/'runtime_fingerprint.json'),'Export and current runtime differ'
R=B.parent/'UNLISTED_FieldTest_04/QA/continuous'
baseline=read(B.parent/'UNLISTED_FieldTest_04/runtime_fingerprint.json')
changed={k for k in fingerprint if fingerprint[k]!=baseline[k]}
assert read(B/"FINAL_DELTA_PROOF.json")["all_four_prior_sources_reconstructed_exactly"]
assert changed=={'scripts/dead_line.gd','scripts/maintenance_store.gd','scripts/inspection_gear.gd','scripts/presentation.gd'},changed
# These final deltas are covered by the final field/reel/layout fixtures. The
# full route uses a completed three-tap rhythm and keyboard navigation.
assert len(read(R/'earned_register_checkpoint.json')['events']['underfloor_pattern'])==3
reports={}
for name,p in [('fresh_both_endings',R/'repair_report.json'),('field_controls',B/'QA/field/report.json'),('layout1080',B/'QA/layout1080/report.json'),('layout1440',B/'QA/layout1440/report.json'),('layout_ultrawide',B/'QA/layoutuw/report.json'),('focused_reel',B/'QA/tape/report.json'),('uv_puzzles_migration',B.parent/'UNLISTED_FieldControls_02/QA/inspection/report.json')]:
    d=read(p);assert d['failed']==0,p
    reports[name]={k:d[k] for k in ['passed','failed','duration_seconds'] if k in d}
for p in B.glob('*.log'):
    s=p.read_text(encoding='utf8',errors='replace');assert 'ERROR:' not in s and ' FAIL ' not in s,p
assert 'QA_QUIT_CALLBACK actual title Quit button' in (B.parent/'UNLISTED_FieldTest_04/continuous.log').read_text(encoding='utf8')
assert read(B/'owner_integrity.json')['unchanged']
frames=read(R/'frames.json');report=read(R/'repair_report.json')
video=B/'UNLISTED_Field_Test_native.mp4';assert not video.exists()
lines=['ffconcat version 1.0']
for i,row in enumerate(frames):
    end=frames[i+1]['seconds'] if i+1<len(frames) else report['duration_seconds']
    lines.extend(["file '"+row['file']+"'",'option framerate 1000','duration '+str(max(.001,end-(row['seconds'] if i else 0)))])
concat=R/'native_frames.ffconcat';concat.write_text('\n'.join(lines)+'\n',encoding='utf8')
with (B/'native_encode.log').open('w',encoding='utf8') as f:
    subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-y','-safe','0','-f','concat','-i',str(concat),'-i',str(R/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-preset','veryfast','-threads','4','-crf','24','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-af','apad','-t',str(report['duration_seconds']),'-movflags','+faststart',str(video)],stdout=f,stderr=subprocess.STDOUT,check=True)
capture=dict(source='Actual native Windows viewport and simultaneous Master bus, isolated automated input',frames=len(frames),duration_seconds=report['duration_seconds'],average_sampled_fps=len(frames)/report['duration_seconds'],largest_sample_interval=max(frames[i+1]['seconds']-frames[i]['seconds'] for i in range(len(frames)-1)),encoded_fps=30,timing='Original wall-clock timestamps, repeated frames; no acceleration or interpolation',audio=prior.signal(R/'game_bus.wav'))
(B/'NATIVE_CAPTURE.json').write_text(json.dumps(capture,indent=2),encoding='utf8')
E=B/'Evidence';E.mkdir();cards=[]
specs=[('Before: native Input settings overflow, rejected',B.parent/'UNLISTED_FieldControls_01/QA/field/F06_controller_settings.png'),('After: complete controller settings and visible Back',B/'QA/field/F06_controller_settings.png'),('Historical reel on its supported shelf lip, earned fresh route',R/'T00_service_reel_on_rack.png'),('Historical observation after actual pickup, carrying and playback',R/'T04_recovered_test_observation.png'),('Low battery: a real pack now matters',B/'QA/field/F01_low_pack_warning.png'),('Rare contact failure / explicit timer fixture',B/'QA/field/F02_loose_contact.png'),('Pad tap restores light without a pack',B/'QA/field/F03_tapped_light_restored.png'),('1440p tonight recording comparison / layout fixture',B/'QA/layout1440/FL02_tonight_comparison.png'),('Ultrawide optional contact setting / layout fixture',B/'QA/layoutuw/FL04_contact_setting.png'),('Preserved real service exit and rainy yard',R/'X06_yard_escape.png'),('Earned close-out ending',R/'R08_ending.png'),('Alternative from the naturally earned porch checkpoint',R/'R09_on_record_branch.png')]
for i,(title,p) in enumerate(specs):
    assert p.exists(),p
    name=f'{i:02d}_'+p.name;shutil.copy2(p,E/name)
    cards.append('<section><h2>'+html.escape(title)+'</h2><img loading="lazy" src="'+name+'"></section>')
for name,p in [('fresh_route',R/'repair_report.json'),('field',B/'QA/field/report.json'),('layout1080',B/'QA/layout1080/report.json'),('layout1440',B/'QA/layout1440/report.json'),('layout_ultrawide',B/'QA/layoutuw/report.json')]:shutil.copy2(p,E/(name+'.json'))
shutil.copy2(B/'NATIVE_CAPTURE.json',E/'NATIVE_CAPTURE.json')
(E/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED / Field Test</title><style>body{background:#111717;color:#d0d5c9;font:17px system-ui;max-width:1400px;margin:35px auto;padding:20px}img{display:block;width:100%;height:auto}section{margin:45px 0}a{color:#c0d8d4}</style><h1>UNLISTED 0.9.2 / Field Test</h1><p>Unretouched actual Windows captures. Native recording uses original timestamps and simultaneous audio; isolated automated input, not a human playtest. Alternate ending restores the naturally earned porch checkpoint. Staged field/layout fixtures and rejected before images are labelled. Human fear, story comprehension, hardware controls, art and subjective listening remain pending.</p><p><a href="../UNLISTED_Field_Test_native.mp4">Native gameplay video (sibling download)</a></p>'+''.join(cards),encoding='utf8')
evidence=B.parent/'UNLISTED-Field-Test-Evidence-v0.9.2.zip';assert not evidence.exists()
with zipfile.ZipFile(evidence,'w',zipfile.ZIP_DEFLATED,6) as z:
    for p in E.iterdir():z.write(p,'Evidence/'+p.name)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip();C.mkdir()
source=C/'UNLISTED_Field_Test_Complete_Source.zip'
subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
with zipfile.ZipFile(source) as z:
    assert z.testzip() is None
    for n in fingerprint:
        a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
        assert a==b or (Path(n).suffix in ['.gd','.gdshader','.tscn','.tres','.godot','.cfg','.import','.json','.txt'] and a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n')),n
    z.extractall(C/'fresh_source_check')
root=C/'fresh_source_check/UNLISTED_Game';engine=r'C:\Users\Snkii\Desktop\Godot_v4.7.2-stable_win64_console.exe'
for name,args in [('import',['--editor','--import','--quit']),('preflight',['--script','res://tools/check_scripts.gd'])]:
    with (C/('fresh_'+name+'.log')).open('w',encoding='utf8') as f:r=subprocess.run([engine,'--headless','--path',str(root),*args],stdout=f,stderr=subprocess.STDOUT,timeout=300)
    s=(C/('fresh_'+name+'.log')).read_text(encoding='utf8',errors='replace');assert r.returncode==0 and 'ERROR:' not in s,(name,s[-1000:])
manifest=dict(version='0.9.2',title='Field Test',private_source_commit=commit,complete_private_source_sha256=prior.sha(source),executable_sha256=prior.sha(B/'UNLISTED.exe'),runtime_source_and_export_match=True,runtime_files=len(fingerprint),reports=reports,full_route_build='UNLISTED_FieldTest_04',final_delta='Final build adds a three-tap fallback for a partly tried joist, adaptive pad/menu/crouch guidance and accurate no-spare warnings. Final native field/reel/layout fixtures verify those edges. The full route retains its completed personal three-tap rhythm, uses keyboard navigation and has collected spares. All other runtime hashes match. UV fixture predates the reel addition; the final fresh route also uses UV, packs and original puzzles.',human_playtested=False,controller_hardware_playtested=False,subjective_listening=False,surveyor_model_changed=False,player_data_preserved=True,audio=capture['audio'])
(B/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
windows=B.parent/'UNLISTED-Windows-Field-Test-v0.9.2.zip';assert not windows.exists()
with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Other-Way-Out-v0.9.1.zip') as z:notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
    z.write(B/'UNLISTED.exe','UNLISTED.exe')
    for n,data in notices.items():z.writestr(n,data)
    for n in ['FIELD_TEST_RELEASE_NOTES.md','FIELD_TEST_VERIFICATION.md','KNOWN_LIMITATIONS.md','THIRD_PARTY.md']:z.write(G/n,n)
    z.write(B/'BUILD_MANIFEST.json','BUILD_MANIFEST.json')
    z.writestr('START_HERE.txt','UNLISTED 0.9.2 / Field Test\nExtract into a NEW folder and run UNLISTED.exe. Preserve earlier builds and AppData/UNLISTED.\nKeyboard: F light mode, B charge, T replace pack (hold with no spares to wind backup), V tap loose contact.\nController: sticks move/look, X use, LB crouch, L3 sprint, RB light, Y pack/wind, D-pad Up charge, Down tap, Left hint, Back journal, Start pause, A select, B back.\nCarry: X/E release, RT/left mouse throw, hold LT + right stick or R + mouse to rotate.\nSettings include controller look speed, deadzone, invert, optional contacts and existing accessibility controls.\nExisting saves retain discoveries and packs; New Game shows the full new investigation.\nUnfinished alpha; human hardware, art, story and listening approval remain pending.\n')
for p in [windows,evidence]:
    with zipfile.ZipFile(p) as z:assert z.testzip() is None
assets=[windows,evidence,video,B/'BUILD_MANIFEST.json',G/'FIELD_TEST_RELEASE_NOTES.md']
(B/'SHA256SUMS.txt').write_text(''.join(prior.sha(p)+'  '+p.name+'\n' for p in assets),encoding='utf8')
receipt=dict(private_checkpoint=commit,source_zip=str(source),source_sha256=prior.sha(source),windows_zip=str(windows),windows_sha256=prior.sha(windows),evidence_zip=str(evidence),video=str(video),published=False)
for folder in [B,C]:(folder/'PACKAGE_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
print(json.dumps(receipt),flush=True)
