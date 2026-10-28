# UNLISTED — Sightline Continuity / 28 October 2026

**PRIVATE QA — STABILITY NOT CLEARED. NATIVE ACCEPTANCE FAILED.**

The new private ZIP is a diagnostic development candidate, not a replacement verified build or public release. A fresh impossible-room run crashed. The earlier build and all original evidence remain intact. No change to the active Surveyor artwork, engine, OS, driver, registry, BIOS or overlays.

## Changes in ordinary gameplay

- **Physical windows govern optical cover.** One shared sight query distinguishes explicitly marked transparent panes from solid walls, real wooden window bars/sills and actual transformed curtain cloth. Decorative frame boxes now participate in optics through their actual transforms and dimensions without adding or moving collision shapes. Glass continues to block bodies and physical attacks; hearing/navigation retain solid queries.
- **A watched presence stays present.** Authored body visibility now samples actor-local head, shoulders, hands and legs through the same optics. A face hidden by a mullion is not sufficient permission to remove the rest of a visible figure. Existing retreat/pursuit/save rules remain. Vent-specific crossing logic is unchanged.
- **Close window encounters stop empty grabs.** When the player remains visible behind a sealed pane at close range, the existing actor turns naturally and plays its living watch animation while keeping gravity and physical separation. Drawing the curtains breaks sight; it does not magically cancel the pursuit or resolve the encounter.
- **Controller crouching receives real cover benefits.** Suspicion uses the player's actual crouched posture rather than a raw held action. B-toggle and held crouch now produce the same 0.6 suspicion rate; standing retains 1.0. No new invulnerability or altered attack range.
- **The returned mug respects the witness.** The existing once-only contradiction checks the current and remembered placements through glass and cloth. Centre plus actual portable-box corners protect partial screen-edge visibility. A quiet, unseen, collision-safe return still works and stays consumed after save/load. No new compulsory puzzle or explanatory text.

The previously completed manual curtains, sewn tabs, transformed-room cover and movement-responsive ceiling contacts are retained. No new save schema, puzzle randomisation, canon, ending meaning, model or voice change. Eli and Simon's unresolved history remain intact.

## Exported Windows evidence

| Native scope | Assertions / failures | Result |
|---|---:|---|
| sight1080 | 26 / 0 | Bounded pass |
| sight1440 | 26 / 0 | Bounded pass |
| sight3440 | 26 / 0 | Bounded pass |
| threat | 58 / 0 | Bounded pass |
| house_remembers | 31 / 0 | GAMEPLAY PASS; RENDERING FAILED |
| ambient | 48 / 0 | Bounded pass |
| dread | 28 / 0 | Bounded pass |
| endings | 70 / 0 | Bounded pass |
| legacy60_sequential | 2 / 0 | Bounded pass |
| prebuilt60_sequential | 2 / 0 | Bounded pass |
| root150 | 1 / 0 | Bounded pass |

1080p uses Balanced, 1440p Original and 3440x1440 Enhanced. Actual screenshots were inspected at these dimensions. Candidate01 established 24 new fixture checks. Candidate02 adds better oblique/caption-free evidence, live idle-animation and edge checks. Its 1080p/1440p cases pass 26 checks. Candidate02 ultrawide failed the coarse one-degree edge sweep: the sweep could skip the tiny mug. Candidate03 replaces only that QA sweep with an exact frustum-boundary search; its ultrawide case passes 26 checks. Production gameplay is identical across these three exports. The failed run remains preserved.

Native fixtures exercise actual physics/input/controller events and save recovery. The ordinary threat suite includes detection, wall cover, pursuit, hiding, escaped windup, death/retry, story mode and visible retreat. Ambient/dread suites cover shared observation and quiet reservations. Both endings continue the previously naturally earned Phase5 investigation checkpoint; they are segmented earned-branch verification, not a new uninterrupted full route. A new full investigation was deferred after the native crash. Unchanged radio, UV/lightbox and original progression retain their baseline instead of repeating historical suites.

The final ZIP's independently extracted launch is recorded separately in DELIVERY.json. Native video uses sampled roughly six-fps frames at real wall-clock durations with repeated frames in a 30fps encode and actual game-bus audio. Fixture placements/camera changes are setup, not authored supernatural teleports. No physical controller hardware, human first-play comprehension/fear, subjective audio quality, artistic approval or 30–60 minute runtime claim.

## Fresh native failure: not shutdown, not a pass

Evidence02/impossible exited 3221225477 / 0xC0000005 after 64.062 wall-clock seconds. It did not time out, print a script error, receive a forced stop or reach its final report. Its last completed assertion restored the resolved room. The next scenario restored the active upside-down room and enabled the actual Surveyor. Last flushed captured phase: `separate restored scenario / Surveyor in active room`, 52.199577 seconds. The multi-resolution loop and cleanup had not yet been reached. Prior passing assertions do not certify the interrupted run. No new room-specific death/retry pass is claimed.

A new 61,495,882-byte Windows dump is preserved privately in CrashAnalysis. Offline CDB shows a READ access violation in nvoglv64.dll + 0xFAAA9F, with Vulkan loader and UNLISTED frames. That module offset matches the earlier retained Crash A report. It does not prove an identical cause, driver fault or a relationship to owner Crash C's null execution. Private engine/driver symbols are unavailable; the offending caller/resource is not established. No speculative rendering/default changes were made. The dump contains private process memory and is not pushed or included in the playable ZIP.

## Missing-particle error: no handoff is not a cure

Evidence02/house_remembers reproduced `Parameter "particles" is null` in `particles_get_instance_buffer_motion_vectors_offsets`, exact binary log line 759. The runner first observed it 5.547 seconds after launch, between printed closed-save recovery and curtain reopening. That is a polling observation, not an engine exception timestamp. All 31 gameplay assertions completed and exit was zero; rendering acceptance FAILED. This no-handoff occurrence rules out live viewport handoff as a required condition in this observed case. It does not identify the RID, the actual resource lifetime fault, or a relationship to either crash.

Same-Candidate01 uncapped Original-profile controls: root-window title, legacy handoff and prebuilt viewport. The root menu completed its nominal 150-second observation (about 165 seconds until the final assertion), without a QA AudioEffectRecord or continuous image readback; start/end snapshots retain five particle-related nodes and equal base RIDs. That is high-level scene evidence, not proof of renderer-internal ownership. The two 60-second legacy/prebuilt observations were rerun sequentially because the first launcher replacement briefly overlapped them. Those original clean logs are retained but excluded from controlled comparisons. The sequential pair also completed cleanly. Intermittent clean observations do not erase the new failures or clear owner-menu stability. Root-report legacy wording says copied owner preferences; this comparison actually used isolated Original-profile QA settings, as launch.json records. No owner preferences were used as evidence of a matched owner reproduction.

Review of actual weather/menu construction and save recovery did not identify a direct scripted particle deletion at the failure point. Without an instrumented matching native caller/RID trace, no safe resource-ownership repair has been demonstrated. Existing graphics, rain and menu atmosphere are retained. No retry was used to turn the crashed room test into a clean result.

## Recovery and use

Runtime source: 2b00921; ordinary gameplay source: 5689571. Entry private 543afb3 / public 6c0359c is protected by recovery/pre-sightline-continuation-20261028. Final private/public commits, new source tag, archive hashes, extracted-executable result and exact paths are in DELIVERY.json. All previous releases, complete raw Assets inbox, saves/settings and editable rejected art remain local and untouched. Source ZIP includes tracked playable game/consumed media, ignored authoring sources and preserved editable studies; the original raw asset inbox remains separately preserved.

Open EVIDENCE.html for screenshots, actual logs and native verification video. If launching the diagnostic candidate, extract the whole ZIP into a fresh folder first. Ordinary launch can use the existing owner save; this is not a request for manual testing. Preserve the earlier Windows candidate. No public release and no stability/quality/completion claim.
