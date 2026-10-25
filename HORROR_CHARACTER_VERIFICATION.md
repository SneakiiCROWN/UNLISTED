# Horror & Character Production / 0.10.5-dev / 26 October 2026

Private candidate; public playable remains 0.10.0. Base: complete private 2da91cd
and safe public 551b805. Older builds, studies, saves and licences are preserved.

## Actual player-visible work

- Replaced the chunky dead-tree crowns with original tapered trunk, branch, fork
  and twig geometry at the existing seeded positions/heights. Dead-tree collision
  derives from the same new geometry. Terrain grade, buildings and required paths
  are unchanged. Original coarse assets remain preserved. Leafy crowns remain
  stylised and are not claimed to be finished naturalistic forest art.
- Added grouped short growth in authored garden/woodland-edge pockets, wet broken
  ground colour and fine coppice framing. Avoids the central approach, car, service
  circuit, east return and footprint evidence. Reuses approved nature meshes;
  render-only low growth adds no collision barriers. Small dressing is batched.
- Small random grass/bush batches no longer cast expensive shadow-map passes.
  Mature trees, rocks/logs, house, doors, flashlight and Surveyor retain shadows.
- The existing stopped-recorder anomaly now moves its real VU needle with the
  backward transport and decays to rest. It uses the existing mechanical click,
  optional caption and event conditions, not a new scare or invented historical
  voice. Partial needle pose, timeline and spent state persist. Pause freezes it;
  reduced motion suppresses it, including preference changes during the event.

## Character construction: useful foundation, not final Surveyor art

The rejected 0.10.4 study paired a generic-body OBJ with clothing reconstructed on
a different canonical base. The new isolated study uses the actual canonical body
and native references for clothing, hair, eyes and complete footwear. No old coat
extrusion or cross-body weight transfer; no rigging or active-model replacement.

Neutral front/side/rear/face renders and native encounter-distance comparisons
show cleaner construction. They also show why this is not a finished antagonist:
ordinary youthful face, unfinished material/neck treatment and no distinctive
horror silhouette. It is not approved, not called frightening and not animated.
The active Surveyor remains byte-identical. Packed Blender source, source inputs
and neutral images are included privately for future authored character work.

## Native verification and preserved failures

- 04 recorder/house-response checks: 33/0. Includes physical footprints, actual
  historical playback, stopped-equipment eligibility, reverse reels, new meter
  movement, partial save/load, pause, interruption, once-only state, legacy saves
  and reduced-motion changes. No human listening/comprehension approval claimed.
- 06 exterior movement: 59/0. Actual input drives first gate entry, both lane
  directions, shed entry/perimeter/return, service doorway and save compatibility.
- 05 native 1080p exterior captures; 06 native 1440p and 3440x1440 captures. These
  are explicit player-height camera fixtures, separate from movement evidence.
- 06 recorder presentation/recovery at 1440p: 24/0. Final reports and
  independently extracted Windows ending/recovery receipt accompany delivery.
- Retained 03 failed runtime load: an inferred twig-vector type was rejected;
  explicitly typing it corrected the actual script error. Retained 05 exterior
  51/4: old QA tried to cross the closed gate from the newer lane-side spawn, then
  attempted interactions out of reach. 06 enters by real gate interaction before
  exercising the original outward loop; no gate/controller workaround was added.
- No unrelated 412-check fresh investigation was repeated. Progression, dialogue,
  endings, enemy rig/AI, upside-down-room safety and controller code are unchanged.
  Current owner checkpoint/settings integrity receipts are retained for each run.

## Performance scope

Actual isolated movement along the connected gate/front/west/rear/shed circuit,
about 25 seconds per pass. Foreground native-resolution rendering at 1080p, 1440p
and ultrawide, displayed in a 1280x720 desktop window. A 1440p A/B pass changes only
small random foliage shadows in the same new environment. No image readback during
sampling, 60fps cap, warmed views, scripted threats disabled. Hardware remains
i9-14900K / RTX 4080 SUPER / Vulkan Forward+. These are longer property samples,
not sustained whole-game, cold-start, minimum-spec or native ultrawide-monitor proof.

The earlier pre-crown 04 A/B reduced median draw calls from 9,882 to 9,513 (3.7%),
with both cases near the cap; this does not establish an FPS gain. 06 measures the
final crowns separately. Raw JSON, frame times and focus exclusions are preserved.
Final 06 1440p A/B: 9,770 versus 9,402 median draw calls (3.8% fewer); median frame
times 16.666 versus 16.667ms, p95 16.904 versus 16.885ms. Optimised 1080p and
3440x1440 medians were 16.666ms, p95 16.853/16.900ms. Each route lasted about
25.17 seconds, 1,509 focused samples, zero focus exclusions. This demonstrates
reduced draw submission, not an uncapped FPS improvement or a universal guarantee.
One first interval was included in the older 04 exclusion counter; 06 separates
that initial interval from actual focus exclusions. More detailed crowns increase
geometry complexity, so lower-spec and sustained encounter profiling remain open.

## Remaining work

Distinctive, professional Surveyor design remains the primary unresolved art task.
The clean construction study needs original face/wardrobe/material art before any
rigging. The woodland is improved but leafy crowns and broader environmental art
still need work. Human art/fear/story/audio approval and physical-controller review
remain pending. No duration or finished-game claim, and no public Windows release.

DELIVERY.json records actual source commits, development tag, hashes, complete
private source, Windows ZIP, independent launch and screenshot/video locations.
