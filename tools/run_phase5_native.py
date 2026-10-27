"""Run existing real-game QA with production atmosphere selection, isolated owner data."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--profile',type=int,choices=[0,1,2],default=1);p.add_argument('--mode',default='atmosphere-integration');p.add_argument('--size',default='1920x1080');p.add_argument('--timeout',type=int,default=900);p.add_argument('--keep-settings',action='store_true');p.add_argument('extra',nargs='*');a=p.parse_args()
E=a.exe.resolve();O=a.output.resolve();assert E.is_file() and not O.exists();O.mkdir(parents=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{str(x):sha(x) for x in owner if x.is_file()}
before=hashes();settings=E.parent/'QA/presentation_settings.cfg';settings.parent.mkdir(exist_ok=True)
if settings.exists():(O/'previous_qa_settings.cfg').write_bytes(settings.read_bytes())
if not a.keep_settings:settings.write_text('[presentation]\natmosphere_mode = '+str(a.profile)+'\nresolution = Vector2i('+a.size.replace('x',', ')+')\n',encoding='utf8')
args=[str(E),'--max-fps','0' if a.mode=='atmosphere-performance' else '60']
if a.mode=='atmosphere-performance':args.append('--disable-vsync')
args+=['--','--'+a.mode+'-qa','--capture-size='+a.size,'--evidence='+str(O),'--route-light-capture',*a.extra]
(O/'launch.json').write_text(json.dumps({'args':args,'profile':a.profile,'exe_sha256':sha(E),'scope':'Native exported gameplay; production startup preferences. Only testing inputs, evidence and saves are isolated.'},indent=2),encoding='utf8')
start=time.monotonic();code=None
try:
 with (O/'native.log').open('w',encoding='utf8') as log:
  proc=subprocess.Popen(args,cwd=E.parent,stdout=log,stderr=subprocess.STDOUT)
  try:code=proc.wait(timeout=a.timeout)
  except subprocess.TimeoutExpired:
   proc.kill();code=proc.wait();(O/'TIMEOUT.txt').write_text('Automation deadline; forced shutdown. Not an ordinary-menu crash.',encoding='utf8')
finally:
 after=hashes();text=(O/'native.log').read_text(encoding='utf8',errors='replace');reports=[]
 for report in O.glob('*report.json'):
  try:
   data=json.loads(report.read_text(encoding='utf8'));reports.append({'file':report.name,'failed':data.get('failed'),'checks':len(data.get('checks',[]))})
  except (ValueError,TypeError):pass
 result={'exit_code':code,'duration_seconds':time.monotonic()-start,'errors':[s for s in text.splitlines() if 'ERROR:' in s],'warnings':[s for s in text.splitlines() if 'WARNING:' in s],'owner_before':before,'owner_after':after,'owner_unchanged':before==after,'reports':reports}
 (O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
 assert before==after,'Owner files changed; evidence retained, do not auto-restore'
assert code==0 and not result['errors'] and reports and all(r['failed']==0 for r in reports),str(O)
