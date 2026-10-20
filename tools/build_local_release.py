"""Build from a complete licensed local project without changing that checkout.
Public source intentionally omits media whose licences restrict loose redistribution.
"""
from pathlib import Path
import argparse,subprocess,hashlib,json,shutil,zipfile
p=argparse.ArgumentParser();p.add_argument('--project',required=True);p.add_argument('--engine',required=True);p.add_argument('--output',required=True);a=p.parse_args()
source=Path(a.project).resolve();output=Path(a.output).resolve();staging=output.parent/(output.stem+'-source-staging')
assert (source/'assets/fonts/AnalogMono_v1_1.ttf').is_file(),'A complete licensed development checkout is required'
assert not output.exists() and not staging.exists(),'Use new output and staging paths; existing deliveries are preserved'
assert source!=staging and source not in staging.parents,'Staging must be outside the active checkout'
files=subprocess.check_output(['git','ls-files','-z'],cwd=source).decode().split('\0');manifest={}
staging.mkdir(parents=True)
for name in files:
 if not name:continue
 path=source/name
 if not path.is_file():continue
 data=path.read_bytes();manifest[name]=hashlib.sha256(data).hexdigest();target=staging/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
assert all(hashlib.sha256((source/n).read_bytes()).hexdigest()==h for n,h in manifest.items()),'Active project changed during snapshot; use a sealed checkpoint'
output.parent.mkdir(parents=True,exist_ok=True);runtime=output.parent/(output.stem+'-runtime');runtime.mkdir()
def run(label,args):
 log=runtime/(label+'.log')
 with log.open('wb') as f:r=subprocess.run([str(x) for x in args],cwd=staging,stdout=f,stderr=subprocess.STDOUT,timeout=600)
 text=log.read_text(errors='replace');assert r.returncode==0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text,(label,r.returncode,str(log))
run('import',[a.engine,'--headless','--path',staging,'--editor','--import','--quit'])
exe=runtime/'UNLISTED.exe';run('export',[a.engine,'--headless','--path',staging,'--export-release','Windows Desktop',exe])
for label,flags in [('systems',['--systems-qa']),('hands',['--hands-qa']),('room',['--impossible-qa']),('story',['--presentation-qa','--story-only']),('polish',['--polish-qa']),('service',['--service-room-qa','--evidence='+str(runtime/'QA/service')])]:run(label,[exe,'--max-fps','60','--',*flags])
# Checks use dedicated fixture files; no normal saves are written by these QA modes.
receipt={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip(),'source_files':manifest,'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'checks':['systems','hands','impossible-room','story','polish','service'],'human_playtest':False}
(runtime/'PRIVATE_BUILD_RECEIPT.json').write_text(json.dumps(receipt,indent=2))
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,6) as z:
 z.write(exe,'UNLISTED.exe')
 for name in ['THIRD_PARTY.md','LICENSE.txt','README.md']:
  path=Path(__file__).resolve().parents[1]/name
  if not path.exists():path=source/name
  if path.exists():z.write(path,name)
 for rel in ['assets/fonts/LICENSE.txt','assets/audio/ambient_license.txt','assets/audio/foley/WASD_License.txt','assets/audio/foley/WASD_License.pdf','assets/audio/foley/SONNISS_GDC_License.pdf']:
  path=source/rel
  if path.exists():z.write(path,'ThirdPartyNotices/'+rel.replace('/','_'))
 for path in (Path(__file__).resolve().parents[1]/'ThirdPartyNotices').glob('*.txt'):z.write(path,'ThirdPartyNotices/'+path.name)
print(hashlib.sha256(output.read_bytes()).hexdigest(),output)
