# UNLISTED — Project Health, 29 October 2026

**PRIVATE QA — STABILITY NOT CLEARED. No public Windows release.**

Entry9c130cb and recovery/pre-project-health-20261029 preserve the complete previous source. Original Assets inbox, licences, Blender sources, saves, old builds and all rejected studies remain intact. No files were deleted or moved.

## Implemented corrections

- Invalid ConfigFile types and non-finite values now fall back to the relevant defaults before casts or typed UI assignments. Invalid resolutions fall back without rewriting the owner file. Valid legacy settings retain their old values. The old loader's float(Dictionary) error was reproduced in an isolated headless fixture; it is not claimed as the cause of the owner's native crash.
- Checkpoint validation rejects malformed door booleans and non-finite/non-numeric swing angles before live restoration. Schema1, optional legacy fields and valid save meanings remain unchanged.
- Interaction prompts are assembled before assignment, removing the blank-then-refill cycle. Controller/keyboard prompt textures preload once and change only when input type changes. Stable cover strength no longer resubmits an identical shader uniform.
- Accessibility material scans now run when window motion changes, rather than on every audio/sensitivity refresh. Real window uniforms and both input icons are verified by focused native checks.
- Equal immutable BoxMesh geometry is shared by size. Nodes, per-instance materials, transforms and collision shapes stay individual. No current caller mutates a returned box mesh. Any future caller that edits geometry must duplicate first. This permits existing renderer instancing without removing furniture or reducing visual quality.
- A NEW Windows Player QA preset omits rejected character-study assets. Both previous presets and their showcase builds remain available. Explicit study flags are refused in this player build before world construction. Runtime Phase2 reflection resources remain included.

## Audit and inventory scope

All130 current game scripts were loaded and compiled by the all-script audit. Active movement/interaction, Surveyor, props, save/load, menu/settings, atmosphere and impossible-room paths received targeted source review and relevant native regression. This is not proof of every possible runtime branch. The conservative literal dependency scan found no missing active runtime file; its one missing candidate is a generated settings file used by a development tool. Dynamic path construction is explicitly outside that scan's proof.

Read-only inventory:346 asset files,150,553,987 source bytes;637 external-library files totalling10,071,619,452 bytes. GLB JSON/accessors, mesh/material/joint/animation inventories and ZIP central directories were inspected. Twenty exact-content duplicate groups are retained because importer identity, dynamic references and attribution differ. No filenames alone justified deletion. Existing texture limits, filtering, audio formats, loop settings, geometry, lighting, weather and character artwork are preserved. No claim of visual character-art improvement or final audio listening approval.

## Before/after measurements

An uncapped native fixed-view probe samples menu, gate arrival, front, woodland, shed, lounge, office, cellar and saved impossible room in all three graphics profiles. Screenshots occur outside measurement. Reports include average/median/p95/p99 frame intervals, engine process/physics time and draw/primitive/resource monitors. These are short placed views, not first-playthrough timing or complete-game/minimum-spec performance. Another game may be running; hardware, drivers and system settings are unchanged. Engine static-memory counters returning zero mean unavailable in this release, not zero memory usage; no direct GPU timestamp or total-VRAM claim is made.

The first optimized player export is17,945,808 bytes smaller than the baseline140,997,920-byte executable, by excluding study assets only. Final exact bytes and hashes belong in DELIVERY.json. Thirty real native unchanged-settings refresh calls improved from54,473 microseconds to969 microseconds in the first comparison; this is narrowly scoped synchronous refresh work, not a whole-game FPS claim. Mesh-sharing draw-call comparisons and final acceptance results are in the private evidence directory.

## Failures preserved and corrected

Validation02 exposed two missing explicit types in the new QA probe. Its failed build/logs remain preserved. Validation03 then exited with0xC0000005 after a failed mesh-contract assertion. Private dump11464 records a null-class pointer read at engine RVA0x16594e4; it is distinct from the earlier Vulkan-module fault and particle-owner error. The fixture passed a Node where the box constructor requires Node3D and used exact float equality for primitive size. A proper Node3D holder and approximate size comparison fix those fixture defects; the corrected standalone contract and native43-check validation pass. This does NOT establish that those defects caused the native AV or resolve any historical crash. No failed evidence was replaced or counted as passing.

## Native stability and remaining limits

The original idle-menu null execution, particle-owner rejection and impossible-room Vulkan access violation remain unresolved. All preceding dumps, the real-error late-attach stack and native-owner analyser are preserved. No error is suppressed and no graphics system disabled. The next discriminating particle experiment still requires full private memory AFTER a matched real owner rejection. Do not interpret a clean QA observation, build-size reduction or changed allocation layout as a native crash cure. No hardware/driver/Windows diagnosis is established.

Focused settings validation passes43 checks with owner hashes unchanged. Final profile, integration, room, pursuit/retry and earned-ending checks are recorded separately; no fresh uninterrupted full investigation or human artistic/story approval is claimed. All automated runs stay muted, off-screen and input-isolated while the owner uses the PC. New source remains a development candidate until the selected final Windows package is independently extracted and checked.

Private detailed inventory, cleanup manifest, native results, screenshots, performance samples and original failures: Checkpoints/20261029_project_health. No process dump or licensed raw asset is pushed to public GitHub. Final checkpoint, package hashes and source-backup locations are recorded in that directory's DELIVERY.json.

## Final selected candidate and verification

Selected runtime6b9f3b6 / Candidate04, executable SHA25651a23882a8c8a85b55f3d7e9aaa4675ab4432029d150619798b6c07442eec173. Final executable123,052,672 bytes versus140,997,920 baseline:17,945,248 bytes smaller (about12.7%). Every one of346 source-asset hashes still matches the pre-edit inventory. Player-only art-flag negative control exits95 with ART_STUDY_NOT_PACKAGED before world construction, preserving owner files; this intentional refusal is not a game crash.

| Controlled workload | Before | Final |
|---|---:|---:|
| Thirty settings refreshes, Balanced |54.473ms|1.278ms|
| Original menu draw calls |15,582|12,363|
| Original front approach draw calls |14,742|11,359|
| Balanced menu draw calls |15,799|12,771|
| Balanced front approach draw calls |14,591|11,474|
| Enhanced front approach draw calls |14,590|11,473|

Front-view primitive counts are unchanged in all three profiles. Tracked engine rendering allocation at menu falls by664,336 bytes; this is not a total-RAM/VRAM claim. Raw per-view averages, medians, p95/p99 frame intervals and process/physics monitors are in PERFORMANCE.csv and HEALTH_COMPARISON.json. Frame-time comparisons are variable under concurrent MW4 load, so no guaranteed aggregate FPS improvement is asserted. The remaining roughly12k menu draw calls warrant future measured work; this pass does not pretend rendering is fully optimised.

Selected final native results:43 health checks; all three nine-view profiles pass;1440p integration19 checks;3440x1440 impossible-room transformation, physical contact, save/load, death/retry and recovery52 checks; both earned ending branches70 checks at1080p from an existing naturally earned investigation source. All selected results exit0 without logged errors/warnings and with owner hashes unchanged. Their coverage is segmented, not a fresh uninterrupted full investigation. Native captures reviewed include matched front/porch views and cellar; further screenshots remain inspectable in EVIDENCE.html. Original and all newly failed logs/builds remain separate. Independent extraction/launch results and final backup hashes are recorded in DELIVERY.json after packaging.

No new foreground menu stability clearance, final vocal design, human listening review, broad narrative rewrite or Surveyor-art acceptance is claimed. Foreground matched full-memory crash reproduction remains deferred while the owner is using MW4; background tests cannot replace it. Immediate priorities: obtain the rejected native RID and owner history; analyse the preserved new null-class dump separately; run a controlled GPU/working-set profile when the PC is otherwise idle; extend semantic branch coverage and physical clue/readability checks without rewriting working systems.
