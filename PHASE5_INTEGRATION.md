# Phase 5 — Integrated Playable QA

**PRIVATE QA — STABILITY NOT CLEARED.** This integrates the complete forensic
gameplay source and the reviewed graphics work. It is not a public release or
an approved art milestone. The owner's ordinary idle-menu crash remains unresolved.

## Actual integration

- Ordinary startup reads the saved Property atmosphere preference before weather
  construction. Original PSX is the default and retains the original terrain,
  vegetation, materials and rendering. Existing preferences are not migrated over.
- Balanced Atmosphere uses the Phase 3 terrain/collision and grounded planting,
  Phase 4 woodland silhouettes and textured stone, restrained wet ground,
  damp timber/brick, warm porch contact lighting, clearer rain-exposed windows,
  and the existing rain fields receiving real scene lights.
- Enhanced Atmosphere adds the reviewed bounded exterior fog, SSAO and SSR.
  It adds no reflection probes, SDFGI, SSIL, live reflection cameras or extra lamps.
- The existing Clean / Modern PSX / Stronger Retro controls remain separate.
  Interface text remains sharp. Reduced motion also updates wet-window trails.
- Powered cellar lights retain gameplay-controlled energy. These settings do
  not enable the rejected character studies, staged actors or puzzle shortcuts.

## Safe profile changes

Settings > Display > Property atmosphere saves the selection. Fully quit and
launch again to apply it. This deliberately avoids replacing active GPU particle
draw meshes, rebuilding collision beneath the player, or resetting a partially
completed investigation. Returning to the title alone does not apply a new profile.
The setting belongs to preferences, not a particular save: loading a case keeps
the profile chosen at application startup. Original is the fallback.

The expanded Settings content scrolls and follows keyboard/controller focus;
the tabs and Back action stay within the panel.

## Excluded and preserved

ReflectionProbe studies remain excluded from ordinary startup. Static room
cubemap reflections are disabled and not loaded by runtime profiles. Rejected
Surveyor art and inactive cinematic studies remain inactive. Previous branches,
archives, builds, licensed sources and crash evidence are preserved.

No Windows, driver, registry, BIOS or engine changes were made.

## Verification boundaries

See PHASE5_RESULTS.md and the private delivery receipt for actual completed runs.
The first native Candidate01 exposed an overflowing Settings panel; its original
screenshots/logs remain in Evidence01. Candidate02 repaired the layout. Subsequent
QA-only additions cover controller pause, relaunch persistence and moving samples.
Do not count segmented ending recovery as two independent fresh investigations.
Eye-height camera placements are visual review, not proof of walking that route.
Sampled-frame videos preserve wall-clock timing and are not native-FPS claims.

Earlier Phase 4 null-particle evidence is retained. Initializing rain materials
before adding emitters is a precaution, not a proven fix for that intermittent
renderer error or the separate ordinary-menu crash. **The error recurred in
Candidate04 during ultrawide ending save/load.** All 35 gameplay checks completed,
but that rendering case failed acceptance. It is not relabelled as passing and
was not repeated until clean. The private candidate is a diagnostic/playable QA
delivery with a known rendering defect, not a stability-approved build.
Passing bounded observations
does not establish permanent stability. Human fear, comprehension, artistic
approval and first-playthrough duration remain pending.
