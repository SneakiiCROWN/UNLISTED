"""Concise Phase3 results from preserved native reports; no human-quality claims."""
from pathlib import Path
import json
G=Path(__file__).resolve().parents[1];C=Path(r'C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261027_graphics_phase3');E=C/'Evidence'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
visual=[]
for width in ['1920','2560','3440']:
 for profile in ['original','balanced','enhanced']:
  d=E/('final_'+profile+width);r=read(d/'result.json');p=read(d/'graphics_report.json')
  assert r['exit_code']==0 and not r['script_errors'] and not r['warnings'] and r['owner_unchanged'] and all(x['passed'] for x in p['checks'])
  visual.append(d)
route=read(E/'final_balanced1920/graphics_report.json');rows=[]
for d in sorted(E.glob('perf_*')):
 p=read(d/'graphics_report.json');r=read(d/'result.json');assert r['exit_code']==0 and not r['script_errors'] and not r['warnings'] and r['owner_unchanged']
 for m in p['measurements']:
  assert m['focused_frames'] and not m['excluded_unfocused']
  rows.append('| '+d.name+' / '+m['view']+' | '+f"{m['median_ms']:.2f} / {m['p95_ms']:.2f}"+' | '+str(int(m['median_draws']))+' | '+str(m['spikes_over_33ms'])+' |')
assert len(rows)==36
s='''# The Living Property - native verification

Runtime checkpoint: 515d733. Selected executable: Candidate05.
This is an opt-in property showcase; ordinary production, saves, releases and
Phase1/2 delivery remain preserved. No public playable release or production merge.

## Actual changes

Shallow contoured garden beds and a finer near-property terrain mesh now have
matching collision. Rolling distant ground replaces the old steep square rim and
extends beyond the forest. Coarse bush batches give way to connected twig/leaf
sprays, grass clusters and a middle woodland layer. Existing trees and matching
colliders follow the changed support height. Foundation aggregate follows the
plinths/drainage; two supported fence offcuts imply maintenance without a new quest.
Existing Phase2 rain/wetness/light profiles are reused. The static window room
return is disabled in Phase3 to avoid false images of changed room states.

## Native checks and scope

Nine final visual cases cover Original/Balanced/Enhanced at 1920x1080,
2560x1440 and 3440x1440, plus three matched previous-environment Balanced
sets. All selected runs exit normally without logged errors/warnings or owner
save/settings hash changes. Actual front-path movement is separate from the
fixed player-eye camera views and static actor glass fixtures.

The focused 1080p route passes 38 checks: gate interaction, front/west movement,
shed entry/exit and perimeter, rear door both ways, yard save/load, pause/resume,
death-screen checkpoint retry, car return, open basement/service cuts, real AI
sight, crouch/standing and the existing Surveyor's physical staged west-side walk.
This does not establish complete natural pursuit/hiding, an earned combat death,
either ending, or a full fresh investigation. Those systems were not rewritten.
Arrival/departure cinematic integration and story-mode full routes are deferred
until the environment is approved for production integration.

Before/Candidate01/Candidate02 failures remain preserved separately. Native
images exposed far-height strips extending beyond actual road/fence lengths;
these were corrected before selection. An initial crouch check failed because
its fixture restored a stance that normal input immediately released. The final
check uses actual crouch input and passes; no controller behavior was changed.

The E04 filename initially implied an office exterior window, but native review
shows that this is an existing solid wall. Its gallery caption is corrected; it
is a wall control, not exterior-view proof. No window is invented for the study.
The E08 rear camera is obstructed by an existing close fence and remains labelled;
it is not used to claim visible woodland quality. Windows, porch and shed views
provide the exterior controls. Coarse original rocks/pines, spare side clearing
and some dark wall surfaces still need artistic review. No rejected character
model, new story claim, light, voice, probe or engine patch was introduced.

## Performance

Below: median / p95 process-frame interval in milliseconds, median draws, and
intervals over 33.3 ms. Each is a five-second stationary focused sample, requested
uncapped with vsync off. Baseline and changed landscape use the same final binary,
settings and cameras; no image readback occurs during measurement. No GPU timing,
CPU/GPU utilization, sustained-play or minimum-spec claim. Engine memory/render
counters are retained in PERFORMANCE.json, not represented as total board VRAM.

| Case / view | Median / p95 ms | Draws | Spikes |
|---|---:|---:|---:|
'''+ '\n'.join(rows)+'''

All samples are preserved. Short-run variation, desktop scheduling and shader
warm-up can affect comparisons; cost judgments must consider the whole table.
Balanced remains the leading visual-review candidate; optional Enhanced is not
automatically preferred. Human artistic approval remains pending.

## Delivery and remaining limits

The private gallery includes native comparisons and short sampled-frame recordings
with real wall-clock timing. These recordings are not a render-FPS benchmark or
human playtest. Non-silent captured audio is not subjective listening approval.
The private packaging receipt records the independent extracted launch, complete
source/history archives, remote branch/tag checks and hashes after finalization.

Original intermittent main-menu crash remains UNRESOLVED. No graphics test proves
it fixed. Existing live ReflectionProbes remain excluded. No paid assets, renderer,
Windows or driver changes were made. The next integration priorities are owner
visual review, route-specific encounter/hiding checks, cinematic weather/contact
review and sustained performance observation before any normal-game activation.
'''
(G/'GRAPHICS_PHASE3_RESULTS.md').write_text(s,encoding='utf8');print('Selected visual cases',len(visual),'PNGs',sum(len(list(d.glob('*.png'))) for d in visual),'Performance samples',len(rows),flush=True)
