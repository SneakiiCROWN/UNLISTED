"""Serial native Windows acceptance; isolated QA never writes the player's saves."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, re, shutil

G = Path(__file__).resolve().parents[1]
B = G.parent / 'Builds/UNLISTED_Investigation_08'

def run(name, flag, *extra, engine_args=(), cwd=None, timeout_seconds=900):
    # Never let a typo silently start ordinary gameplay with the owner's save.
    known=set(re.findall(r'"(--[a-z0-9-]+)"',(G/'scripts/world.gd').read_text(encoding='utf8')))
    assert flag in known, 'Unknown QA flag: '+flag
    owner=[Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
    hashes=lambda:{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in owner if p.exists()}
    before=hashes();snapshot=B/'OwnerDataBefore'
    if not snapshot.exists():
        snapshot.mkdir(parents=True)
        for p in owner:
            if p.exists():shutil.copy2(p,snapshot/p.name)
        (snapshot/'hashes.json').write_text(json.dumps(before,indent=2),encoding='utf8')
    evidence = B / 'QA' / name
    args = [str(B/'UNLISTED.exe'), *engine_args, '--max-fps', '60', '--', flag,
            '--evidence='+str(evidence), *extra]
    try:
        with (B/(name+'.log')).open('w', encoding='utf8') as log:
            p = subprocess.run(args, cwd=Path(cwd) if cwd is not None else G, stdout=log, stderr=subprocess.STDOUT, timeout=timeout_seconds)
    finally:
        after=hashes()
        (B/(name+'_owner_integrity.json')).write_text(json.dumps({'before':before,'after':after,'unchanged':before==after},indent=2),encoding='utf8')
        if before!=after:
            changed=B/('OwnerDataChanged_'+name);changed.mkdir(exist_ok=True)
            for path in owner:
                if path.exists():shutil.copy2(path,changed/path.name)
            raise AssertionError('Owner data changed; preserved both versions, no automatic restore: '+name)
    text = (B/(name+'.log')).read_text(encoding='utf8', errors='replace')
    print(name, 'exit', p.returncode, 'errors', text.count('ERROR:'), flush=True)
    assert p.returncode == 0 and 'ERROR:' not in text and ' FAIL ' not in text, name
    assert 'QA_INPUT_ISOLATED' in text, 'Missing isolated-input confirmation: '+name

def main():
    files = [Path(os.environ['APPDATA'])/'UNLISTED'/n for n in ['checkpoint.json','settings.cfg']]
    hashes = lambda: {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.exists()}
    before = hashes()
    try:
        specs = [
            ('investigation','--investigation-qa','--capture-size=1920x1080'),
            ('accounted','--recording-repair-qa','--capture-size=1920x1080','--service-aisle'),
            ('on_record','--recording-repair-qa','--capture-size=1920x1080','--on-record-ending'),
            ('impossible','--impossible-qa'),
            ('threat','--threat-qa'),
            ('systems','--systems-qa'),
            ('story','--presentation-qa','--story-only'),
            ('recount_1440','--recount-qa','--capture-size=2560x1440'),
            ('recount_ultrawide','--recount-qa','--capture-size=3440x1440'),
        ]
        selected = sys.argv[1:]
        for name, flag, *extra in specs:
            if not selected or name in selected: run(name, flag, *extra)
    finally:
        after=hashes()
        (B/'player_data_integrity.json').write_text(json.dumps({'before':before,'after':after,'unchanged':before==after},indent=2),encoding='utf8')
        assert before == after, 'Live player data changed; never restore over user changes'

if __name__ == '__main__': main()
