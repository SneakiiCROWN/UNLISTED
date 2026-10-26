"""Expected negative native QA test; exit92 is rejection, never a game-health pass."""
from pathlib import Path
import hashlib,json,os,subprocess
G=Path(__file__).resolve().parents[1];B=G.parent/'Builds/UNLISTED_Forensic_Repair_02';O=B/'QA/missing_recorder'
assert not O.exists();O.mkdir(parents=True)
owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
hashes=lambda:{p.name:sha(p) for p in owner if p.exists()}
before=hashes()
args=[str(B/'UNLISTED.exe'),'--max-fps','60','--','--ambient-qa','--forensic-focus','--forensic-missing-recorder','--evidence='+str(O)]
(O/'launch.json').write_text(json.dumps({'args':args,'executable_sha256':sha(B/'UNLISTED.exe')},indent=2))
with (O/'native.log').open('w',encoding='utf8') as f:p=subprocess.run(args,cwd=G,stdout=f,stderr=subprocess.STDOUT,timeout=90)
after=hashes();text=(O/'native.log').read_text(errors='replace')
result={'actual_exit':p.returncode,'expected_exit':92,'controlled_rejection':p.returncode==92 and (O/'capture_setup_failure.json').exists(),'native_access_violation':p.returncode in [-1073741819,3221225477],'script_errors':'ERROR:' in text,'owner_before':before,'owner_after':after,'owner_unchanged':before==after,'scope':'Deliberately missing QA recorder rejected; not ordinary gameplay or proof that owner idle crash is fixed.'}
(O/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
assert result['controlled_rejection'] and not result['native_access_violation'] and not result['script_errors'] and before==after
