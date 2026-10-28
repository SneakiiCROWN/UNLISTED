"""Run existing real-game QA with production atmosphere selection, isolated owner data."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--profile',type=int,choices=[0,1,2],default=1);p.add_argument('--mode',default='atmosphere-integration');p.add_argument('--size',default='1920x1080');p.add_argument('--timeout',type=int,default=900);p.add_argument('--keep-settings',action='store_true');p.add_argument('--prebuilt-viewport',action='store_true');p.add_argument('--fps',type=int,default=60);p.add_argument('extra',nargs='*');a=p.parse_args()
assert 0<=a.fps<=240
E=a.exe.resolve();O=a.output.resolve();assert E.is_file() and not O.exists();O.mkdir(parents=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{str(x):sha(x) for x in owner if x.is_file()}
before=hashes();settings=E.parent/'QA/presentation_settings.cfg';settings.parent.mkdir(exist_ok=True)
if settings.exists():(O/'previous_qa_settings.cfg').write_bytes(settings.read_bytes())
if not a.keep_settings:settings.write_text('[presentation]\natmosphere_mode = '+str(a.profile)+'\nresolution = Vector2i('+a.size.replace('x',', ')+')\n',encoding='utf8')
args=[str(E),'--max-fps','0' if a.mode=='atmosphere-performance' else str(a.fps)]
if a.mode=='atmosphere-performance':args.append('--disable-vsync')
args+=['--','--'+a.mode+'-qa','--capture-size='+a.size,'--evidence='+str(O),'--route-light-capture',*a.extra]
if a.prebuilt_viewport:args.append('--prebuilt-viewport')
(O/'launch.json').write_text(json.dumps({'args':args,'profile':a.profile,'exe_sha256':sha(E),'scope':'Native exported gameplay; production startup preferences. Only testing inputs, evidence and saves are isolated.'},indent=2),encoding='utf8')
start=time.monotonic();code=None;seen_lines=0
try:
 with (O/'native.log').open('w',encoding='utf8') as log:
  proc=subprocess.Popen(args,cwd=E.parent,stdout=log,stderr=subprocess.STDOUT)
  try:
   while proc.poll() is None:
    if time.monotonic()-start>a.timeout:raise subprocess.TimeoutExpired(args,a.timeout)
    current_log=(O/'native.log').read_text(encoding='utf8',errors='replace')
    lines=current_log.splitlines()
    for line in lines[seen_lines:]:
     if 'ERROR:' in line or 'WARNING:' in line:
      with (O/'observed_errors.jsonl').open('a',encoding='utf8') as observations:observations.write(json.dumps({'observed_seconds_after_launch':time.monotonic()-start,'line':line,'scope':'Polling observation time, not an engine timestamp'})+'\n')
    seen_lines=len(lines)
    if 'SCRIPT ERROR:' in current_log or 'Failed to load script' in current_log:
     proc.terminate();(O/'SCRIPT_ABORT.txt').write_text('Stopped this exact QA child after a script failure; not an ordinary owner crash.',encoding='utf8');break
    time.sleep(.25)
   code=proc.wait(timeout=5)
  except subprocess.TimeoutExpired:
   proc.kill();code=proc.wait();(O/'TIMEOUT.txt').write_text('Automation deadline; forced shutdown. Not an ordinary-menu crash.',encoding='utf8')
finally:
 after=hashes();text=(O/'native.log').read_text(encoding='utf8',errors='replace');reports=[]
 fixed_reports={'input-isolation':('input_isolation','report.json','input_report.json'),'caption':('captions','caption_report.json','caption_report.json')}
 if a.mode in fixed_reports:
  folder,filename,destination=fixed_reports[a.mode]
  fixed=E.parent/'QA'/folder/filename
  assert fixed.exists() and fixed.stat().st_mtime>=time.time()-(time.monotonic()-start)-2,'Missing current fixed-path report'
  shutil.copy2(fixed,O/destination)
  for screenshot in fixed.parent.glob('*.png'):
   if screenshot.stat().st_mtime>=time.time()-(time.monotonic()-start)-2:shutil.copy2(screenshot,O/screenshot.name)
 for report in O.glob('*report.json'):
  try:
   data=json.loads(report.read_text(encoding='utf8'));reports.append({'file':report.name,'failed':data.get('failed'),'checks':len(data.get('checks',[]))})
  except (ValueError,TypeError):pass
 result={'exit_code':code,'duration_seconds':time.monotonic()-start,'errors':[s for s in text.splitlines() if 'ERROR:' in s],'warnings':[s for s in text.splitlines() if 'WARNING:' in s],'owner_before':before,'owner_after':after,'owner_unchanged':before==after,'reports':reports}
 (O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
 assert before==after,'Owner files changed; evidence retained, do not auto-restore'
assert code==0 and not result['errors'] and reports and all(r['failed']==0 for r in reports),str(O)
