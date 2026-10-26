# Phase 1 native results — 26 October 2026

**Working isolated study, not integrated production graphics or human approval.**
Runtime source `7bf7923`; original production remains `9e09084`. Godot/editor and
release template 4.7.2-stable, Forward+ Vulkan, no renderer/system changes. A$0
spent. New source lives only on `experiment/rain-soaked-property`; safe public
source is on the separate `graphics/rain-soaked-property` branch.

## Delivered and observed

- A real exported original/modified property comparison: broken-edged front-path
  wetness, subdued moving water response, warm porch highlight and existing
  light/contact-shadow adjustments. Initial orange crescent rejected; final
  water patch is placed to receive the lamp highlight through its body.
- Existing windows receive edge grime, fine vertical moisture and restrained
  specular/roughness response. Window frames and exterior remain visible in the
  reviewed views. Accurate reflected room detail is **not** approved: the static
  probe study remains separate. Surveyor-in-window readability in motion still
  needs a dedicated encounter check before any production integration.
- Existing cellar lamps receive source-size, shadow-bias and energy refinements;
  Enhanced compares short-radius SSAO. Improvements here are subtle; this is not
  a finished cellar art pass or a new character/silhouette encounter.

The final Build04 produced 72 original native PNGs: eight per profile at each of
1920x1080, 2560x1440 and 3440x1440. Seven fixed views plus the actual walked-to
porch view. All nine visual runs exit 0, no logged errors/warnings, unchanged
owner hashes and successful existing-physics path traversal. Matched exposure,
camera positions and retro strength; particle/weather phases differ. Originals
are unedited. Review sheets only resize images for navigation.

Independent ZIP extraction launched the same executable, repeated the Balanced
walk/tour, exit 0 with no logged errors/warnings and unchanged owner data. No
full investigation, death/retry or two-ending suite was rerun: these graphics
are opt-in QA-only and no story/AI/puzzle/controller/physics code was changed.
The existing forensic regression baseline remains preserved, not relabeled.

## Measured cost, with limitations

One process per fixed render size; explicit uncapped / vsync-disabled arguments;
three five-second stationary samples per run, no readback during measurement.
All recorded samples retained focus. Sixteen Build03 technique/profile runs
produce 48 samples; final Build04 wide rechecks and capped run add nine samples.
Build03 precedes the final wet-patch coordinate change; Build04 uses final source.

| Final Build04 / 3440x1440 | Median ms | p95 ms |
| --- | ---: | ---: |
| Balanced exterior | 10.732 | 11.503 |
| Enhanced exterior | 10.707 | 11.354 |
| Balanced lounge | 8.912 | 9.892 |
| Enhanced lounge | 9.025 | 9.814 |
| Balanced cellar | 2.560 | 3.130 |
| Enhanced cellar | 3.026 | 3.662 |

Separate capped Balanced 1080p sample: medians about16.7ms, p95 below16.85ms.
That is the 60fps cap, not an uncapped performance improvement. Full matrix,
draw calls/primitives, static memory and Godot-reported render memory are in
the packaged `PERFORMANCE.json` and HTML table. Render memory is not a Windows
process-VRAM audit. Exterior draw workload already exceeds13,000 calls in this
fixture; further effects should not be stacked without measuring them.

Results vary by run order/warmup: some higher-resolution samples were faster
than earlier1080p samples. Do not attribute small differences solely to an
effect or claim percentage gains. No sustained gameplay benchmark, GPU timing,
minimum-spec result or promise of60fps on other hardware. RTX4080SUPER/i9-14900K
only. Single-technique comparisons include wet, lights, glass, probes, SSAO,
SSIL and SSR; the selected profiles omit SSIL and probes.

## Recording and failures

Two actual native front-path clips, original and Balanced, retain positional
rain audio: approximately5.4 seconds each. Captured at variable wall-clock
cadence (93/92 native frames), presented in a30fps H.264/AAC container with
repeated frames. They are movement evidence, not FPS proof. Audio peaks near
-22.9dBFS; non-silent signal is not subjective listening/mix approval.

No application crash or script/shader error observed in these graphics runs.
The probe configuration repeatedly logs seven Texture RIDs at shutdown, even
after explicit teardown. Its original images/logs remain in Build01–03. It is
excluded from Balanced/Enhanced, not declared fixed or blamed for owner Crash C.
Earlier oversharp wetness images are preserved as rejected comparisons.

Original owner main-menu Crash C and earlier driver-path Crash A remain
unresolved. Short clean study runs do not certify permanent stability.

## Integration recommendation

Use Balanced as the first visual-review candidate; keep Enhanced optional.
Wet-material response and local light adjustments are preferable to blanket
SSR/GI/volumetric changes. SSR offers limited extra value in these views and
cannot provide off-screen/transparent-window reflections. Probe reflections
need further resource-lifetime investigation. No ray-tracing, GI or fog change.

Before integration: review moving highlights at normal walking speed, scope the
front-study wet mask against original rear/side-yard response, test actual
window sightings, review material contact in unpowered states and pause/load
across lighting transitions. Keep Original PSX available. No existing preferences
were overwritten and none of these configurations is a persisted player preset.

Private Windows/source ZIPs, history bundle, exact commits and SHA-256 values
are in the sibling `DELIVERY.json`. No public Windows release was published.
