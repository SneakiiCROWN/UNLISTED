"""Seal reviewed Night Arrival; complete licensed source remains local."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,sys,zipfile
import package_service_repair as prior
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_NightArrival_03'
C=G.parent/'Checkpoints/20261023_night_arrival_release'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=prior.sha
resume='--resume-verified-import' in sys.argv
assert not C.exists() or resume,'Preserve previous checkpoints'
source_commit=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--source-checkpoint=')),None)
assert not resume or source_commit,'Resume must identify the preserved archive checkpoint'
assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
paths=[p for folder in ['scripts','assets','scenes','shaders','themes'] for p in (G/folder).rglob('*') if p.is_file() and p.suffix!='.uid' and not p.name.endswith('_qa.gd')]+[G/'project.godot',G/'export_presets.cfg']
fingerprint={p.relative_to(G).as_posix():sha(p) for p in paths}
assert fingerprint==read(B/'runtime_fingerprint.json'),'Current runtime differs from native export'
reports={}
for name,folder,file in [('car',B/'QA/car','repair_report.json'),('car1440',B/'QA/car1440','repair_report.json'),('caruw',B/'QA/caruw','repair_report.json'),('arrival',B/'QA/arrival','repair_report.json'),('reload',B/'QA/reload','report.json'),('original_inspection',B.parent/'UNLISTED_TorchService_03/QA/inspection','report.json'),('field_controls',B.parent/'UNLISTED_TorchService_03/QA/field','report.json')]:
 d=read(folder/file);assert d['failed']==0,name
 reports[name]={k:d[k] for k in ['passed','failed','elapsed_seconds','duration_seconds'] if k in d}
for p in B.glob('*.log'):
 s=p.read_text(encoding='utf8',errors='replace');assert 'ERROR:' not in s and ' FAIL ' not in s,p
assert read(B/'owner_integrity.json')['unchanged']
old=read(B.parent/'UNLISTED_TorchService_03/runtime_fingerprint.json')
for name in ['scripts/inspection_gear.gd','scripts/flashlight_viewmodel.gd','scripts/torch_service.gd']:
 assert fingerprint[name]==old[name],name
# The larger fresh route and original ending conditions remain the accepted baseline.
route=read(B.parent/'UNLISTED_FieldTest_04/QA/continuous/repair_report.json');assert route['failed']==0
R=B/'QA/reload';d=read(R/'report.json');frames=d['frames'];start=d['audio_start_seconds'];duration=d['duration_seconds']-start
lines=['ffconcat version 1.0']
for i,row in enumerate(frames):
 end=frames[i+1]['seconds'] if i+1<len(frames) else d['duration_seconds']
 lines += ["file '"+row['file']+"'",'option framerate 1000','duration '+str(max(.001,end-(row['seconds'] if i else start)))]
concat=R/'native_frames.ffconcat';concat.write_text('\n'.join(lines)+'\n',encoding='utf8')
video=B/'UNLISTED_Night_Arrival_native.mp4'
with (B/'native_encode.log').open('w',encoding='utf8') as f:
 subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-y','-safe','0','-f','concat','-threads','1','-i',str(concat),'-i',str(R/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-preset','veryfast','-threads','2','-crf','24','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-af','apad','-t',str(duration),'-movflags','+faststart',str(video)],stdout=f,stderr=subprocess.STDOUT,check=True)
audio=prior.signal(R/'game_bus.wav')
E=B/'Evidence';E.mkdir(exist_ok=resume);cards=[]
specs=[('Parked arrival car / actual native player-eye view',B/'QA/car/C03_modern_psx.png'),('Gate-side context / actual movement route',B/'QA/car/C06_gate_car_context.png'),('Clean / same camera',B/'QA/car/C02_clean_world.png'),('Modern PSX / same camera',B/'QA/car/C03_modern_psx.png'),('Stronger Retro / same camera',B/'QA/car/C04_stronger_retro.png'),('1440p display controls remain sharp',B/'QA/car1440/C09_readable_settings.png'),('Ultrawide world presentation',B/'QA/caruw/C03_modern_psx.png'),('Baseline held torch / staged native pose',B/'QA/reload/P00_original_held_pose.png'),('Actual cap opening / staged AnimationPlayer pose',B/'QA/reload/P02_open_compartment.png'),('Pack extracted and supported / staged AnimationPlayer pose',B/'QA/reload/P03_old_pack_extracted.png'),('Pack seated / staged AnimationPlayer pose',B/'QA/reload/P05_new_pack_seating.png'),('Rejected first sleeve fitting / preserved before correction',B.parent/'UNLISTED_TorchService_01/QA/reload/P03_old_pack_extracted.png'),('Existing knock opens door ajar / final exported input test',B/'QA/arrival/G03_door_ajar.png')]
for i,(title,p) in enumerate(specs):
 assert p.exists(),p
 name=f'{i:02d}_'+p.name;shutil.copy2(p,E/name);cards.append('<section><h2>'+html.escape(title)+'</h2><img loading="lazy" src="'+name+'"></section>')
for n in ['NIGHT_ARRIVAL_VERIFICATION.md','NIGHT_ARRIVAL_RELEASE_NOTES.md','KNOWN_LIMITATIONS.md']:shutil.copy2(G/n,E/n)
for name,folder in [('car',B/'QA/car'),('car1440',B/'QA/car1440'),('caruw',B/'QA/caruw'),('arrival',B/'QA/arrival'),('reload',R)]:
 src=folder/('report.json' if name=='reload' else 'repair_report.json');shutil.copy2(src,E/(name+'_report.json'))
(E/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED Night Arrival evidence</title><style>body{background:#11171b;color:#d4dad6;font:17px system-ui;margin:28px}section{margin:40px 0}img{width:100%;max-width:1600px}</style><h1>UNLISTED 0.9.3 / Night Arrival</h1><p>Unretouched native Windows screenshots. Staged reload poses are identified; the accompanying video records live interruption tests at original elapsed time with sampled repeated frames. Human art/hardware/listening approval remains pending. Car asset: <a href="https://opengameart.org/content/psx-style-cars">GGBotNet / CC0</a>. Read the verification document for baseline and scope.</p>'+''.join(cards),encoding='utf8')
commit=subprocess.check_output(['git','rev-parse',source_commit or 'HEAD'],cwd=G,text=True).strip();C.mkdir(exist_ok=resume)
source=C/'UNLISTED_Night_Arrival_Complete_Source.zip'
if not resume:subprocess.run(['git','archive','--format=zip','--prefix=UNLISTED_Game/','-o',str(source),commit],cwd=G,check=True)
with zipfile.ZipFile(source) as z:
 assert z.testzip() is None
 for n in fingerprint:
  a=z.read('UNLISTED_Game/'+n);b=(G/n).read_bytes()
  assert a==b or (Path(n).suffix in ['.gd','.gdshader','.tscn','.tres','.godot','.cfg','.import','.json','.txt'] and a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n')),n
 if not resume:z.extractall(C/'fresh_source_check')
root=C/'fresh_source_check/UNLISTED_Game';engine=r'C:\Users\Snkii\Desktop\Godot_v4.7.2-stable_win64_console.exe'
if resume:
 assert read(C/'import_retry_result.json')['returncode']==0
 assert 'ERROR:' not in (C/'fresh_import_retry.log').read_text(encoding='utf8',errors='replace')
 assert 'SCRIPT_PREFLIGHT checked=81 failed=0' in (C/'fresh_preflight.log').read_text(encoding='utf8')
for name,args in ([] if resume else [('import',['--editor','--import','--quit']),('preflight',['--script','res://tools/check_scripts.gd'])]):
 with (C/('fresh_'+name+'.log')).open('w',encoding='utf8') as f:r=subprocess.run([engine,'--headless','--path',str(root),*args],stdout=f,stderr=subprocess.STDOUT,timeout=300)
 s=(C/('fresh_'+name+'.log')).read_text(encoding='utf8',errors='replace');assert r.returncode==0 and 'ERROR:' not in s,(name,s[-1500:])
manifest=dict(version='0.9.3',title='Night Arrival',private_source_commit=commit,source_sha256=sha(source),executable_sha256=sha(B/'UNLISTED.exe'),runtime_source_export_match=True,reports=reports,full_route_baseline='FieldTest_04 362/0; FieldTest_05 final deltas documented. No new independent full route for cosmetic/equipment milestone.',human_playtested=False,controller_hardware_playtested=False,subjective_listening=False,surveyor_model_changed=False,player_data_preserved=True,source_import_note='First extracted import stopped early; preserved retry completes cleanly, all 81 scripts compile. Cause not established. No source or raw asset loss.',audio=audio,native_capture=dict(duration_seconds=duration,sampled_frames=len(frames),timing='Original elapsed time; repeated sampled frames; no acceleration or interpolation'))
(B/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
windows=B.parent/'UNLISTED-Windows-Night-Arrival-v0.9.3.zip';evidence=B.parent/'UNLISTED-Night-Arrival-Evidence-v0.9.3.zip'
assert not windows.exists() and not evidence.exists()
with zipfile.ZipFile(B.parent/'UNLISTED-Windows-Field-Test-v0.9.2.zip') as z:notices={n:z.read(n) for n in z.namelist() if n.startswith('ThirdPartyNotices/') or n=='LICENSE.txt'}
with zipfile.ZipFile(windows,'w',zipfile.ZIP_DEFLATED,6) as z:
 z.write(B/'UNLISTED.exe','UNLISTED.exe')
 for n,data in notices.items():z.writestr(n,data)
 z.write(G/'assets/exterior/arrival/GGBotNet_CC0.txt','ThirdPartyNotices/GGBotNet_CC0.txt')
 for n in ['NIGHT_ARRIVAL_RELEASE_NOTES.md','NIGHT_ARRIVAL_VERIFICATION.md','KNOWN_LIMITATIONS.md','THIRD_PARTY.md']:z.write(G/n,n)
 z.write(B/'BUILD_MANIFEST.json','BUILD_MANIFEST.json')
 z.writestr('START_HERE.txt','UNLISTED 0.9.3 / Night Arrival\nExtract into a new folder and run UNLISTED.exe. Preserve earlier builds and AppData/UNLISTED.\nF/RB light mode; T/Y replace pack, hold with no spares at low charge to wind backup; V/D-pad Down tap loose contact.\nPut carried objects down before changing packs. Movement remains available.\nSettings / Display: Clean, Modern PSX, Stronger Retro and saved colour depth strength. UI stays sharp.\nHardware controller, subjective listening and final art approval remain pending. Read the verification and limitations.\n')
with zipfile.ZipFile(evidence,'w',zipfile.ZIP_DEFLATED,6) as z:
 for p in E.rglob('*'):
  if p.is_file():z.write(p,'Evidence/'+p.relative_to(E).as_posix())
for p in [windows,evidence]:
 with zipfile.ZipFile(p) as z:assert z.testzip() is None
assets=[windows,evidence,video,B/'BUILD_MANIFEST.json',G/'NIGHT_ARRIVAL_RELEASE_NOTES.md']
(B/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.name+'\n' for p in assets),encoding='utf8')
receipt=dict(private_checkpoint=commit,complete_source_zip=str(source),source_sha256=sha(source),windows_zip=str(windows),windows_sha256=sha(windows),evidence_zip=str(evidence),video=str(video),published=False)
for folder in [B,C]:(folder/'PACKAGE_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
print(json.dumps(receipt),flush=True)
