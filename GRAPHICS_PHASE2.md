# Phase2 — reflections and atmospheric horror

Isolated branch `experiment/reflections-atmosphere`, continuing Phase1 `0024b0a`.
Production remains at `9e09084` in `C:\Users\Snkii\Documents\UNLISTED\Game`.
Experimental source remains in the existing Phase1 worktree on its new branch;
new builds/evidence are in `Checkpoints/20261027_graphics_phase2`.
Previous tags, builds, saves, settings, licensed sources and forensic evidence
are preserved. No public Windows release or production integration.

## Implemented changes

- `phase2_ground.gdshader`: irregular warped wet-patch unions, finer broken edges,
  water-normal flattening, roughness transitions and rain rings. Front wetness
  is scoped to the existing approach, with original side/rear roughness response
  restored. Sheltered porch stays excluded; no mesh/height/collision edits.
- `phase2_timber.gdshader`: existing timber maps receive exposed damp roughness
  and restrained darkening. Existing brick material is cloned with a less chalky
  response. Protected porch regions retain a drier finish. No replacement art.
- `phase2_rain.gdshader`: same roof-colliding particles, using actual scene lighting
  instead of a fixed unshaded colour. A weak emission floor keeps distant drizzle
  readable; tapered streak sides reduce bar-like appearance. Existing roof,
  cellar and service-void masks remain intact.
- `phase2_window.gdshader`: lower-haze centre, rough edge dirt, fine wet trails,
  variable roughness and weak box-projected static room sampling. The actual
  lounge is baked to a private six-face128px Cubemap. No live probes, invented
  room image or dynamic character-reflection claim. Reduced-motion preference
  freezes material trail motion.
- `phase2_low_fog.gdshader`: Enhanced-only feathered exterior volume, bounded
  above the ground between porch and gate. Global volumetric density is zero;
  volume does not overlap the house/porch. Original mist sprites are hidden only
  for that comparison. Balanced retains cheaper existing atmospheric depth.
- `graphics_phase2_profile.gd`: optional second-generation layer on Phase1.
  Original changes nothing; Balanced adds the materials/weather; Enhanced adds
  existing SSAO/SSR plus optional local fog. `--phase2-no-fog` and
  `--phase2-no-reflection` support controlled comparisons.

Existing practical-light changes from Phase1 are retained rather than adding
another lighting rig. No global exposure/grading increase, extra bloom, higher
polygon models, new story event, Surveyor redesign or player-preference writes.

## Actual verification and limitations

Build05 captures Original, Balanced and Enhanced at1920x1080,2560x1440 and
3440x1440 using the preserved exact cameras. Added views inspect glass from
both sides with the actual active Surveyor plus a direct-view control. These
are deliberately staged static visibility fixtures, not new authored encounters
or proof of every sighting's timing. The same actual front-path physics walk is
included. The utility narrative mirror and ordinary AI are untouched.

Native performance runs use fixed resolution per process, uncapped/vsync-off
arguments, focused five-second stationary samples without image readback.
Median/p95/max intervals, average observed frame rate, spikes over33.3ms,
draws/primitives and Godot memory counters are retained. No GPU timestamps,
sustained gameplay or minimum-spec guarantee. Separate capped runs and native
recordings are labelled; recording cadence is not rendering FPS.

The window-motion clip is a controlled camera strafe in the existing room,
not a physics traversal. The front-approach clip uses actual movement inputs.
Neither clip is a human playtest or artistic approval. Weather phases differ
between comparisons; exposure/retro strength/cameras remain matched.

Read `REFLECTION_WARNING_FINDINGS.md` for the minimal native reproduction and
supported engine-source explanation. Probes remain rejected. The selected
precomputed alternative has no live atlas and is not represented as accurate
reflection of dynamic occupants. Old captures/failures remain separate.

## Integration priorities

1. Review moving wet highlights and the clearer glass against Phase1's native
   baseline, not just feature counts. Balanced is the first review candidate.
2. Gate static room reflection for changed power, furniture and transformed-room
   states; keep outside silhouettes and existing clues readable in actual events.
3. Judge Enhanced fog/SSAO/SSR by visible benefit and measured cost. SSIL remains
   an independent Phase1 study, not an automatically stacked effect.
4. Test ordinary pause/save/load/encounter compatibility only when a reviewed
   effect is proposed for integration. Do not rerun unrelated full routes now.

Completed counts, performance data, independent extracted launch and exact
artifact hashes are in the private `DELIVERY.json` and comparison gallery after
finalization. Complete private source includes the baked resource and minimal
probe fixture. Safe GitHub source excludes derived texture/raw media and dumps.
No new assets were purchased or downloaded; existing licences remain in force.

Owner main-menu Crash C and driver-path Crash A remain unresolved. Clean short
graphics runs do not certify them fixed. Owner artistic approval remains pending.
