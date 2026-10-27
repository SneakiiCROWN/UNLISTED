"""One isolated native graphics process, explicit cap and protected owner data."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess,time
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--exe',required=True,type=Path);p.add_argument('--output',required=True,type=Path)
p.add_argument('--profile',required=True,choices=['original','wet','lights','probe','glass','ao','ssil','ssr','balanced','enhanced'])
p.add_argument('--size',default='1920x1080',choices=['1920x1080','2560x1440','3440x1440'])
p.add_argument('--window-camera-outside',action='store_true')
p.add_argument('--phase4',action='store_true');p.add_argument('--atmosphere-baseline',action='store_true');p.add_argument('--window-actor-motion',action='store_true')
p.add_argument('--phase3',action='store_true');p.add_argument('--property-baseline',action='store_true');p.add_argument('--property-route',action='store_true')
p.add_argument('--no-fog',action='store_true');p.add_argument('--window-record',action='store_true');p.add_argument('--phase2',action='store_true');p.add_argument('--no-room-reflection',action='store_true');p.add_argument('--performance',action='store_true');p.add_argument('--uncapped',action='store_true')
p.add_argument('--foreground',action='store_true');p.add_argument('--walk',action='store_true');p.add_argument('--record',action='store_true')
a=p.parse_args();E=a.exe.resolve();O=a.output.resolve()
assert E.is_file() and not O.exists();O.mkdir(parents=True)
sha=lambda x:hashlib.sha256(x.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{str(x):sha(x) for x in owner if x.is_file()}
before=hashes()
args=[str(E),'--max-fps','0' if a.uncapped else '60']
if a.uncapped:args.append('--disable-vsync')
args+=['--','--graphics-study-qa','--graphics-profile='+a.profile,'--capture-size='+a.size,'--evidence='+str(O)]
if a.window_camera_outside:args.append("--window-camera-outside")
if a.phase4:args.append("--graphics-phase4")
if a.atmosphere_baseline:args.append("--atmosphere-baseline")
if a.window_actor_motion:args.append("--window-actor-motion")
if a.phase3:args.append("--graphics-phase3")
if a.property_baseline:args.append("--property-baseline")
if a.property_route:args.append("--property-route")
if a.phase2:args.append('--graphics-phase2')
if a.no_fog:args.append('--phase2-no-fog')
if a.no_room_reflection:args.append('--phase2-no-reflection')
if a.performance:args.append('--graphics-performance')
if a.foreground:args.append('--foreground-profile')
if a.walk:args.append('--graphics-walk')
if a.window_record:
 assert not a.performance
 args.append('--graphics-window-record')
if a.record:
 assert a.walk and not a.performance,'Recording is separate from uncaptured measurements'
 args.append('--graphics-record')
(O/'launch.json').write_text(json.dumps({'args':args,'executable_sha256':sha(E),'fps_cap':0 if a.uncapped else 60,'vsync_disabled_requested':a.uncapped,'scope':'Private fixed-resolution spatial study. Foreground preview may be smaller than render; physical input rejected.'},indent=2),encoding='utf8')
start=time.monotonic()
try:
 with (O/'native.log').open('w',encoding='utf8') as log:r=subprocess.run(args,cwd=E.parent,stdout=log,stderr=subprocess.STDOUT,timeout=420 if a.property_route else 180)
finally:
 after=hashes();(O/'owner_integrity.json').write_text(json.dumps({'before':before,'after':after,'unchanged':before==after},indent=2),encoding='utf8')
 assert before==after,'Owner data changed; preserve both versions, no automatic restore'
text=(O/'native.log').read_text(errors='replace');report=O/'graphics_report.json'
result={'exit_code':r.returncode,'duration_seconds':time.monotonic()-start,'script_errors':'ERROR:' in text,'warnings':[s for s in text.splitlines() if 'WARNING:' in s],'report_written':report.is_file(),'owner_unchanged':True}
(O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
assert r.returncode==0 and not result['script_errors'] and result['report_written'] and 'QA_INPUT_ISOLATED' in text
checks=json.loads(report.read_text())['checks'];assert all(c['passed'] for c in checks)
