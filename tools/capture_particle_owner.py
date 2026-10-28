"""Bounded, input-isolated native owner-lookup capture; never patches game files."""
from pathlib import Path
import argparse, hashlib, json, os, re, subprocess, time

G=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--exe',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
p.add_argument('--mode',choices=['menu','house-remembers','impossible','nightmare','lifecycle'],default='house-remembers')
p.add_argument('--timeout',type=int,default=180);a=p.parse_args()
E=a.exe.resolve();O=a.output.resolve();root=G.parent.resolve()
assert E.is_file() and O.is_relative_to(root/'Checkpoints') and not O.exists()
assert 30<=a.timeout<=600
# Refuse to overlap an owner game or another GPU comparison. This never kills it.
running=subprocess.check_output(['tasklist','/fi','IMAGENAME eq UNLISTED.exe','/fo','csv','/nh'],text=True)
assert '"UNLISTED.exe"' not in running,'An UNLISTED process is already running; no overlap permitted'
CDB=Path(r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe');assert CDB.is_file()
O.mkdir(parents=True);(O/'Symbols').mkdir()
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{str(f):sha(f) for f in owner if f.is_file()}
before=hashes()
# Pinned ed1daf0bf release-template getter, identified via function-name RIP
# references and PE unwind bounds, then checked against actual loaded bytes.
# Resolve ImageBase from x64 PEB: the live image's debugger module name can be
# its internal template name rather than the renamed UNLISTED.exe filename.
prefix=O.as_posix()
commands='''r @$t0=poi(@$peb+0x10)
.printf "ENGINE_BASE=%p\\n", @$t0
.if (dwo(@$t0+0x2832a2c)==0x282444c7) { bp /1 @$t0+0x2832a2c ".echo REJECTED_PARTICLE_OWNER; r; kv; ub poi(@rsp+0x48) L18; dq @rsp L20; .dump /mi /u PREFIX/rejected_owner.dmp; gc"; .echo VERIFIED_ERROR_BRANCH_ARMED } .else { .echo WRONG_NATIVE_BYTES; qd }
bl
sxe -c "gn" -c2 ".echo UNHANDLED_NATIVE_AV; .ecxr; .exr -1; kv; .dump /mi /u PREFIX/unhandled_av.dmp; q" av
g
'''.replace('PREFIX',prefix)
(O/'commands.txt').write_text(commands,encoding='ascii')
args=[str(CDB),'-G','-y',str(O/'Symbols'),'-cf',str(O/'commands.txt'),str(E)]
if a.mode=='menu':args+=['--log-file',str(O/'ordinary_game.log')]
else:
    mode='nightmare' if a.mode=='lifecycle' else a.mode
    args+=['--max-fps','60','--','--'+mode+'-qa','--prebuilt-viewport','--capture-size=1920x1080','--evidence='+str(O/'Native'),'--route-light-capture','--resource-trace']
    if a.mode=='lifecycle':
        earned=root/'Checkpoints/20261027_phase5_integration/Evidence02/fresh_balanced1080/checkpoint.json'
        assert earned.is_file();args+=['--particle-lifecycle','--earned-source='+str(earned)]
(O/'launch.json').write_text(json.dumps({'args':args,'exe_sha256':sha(E),'owner_before':before,
 'scope':'Ordinary root menu with owner settings under a byte-verified native debugger, no QA flags; quit through the actual menu.' if a.mode=='menu' else 'Read-only evidence plus a byte-verified software breakpoint in this exact private QA child. No disk/native engine patch, desktop input hook, driver/OS change or ordinary-foreground stability claim.'},indent=2),encoding='utf8')
start=time.monotonic();timed_out=False
with (O/'debugger.log').open('w',encoding='utf8') as log:
    child=subprocess.Popen(args,cwd=E.parent,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    try:code=child.wait(timeout=a.timeout)
    except subprocess.TimeoutExpired:
        timed_out=True
        subprocess.run(['taskkill','/PID',str(child.pid),'/T','/F'],capture_output=True)
        code=child.wait(timeout=10)
        (O/'TIMEOUT.txt').write_text('Forced this exact owned debugger tree after the diagnostic deadline. This is not an ordinary game crash.',encoding='utf8')
log=(O/'debugger.log').read_text(encoding='utf8',errors='replace')
exact=lambda marker:bool(re.search(r'^'+re.escape(marker)+r'\s*$',log,re.M))
reports=[]
for f in (O/'Native').glob('*report.json'):
    d=json.loads(f.read_text(encoding='utf8'));reports.append({'file':f.name,'failed':d.get('failed'),'checks':len(d.get('checks',[]))})
result={'debugger_exit':code,'seconds':time.monotonic()-start,'breakpoint_armed':exact('VERIFIED_ERROR_BRANCH_ARMED'),
        'rejected_owner_captured':exact('REJECTED_PARTICLE_OWNER'),'unhandled_native_av':exact('UNHANDLED_NATIVE_AV'),
        'forced_timeout':timed_out,'engine_errors':[s for s in log.splitlines() if s.startswith('ERROR:')],
        'reports':reports,'owner_before':before,'owner_after':hashes(),'dumps':[f.name for f in O.glob('*.dmp')]}
result['owner_unchanged']=result['owner_before']==result['owner_after']
(O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
assert result['owner_unchanged'],'Owner changed; retain evidence, do not auto-restore'
assert result['breakpoint_armed'] and not timed_out,'Invalid or incomplete capture setup'

