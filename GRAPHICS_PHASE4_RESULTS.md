# Phase 4 - native results and limits

Runtime source: 6d4162a. Selected native export: Candidate04.

## Changed experience

Three focused changes refine Phase3: all intended coarse crown batches are now
selected by stable source asset identity; 60 conifer placements use connected
branch/leaf silhouettes, and stones use existing granular texture. Existing damp
timber receives a restrained diffuse/lighting lift. Front puddles have softer,
less mirror-like highlights. No new lights, probes, story events or layout changes.
The static room-return reflection remains disabled. Original, Balanced and
Enhanced are separate explicit QA choices. See GRAPHICS_PHASE4.md for files.

## Actual native proof

Nine Original/Balanced/Enhanced visual cases cover 1920x1080, 2560x1440 and
3440x1440. Selected runs have normal exits, no logged errors/warnings and unchanged
owner save/settings hashes. Native before images are preserved Phase3 Balanced
views, not recreated images; weather phases differ. Every selected case verifies
that all 31 source coarse crown batches are suppressed by asset identity.
Static actor fixtures alone are not claimed as live encounter proof.

The Candidate02 focused route passed before the metadata selection correction:
gate, shed/perimeter/rear crossings, save/load, pause/resume, checkpoint retry,
crouch/stand, staged actual Surveyor movement, wall concealment, first front knock,
ajar/full-open/normal-close and front-door entry/exit. Candidate04 changes which
render batches are selected; it does not move near trees, routes or colliders.
Final extracted verification repeats the physical route and is recorded in
DELIVERY.json/IndependentExtract/Verification after packaging. Do not confuse this
segmented QA with a naturally earned uninterrupted full investigation or combat
death. Both endings and natural hiding/pursuit sequences were not rewritten.

Moving glass clips use the working actor's actual movement, collision and animation
method. Inside/outside cameras are explicit controlled strafes; this is not a new
story encounter. The body remains in its reached position until diagnostic exit.
The clips preserve recorded wall-clock durations and captured game audio. They do
not establish subjective audio quality, fear, artistic approval or gameplay FPS.
The unchanged car cinematics still require an integration-specific visual check.

A Candidate03 1440p run completed but logged a null-particle resource error and
was rejected. Its native log/results are preserved under Evidence03. The exact
cause is not established. The selected candidate initializes the same lit-rain
material before emitters enter the scene tree rather than swapping a live draw
mesh. Bounded rechecks and the selected matrix are recorded; clean finite runs
are not proof of a permanent engine fix or an explanation of the owner crash.

Candidate01/02 images exposed duplicate node auto-renaming that caused incomplete
selection. The earlier comparison driver was deliberately stopped; its current
native child was allowed to finish. Those files remain outside selected Evidence04.
This was a controlled QA stop, not a native game crash or a passing selected run.

## Measured cost

Five-second stationary focused native samples; requested uncapped/vsync off. No
readback during measurement. Baseline/after use the same executable and cameras,
with --atmosphere-baseline selecting Phase3. Process intervals are not GPU
measurements or sustained/minimum-spec claims. Engine memory and primitive counts
remain in PERFORMANCE.json; render-memory counters are not total board VRAM.

| Case / view | Median / p95 ms | Draws | Spikes >33.3ms |
|---|---:|---:|---:|
| perf_balanced1920 / V08_lane | 9.48 / 10.12 | 13161 | 0 |
| perf_balanced1920 / E02_porch_outward | 1.41 / 1.72 | 833 | 0 |
| perf_balanced1920 / E06_yard_shed | 1.59 / 1.97 | 1457 | 0 |
| perf_balanced2560 / V08_lane | 9.65 / 11.11 | 13161 | 0 |
| perf_balanced2560 / E02_porch_outward | 1.49 / 1.85 | 833 | 0 |
| perf_balanced2560 / E06_yard_shed | 1.63 / 1.95 | 1457 | 0 |
| perf_balanced3440 / V08_lane | 9.75 / 12.23 | 13195 | 2 |
| perf_balanced3440 / E02_porch_outward | 1.65 / 2.08 | 931 | 0 |
| perf_balanced3440 / E06_yard_shed | 1.71 / 2.24 | 1504 | 0 |
| perf_before_balanced1920 / V08_lane | 10.09 / 11.09 | 13534 | 0 |
| perf_before_balanced1920 / E02_porch_outward | 1.40 / 1.75 | 819 | 0 |
| perf_before_balanced1920 / E06_yard_shed | 1.56 / 1.88 | 1444 | 0 |
| perf_before_balanced2560 / V08_lane | 9.95 / 11.70 | 13534 | 0 |
| perf_before_balanced2560 / E02_porch_outward | 1.48 / 1.83 | 819 | 0 |
| perf_before_balanced2560 / E06_yard_shed | 1.59 / 1.97 | 1444 | 0 |
| perf_before_balanced3440 / V08_lane | 9.95 / 11.30 | 13567 | 0 |
| perf_before_balanced3440 / E02_porch_outward | 1.62 / 2.02 | 918 | 0 |
| perf_before_balanced3440 / E06_yard_shed | 1.67 / 2.06 | 1486 | 0 |
| perf_enhanced1920 / V08_lane | 9.97 / 10.72 | 13160 | 0 |
| perf_enhanced1920 / E02_porch_outward | 1.51 / 1.83 | 832 | 0 |
| perf_enhanced1920 / E06_yard_shed | 1.77 / 2.17 | 1456 | 0 |
| perf_enhanced2560 / V08_lane | 9.99 / 12.12 | 13160 | 0 |
| perf_enhanced2560 / E02_porch_outward | 1.79 / 2.28 | 832 | 0 |
| perf_enhanced2560 / E06_yard_shed | 1.83 / 2.23 | 1456 | 0 |
| perf_enhanced3440 / V08_lane | 10.02 / 11.23 | 13194 | 0 |
| perf_enhanced3440 / E02_porch_outward | 2.15 / 2.79 | 930 | 0 |
| perf_enhanced3440 / E06_yard_shed | 2.04 / 2.51 | 1503 | 2 |
| perf_original1920 / V08_lane | 9.36 / 10.05 | 12663 | 0 |
| perf_original1920 / E02_porch_outward | 1.38 / 1.69 | 829 | 0 |
| perf_original1920 / E06_yard_shed | 1.59 / 1.90 | 1411 | 0 |
| perf_original2560 / V08_lane | 9.34 / 11.12 | 12663 | 0 |
| perf_original2560 / E02_porch_outward | 1.44 / 1.77 | 829 | 0 |
| perf_original2560 / E06_yard_shed | 1.63 / 2.12 | 1411 | 0 |
| perf_original3440 / V08_lane | 9.29 / 11.15 | 12694 | 0 |
| perf_original3440 / E02_porch_outward | 1.52 / 1.92 | 927 | 0 |
| perf_original3440 / E06_yard_shed | 1.71 / 2.45 | 1458 | 0 |

All results remain available, including slower samples and spikes. Balanced is
provisionally preferred for its restrained wetness and readability. Enhanced adds
existing SSAO/SSR and bounded fog, not an automatic quality winner. Integration
ranking and its conditions are in GRAPHICS_INTEGRATION_RANKING.md.

## Unfinished / limits

Original intermittent owner main-menu crash is UNRESOLVED. Clean graphics cases
and extraction do not certify a fix. ReflectionProbe atlas warnings remain
excluded; no engine/driver/Windows changes. Office E04 is a solid-wall control,
not a window; E08 is obscured by a close fence. Neither is exterior-view proof.
The existing property remains sparse in some side views, branch silhouettes can
alias, and the Surveyor's art is still unapproved. Human artistic approval,
complete story-state encounter compatibility and sustained stability remain
pending. Production, saves, previous builds/releases and licensed raw media are
preserved. No public Windows release or production merge.
