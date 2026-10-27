from pathlib import Path
import subprocess,sys,time,json
c=Path(r'C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261027_graphics_phase3');exe=c/'Candidate05/UNLISTED.exe';e=c/'Evidence'
first=e/'final_balanced1920/result.json';deadline=time.monotonic()+220
while not first.exists() and time.monotonic()<deadline:time.sleep(.5)
r=json.loads(first.read_text());assert r['exit_code']==0 and not r['script_errors']
report=json.loads((first.parent/'graphics_report.json').read_text());assert all(x['passed'] for x in report['checks'])
manifest=[]
def run(name,profile,size,extra):
 args=[sys.executable,'tools/run_graphics_study.py','--exe',str(exe),'--output',str(e/name),'--profile',profile,'--size',size,'--phase2','--phase3','--foreground',*extra]
 r=subprocess.run(args);manifest.append({'case':name,'wrapper_exit':r.returncode});(c/'matrix_progress.json').write_text(json.dumps(manifest,indent=2),encoding='utf8');assert r.returncode==0,name
for size in ['1920x1080','2560x1440','3440x1440']:
 for profile in ['original','balanced','enhanced']:
  name='final_'+profile+size.split('x')[0]
  if name=='final_balanced1920':continue
  run(name,profile,size,['--walk'])
# Paired before/after samples use the SAME exported binary and cameras.
for size in ['1920x1080','2560x1440','3440x1440']:
 for profile,extra in [('before_balanced',['--property-baseline']),('balanced',[]),('original',[]),('enhanced',[])]:
  run('perf_'+profile+size.split('x')[0],profile.replace('before_',''),size,['--performance','--uncapped',*extra])
run('record_approach','balanced','1920x1080',['--walk','--record'])
run('record_window','balanced','1920x1080',['--window-record'])
print('PHASE3_MATRIX_COMPLETE',flush=True)
