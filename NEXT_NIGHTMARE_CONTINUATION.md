# UNLISTED — Next Nightmare continuation, 29 October 2026

**PRIVATE QA — STABILITY NOT CLEARED. No public Windows release.**

Entry43bcaec / dev-project-health-20261029 remains preserved. Recovery/pre-next-nightmare-20261029 protects entry. Existing optimisations, source assets, saves, both endings and previous private/public builds remain intact. The active Surveyor is unchanged; no rejected artwork is promoted.

## Validation03: specific cause established

The original Project Health dump11464 reads0x198 with RCX=0 at native engine RVA0x16594e4. A separate minimal Windows release project now reproduces that exact fault and instruction488b8198010000 with an identical native .text hash. Its source has no owner save/settings files, game UI, weather, Surveyor, rendered Vulkan scene or QA audio recorder.

The old fixture passed a plain Node to world.box's Node3D-typed parent. Release execution returned null constructor results. Comparing two null .mesh values falsely passed the sharing assertion; queue_free on the null result then caused the matching native access violation. The minimal log stops at REPRO_BEFORE_FREE, and the native dump confirms the same null-this read.

Controls: correct Node3D parent exits0 with two valid, separate instances sharing their intended mesh. Wrong parent plus an explicit validity guard exits12 cleanly. Wrong parent plus the original unguarded free exits0xC0000005. Original and new dumps/logs are private and preserved. The main health fixture now checks actual instance validity before any property access/free. Its corrected parent was already present in the secured Health build; this milestone establishes why the crash happened and adds defence against false-positive/null-result tests.

The previous suspicion about exact primitive-size equality was not demonstrated as a cause: the valid minimal control also passes the exact comparison. Approximate comparison remains a sensible test tolerance, not a native-crash repair.

This explains Validation03 only. Earlier idle-menu RIP0, particle-owner rejection and Vulkan-module access violation are not claimed fixed or proved independent.

## Player-facing improvements

1. Placement prompts now use the same reach, upright-start, swept-path and endpoint collision rules as the actual action. A ray hitting a tabletop is no longer enough to advertise Put down when the object cannot fit. Same-physics-frame identical UI queries reuse their plan; the actual action ALWAYS recomputes against live collision. Release/throw behaviour, individual bodies, masses, collision masks and saves remain unchanged. The one-time carry reminder now describes place OR release.
2. Manual torch winding respects the existing free-hand battery rule. Carrying cannot secretly wind the backup; carrying STILL drains a lit torch normally. Picking up an object interrupts winding without granting charge. A brief existing battery meter displays actual winding progress and charge after completion. Existing3.2-second duration,25% backup, spare inventory, pause and accessibility rules remain intact.
3. Locked-cellar feedback refers to an unsuitable key only when Eli actually has it. Otherwise he observes the small keyhole. A quiet positional latch supplies physical feedback. No destination hint, new key or progression change is introduced.

Focused native1080p checks pass23, including the actual shed bench, a labelled temporary collision blocker, real pickup/placement, charge drain while carrying, real winding progress/pause/cancellation/save-load and pickup interruption. These are placed fixtures with actual input, not a human first investigation. No scene is changed to improve screenshots.

## Remaining renderer investigation

Existing late-attach stack and owner analyser are retained. A NEW explicit --native-capture-background option keeps the ACTUAL root Window/world (no QA SubViewport or reparenting), rejects app-local input and quits through the real title button after its controlled duration. Owner preferences/checkpoint are copied; background mode changes only copied display mode to windowed and master audio to mute. It never changes the owner's files, desktop input, drivers or Windows settings. Root position/no-focus and input isolation differ from foreground-owner use and are labelled accordingly. Full private process memory is requested only AFTER the exact real particle error. No constant debugger, audio recorder or repeated image readback is added.

This is a discriminating root-versus-QA-viewport capture attempt, not another unchanged foreground observation or a crash cure. Runtime and trigger results are recorded in RootCapture; failed/suppressed reproduction does not exonerate the resource path.

## Verification and delivery boundaries

Reuse the complete Project Health three-profile draw-call/primitive-count and build-exclusion baseline where unchanged. New relevant native checks cover all three sizes, keyboard/controller, reduced motion, placement and carried saves, torch exchange/winding, windows/curtains, impossible room, retry and both earned endings. Segmented cases are labelled; no new uninterrupted investigation, human fear/comprehension approval or 30–60-minute duration is claimed. All new runs remain muted and off-screen. Native sound playback/state can be checked, but subjective listening is pending.

Detailed source changes, source/executable hashes, test results, screenshots, sampled native recording, complete private source/history backup and verified safe GitHub checkpoint/tag are recorded in Checkpoints/20261029_next_nightmare/DELIVERY.json after final acceptance. No public release. Next priorities remain the rejected native RID/owner history, sustained ordinary play stability, then coherent investigation and authored horror quality without replacing the working Surveyor prematurely.
