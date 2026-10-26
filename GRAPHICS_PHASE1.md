# Phase 1 — isolated rainy property study

Branch: `experiment/rain-soaked-property`, based on forensic recovery `9e09084`.
Production checkout remains at `C:\Users\Snkii\Documents\UNLISTED\Game`.
Experimental checkout:
`C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261026_graphics_phase1\Game`.
Original native crash investigation, player data and previous builds untouched.
This is not a new public release or an approved production graphics upgrade.

## Actual implementation

- `shaders/study_property_ground.gdshader`: derivative of the existing property
  shader using the same ambientCG soil/concrete colour, normal and roughness maps.
  Three broken-edged wet patches follow the front footpath; lower roughness,
  flattened water normals and existing rain-ring logic. Dry porch exclusion,
  no terrain plate, vertex displacement, collider or path changes.
- `shaders/study_window.gdshader`: existing glazing surfaces receive restrained
  edge dirt, thin moving rain trails and varying roughness. Transparent centre
  remains .055 alpha; no fake opaque mirror panels or extra reflection cameras.
  Existing utility narrative mirror is untouched.
- `scripts/graphics_profile_study.gd`: separately switchable wetness, lighting,
  glass, static probes, SSAO, SSIL and SSR. Original profile changes none of them.
  Porch light redistributes its existing source with contact-shadow adjustments;
  two existing cellar utility lamps receive bias/source-size/intensity changes.
  No additional lamp array, global exposure change or new horror event.
- `scripts/graphics_study.gd`: real world construction, preserved baseline camera
  positions plus close ground/window views, fixed native resolution per process,
  physics-driven front-path approach and optional separate audio/video capture.
- `tools/run_graphics_study.py`: exact cap/vsync/arguments/executable hash logged;
  private save/settings paths and isolated input, before/after owner hashes,
  failed runs preserved and no output directory overwritten.

`world.gd` changes only register the explicit `--graphics-study-qa` mode and
dispatch it. Normal startup never applies experimental profiles. Renderer,
project preferences, export presets, models, story, AI, collision and saves are
not changed. The original profile and previous 36 native screenshots remain.

## Experimental profiles

| Profile | Active changes |
| --- | --- |
| Original | Existing rendering unchanged |
| Balanced | Wet material, existing-light adjustments, rain-aged glazing |
| Enhanced | Balanced plus short-radius SSAO and 48-step SSR |
| Individual studies | wet / lights / glass / probe / ao / ssil / ssr |

These are development configurations, not persisted player settings. Enhanced
does not include static probes. SSIL remains a separate comparison rather than
an automatic extra effect. No volumetric-fog, GI, ray-tracing or engine change.

## Findings and cautions

The first stronger wet candidate produced a conspicuous curved orange highlight.
It was retained in Build01, then softened by flatter normals, higher water
roughness, gentler edges and better patch placement. No emission-based painted
reflection is used. Final visual assessment belongs to the final native images,
not this description or the number of passing checks.

Probe-enabled Build01/02 and the isolated Build03 probe run exit 0 but log seven
texture RIDs left at renderer shutdown. Explicit removal and extra frames did
not clear it. This is a demonstrated probe-configuration correlation, not proof
of its internal engine cause or a relationship to owner Crash C. Probes are kept
out of selected profiles; the separate stronger window-reflection study remains
experimental and not recommended for integration yet.

SSR cannot supply off-screen information or reliable transparent-window returns.
Selected profiles preserve the existing sky reflection; accurate reflected room
detail from probes is deferred. No new window anomaly is implemented.

## Verification scope

Native logs, screenshots, configuration, owner integrity and frame-time samples
remain under the sibling Build01–Build04 evidence folders. Earlier rejected
captures and warnings are preserved. Performance uses one fixed render size per
process, no readback during five-second stationary samples, focus exclusions and
explicit uncapped/vsync-disabled arguments. Original, Balanced and Enhanced are
compared at 1080p/1440p/3440x1440. Separate recordings include readback and must
not be used as FPS measurements. Desktop preview is 1280x720, independent of the
native render size; no physical ultrawide-monitor claim.

These short samples are not sustained gameplay benchmarks, GPU timestamps,
minimum-spec testing, human artistic approval or a permanent stability claim.
Detailed completed results and final artifact hashes belong in the private
`DELIVERY.json` and evidence gallery, produced after the runs complete.

## Reused rights and integration gate

ambientCG and Quaternius CC0 resources and existing original shaders are reused;
all raw media stay private. Existing other models and recordings retain their
licences/notices; no asset purchase, download or blanket relicensing occurred.
Use the retained `THIRD_PARTY.md` and asset provenance files for exact selections.

Do not cherry-pick the world hook into production by itself. Review matched
images and moving highlights, investigate probe teardown separately, validate
settings/room transitions and relevant gameplay before promoting any effect.
Owner idle Crash C and earlier driver-path Crash A remain unresolved.
