"""Ordinary released executable under first-chance native observation; no registry changes."""
from pathlib import Path
import datetime,hashlib,json,os,shutil,subprocess,time,re
G=Path(__file__).resolve().parents[1]
E=G.parent/'Checkpoints/20261026_player_experience_candidate/IndependentExtract/UNLISTED.exe'
O=G.parent/'Builds/UNLISTED_Priority_Zero_Evidence/first_chance_0109_02'
CDB=Path(r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe')
assert E.exists() and CDB.exists() and not O.exists();O.mkdir(parents=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{p.name:sha(p) for p in owner if p.exists()}
before=hashes();snap=O/'OwnerDataBefore';snap.mkdir()
for p in owner:
    if p.exists():shutil.copy2(p,snap/p.name)
# Capture at most two first-chance full dumps. gn preserves the application's
# own exception handling. A handled first-chance event alone is NOT a crash.
first='.if (@$t0 < 2) {r @$t0 = @$t0 + 1; .echo FIRST_CHANCE_AV; .ecxr; kv; .dump /ma /u '+(O/'first_av.dmp').as_posix()+'}; gn'
second='.echo SECOND_CHANCE_UNHANDLED_AV; .ecxr; kv; .dump /ma /u '+(O/'unhandled_av.dmp').as_posix()+'; q'
command='r @$t0=0\nsxe -c "'+first+'" -c2 "'+second+'" av\n.echo PRIORITY_ZERO_FILTERS_ARMED\nsx\ng\n'
(O/'debugger_commands.txt').write_text(command,encoding='utf8')
args=[str(CDB),'-G','-y',str(O),'-cf',str(O/'debugger_commands.txt'),str(E),'--log-file',str(O/'game.log')]
start=time.monotonic()
with (O/'debugger.log').open('w',encoding='utf8') as log:
    child=subprocess.Popen(args,cwd=E.parent,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    (O/'launch.json').write_text(json.dumps({'args':args,'debugger_pid':child.pid,'executable_sha256':sha(E),'start_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'owner_before':before,'scope':'Same ordinary extracted v0.10.9 executable under debugger. No QA, render change, disabled handler or environment override. Not an uninstrumented run.'},indent=2),encoding='utf8')
    print('CDB_OBSERVER_PID',child.pid,flush=True)
    while child.poll() is None:
        (O/'status.json').write_text(json.dumps({'seconds':time.monotonic()-start,'alive':True,'ready_for_observed_menu_quit':time.monotonic()-start>=600}),encoding='utf8');time.sleep(5)
text=(O/'debugger.log').read_text(errors='replace')
result={'debugger_exit_code':child.returncode,'duration_seconds':time.monotonic()-start,'filter_table_armed':'av - Access violation - break - not handled' in text,'first_chance_av_count':len(re.findall(r'^FIRST_CHANCE_AV\s*$',text,re.M)),'unhandled_av':bool(re.search(r'^SECOND_CHANCE_UNHANDLED_AV\s*$',text,re.M)),'full_dumps':[p.name for p in O.glob('*.dmp')],'owner_after':hashes(),'owner_unchanged':before==hashes()}
(O/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
