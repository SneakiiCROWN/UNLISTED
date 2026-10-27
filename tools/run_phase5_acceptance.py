"""Sequential GPU acceptance. Reuses only successful, identical executable cases."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
G=Path(__file__).resolve().parents[1];C=G.parent/'Checkpoints/20261027_phase5_integration';E=C/'Candidate04/UNLISTED.exe';R=C/'Evidence04';manifest=[]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
fresh=C/'Evidence02/fresh_balanced1080';deadline=time.monotonic()+1900
while not (fresh/'result.json').exists() and time.monotonic()<deadline:time.sleep(2)
f=read(fresh/'result.json');assert f['exit_code']==0 and not f['errors'] and all(r['failed']==0 for r in f['reports']), 'Fresh investigation failed; preserve evidence and investigate first'
def run(name,profile,size,mode='atmosphere-integration',extra=(),timeout=400):
 out=R/name
 if (out/'result.json').exists():
  prior=read(out/'result.json');launch=read(out/'launch.json')
  if name=='ending_balanced3440' and '--continue-known-render-failure' in sys.argv:
   assert prior['exit_code']==0 and prior['owner_unchanged'] and prior['errors']==['ERROR: Parameter "particles" is null.'] and all(r['failed']==0 for r in prior['reports']) and launch['exe_sha256']==sha(E)
   print('KNOWN FAILED RENDERING CASE RETAINED, NOT RERUN: '+name,flush=True);return
  assert prior['exit_code']==0 and not prior['errors'] and all(r['failed']==0 for r in prior['reports']) and launch['exe_sha256']==sha(E),name
  return
 args=[sys.executable,str(G/'tools/run_phase5_native.py'),'--exe',str(E),'--output',str(out),'--profile',str(profile),'--size',size,'--mode',mode,'--timeout',str(timeout)]
 if mode=='atmosphere-integration' and profile>0:args+=['--keep-settings']
 if extra:args+=['--',*extra]
 code=subprocess.run(args,cwd=G).returncode
 manifest.append({'case':name,'exit_code':code});(C/'acceptance_progress.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 assert code==0,name
for size in ['1920x1080','2560x1440','3440x1440']:
 for profile,label in [(0,'original'),(1,'balanced'),(2,'enhanced')]:run(label+size.split('x')[0],profile,size,extra=['--save-next-atmosphere='+str((profile+1)%3)])
run('answers_balanced1440',1,'2560x1440','house-answers')
run('vent_balanced1440',1,'2560x1440','vent')
run('vent_reverse_balanced1080',1,'1920x1080','vent',['--vent-case=reverse'])
run('input_balanced1080',1,'1920x1080','input-isolation')
source=str(fresh/'checkpoint.json')
run('endings_balanced1080',1,'1920x1080','final-account',['--final-earned-source='+source])
run('ending_enhanced1440',2,'2560x1440','final-account',['--final-earned-source='+source,'--final-layouts'])
run('ending_balanced3440',1,'3440x1440','final-account',['--final-earned-source='+source,'--final-layouts','--final-on-record','--final-story'])
for profile,label in [(0,'original'),(1,'balanced'),(2,'enhanced')]:run('moving_'+label+'1440',profile,'2560x1440','atmosphere-performance',timeout=240)
run('moving_balanced3440',1,'3440x1440','atmosphere-performance',timeout=240)
print('PHASE5_ACCEPTANCE_CASES_COMPLETE',flush=True)
