"""Serial exported-game checks with isolated inputs and live-save integrity."""
from pathlib import Path
import hashlib,json,os,sys,subprocess
import validate_investigation as suite
G=Path(__file__).resolve().parents[1]
suite.B=G.parent/'Builds'/sys.argv[1]
selected=sys.argv[2:]
if 'export' in selected:
    subprocess.run([sys.executable,str(G/'tools/validate_dead_line.py'),sys.argv[1],'export'],cwd=G,check=True)
files=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
hashes=lambda:{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.exists()}
before=hashes()
try:
    for name,flag,extra in [('exit','--exit-qa',['--capture-size=1920x1080','--exit-risk-qa']),('exit1080','--exit-qa',['--capture-size=1920x1080','--exit-layouts-only']),('exit1440','--exit-qa',['--capture-size=2560x1440','--exit-layouts-only']),('exituw','--exit-qa',['--capture-size=3440x1440','--exit-layouts-only'])]:
        if name in selected:suite.run(name,flag,*extra)
    if 'continuous' in selected:suite.run('continuous','--recording-repair-qa','--both-earned-endings','--underfloor-route','--witness-route','--exit-route','--dead-line-route','--service-aisle','--capture-size=1920x1080')
finally:
    after=hashes();receipt=suite.B/('player_data_integrity_exit_'+str(len(list(suite.B.glob('player_data_integrity_exit*'))))+'.json')
    receipt.write_text(json.dumps(dict(before=before,after=after,unchanged=before==after),indent=2));assert before==after
