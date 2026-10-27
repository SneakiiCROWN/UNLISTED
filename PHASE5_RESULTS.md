# Phase 5 — Integrated Playable QA results

**PRIVATE QA — STABILITY NOT CLEARED. Rendering acceptance has not passed.**

Runtime export: Candidate04, private source `af2ba3f`. Original remains the default.
No public Windows release. No driver, OS or engine changes.

## Actual investigation and focused native runs

The fresh investigation used Candidate02 and finished in 723.94 seconds with 428 checks, zero logged errors/warnings and unchanged owner files. It used actual inputs through the current investigations, Surveyor death/retry and physical departure. This is automated route timing, not human playthrough duration. Candidate04 subsequently added QA dispatch/coverage; production graphics, story and menu implementation were unchanged. Its focused runs are listed separately. Both alternative conclusions are verified from the naturally earned investigation checkpoint, not claimed as two fresh playthroughs.

| Selected-export case | Gameplay checks | Process exit | Logged rendering errors |
|---|---:|---:|---:|
| answers_balanced1440 | 33 | 0 | 0 |
| balanced1920 | 19 | 0 | 0 |
| balanced2560 | 19 | 0 | 0 |
| balanced3440 | 19 | 0 | 0 |
| ending_balanced3440 | 35 | 0 | 1 |
| ending_enhanced1440 | 35 | 0 | 0 |
| endings_balanced1080 | 70 | 0 | 0 |
| enhanced1920 | 19 | 0 | 0 |
| enhanced2560 | 19 | 0 | 0 |
| enhanced3440 | 19 | 0 | 0 |
| input_balanced1080 | 14 | 0 | 0 |
| moving_balanced1440 | 28 | 0 | 0 |
| moving_balanced3440 | 28 | 0 | 0 |
| moving_enhanced1440 | 28 | 0 | 0 |
| moving_original1440 | 28 | 0 | 0 |
| original1920 | 19 | 0 | 0 |
| original2560 | 19 | 0 | 0 |
| original3440 | 19 | 0 | 0 |
| vent_balanced1440 | 10 | 0 | 0 |
| vent_reverse_balanced1080 | 8 | 0 | 0 |

The nine profile/resolution runs each verify real startup, actual menu selection/persistence, restart-selected rendering, arrival, gate movement, save/load, keyboard pause, controller Start/B and reduced-motion glass. Their room screenshots use explicitly labelled eye-height placements. The fresh investigation separately proves movement through the route. Normal/story ending checks include receipt recovery, controller interaction, pause, boarding interruption, physical car departure and View Ending. Input-isolation testing uses synthetic input; physical controller hardware remains untested.

## Failures retained

- Candidate01: new Display rows grew outside the screen. Candidate02 replaced the unbounded content with focus-following scrolling; the fixed panel and Back action passed all three resolutions. Original image retained.
- The input-isolation run completed all 14 checks cleanly, but its wrapper initially missed the existing fixed report path. The original wrapper failure is retained, the actual report was collected, and the same run was reconciled without rerunning gameplay.
- Candidate04 `ending_balanced3440`: all 35 gameplay checks completed and exit was 0, but `Parameter "particles" is null` recurred in `particles_get_instance_buffer_motion_vectors_offsets` after receipt checkpoint load. **This is failed rendering evidence**, not a passing case. No clean rerun is substituted. The earlier Phase4 failure is also retained.
- A bounded source review found no new application-side particle destruction or live rain-mesh swaps at that recovery point. The exact caller/resource cause remains unestablished. The same-named upstream method identifies a missing particle lookup but does not establish this binary's root cause; source line numbering differs. Reference: https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp
- The separate owner ordinary-menu crash remains unresolved. No relationship to this renderer error is proved.

## Longer moving samples

Uncapped/vsync-off requests, ninety seconds of actual repeated walking along the front approach, isolated exact native viewport, no image readback during measurement. Complete production systems remain active. These are process-frame intervals, not GPU timestamps, foreground/minimum-spec certification or whole-game performance. Engine render memory is not total VRAM; the release static-memory monitor returned zero and is not treated as zero memory usage.

| Profile / size | Seconds | Median ms | p95 ms | Intervals >33.3ms | Median draws | Engine render MiB, first/last |
|---|---:|---:|---:|---:|---:|---|
| moving_balanced1440 | 91.64 | 1.279 | 12.960 | 2 | 543 | 375.6 / 375.6 |
| moving_balanced3440 | 91.69 | 1.451 | 12.813 | 0 | 594 | 423.8 / 423.8 |
| moving_enhanced1440 | 91.67 | 1.680 | 13.726 | 9 | 544 | 488.5 / 488.5 |
| moving_original1440 | 91.66 | 1.230 | 12.819 | 1 | 440 | 369.9 / 369.9 |

Earlier Phase4 stationary samples remain preserved; the longer moving workload differs, so a difference is not automatically a performance regression or gain. Stutters are reported rather than hidden.

## Ordinary launch observations

- ordinary_menu_01: process remained alive for 365.28s, owner files unchanged True. Normal owner settings and no QA flag. **Foreground observation inconclusive:** another application became visible and computer-use detected human input. Foreground automation stopped. The exact launched test process was intentionally terminated (exit 4294967295); this is neither normal Quit nor a reproduced game crash. The incorrect end capture is retained privately as invalid evidence and is not shipped.
- ordinary_menu_02: not run; foreground testing stopped to avoid interfering with human PC use. No passing claim.

Continuous foreground idle and normal Quit remain pending. No permanent crash-fix claim. Native automated profile checks use separate settings. PC coactivity was not controlled; a different 3D application was visible during the later idle observation, so performance numbers are bounded desktop observations rather than a controlled hardware benchmark.

## Delivery and limits

The private Windows ZIP, independently extracted executable verification, exact hashes, complete source ZIP, history bundle and safe GitHub development tag are recorded in the private `DELIVERY.json` after packaging. Earlier builds, experimental branches, source archives, raw licensed Assets inbox and owner data remain preserved.

Representative clips use real native sampled frames with wall-clock timing and game-bus audio; a 30fps encoding repeats roughly six captured frames per second. They are not full-frame-rate captures, subjective listening approval or evidence of human first-playthrough duration.

Human artistic approval, story comprehension, fear, emotional payoff, hardware-controller playtesting and 30–60-minute duration remain pending. The current Surveyor model is retained. No new character or content expansion is claimed.

## Independently extracted executable

The executable extracted from the private Windows ZIP completed 19 focused native checks; exit 0, logged errors 0, warnings 0, owner files unchanged True. This used isolated inputs and Balanced startup settings, not an uninterrupted ordinary foreground observation.

Executable SHA-256: `5f52261be8a8ee7ee0e37999d567744d287e81c821b39d0d0370ebf65ed64b09`. The final private delivery receipt records the Windows/source ZIP hashes and source tag.
