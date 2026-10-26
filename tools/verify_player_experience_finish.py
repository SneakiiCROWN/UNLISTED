"""Final UI-only cleanup acceptance; unchanged mechanics use the hashed 05 tests."""
from pathlib import Path
import validate_investigation as suite
G=Path(__file__).resolve().parents[1];suite.B=G.parent/'Builds/UNLISTED_Player_Experience_06'
for name,extra in [('experience',[]),('after1440',['--experience-before','--capture-size=2560x1440']),('afterwide',['--experience-before','--capture-size=3440x1440'])]:
    suite.run(name,'--ambient-qa','--experience-focus',*(extra or ['--capture-size=1920x1080']))
