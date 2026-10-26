# Phase 2 - isolated native graphics results

## Selected scope

Balanced is the first visual review candidate: irregular wet ground, exposed wet
timber/brick, light-responsive rain and clearer glass with a faint precomputed
lounge return. Enhanced adds optional SSAO/SSR and bounded outdoor low fog.
Original rendering is retained. These effects remain opt-in QA code, outside
ordinary gameplay. No public playable release or production merge is authorized.

## Native evidence

Build05 runtime source: eb93426eeb41f2222556d206f5f470a8318f2c73.
Nine visual cases cover Original/Balanced/Enhanced at 1920x1080, 2560x1440 and
3440x1440. All exited normally, without logged script errors or warnings, with
owner save/settings hashes unchanged. There are 108 native PNGs, including the
actual input-driven front-path walk and static Surveyor glass-readability views
from both sides plus a direct-view control. These placements are diagnostic
fixtures, not authored encounters or proof of complete encounter timing.

Two short native recordings preserve actual sampled-frame wall-clock timing:
front walk (5.65 seconds of frame timestamps) and controlled lounge camera strafe
(4.04 seconds). Captured game audio is non-silent; this is not subjective listening
approval. An independent reflection-off control and Phase1 images are retained.

## Performance - limitations matter

Nine initial uncapped native cases use three focused five-second stationary views
each, without image readback. Initial exterior median frame intervals range from
9.63 to 10.40 ms; lounge 7.34 to 8.63 ms; cellar 1.98 to 3.00 ms. Initial samples
have no intervals above 33.3 ms. These are short process-frame observations, not
GPU timings, sustained gameplay measurements or minimum-spec claims.

The separate capped 1080p Balanced case has median intervals near 16.7 ms, but
lounge p95 is 24.03 ms. Do not describe it as a perfect sustained 60 FPS result.

A later ultrawide Enhanced no-fog control was substantially slower than the
initial set. One bounded matched on/off recheck also remained slower in both
conditions: exterior median 26.95/26.09 ms, lounge 21.63/23.44 ms, cellar
5.33/5.32 ms (fog on/off). There were frame spikes in both exterior and lounge.
No focus exclusions were recorded. The cause of the between-run slowdown is not
established. It prevents attributing a reliable isolated cost or gain to fog.
All results, including poor samples, are preserved in PERFORMANCE.json/gallery;
no retry-until-pass or selective benchmark claim is made.

## Visual assessment and remaining work

The reviewed images retain crisp retro silhouettes, visible rain and a readable
warm entrance. Wet highlights and rain remain the main candidates; the room
return is deliberately faint. The Surveyor can be seen through glass, with parts
occluded by the actual frame. Static cubes cannot reflect moving actors or
changed rooms. Power, furniture and copied-room state gating must precede any
normal-game integration, followed by relevant real encounter checks.

Live reflection probes remain excluded. A minimal native editor/release control
reproduces the seven-texture shutdown warning only when a probe exists; the
engine cleanup defect is strongly supported, not patched or proven harmless.
See REFLECTION_WARNING_FINDINGS.md. This does not explain or fix the owner's
ordinary main-menu idle crash, which remains unresolved.

Failed/intermediate bake, parse and earlier visual evidence remain separate.
Previous production, Phase1 delivery, licensed media, saves and releases are
preserved. Human artistic approval and complete dynamic encounter compatibility
remain pending. DELIVERY.json records the final extracted launch, exact private
and public checkpoints, archive hashes and artifact paths after finalization.
