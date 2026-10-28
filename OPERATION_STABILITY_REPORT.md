# UNLISTED — Operation Stability / 28 October 2026

**PRIVATE QA — STABILITY NOT CLEARED. No game-native crash fix has been demonstrated.**

This is a forensic/instrumentation milestone, not a claim that UNLISTED is reliable or complete. The active Surveyor, art, graphics profiles, puzzles, physics, saves and both endings remain unchanged. Original complete source 90be6a3, previous Windows builds, licensed assets and source history are preserved; recovery/pre-operation-stability-20261028 protects entry. Runtime of the new package: b530e0f. No public release.

## What the evidence establishes

| Requested problem | Evidence / current conclusion |
|---|---|
| A — original idle-menu disappearance | Retained owner dump records attempted execution at zero, around 110 seconds. Earlier caller reconstruction was inconclusive. This session's ordinary foreground menu remained responsive for 380.407 seconds and exited through the observed Quit button. That does not clear an intermittent crash. |
| B — rejected particle owner | **Reproduced in an ordinary foreground launch without QA flags, QA recorder or viewport handoff.** The same process continued and quit normally. This is a rendering failure, not an access violation, and it is not confined to our harness. Precise first onset is not known; the first explicit observation is separately timestamped. |
| C — impossible-room native crash | Preserved 64.062-second failure reads through an invalid pointer in nvoglv64.dll + 0xFAAA9F, with Vulkan and engine frames. That matches the historical Vulkan-fault module offset, not a proven root cause. Its multi-resolution loop/cleanup had not been reached. This session's direct native room run and corrected debugger run completed; those observations do not undo the original crash. |

A, B and C are not proved to share a cause or to be independent. B can occur without a crash. The historical report called the Vulkan fault Crash A and the owner null execution Crash C; the table above uses the CURRENT request's lettering.

An additional competing explanation must remain open: while UNLISTED was absent, the read-only PE-analysis workload generated inconsistent internal Python errors and native faults in two installed interpreters. Preserved Python3.12 dump: execution at zero inside its evaluator; Python3.14 dump: invalid read at FFFFFFFFFFFFFFFF in PyObject_Vectorcall. These are separate from Godot and do not prove a CPU, RAM, OS, driver or runtime cause. Small standard-library byte-search controls passed in both; two child-only scheduling controls also passed. No permanent affinity or game workaround was installed. No WHEA event was found in the bounded query; absence of an event is not hardware clearance. Raw dumps and process/module logs stay private.

## Confirmed QA defects repaired

1. **Evidence disappeared when the process could not finalize a report.** Completed assertions now flush to checks_live.jsonl. The explicit resource observer catalogs application-visible instance/base RIDs, snapshots particle/camera/world/room/threat context and streams emitter add/remove observations. It introduces no resource setter, render pass, audio effect or player-file write. Tree signals disconnect before streams close. A deliberately terminated OWNED isolated QA child retained valid check and resource records without a final report. This was an INJECTED termination, not a new game crash.
2. **The first native breakpoint did not arm.** CDB initially used the renamed filename as module name; this live image exposed its internal template name. The corrected helper resolves its own child's image base through the x64 PEB and checks native instruction bytes before arming. Wrong bytes refuse setup rather than attaching to an unknown target. Software breakpoints affect only that diagnostic process, not engine files. All original failed setup evidence is retained.
3. **Debugger delay looked like an AI obstruction.** The old contact fixture spent its 18-second wall budget after only108 pursuit physics ticks (1.8 seconds). The normal passing run used209 pursuit ticks (about3.48 seconds). The fixture now preserves its intended18 simulated seconds with a separate60-second wall cap. The corrected debugger run completed capture, death/retry and recovery:52 checks, zero failed; it used209 pursuit ticks, matching the native run. No AI, navigation, collider, furniture or gameplay timer was changed.

## Native operation and new capture tools

The pinned [exact engine revision's particle getter](https://github.com/godotengine/godot/blob/ed1daf0bf/servers/rendering/renderer_rd/storage_rd/particles_storage.cpp#L757) fails its owner lookup at line759; its [Forward+ caller](https://github.com/godotengine/godot/blob/ed1daf0bf/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L577) uses a particle-flagged geometry base. String reference, PE unwind range0x28329c0..0x2832aa6 and loaded error-branch bytes at RVA0x2832a2c identify the operation in this installed release template. This does not identify WHY the requested ID is invalid.

The explicit --resource-trace QA observer supplies a future ID catalog. tools/capture_particle_owner.py supports bounded early-debugger menu, room, curtain and lifecycle captures, preserving owner hashes and refusing another running game. Existing instrumented reproductions did not hit the rejected-owner branch. Debugger startup took longer than ordinary startup; handled C++ exception notifications are not classified as native crashes. GetterOrdinary03 reached the menu and quit normally after261.009 seconds; that was a debugger observation, not another uninstrumented idle pass.

Because startup debugging changes conditions, **--particle-error-hold is an isolated-QA-only diagnostic**, registered before geometry construction. A mutex-protected Logger writes errors without scene access or recursive logging. Only the exact particle-storage error causes one explicitly labelled15-second hold, allowing --attach-on-particle-hold to attach AFTER the failure and save its native stack, then detach. Normal play never registers this logger. Root and viewport observations did not trigger the error, so the real-error hold/late-attach path remains **UNEXERCISED**, not proven. A separate native Windows headless control verified registration/journaling of an intentionally injected warning without activating the hold; it is not a renderer reproduction or gameplay acceptance.

No evidence justifies masking the error, disabling rain/mist, replacing the engine, changing drivers/Windows/BIOS/registry, or promoting an affinity workaround. No such change was made.

## Actual exported coverage

| Native Windows case | Seconds | Assertions / failed |
|---|---:|---:|
| Acceptance01/sight1080 | 20.676 | 26 / 0 |
| Acceptance01/curtains1440 | 16.965 | 31 / 0 |
| Acceptance01/sight3440 | 21.164 | 26 / 0 |
| Acceptance01/impossible_native | 68.383 | 52 / 0 |
| Acceptance01/endings | 62.960 | 70 / 0 |
| LateRoot07 | 137.713 | 1 / 0 |
| Lifecycle08 | 13.063 | 2 / 0 |

Candidate02 supplies the three display/profile fixtures:1080p Balanced,1440p Original and3440x1440 Enhanced. They cover real curtain input, transformed cover, glass/frame/solid separation, watched bodies and props, crouch parity, movement-led overhead response, pause and saves. The direct room run includes transformation/reversal, props, physical pursuit, death/retry and recovery. Both departures continue the preserved naturally earned investigation checkpoint; this is segmented ending coverage, not a new complete investigation or human comprehension test. Existing58-check ordinary threat coverage remains the unchanged baseline.

Candidate03 adds only the optional diagnostic logger; Candidate04 changes only the QA contact deadline. Ordinary gameplay/assets/rendering are identical across the current exports. GetterImpossible06 uses Candidate04 and completes52 checks in134.209 seconds under the verified breakpoint. LateIdle05 lasted48.820 seconds without a recorder and did not trigger the hold. LateRoot07 used an isolated COPY of the owner's preferences, normal root Window, uncapped rendering and input guard; its137.713 seconds and no-error log are bounded observations. OrdinaryMenu01 is the separate no-QA foreground run that DID log the error. It must not be counted as rendering acceptance passed just because its exit code is zero.

Lifecycle08 traces12 repeated earned-save/title/porch recovery cycles at ultrawide Enhanced. Application-visible particle nodes/base RIDs are stable and no new emitter creation/removal was seen in the inspected recovery traces. Scene handles do not certify renderer-internal lifetime. Recorded frame gaps include screenshot readback/debugger/desktop effects and are not a minimum-spec benchmark. Native screenshots and sampled wall-clock video retain actual game audio. Fixture placements are verification setup, not newly authored teleports.

The independently extracted ZIP check and exact source/public/tag identities/hashes are recorded in DELIVERY.json. All owner save/settings hashes remain unchanged. Human hardware-controller testing, story comprehension, subjective audio/artistic quality and fear remain pending.

## Remaining defects and next experiments

- A, B and C remain unresolved. No source-only native fix is claimed. The rejected RID/caller context was not captured; no causal connection is established with the independent interpreter faults.
- Next useful capture: register the narrowly targeted error logger on an ordinary-root diagnostic with cloned owner data, preserving normal startup until the actual error, then attach. This is different from indefinitely rerunning clean early-debugger tests. If a bad ID is obtained, classify it against the instance/base catalog and matching native caller before changing ownership code.
- The unrelated interpreter native faults warrant a separate known-good-machine/control comparison before treating every native failure as game content. No external machine test or system repair was performed.
- Keep all failures, the old wall-clock fixture result and injected controls separate. Do not repeat unrelated radio/UV/lightbox suites or redesign the Surveyor to pursue this issue.

Extract the private ZIP into a fresh folder to inspect EVIDENCE.html and the recording. It is a diagnostic candidate, not a replacement stable release or a request for personal playtesting. Complete source includes consumed media and preserved editable art; the original raw Assets library, player files, old builds and dumps remain separately untouched.
