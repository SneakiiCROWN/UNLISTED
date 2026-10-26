# The Surveyor Identity / 0.10.6-dev / 26 October 2026

Private development candidate from complete 9f06206 / public f042833.
Previous deliveries, source, studies, licences and player data are preserved.
Public playable remains 0.10.0. No public release is authorised by this milestone.

## Player-visible implementation

The existing rare across-hall footstep event now crosses the actual utility room
towards its closed door. Four positional steps are followed by a quiet pause,
then two small attempts at the real handle. Both sides rotate about the same
spindle. No leaf animation, lock, enemy, forced camera or new narrative identity.
Opening the door cancels the lever response. An open door receives footsteps
only. Existing eligibility, seeded variety, long cooldown and once-only saved
consumption remain; no independent random scare controller was added.

Pause suspends timing. Reduced motion retains sound and optional sound captions
without handle animation. Reload consumes an interrupted transient event and
returns the handle to rest rather than replaying the sound. Pending authored
encounters cancel it; its reservation prevents the recorder response overlapping
the quiet interval. No AI, enemy locomotion or attack mechanics were changed.

Common, birch and willow trees now have original connected trunks, branches,
twigs and opaque leaf sprays instead of the old large solid crown meshes. Willow
tips droop; birch has narrower leaves and reach. No alpha foliage overdraw.
Existing seeded placements, scales, paths and property grade are unchanged.
Near-tree collision is rebuilt from the same new visible geometry, not an old
invisible canopy. Dead trees, pines, terrain, clues and property infrastructure
retain their previous sources. This is stylised sparse woodland, not a finished
photorealistic forest or minimum-spec performance approval.

## Character design gate

Three painted concept directions include front/side/rear, silhouette, face,
encounter-distance and movement intent. Observer's silhouette is provisionally
preferred. Its follow-up reads too much like an ordinary aged worker, so no new
3D mannequin, coat, rig or active replacement was made. See the design review.
The blocker remains distinctive authored character art. Owner approval pending.

## Verification scope

Final native results, actual package hashes and independent extraction/launch
are recorded in the accompanying DELIVERY.json. Focused tests exercise the
changed event, shared event scheduler, exterior traversal and relevant recovery.
Three render sizes are inspected using native exported screenshots: 1920x1080,
2560x1440 and 3440x1440. Camera fixtures are distinct from actual movement input.
No fresh 412-check investigation is repeated for unchanged progression.

Preserved failures: 02 runtime rejected an untyped time subtraction in the new
handle curve; explicit float type fixed it. 03's reduced-motion sound assertion
incorrectly counted temporary sound players after cleanup. The sound played;
04 records actual cue emission instead. Neither failure is hidden or called a
passing build. Final logs must be clean before delivery.

Moving foreground profile uses the existing connected property route, 60fps cap,
native-resolution private viewport presented in a desktop window, no readback
during sampling and focused frames only. It additionally records rendered
primitive counts. This is not an uncapped FPS, whole-game, cold-start, minimum-spec
or physical ultrawide-monitor guarantee. Prior 0.10.5 values are a separate
session baseline, not a controlled simultaneous before/after benchmark.

## Optional owner review, when convenient

- From the powered office, listen for an eligible quiet across-hall event. Is
  the approach, pause, handle movement and subsequent empty room unsettling?
  It is deliberately rare; F1's existing event tools can request eligible events.
- Compare the three concept silhouettes and faces. No replacement is approved.
- Walk gate/front, side path, shed and return. Judge woodland depth, rain and
  whether the finer leaves are comfortable under the configured retro effect.
- Judge the unchanged investigation, enemy sound variety and ending pacing.
  Automation does not establish comprehension, fear or emotional payoff.

Human listening/artistic approval, physical-controller review and first-play
duration remain pending. No 30-60-minute or finished-game claim.

## Completed candidate 04 results

- Physical door response: 23/0 at each of 1080p, 1440p and 3440x1440. Includes
  the four actual sources, real lever pose, quiet interval, pause, once-only
  recovery, interrupted partial load, player door opening, pending encounters,
  reduced motion and input-driven investigation of the empty room.
- Shared ambient scheduler/physics/gaze regression: 47/0. Exterior gate, yard,
  shed, service threshold and save compatibility: 59/0. Recorder recovery and
  1440p presentation: 24/0. Vent fast-reversal regression: 8/0.
- Ending B from the preserved genuinely earned 0.10.2 investigation snapshot:
  35/0 at 1440p, story/reduced-motion with simulated controller buttons. A segmented
  ending/recovery check, not another fresh investigation or physical-controller
  review. Independent extracted Windows normal-mode ending A is recorded in
  DELIVERY.json after packaging; do not infer its result from this source note.
- 17 native exterior views per resolution. 1080p geometry inspection in 03;
  final 04 uses identical foliage source and supplies 1440p/ultrawide. The close
  rear-fence fixture is physically right against its existing 1.8 m palings;
  it is not a useful unobstructed horizon view. The world was not moved for it.
- Four foreground moving passes, 25.17 seconds and 1,509 focused frames each,
  no focus exclusions. 1440p small-shadow A/B medians: 9,331 versus 8,594 draw
  calls (7.9% fewer), 16.663 versus 16.662ms. Optimised 1080p / ultrawide medians
  16.662 / 16.664ms, p95 16.928 / 16.951ms. Rendered primitive medians are
  approximately 15.4 million at 1080p/1440p and 16.2 million ultrawide, including
  reported render passes. This remains significant geometry work for weaker
  hardware; no minimum-spec or uncapped performance guarantee is made.

All listed native logs have zero reported runtime errors. Owner checkpoint and
settings hashes remained unchanged. Failure receipts remain separately preserved.
The delivery contains the original native footage and a short first-event clip;
audio setup is aligned to the first recording physics tick, within about 16.7ms.
No simulated speedup, generated gameplay frames or subjective listening claim.
