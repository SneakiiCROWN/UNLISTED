"""Explicit alternative entry; serial native process, private data, no desktop inputs."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,time
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Priority_Zero_Diagnostic_05'
O=B/'QA/deferred'
assert not O.exists()
O.mkdir(parents=True)
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
hashes=lambda:{p.name:sha(p) for p in owner if p.exists()}
before=hashes()
for p in owner:
    if p.exists():shutil.copy2(p,O/('owner_before_'+p.name))
shutil.copy2(Path(os.environ['APPDATA'])/'UNLISTED/settings.cfg',B/'QA/presentation_settings.cfg')
args=[str(B/'UNLISTED.exe'),'--','--visual-probe','--deferred-title-diagnostic','--case-output='+str(O)]
(O/'launch.json').write_text(json.dumps({'args':args,'executable_sha256':sha(B/'UNLISTED.exe'),'scope':'Native alternate-entry diagnostic, initial 2D-only title then original main scene/arrival. Own save path. Not ordinary launch or crash fix.'},indent=2))
start=time.monotonic()
with (O/'native.log').open('w',encoding='utf8') as log:
    p=subprocess.Popen(args,cwd=B,stdout=log,stderr=subprocess.STDOUT)
    while p.poll() is None and time.monotonic()-start<240:
        (O/'status.json').write_text(json.dumps({'pid':p.pid,'seconds':time.monotonic()-start,'alive':True}))
        time.sleep(2)
    if p.poll() is None:
        # This exact child only; timeout is failure, never a passed idle test.
        p.terminate();p.wait(15)
        timed_out=True
    else:timed_out=False
after=hashes()
text=(O/'native.log').read_text(errors='replace')
report=json.loads((O/'deferred_report.json').read_text()) if (O/'deferred_report.json').exists() else {}
events=[r['event'] for r in report.get('events',[])]
expected=['minimal title ready','original arrival restores control=true','pause/resume control=true','private save/load control=true','return to original title section=title','completed']
result={'exit_code':p.returncode,'timed_out':timed_out,'seconds':time.monotonic()-start,'owner_before':before,'owner_after':after,'owner_unchanged':before==after,'events':events,'all_expected_events':all(e in events for e in expected),'script_errors':'ERROR:' in text}
(O/'result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2),flush=True)
assert p.returncode==0 and not timed_out and before==after and result['all_expected_events'] and not result['script_errors']
