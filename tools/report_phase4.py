from pathlib import Path
import json
G=Path(__file__).resolve().parents[1];C=Path(r"C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261027_graphics_phase4");E=C/"Evidence04"
read=lambda p:json.loads(p.read_text(encoding="utf-8-sig"))
rows=[];count=0
for width in ["1920","2560","3440"]:
 for profile in ["original","balanced","enhanced"]:
  d=E/("final_"+profile+width);r=read(d/"result.json");p=read(d/"graphics_report.json")
  assert r["exit_code"]==0 and not r["script_errors"] and not r["warnings"] and r["owner_unchanged"] and all(c["passed"] for c in p["checks"])
  count+=len(list(d.glob("*.png")))
for d in sorted(E.glob("perf_*")):
 p=read(d/"graphics_report.json");r=read(d/"result.json");assert r["exit_code"]==0 and not r["script_errors"] and not r["warnings"] and r["owner_unchanged"]
 for m in p["measurements"]:
  assert m["focused_frames"]>0 and m["excluded_unfocused"]==0
  rows.append("| "+d.name+" / "+m["view"]+" | "+f"{m['median_ms']:.2f} / {m['p95_ms']:.2f}"+" | "+str(int(m["median_draws"]))+" | "+str(m["spikes_over_33ms"])+" |")
assert len(rows)==36
text="""# Phase 4 - native results and limits

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
"""+"\n".join(rows)+"""

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
"""
(G/"GRAPHICS_PHASE4_RESULTS.md").write_text(text,encoding="utf8")
print("Selected PNGs",count,"performance samples",len(rows),flush=True)
