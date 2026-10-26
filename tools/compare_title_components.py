"""One GPU process at a time. Explicit diagnostic switches never affect ordinary launch."""
from pathlib import Path
import json,os,shutil
import validate_investigation as q
G=Path(__file__).resolve().parents[1];q.B=G.parent/'Builds/UNLISTED_Priority_Zero_Diagnostic_04'
cases=[('full',[]),('no_audio',['--title-no-audio']),('no_particles',['--title-no-particles']),('no_silhouette',['--title-no-silhouette']),('stationary',['--title-no-animation']),('ui_only_full_world',['--title-ui-only','--title-no-audio','--title-no-particles','--title-no-silhouette','--title-no-animation'])]
(q.B/'QA').mkdir(exist_ok=True)
shutil.copy2(Path(os.environ['APPDATA'])/'UNLISTED/settings.cfg',q.B/'QA/presentation_settings.cfg')
results=[]
for name,flags in cases:
    (q.B/'active_case.json').write_text(json.dumps({'case':name,'phase':'starting'}),encoding='utf8')
    q.run(name,'--stability-qa','--stability-case=root','--menu-idle-only','--idle-seconds=135','--foreground-profile','--title-trace',*flags,timeout_seconds=240)
    r=json.loads((q.B/'QA'/name/'probe_report.json').read_text())
    assert r['completed'] and all(c['passed'] for c in r['checks'])
    results.append({'case':name,'completed':True,'components':r['components'],'seconds':r['samples'][-1]['menu_clock']})
    (q.B/'component_results.json').write_text(json.dumps(results,indent=2),encoding='utf8')
(q.B/'active_case.json').write_text(json.dumps({'phase':'all_completed'}),encoding='utf8')
