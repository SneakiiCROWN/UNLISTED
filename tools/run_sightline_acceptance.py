"""Sequential native GPU checks; failed observations stay on disk, never retried."""
from pathlib import Path
import json, subprocess, sys, time

G = Path(__file__).resolve().parents[1]
C = G.parent / 'Checkpoints/20261028_sightline_continuation'
deadline = time.monotonic() + 220
while not (C/'Evidence01/root150/result.json').exists():
    assert time.monotonic() < deadline, 'Root comparison did not finish; do not overlap GPU runs'
    time.sleep(1)

cases = [
    ('legacy60', 'house-remembers', 'Candidate01', 0, '1920x1080', False, 110,
     ['--fps', '0'], ['--idle-no-recorder', '--idle-seconds=60', '--route-no-images']),
    ('prebuilt60', 'house-remembers', 'Candidate01', 0, '1920x1080', True, 110,
     ['--fps', '0'], ['--idle-no-recorder', '--idle-seconds=60', '--route-no-images']),
    ('sight1080', 'sightline', 'Candidate02', 1, '1920x1080', True, 110, [], []),
    ('sight1440', 'sightline', 'Candidate02', 0, '2560x1440', True, 110, [], []),
    ('sight3440', 'sightline', 'Candidate02', 2, '3440x1440', True, 110, [], []),
    ('threat', 'threat', 'Candidate02', 1, '1920x1080', True, 200, [], []),
    ('house_remembers', 'house-remembers', 'Candidate02', 1, '1920x1080', True, 130, [], []),
    ('ambient', 'ambient', 'Candidate02', 1, '1920x1080', True, 180, [], []),
    ('dread', 'ambient', 'Candidate02', 1, '1920x1080', True, 180, [], ['--dread-focus']),
    ('impossible', 'impossible', 'Candidate02', 1, '1920x1080', True, 180, [], []),
    ('endings', 'final-account', 'Candidate02', 1, '1920x1080', True, 210, [],
     ['--final-earned-source='+str(G.parent/'Checkpoints/20261027_phase5_integration/Evidence02/fresh_balanced1080/checkpoint.json')]),
]
results = []
for name, mode, candidate, profile, size, prebuilt, timeout, options, extra in cases:
    command = [sys.executable, str(G/'tools/run_phase5_native.py'), '--exe', str(C/candidate/'UNLISTED.exe'),
               '--output', str(C/'Evidence02'/name), '--mode', mode, '--profile', str(profile), '--size', size,
               '--timeout', str(timeout), *options]
    if prebuilt: command += ['--prebuilt-viewport']
    if extra: command += ['--', *extra]
    print('START', name, flush=True)
    run = subprocess.run(command, cwd=G)
    results.append({'case': name, 'runner_exit': run.returncode})
    (C/'acceptance_progress.json').write_text(json.dumps(results, indent=2), encoding='utf8')
    # Preserve renderer errors as observations; script/assertion failures stop
    # that case in the runner. Independent following cases can still diagnose.
    print('DONE', name, run.returncode, flush=True)
