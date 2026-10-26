# Graphics performance — measured scope and open work

No new FPS target or graphics-profile performance claim at this checkpoint.
The 36 baseline screenshots include GPU readback and short fixed placements;
their runtime is not an uncaptured gameplay benchmark.

Renderer audit: `project.godot` Forward+, engine 4.7.2-stable, embedded release
PCK, x86_64, no custom template, desktop S3TC/BPTC. Root UI design viewport is
1280x720 with expanding canvas stretch. Test render sizes are independent from
the desktop preview window. Existing retro strength is configurable; documents
stay sharp. Filmic tone mapping; exterior ambient energy .22, moon energy .30,
two directional shadow splits/max distance 55, sky radiance 64, distance fog
.010. Terrain wetness roughness approaches .43 in patches with normal ripples.
No explicit production SSAO/SSIL/SSR/SDFGI enable found in the reviewed setup.
Runtime inherited defaults must still be recorded for effect experiments.

Ordinary idle run 01: 16m40s, native exit 0 via actual Quit, owner data unchanged.
After 120s warmup, external process working set ranged 1,151,340,544–1,158,770,688
bytes; private commit 1,904,177,152–1,926,402,048 bytes; handles 999–1,023.
These counters are process memory/handles, **not VRAM, GPU time or leak proof**.
A second ordinary observation completed after 975.281 seconds (16m15s), actual
Quit/exit 0, owner files unchanged. Raw counters and summaries for both runs are
preserved under the audit root; final hashes/paths are sealed in DELIVERY.json.

Future measurements: median/p95 native frame times and stutters, focused-frame
count/exclusions, render calls/primitives, resource memory and available GPU
timings, exact scene/preference/state, capped versus uncapped, warmup, moving
route duration and image-readback off. Preserve failed captures. Don't change
viewport size during an active sample; the earlier driver-path failure leaves
that harness condition under investigation.

The RTX 4080 SUPER/i9-14900K development PC does not establish minimum hardware.
No Original/Balanced/Enhanced preset has been added. Owner idle Crash C and
driver-path Crash A remain unresolved despite passing observations.
