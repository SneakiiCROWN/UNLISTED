"""Observe an ordinary extracted executable. No QA flag, renderer override or input hook."""
from pathlib import Path
import datetime,hashlib,json,os,shutil,subprocess,sys,time
exe=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();duration=int(sys.argv[3])
assert exe.is_file() and not out.exists()
out.mkdir(parents=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{p.name:sha(p) for p in owner if p.exists()}
before=hashes();snap=out/'OwnerDataBefore';snap.mkdir()
for p in owner:
    if p.exists():shutil.copy2(p,snap/p.name)
args=[str(exe),'--log-file',str(out/'godot.log')]
start=time.monotonic()
with (out/'stdout.log').open('w',encoding='utf8') as log:
    child=subprocess.Popen(args,cwd=exe.parent,stdout=log,stderr=subprocess.STDOUT)
    stats=None
    if '--resource-stats' in sys.argv[4:]:
        from windows_process_stats import WindowsProcessStats
        stats=WindowsProcessStats(child.pid)
    record={'scope':'Ordinary extracted Windows executable, normal owner settings, no QA or subsystem overrides. Foreground verified separately using window screenshot. User interaction/focus is not globally monitored.','pid':child.pid,'executable':str(exe),'executable_sha256':sha(exe),'args':args,'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'target_idle_seconds':duration,'initial_owner_hashes':before}
    (out/'launch.json').write_text(json.dumps(record,indent=2),encoding='utf8')
    print('NORMAL_MENU_PID',child.pid,flush=True)
    with (out/'heartbeats.jsonl').open('w',encoding='utf8') as heart:
        while child.poll() is None:
            elapsed=time.monotonic()-start
            row={'seconds':elapsed,'alive':True,'ready_for_observed_menu_quit':elapsed>=duration}
            if stats:row['process_counters']=stats.read()
            heart.write(json.dumps(row)+'\n');heart.flush()
            (out/'status.json').write_text(json.dumps(row),encoding='utf8')
            time.sleep(5)
    if stats:stats.close()
    result={'exit_code':child.returncode,'duration_seconds':time.monotonic()-start,'target_duration_reached':time.monotonic()-start>=duration,'owner_before':before,'owner_after':hashes(),'owner_unchanged':before==hashes(),'quit_action':'Record separately; exit0 alone is not proof of intended menu quit'}
    (out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8')
    print(json.dumps(result),flush=True)
