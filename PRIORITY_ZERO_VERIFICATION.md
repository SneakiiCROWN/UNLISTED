# Priority zero: ordinary main-menu crash investigation

26 October 2026. **Unresolved crash; diagnostic candidate, not a repaired release.**
No new game content, version bump or public Windows release. Normal startup still
uses the existing 3D title, audio, full world and arrival. Experimental deferral is
an explicitly selected diagnostic scene, never the normal entry point.

## Actual owner failure

The preserved PID 5300 dump matches the owner's ordinary menu crash at about
110 seconds. It records an execution access violation at RIP 0 on the main
thread. Its unwind contains invalid-looking return addresses, including 0x5a0;
there is no trustworthy responsible native caller. Nearest-export labels are
not function identifications. No script error precedes the failure in the log.
This exception differs from the older NVIDIA ICD invalid read and the separate
fixture's null-object read; a shared cause is unproved.

The ZIP-launched temporary executable has gone, so its exact full-file hash
could not be recovered. The retained delivered executable matches its sealed
hash. Launching from Explorer's compressed-folder view is an observed difference,
not a demonstrated cause. All dumps, events and original logs remain private.

## Source and engine findings

The actual private source still constructs the complete world and gameplay
subsystems before showing the title. Presentation and MenuStage process while
the game is paused. Title wind/drone playback restarts, the 27-second creak and
47-second silhouette cycle were confirmed. These operations are hypotheses,
not identified defects. No invalid receiver/lifetime was established in them.

The local fresh template archive's SHA-256 matches the official release digest.
Its Windows release template matches the installed template byte for byte.
The retained delivered executable's native `.text` matches that template.
No template/native-code corruption was found in these retained files.
This does not independently authenticate the vanished owner temporary image.

The release metadata has no matching Windows PDB asset, and the inspected native
image has no usable embedded CodeView signature. Android symbols cannot identify
Windows operations. The unavailable trustworthy caller and absent reproduction
are the current blockers to an evidence-based production correction.

## Native evidence completed before component isolation

| Case | Duration | Observed result |
|---|---:|---|
| Original delivered, fully extracted v0.10.9, ordinary startup | 625.28 s | Title remained present; actual Quit button; exit 0 |
| Preserved fully extracted v0.10.6, equivalent owner preferences | 715.31 s | Title remained present; actual Quit button; exit 0 |
| Original delivered v0.10.9 under armed CDB AV observation | 855.25 s | No first-chance AV or unhandled AV; actual Quit; debugger exit 0 |

The first two launches used only the engine log-file argument: no QA mode,
renderer override, frame cap or subsystem removal. The third is instrumented
and cannot be counted as an ordinary uninstrumented run. Foreground title views
were inspected at the beginning/end, not continuously monitored system-wide.
Owner checkpoint and settings hashes were unchanged in every completed case.

First debugger setup 01 was stopped at 265 seconds because its initialization
filters were not armed. It remains failed setup evidence, not an AV-free pass.
Corrected setup 02's `sx` table proves first/second-chance AV callbacks were armed.
Its quoted backslashes were stripped from dump paths; no AV occurred and no dump
was generated. The repeatable helper now uses forward slashes and unique private
output directories. An actual exception-triggered dump write remains unexercised.

## Controlled comparisons and deferred-world diagnostic

Native export: `Builds/UNLISTED_Priority_Zero_Diagnostic_04/UNLISTED.exe`.
Clean import/export passed; exact arguments, executable fingerprints, logs,
screenshots and private-data integrity receipts are retained beside each case.

The serial component cases are: full; Presentation audio disabled; GroundMist
not allocated; title silhouette model not allocated; title camera/tree/porch
animation stationary; 2D UI with the full world hidden and particles stopped.
The last case still constructs the world. Audio/mist/model/animation exclusions
are explicit QA-only flags. Other world geometry/resources remain unchanged.
The root-window input guard and private writes distinguish these from an
ordinary owner launch. The helper removes its initial command-line frame cap
before the timed interval; no repeated resolution loop or SubViewport is used.
Per-operation before/after traces cover audio restarts, creaks and silhouette
visibility transitions, including the owner's approximate 110-second interval.

The separate nondefault deferred entry starts without constructing the world,
then loads the original main scene/New Game arrival and checks pause/resume,
private save/load and return to title. This comparison is not a promoted menu
replacement or an engine fix. Consult current raw reports for completion;
consolidated final results will be appended after the cases finish.

## Limits and preservation

Successful repeats do not eliminate intermittent native corruption. No root
cause or minimal production fix has been established, and there is no valid
before/after repair comparison. Static-memory monitor values of 0 in a release
build are unavailable measurements, not evidence that memory is unused.
Stable node/object counts alone cannot exclude memory corruption.

No Windows, driver, registry, BIOS, overlay or unrelated-application setting was
changed. Original builds, complete licensed source, raw assets, owner saves and
settings remain intact. New source is recoverable in private Git and only safe
code/documentation goes to the existing public repository. No public release.

Unchanged gameplay test evidence remains in the previous Player Experience
delivery; it is not relabelled as fresh testing of this candidate. No unrelated
full-route suite, art replacement or new content was performed during this pass.

Primary references: [official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable),
[exception-filter behavior](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/sx--sxd--sxe--sxi--sxn--sxr--sx---set-exceptions-),
[dump commands](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-dump--create-dump-file-).

## Completed component comparison / export 04

| Case | Menu clock at final sample | Result |
|---|---:|---|
| All title features enabled | 150.2 s | exit 0; title retained; owner data unchanged |
| Title sound playback disabled | 150.18 s | exit 0; title retained; owner data unchanged |
| GroundMist not allocated | 150.19 s | exit 0; title retained; owner data unchanged |
| Title silhouette model not allocated | 150.19 s | exit 0; title retained; owner data unchanged |
| Title camera, trees and porch animation stopped | 150.2 s | exit 0; title retained; owner data unchanged |
| World hidden; UI only, particles stopped | 150.16 s | exit 0; title retained; owner data unchanged |

All recorded before/after operation trace pairs completed. These are bounded
component experiments, not evidence that any omitted component caused the owner
crash. Every case exceeded the reported 110-second failure interval. Full-world
node counts remained constant in sampled intervals; that does not prove memory
safety. Exact operation counts and object ranges are in operation_summary.json.

The first deferred entry failed immediately because the official Windows release
template disables command-line scene-path overrides. This was a diagnostic launch
error, not the owner crash; its logs remain under export04/QA/deferred. Export05
adds an explicit two-flag early entry before world construction, guarded by a root
marker so original New Game initializes exactly once. No flag selects it during
normal startup. Other runtime resources and title component code are unchanged.

## Completed deferred-world comparison / export05

The explicit deferred diagnostic completed in152.11 seconds, exit0, no logged
script/runtime errors. Its initial minimal title had10 nodes and remained
without the gameplay world until the135-second New Game request. The original
rainy arrival then ran; native screenshots show both the minimal title and
original arrival. Player control, actual Resume button callback, private
save/load and return to the original title were confirmed. Owner data was
unchanged. This is a segmented diagnostic recovery check, not ordinary gameplay
or a repaired-build acceptance run. No deferral was enabled for normal startup.

The new private Windows package will be extracted and launched ordinarily for
an additional bounded idle check. Its final result is recorded separately in
the delivery receipt; a new package alone does not establish a crash repair.
