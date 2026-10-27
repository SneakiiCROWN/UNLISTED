# UNLISTED — The Next Nightmare / private production pass

**PRIVATE QA — STABILITY NOT CLEARED.** Version remains v0.10.9-dev; public v0.10.0 and previous private builds are preserved.

## Player-visible changes

1. **Carried-object recovery:** saving with a mug, fitting or tool in hand records its actual pose and identity. Loading reacquires it only when it is within reach and clear of walls, actors and other objects. Unsafe/remote placements remain physical objects rather than being pulled through the house. Legacy saves without this field retain their previous dropped-object behaviour. Grip, rotation, release and throw physics remain the existing system.
2. **Surveyor listening:** a newly heard sound receives a short 0.65-second listening/turning pause before approach. Nearby repeated contacts do not continually restart that pose; a weaker competing noise cannot immediately erase a stronger recent source. Visible-player detection still wins. Noise never cancels an active pursuit. Hiding, attack warning, story mode, death/retry and the current model remain intact.
3. **Horror aftermath:** existing window taps, utility steps, overhead sounds and physical-object events reserve a brief quiet interval. The existing score fades down around their actual positional sounds and aftermath; weather and SFX remain audible and user bus settings are unchanged. Pause freezes the interval. Save/load preserves its remainder without replaying a spent event. Other optional responses wait rather than crowding the beat.

## Actual defects corrected

- Carried props previously serialized their original home, losing transported-object progress on loading. Reach/clearance checks now preserve safe carry continuity.
- Malformed nested physical data could reach typed array/vector operations. The checkpoint validator now rejects invalid prop containers, transform shapes, nonnumeric values and invalid carried identity types before live mutation. Physical restoration also tolerates bad direct fixture data safely. Valid and legacy saves remain accepted; this does not certify every possible future narrative field.
- Input-isolation QA now honours --evidence directly and writes its actual report there. The wrapper retains compatibility with older fixed-path builds. The new 14-check run confirms this without replaying the full investigation.

## Native verification

| Native case | Checks | Seconds |
|---|---:|---:|
| Evidence03/features1080 | 19 | 12.14 |
| Evidence03/features1440 | 19 | 11.7 |
| Evidence03/features3440 | 19 | 12.0 |
| Evidence03/input_report1080 | 14 | 7.09 |
| Evidence03/surveyor_regression | 58 | 114.59 |
| Evidence03/lifecycle3440 | 2 | 13.02 |
| Evidence04/physical_regression | 48 | 30.7 |
| Evidence05/ambient_regression | 48 | 26.95 |
| Evidence05/weight_and_support | 36 | 60.45 |
| Evidence05/endings1080 | 70 | 63.41 |
| Evidence05/lifecycle_original | 2 | 12.5 |
| Evidence05/menu_idle_original | 2 | 153.89 |
| Evidence05/recording_distraction | 44 | 82.31 |

These are actual Windows exports with isolated inputs/settings and protected owner data. Candidate03 covers the new features at 1080p, 1440p and 3440x1440, plus hearing/hiding/attack regression and particle tracing. Candidate04 changes only the obsolete carry-home assertion and dependent bench fixture. Candidate05 changes only ambient test scheduling to respect the new quiet interval. Production code is unchanged across those three candidates. Native animation, physics, controller events, files and screenshots are exercised; these are segmented fixtures, not human playtesting or a fresh uninterrupted investigation.

The earlier Phase5 fresh 428-check investigation remains the route baseline. Both endings are rechecked here from that naturally earned checkpoint, including receipts, car departure, pause/save recovery and View Ending. Rendering geometry/shaders/profiles are unchanged; previous moving-performance samples are retained rather than claiming a new benchmark or gain. Sampled QA frame timing includes capture overhead.

## Failure evidence retained

- Candidate02's drop-distance assertion mistook normal falling for failed release. Its original 18-pass/1-fail result remains. The corrected test checks actual release into physics.
- Candidate03's old physical suite expected a carried tool to return home on load; its dependent bench fixture consequently began from the wrong location (46 pass/2 fail). Updated coverage positively checks the retained tool/grip and independently resets the bench collision fixture.
- Candidate04's old ambient suite attempted back-to-back events during the newly preserved quiet interval (43 pass/4 fail). The corrected fixture first proves the reservation blocks that request, then waits the real interval before testing the next event and physical tin fall.
- None of those historical results is rewritten or counted as a passing run. Older Phase5 renderer failures, dumps, bundles and owner-crash evidence remain preserved.

## Stability investigation and limits

The retained forensic report distinguishes owner Crash C (null execution after approximately 110 seconds), the earlier Vulkan read fault and the separately repaired QA recorder fault. No new dump establishes the owner crash's caller. No engine, driver, Windows, registry, BIOS or overlay change was made.

The new diagnostic takes 38 particle snapshots around twelve completed-ending/title/earned-porch recovery cycles. In the Balanced ultrawide run, the same three live nodes (far rain, near rain, title mist), their base handles and draw meshes survived unchanged. Original is checked separately. The trace is high-level ownership evidence, not proof that an opaque RID still has valid renderer-internal storage. It does not identify the missing RID from the earlier native error or establish an upstream fix. Known particle failure remains unresolved even when these runs are clean. No weather system is removed as a guess.

The 150-second title observation is isolated/off-screen. It is not an uninterrupted ordinary foreground owner test. Foreground idle, physical Alt-Tab/quit and real controller hardware remain pending because prior foreground automation encountered active human PC use. Actual in-game Quit callbacks are used by the native tests. A nonreproduction is not a permanent stability fix.

## Owner guide and remaining work

Extract the entire private ZIP into a new folder and run UNLISTED.exe. It is the ordinary full game: no test actors, automatic puzzle solutions or forced overlays on normal launch. Settings > Display > Property atmosphere retains Original as default; choose Balanced or Enhanced and fully quit/relaunch to apply it. Use Settings > Input for current controls. Previous saves/settings and accessibility options remain available. No manual testing is requested as a prerequisite for continued development.

Human fear, artistic quality, story comprehension and first-playthrough duration remain unverified. Highest remaining priorities: resolve the two intermittent stability faults with reproducible evidence; obtain uninterrupted foreground coverage when feasible; continue first-player narrative/environment review and the separately approved character-art work without inserting rejected studies. This pass refines existing content rather than claiming a completed full game or longer human playtime.

Exact file changes, hashes, source checkpoints, the complete private source ZIP and Git history bundle are recorded in the private delivery folder. No public Windows release.

## Independent extracted launch

The executable independently extracted from the new Windows ZIP completed 19
native startup/menu/arrival/profile/pause/controller/save checks, exit0, with no
logged errors or warnings and unchanged owner files. The selected executable's
hash matches the packaged Candidate05. This remains isolated automation, not
ordinary foreground stability clearance or human artistic approval.
