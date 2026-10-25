"""Focused room/presentation verification; never restarts the historical full route."""
from pathlib import Path
import sys
import validate_investigation as qa

G=Path(__file__).resolve().parents[1]
qa.B=G.parent/'Builds'/sys.argv[1]
selected=sys.argv[2:]
earned=G.parent/'Builds/UNLISTED_Production_Continuation_08/QA/fresh_integrated/earned_register_checkpoint.json'
specs=[
 ('rooms1080','--production-views',['--capture-size=1920x1080']),
 ('rooms1440','--production-views',['--capture-size=2560x1440']),
 ('roomswide','--production-views',['--capture-size=3440x1440']),
 ('vent_normal','--vent-qa',['--vent-case=normal','--capture-size=1920x1080']),
 ('endingA','--final-account-qa',['--final-layouts','--capture-size=2560x1440','--final-earned-source='+str(earned)]),
 ('endingB_story','--final-account-qa',['--final-layouts','--final-on-record','--final-story','--capture-size=3440x1440','--final-earned-source='+str(earned)]),
 ('room_interactions','--ambient-qa',['--capture-size=1920x1080']),
 ('foreground_performance','--production-views',['--foreground-profile','--capture-size=1920x1080']),
]
for name,flag,args in specs:
    if name in selected or not selected:qa.run(name,flag,*args,timeout_seconds=240)
