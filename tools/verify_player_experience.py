"""Bounded changed-system acceptance, one native GPU process at a time."""
from pathlib import Path
import json,sys
import validate_investigation as suite
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Player_Experience_05';suite.B=B
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
assert read(B/'QA/experience/repair_report.json')['failed']==0
earned=G.parent/'Builds/UNLISTED_Production_Continuation_08/QA/fresh_integrated/earned_register_checkpoint.json'
assert earned.exists()
specs=[
 ('threat','--threat-qa',[]),
 ('recorder_recovery','--house-answers-qa',['--capture-size=1920x1080']),
 ('arrival','--night-arrival-qa',['--arrival-layouts','--capture-size=1920x1080']),
 ('after1440','--ambient-qa',['--experience-focus','--experience-before','--capture-size=2560x1440']),
 ('afterwide','--ambient-qa',['--experience-focus','--experience-before','--capture-size=3440x1440']),
 ('ending_b','--final-account-qa',['--final-layouts','--final-on-record','--final-story','--final-earned-source='+str(earned),'--capture-size=2560x1440'])]
for name,flag,extra in specs:
    suite.run(name,flag,*extra)
print('Changed-system acceptance finished; no fresh 412-route or crash stress loop.',flush=True)
