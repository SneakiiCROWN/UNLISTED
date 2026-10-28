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
