# Stability & Terror / 0.10.8-dev / 26 October 2026

Private QA continuation of 7dc6c29 / dd93311. The original intermittent native
crash is **unresolved**, not repaired by successful repeats. Previous verified
0.10.6, candidate 0.10.7, player data, assets, studies and releases are preserved.

## Established from the original failure

- Original PID 23508 / 0x5BD4 matches Application Error 1000, WER report ID
  ae2fbd95-c5fc-4f6f-a7eb-4d360f4ec93d and the recovered 61,508,376-byte local dump.
  The original WER temporary dump was gone and the WER archive denied read access;
  no permissions were changed. The matching Local CrashDumps file was copied,
  hashed and inspected read-only with the installed Microsoft debugger.
- Exception context shows an invalid read at nvoglv64.dll + 0xFAAA9F. Its stack
  crosses the game executable, vulkan-1.dll and NVIDIA's module. Private driver
  and Godot symbols are unavailable: large offsets from the nearest exported
  vkGetInstanceProcAddr/vkResetEvent names are **not exact internal function names**.
  The early offline automatic analysis had symbol warnings; it is not a valid
  diagnosis of an ntdll fault. The preserved exception context is authoritative.
- The installed nv-vk64.json explicitly names .\\nvoglv64.dll as the Vulkan ICD,
  API 1.4.357. The failed engine log reports Vulkan 1.4.357 / Forward+. The DLL's
  OpenGL product description does not imply an OpenGL renderer was active.
- Driver file version is 32.0.16.2101. Original module enumeration includes
  RTSSVkLayer64 and nvspcap64. Fresh Vulkan loader logs show inserted OBS, RTSS,
  Medal and NVIDIA layers. Presence is not proof of causation.
- The old profiler starts at 2560x1440, then changes the live private viewport to
  1920x1080, 2560x1440 and 3440x1440 while a root TextureRect samples its texture.
  Its log ended during the second moving pass. It did not write final metrics.
  No other UNLISTED GPU process was intentionally run concurrently.

No link to the owner's separate idle-triggered Windows crashes is established.
An older UNLISTED dump has a different invalid instruction address and is not
treated as the same failure. No BIOS, driver, registry, overclock or system-wide
overlay settings were changed.

## Controlled comparisons

The new embedded observer uses one identical 02 Windows executable for fixed
1080p/1440p/3440x1440, title resizing, live gameplay resizing, and the normal root
Window path without the SubViewport/presentation texture. All completed. Actual
runtime queries report vulkan / forward_plus. Root tests retain automation/private
data isolation; they are not an uninstrumented human playthrough.

The root case exercises fullscreen/windowed, pause/resume, save/load and minimise/
restore. Minimise/restore is not a claimed manual Alt-Tab test. A later final
candidate also exercises normal supported resolution requests; oversized windows
are clamped by the existing settings code to the actual desktop work area.

One child-only comparison filters VK_LAYER_RTSS, VK_LAYER_OBS_HOOK and
VK_LAYER_MEDAL_HOOK. Loader logs verify those filters applied; both filtered and
unfiltered live-resize cases pass. That does not isolate a guilty overlay.
Environment changes exist only in that child process, not Windows or other apps.

The preserved 0.10.7 executable separately completed its original three-resolution
route again with the same old profiling helper. No root-cause fix is inferred.

An attempted external --script/--visual-probe entry failed before any phase marker,
with a different invalid instruction address (0x360). Its log, dump and attempted
probe source are preserved. It is not counted as a fixed-resolution control or
proof that resizing/overlays caused either failure. The embedded observer replaced
that experiment; it is not an alternative monster or normal-game controller.

## Implemented narrow QA corrections

- The default cellar profiler now keeps the resolution selected at the title;
  run separate processes for different render sizes. --legacy-live-profile
  explicitly retains the old transition sequence for bounded diagnostics.
- Completed pass results are flushed immediately. The embedded comparison also
  writes before/after resize and movement phase markers, backend and method.
- Launch receipts retain executable SHA-256, exact arguments and explicitly
  supplied child environment only. They never dump the user's whole environment.
- Input isolation and checkpoint/settings integrity checks remain. The normal
  root control removes physical action bindings and rejects unmarked window
  inputs rather than installing global hooks or injecting desktop keystrokes.

These improve evidence and remove the known trigger sequence from routine QA.
They are a scoped exposure reduction, **not a proven driver/game crash fix**.
Normal graphics settings, renderer, shader quality, foliage, AI and gameplay
remain unchanged. No speculative force-sync calls or system modifications.

## Acceptance, limitations and next work

Final reports, hashes and independent extraction are in private DELIVERY.json.
Only changed-system tests and relevant gameplay baselines are used; the old 412
fresh-route baseline is not rerun or presented as new. Safe fixed-resolution
profiles are short capped samples, not whole-game/minimum-spec or uncapped FPS
proof. Human audio/art/story/fear and physical controller approval remain pending.

Crash investigation took priority over new character or environment construction.
Existing 0.10.7 horror, repaired curtains, cellar and Surveyor floor contacts stay
active. No new visitor, ending, speculative art replacement or public release.
The next stability step is better internal symbols or a reproducible failure
boundary, not a blind driver/BIOS change or repeatedly stressing the PC.

Owner checklist, whenever convenient: launch, pause/load, traverse the cellar and
service return; inspect settings window/fullscreen behaviour; revisit the lounge
aftermath; assess Surveyor presence and both departure meanings. Keep 0.10.6 as
rollback while intermittent native stability remains open.

## Primary references

- Local installed NVIDIA nv-vk64.json and the matching original minidump are the
  direct evidence for the active driver/library, not a web filename guess.
- [Khronos loader layer filtering](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderLayerInterface.md): child loader filtering and diagnostic interpretation.
- [Godot RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html): actual driver/method queries. A force_sync API exists but has a cost and was not inserted speculatively.

## Final candidate 03 completed evidence

Native exported checks: aftermath 25/0, impossible 52/0, ending_b 35/0, normal_root 10/0. Owner save/settings integrity remained unchanged. Ending B uses an earned historical snapshot; this is segmented verification, not a fresh full investigation. Independent extracted-package ending A is recorded separately in DELIVERY.json.

| Render size | Median ms | p95 ms | Maximum ms |
|---|---:|---:|---:|
| (1920, 1080) | 16.667 | 16.951 | 27.082 |
| (2560, 1440) | 16.666 | 16.921 | 35.887 |
| (3440, 1440) | 16.664 | 16.933 | 17.408 |

These are warmed ~16.6-second, 60fps-capped, isolated walking samples on i9-14900K / RTX 4080 SUPER. Native render sizes are presented in a desktop window. Not uncapped speed, whole-game stability, minimum-spec approval or proof of a crash fix. All successful controls leave intermittence unresolved. No literal manual Alt-Tab, physical-controller or human comprehension approval is claimed.
