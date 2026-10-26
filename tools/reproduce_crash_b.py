"""One bounded preserved-fixture reproduction, not ordinary owner gameplay."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,time
G=Path(__file__).resolve().parents[1];R=G.parent
B=R/'Builds/UNLISTED_Player_Experience_01'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,default=R/'Checkpoints/20261026_full_forensic_audit/crash_b_reproduction_02')
O=parser.parse_args().output.resolve()
assert O.is_relative_to(R.resolve())
assert not O.exists();O.mkdir()
E=B/'UNLISTED.exe';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(E)=='8052d3f6365034f7f4338dea3839b0b5210be69fb626f1ca1fde1f1c38d9e0cf'
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{p.name:sha(p) for p in owner if p.exists()}
before=hashes()
for p in owner:
    if p.exists():shutil.copy2(p,O/('owner_before_'+p.name))
game_args=json.loads((B/'before_launch.json').read_text())['args'][1:]
game_args=[('--evidence='+str(O/'QA')) if a.startswith('--evidence=') else a for a in game_args]
cmd='sxe -c ".echo FORENSIC_FIRST_AV; .ecxr; .fnent @rip; u @rip L4; kv; .dump /mA /u '+(O/'first_av.dmp').as_posix()+'; gn" -c2 ".echo FORENSIC_UNHANDLED_AV; .ecxr; kv; q" av\n.echo FORENSIC_ARMED\nsx\ng\n'
(O/'commands.txt').write_text(cmd)
args=[r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe','-G','-y',str(O),'-cf',str(O/'commands.txt'),str(E),*game_args]
(O/'launch.json').write_text(json.dumps({'args':args,'original_executable_sha256':sha(E),'scope':'Preserved failed QA fixture, same flags except a fresh evidence directory. Under CDB. NOT ordinary title playtest.'},indent=2))
start=time.monotonic()
with (O/'debugger.log').open('w',encoding='utf8') as f:
    p=subprocess.run(args,cwd=G,stdout=f,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
t=(O/'debugger.log').read_text(errors='replace');after=hashes()
result={'debugger_exit':p.returncode,'seconds':time.monotonic()-start,'first_av': '\nFORENSIC_FIRST_AV\n' in t,'owner_before':before,'owner_after':after,'owner_unchanged':before==after,'dump_files':[p.name for p in O.glob('*.dmp')]}
(O/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
assert before==after
