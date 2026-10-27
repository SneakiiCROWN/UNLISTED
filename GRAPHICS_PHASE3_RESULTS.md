# The Living Property - native verification

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
| perf_balanced1920 / V08_lane | 11.80 / 15.36 | 13535 | 0 |
| perf_balanced1920 / E02_porch_outward | 1.51 / 2.39 | 819 | 0 |
| perf_balanced1920 / E06_yard_shed | 1.76 / 2.58 | 1444 | 0 |
| perf_balanced2560 / V08_lane | 13.47 / 18.31 | 13535 | 1 |
| perf_balanced2560 / E02_porch_outward | 1.64 / 3.00 | 819 | 0 |
| perf_balanced2560 / E06_yard_shed | 2.03 / 3.88 | 1444 | 0 |
| perf_balanced3440 / V08_lane | 13.81 / 19.05 | 13567 | 0 |
| perf_balanced3440 / E02_porch_outward | 1.83 / 3.78 | 918 | 0 |
| perf_balanced3440 / E06_yard_shed | 2.02 / 3.83 | 1486 | 0 |
| perf_before_balanced1920 / V08_lane | 11.42 / 14.75 | 13532 | 0 |
| perf_before_balanced1920 / E02_porch_outward | 1.46 / 2.34 | 814 | 0 |
| perf_before_balanced1920 / E06_yard_shed | 1.68 / 2.45 | 1442 | 0 |
| perf_before_balanced2560 / V08_lane | 12.62 / 16.60 | 13532 | 0 |
| perf_before_balanced2560 / E02_porch_outward | 1.69 / 3.31 | 814 | 0 |
| perf_before_balanced2560 / E06_yard_shed | 1.95 / 3.69 | 1442 | 2 |
| perf_before_balanced3440 / V08_lane | 12.70 / 18.04 | 13565 | 0 |
| perf_before_balanced3440 / E02_porch_outward | 1.83 / 3.79 | 915 | 0 |
| perf_before_balanced3440 / E06_yard_shed | 1.90 / 3.52 | 1484 | 0 |
| perf_enhanced1920 / V08_lane | 12.35 / 15.90 | 13534 | 0 |
| perf_enhanced1920 / E02_porch_outward | 1.63 / 2.87 | 818 | 0 |
| perf_enhanced1920 / E06_yard_shed | 1.99 / 3.35 | 1443 | 0 |
| perf_enhanced2560 / V08_lane | 13.64 / 19.68 | 13534 | 0 |
| perf_enhanced2560 / E02_porch_outward | 1.94 / 3.88 | 818 | 0 |
| perf_enhanced2560 / E06_yard_shed | 2.15 / 4.16 | 1443 | 0 |
| perf_enhanced3440 / V08_lane | 13.62 / 18.83 | 13566 | 0 |
| perf_enhanced3440 / E02_porch_outward | 2.25 / 4.47 | 917 | 0 |
| perf_enhanced3440 / E06_yard_shed | 2.27 / 4.12 | 1485 | 0 |
| perf_original1920 / V08_lane | 11.50 / 14.76 | 13037 | 0 |
| perf_original1920 / E02_porch_outward | 1.52 / 2.52 | 815 | 0 |
| perf_original1920 / E06_yard_shed | 1.70 / 2.47 | 1398 | 0 |
| perf_original2560 / V08_lane | 12.46 / 18.09 | 13037 | 0 |
| perf_original2560 / E02_porch_outward | 1.76 / 3.38 | 815 | 0 |
| perf_original2560 / E06_yard_shed | 1.79 / 3.12 | 1398 | 0 |
| perf_original3440 / V08_lane | 13.19 / 17.95 | 13066 | 0 |
| perf_original3440 / E02_porch_outward | 1.77 / 3.54 | 914 | 0 |
| perf_original3440 / E06_yard_shed | 1.87 / 3.33 | 1440 | 0 |

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
