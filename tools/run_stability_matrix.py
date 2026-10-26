"""Bounded serial comparison. Child-only loader settings; no driver/system edits."""
from pathlib import Path
import json,sys
import validate_investigation as q
G=Path(__file__).resolve().parents[1]
q.B=G.parent/'Builds/UNLISTED_Stability_Terror_02'
cases=[('fixed_1440','fixed','2560x1440',False),('fixed_wide','fixed','3440x1440',False),('prestart','prestart','1920x1080',False),('live','live','1920x1080',False),('normal_root','root','1280x720',False),('live_filtered','live','1920x1080',True)]
results=[]
for name,kind,size,filtered in cases:
    env={'VK_LOADER_DEBUG':'warn,layer'}
    if filtered:env['VK_LOADER_LAYERS_DISABLE']='VK_LAYER_RTSS,VK_LAYER_OBS_HOOK,VK_LAYER_MEDAL_HOOK'
    try:
        q.run(name,'--stability-qa','--foreground-profile','--stability-case='+kind,'--capture-size='+size,env_overrides=env,timeout_seconds=100)
        report=json.loads((q.B/'QA'/name/'probe_report.json').read_text())
        assert report['completed'] and all(c['passed'] for c in report['checks'])
        results.append({'case':name,'passed':True,'backend':report['backend'],'method':report['method'],'child_layer_filter':env.get('VK_LOADER_LAYERS_DISABLE')})
    except Exception as error:
        results.append({'case':name,'passed':False,'error':str(error)})
        (q.B/'matrix_results.json').write_text(json.dumps(results,indent=2),encoding='utf8')
        raise
    (q.B/'matrix_results.json').write_text(json.dumps(results,indent=2),encoding='utf8')
print(json.dumps(results,indent=2),flush=True)
