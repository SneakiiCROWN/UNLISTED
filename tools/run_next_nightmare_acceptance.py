"""Sequential changed-system native checks; no replay of the unchanged full route."""
from pathlib import Path
import json,subprocess,sys
G=Path(__file__).resolve().parents[1];C=G.parent/'Checkpoints/20261027_next_nightmare';E=C/'Candidate03/UNLISTED.exe';R=C/'Evidence03'
source=str(G.parent/'Checkpoints/20261027_phase5_integration/Evidence02/fresh_balanced1080/checkpoint.json')
cases=[('features1440','nightmare',1,'2560x1440',[]),('features3440','nightmare',2,'3440x1440',[]),('input_report1080','input-isolation',1,'1920x1080',[]),('surveyor_regression','threat',1,'1920x1080',[]),('physical_regression','sound-touch',1,'1920x1080',[]),('ambient_regression','ambient',1,'2560x1440',[]),('endings1080','final-account',1,'1920x1080',['--final-earned-source='+source]),('lifecycle_original','nightmare',0,'1920x1080',['--particle-lifecycle','--earned-source='+source]),('menu_idle_original','nightmare',0,'1920x1080',['--menu-idle'])]
progress=[]
for name,mode,profile,size,extra in cases:
 out=R/name
 if (out/'result.json').exists():
  r=json.loads((out/'result.json').read_text());assert r['exit_code']==0 and not r['errors'] and r['owner_unchanged'] and r['reports'] and all(x['failed']==0 for x in r['reports']);continue
 args=[sys.executable,str(G/'tools/run_phase5_native.py'),'--exe',str(E),'--output',str(out),'--mode',mode,'--profile',str(profile),'--size',size,'--timeout','300']
 if extra:args+=['--',*extra]
 code=subprocess.run(args,cwd=G).returncode;progress.append({'case':name,'wrapper_exit':code});(C/'acceptance_progress.json').write_text(json.dumps(progress,indent=2),encoding='utf8')
 if code:print('STOPPED; failure retained: '+name,flush=True);sys.exit(code)
print('NEXT_NIGHTMARE_CHANGED_SYSTEM_CHECKS_FINISHED',flush=True)
