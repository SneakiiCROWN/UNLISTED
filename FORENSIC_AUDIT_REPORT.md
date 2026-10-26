# UNLISTED forensic recovery — 26 October 2026

**Active investigation, not a stability-cleared release.** Runtime source is
`4d6e32c`; subsequent inventory/report changes do not change that executable.
The owner's ordinary idle-menu crash remains unresolved. No public playable
release, system settings, driver, BIOS, registry or overlay changes were made.

## Findings, in priority order

| Status | Finding and evidence | Action / limit |
| --- | --- | --- |
| Unresolved, high priority | Owner Crash C: main-thread attempted execution at zero after 110 seconds. Original dump/WER preserved. Reliable caller could not be recovered from the available stack. | No root-cause claim. Retained candidate is identified, but the owner's vanished temporary ZIP-launched executable cannot be independently hashed. |
| Confirmed, repaired QA defect | Crash B: two controlled original-fixture reproductions read through null RCX at executable RVA `0x24662f5`. Unwind function bounds and strings within that function identify `AudioEffectRecord::set_recording_active(false)`. | `scripts/recording_repair_qa.gd:460` checks validity before the native call, reports missing capture setup and exits 92. Initialized recorder path completes. This recorder is absent from ordinary owner startup. |
| Unresolved | Crash A: invalid read in NVIDIA Vulkan ICD `nvoglv64.dll+0xFAAA9F`, with Vulkan frames in the actual exception stack. | Driver presence does not establish driver fault. Live-resizing capture fixture is a suspect condition, not a demonstrated cause. No private engine/driver symbols available. |
| Confirmed, repaired save defect | `{"schema":1,"pos":7}` reproduced `.size()` on a float in title checkpoint availability. | Shared `scripts/world.gd:1354` core validator is used by menu availability (`presentation.gd:340`) and load before live mutation. Modern and minimal legacy checkpoints remain accepted. File is left untouched on rejection. Deeply nested future narrative data is not fully certified. |
| Confirmed redundant work; hardened | Settled title/weather gains were assigned every frame; the engine forwards unchanged volume writes into native bus-data replacement. Weather inherits always-processing mode. | Equality guards in `presentation.gd:892` and `exterior_weather.gd:114` retain crossfades. Reduced churn, **not proof of fixing Crash C or an upstream audio race**. Spatial audio still updates normally. |
| Confirmed diagnostic failure; repaired | First reproduction's `/ma` dump aborted on inaccessible memory, error 299. | `/mA` captured a separately validated 2,375,408,662-byte first-chance dump. Unreadable pages may be omitted; raw dump remains private. |

Exception module names, overlay presence and nearest exported symbol names are
not sufficient attribution. Old RIP0 cases are not automatically the same bug.

## Coverage and its limits

Evidence root: `../Checkpoints/20261026_full_forensic_audit/`.

| Scope | What was actually checked | Result |
| --- | --- | --- |
| Initial code inventory | 125 GDScripts, 16 shaders, 8 scenes, 108 Python tools; all text mechanically scanned, Python AST parsed, 532 literal resource edges recorded | No initial Python syntax errors. Mechanical coverage does not mean every line received manual semantic review. |
| Current resource parsing | Godot 4.7.2 loads scripts/scenes/themes/shaders; current runner excludes itself | 153 resources, no reported parse failures. Headless shader load is not GPU compilation proof. |
| Imported assets | 275 assets loaded; 104 GLBs checked for container bounds, hierarchy, finite mesh/bone transforms and animation targets | No structural faults, missing import outputs or stale source MD5 found. Not artistic approval. |
| Raw library | 635 files / 9,731,315,066 bytes hashed; 39 ZIPs CRC/path checked without extraction | No ZIP CRC/path failures. Non-ZIP archives are hash-indexed, not format-certified. Licence filenames alone do not approve reuse. |
| Release packs | Crash A, B, retained C candidate, diagnostic05 and forensic02 embedded PCK directories, content MD5 and bounds | No detected pack integrity errors. Forensic02 has 787 entries, format 4, engine 4.7.2. |
| Export identity | Seven retained executables compared with installed release template native `.text` | All match; installed template matches preserved official export archive. No application-native engine patch established. |
| History | Chronological changed-file map and configuration/asset-tree comparison from 0.10.6 through diagnostic/current work | Asset tree unchanged across these milestones; engine/renderer/export settings unchanged apart from version text. No reliable ordinary-menu good/bad boundary. |

Machine-readable source/resource edges, imported dependency lists, lifecycle
candidate sites, native asset statistics, full Git history and build hashes are
retained in that evidence root. Dynamic paths need runtime coverage; regex
matching alone cannot establish their safety. Initial missing-literal candidates
were QA output names, guarded optional owner-audio paths and scanner patterns,
not confirmed missing production resources.

## Initialization, ownership and idle processing

`scenes/main.tscn` enters `world.gd:95`. It configures input/audio, constructs
world geometry, player and presentation, then horror/threat, physical objects,
investigation chapters, maintenance, evidence, mirror, ambient director,
equipment, hiding/search, service exit, final investigation and optional F1
tools (`world.gd:154–213`). Most systems reference the root world and are its
children; geometry factories extending RefCounted are not orphan Nodes.

The ordinary title still constructs the full world. The separately guarded
deferred-world diagnostic starts roughly ten nodes and later enters the original
main scene; it has **not** replaced normal startup. Approximately 4,900 nodes is
an allocation/workload observation, not a crash diagnosis.

The paused original-world snapshot identifies always-processing presentation,
controller, title camera, exterior, front-gate and inherited weather. Gameplay
physics/story/Surveyor processing is paused. Menu wind/drone loop callbacks,
occasional creak, silhouette visibility, mist, sky/weather and shader animation
continue. A player's `playing` property alone does not prove active mixing while
paused. No explicit GDScript worker-thread APIs were found; engine audio/render
threads and procedural texture generation still exist.

Focused lifecycle review covered title transitions, audio players/callbacks,
weather, ambient source cleanup, Surveyor animation/gaze ownership, save entry
points, physics relocation and mirror viewport gating. The mirror viewport starts
disabled and is gated by gameplay/visibility; its cloth update is deliberately
animated. Ambient source references are filtered/cleared; queued cues are
consumed. No additional freed-receiver/native-lifetime defect was demonstrated.
This is not certification of every dormant conditional path in the project.

## Tests and evidence interpretation

Current Windows export: `../Builds/UNLISTED_Forensic_Repair_02/UNLISTED.exe`.
Independent ZIP extraction: `../Checkpoints/20261026_full_forensic_audit/PrivateCandidate/IndependentExtract/`.

- Focused repair acceptance: 33 passed, zero failed, native exit 0; arrival,
  gains/fades, ten malformed core saves, valid/legacy save recovery, pause/title.
- Correctly initialized baseline recorder fixture: exit 0, no logged errors.
- Deliberately missing recorder: expected exit 92, explicit rejection, no AV.
- Ending A and story-mode B: 35 checks each, exit 0, from a preserved naturally
  earned investigation state, including receipt, car, pause/load and completion.
  These are segmented ending tests, not two new complete investigations.
- First ordinary extracted repaired candidate: 1,000.313 seconds (16m40s),
  normal startup, no QA/subsystem flags, observed title and actual Quit, exit 0.
  Owner checkpoint/settings hashes unchanged. External warm-state working set
  ranged 1,151,340,544–1,158,770,688 bytes and handles 999–1,023. This is neither
  GPU VRAM measurement nor proof of no leaks/intermittent crashes.
- Extracted candidate pursuit: 58 passed, zero failed, exit 0; includes real
  movement/search, cover, warned grab/escape, story-mode capture and door use.
- Extracted recorder recovery: 33 passed, zero failed, exit 0; event interruption,
  pause/load and reduced-motion response. Both preserve owner files.
- Three spatial visual baselines: twelve room/property PNGs per render size,
  all native exits 0/no logged errors. These are placement fixtures, not route
  acceptance or performance benchmarks. See `VISUAL_BASELINE_RESULTS.md`.
- Second ordinary idle observation remains in progress; its result belongs in
  the delivery receipt only after completion.

All earlier component/deferred/historical tests are retained, not rerun or
relabeled. They did not reproduce the owner's crash and cannot exonerate a
subsystem. No evidence justifies adopting deferred startup as a crash fix.

Failures retained: forced-cache parser runner setup; export01's premature
return-title fade assertion (2 seconds versus retained 7.875-second fade);
original/reproduced Crash B; aborted full dump. Corrected parser setup and test
timing did not rewrite working production behaviour.

## Next reliability gate

Preserve and push this bounded repair checkpoint. Continue ordinary extracted
menu observation and capture a new first-chance failure if it recurs. A controlled
bisect requires a repeatable failure boundary; no such boundary exists yet.
Do not attribute Crash C to audio, rendering, hooks, hardware or ZIP launch
without supporting exception/caller evidence. Human quality assessment remains
pending. Experimental graphics stay separate from normal gameplay.
