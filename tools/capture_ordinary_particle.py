"""Ordinary root/render startup with copied data; attach only after a real error."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,time
G=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--exe',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--seconds',type=int,default=150);p.add_argument('--full-dump',action='store_true',help='Private process memory; never publish dumps');p.add_argument('--mute',action='store_true',help='Mute only copied diagnostic settings; not an audio acceptance run');p.add_argument('--background',action='store_true',help='Muted input-isolated root Window; not foreground-equivalent');a=p.parse_args()
E=a.exe.resolve();O=a.output.resolve();assert E.is_file() and not O.exists() and O.is_relative_to(G.parent/'Checkpoints') and 30<=a.seconds<=600
running=subprocess.check_output(['tasklist','/fi','IMAGENAME eq UNLISTED.exe','/fo','csv','/nh'],text=True);assert '"UNLISTED.exe"' not in running,'No GPU-test overlap permitted'
O.mkdir(parents=True);owner=Path(os.environ['APPDATA'])/'UNLISTED';files=[owner/n for n in ['settings.cfg','checkpoint.json']]
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();hashes=lambda:{str(f):sha(f) for f in files if f.is_file()};before=hashes()
assert files[0].is_file(),'A copied settings file is required for this matched control'
for f in files:
 if f.is_file():shutil.copy2(f,O/f.name)
if a.background:assert a.mute,'Background sessions must explicitly mute copied settings'
if a.mute:
 cfg=O/'settings.cfg';text=cfg.read_text(encoding='utf8');text=re.sub(r'(?m)^(master|volume)\s*=.*$',lambda m:m[1]+'=0.0',text);cfg.write_text(text,encoding='utf8')
args=[str(E),'--log-file',str(O/'game.log'),'--','--native-error-capture='+str(O)]
if a.background:
 cfg=O/'settings.cfg';text=cfg.read_text(encoding='utf8');text=re.sub(r'(?m)^display_mode\s*=.*$','display_mode=0',text);cfg.write_text(text,encoding='utf8')
 args+=['--native-capture-background','--native-capture-seconds='+str(a.seconds)]
(O/'launch.json').write_text(json.dumps({'args':args,'exe_sha256':sha(E),'owner_before':before,'muted_copied_settings':a.mute,'background_root_not_foreground_equivalent':a.background,'scope':'Normal main scene/root Window/render path and copied owner preferences/save. No QA viewport, startup debugger, rendering override or input injection. Explicit logger and resource observer; a matching real error deliberately holds its caller for late attach.'},indent=2),encoding='utf8')
start=time.monotonic();attached=False;forced=False;observed=[];seen=set()
with (O/'stdout.log').open('w',encoding='utf8') as f:
 child=subprocess.Popen(args,cwd=E.parent,stdout=f,stderr=subprocess.STDOUT)
 print('ORDINARY_CAPTURE_PID',child.pid,flush=True)
 while child.poll() is None:
  elapsed=time.monotonic()-start
  signal=O/'native_hold.json'
  if not attached and signal.exists():
   try:hold=json.loads(signal.read_text(encoding='utf8'))
   except (ValueError,OSError):hold=None
   if hold:
    assert hold['pid']==child.pid,'Refusing to attach to any other process'
    attached=True;cdb=Path(r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe')
    command='r @$t0=poi(@$peb+0x10); .printf "ENGINE_BASE=%p\\n", @$t0; ~*kv; .dump '+('/ma' if a.full_dump else '/mi')+' /u '+(O/'particle_caller.dmp').as_posix()+'; qd'
    with (O/'late_attach.log').open('w',encoding='utf8') as log:
     try:r=subprocess.run([str(cdb),'-p',str(child.pid),'-y',str(O),'-c',command],stdout=log,stderr=subprocess.STDOUT,timeout=120 if a.full_dump else 40,creationflags=subprocess.CREATE_NO_WINDOW);attach={'debugger_exit':r.returncode,'hold':hold,'full_private_dump':a.full_dump}
     except (OSError,subprocess.TimeoutExpired) as error:attach={'error':str(error),'hold':hold}
    (O/'late_attach_result.json').write_text(json.dumps(attach,indent=2),encoding='utf8');print('LATE_ATTACH_COMPLETE',flush=True)
  for name in ['stdout.log','game.log']:
   log=O/name
   if log.exists():
    for line in log.read_text(encoding='utf8',errors='replace').splitlines():
     if ('ERROR:' in line or 'WARNING:' in line) and (name,line) not in seen:seen.add((name,line));observed.append({'seconds_first_observed':elapsed,'file':name,'line':line})
  (O/'status.json').write_text(json.dumps({'pid':child.pid,'seconds':elapsed,'attached_after_error':attached,'ready_for_observed_quit':elapsed>=a.seconds,'observed_messages':observed}),encoding='utf8')
  if elapsed>a.seconds+180:
   forced=True;child.terminate();break
  time.sleep(.25)
 code=child.wait(timeout=10)
result={'exit_code':code,'duration_seconds':time.monotonic()-start,'attached_after_real_error':attached,'forced_deadline':forced,'owner_before':before,'owner_after':hashes(),'observed_messages':observed,'scope':'A hold/attach is an intentional diagnostic intervention AFTER an error, not a spontaneous freeze, crash or fix. Foreground/menu/Quit evidence is recorded separately.'};result['owner_unchanged']=before==result['owner_after']
(O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True);assert result['owner_unchanged']
