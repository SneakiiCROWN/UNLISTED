# UNLISTED

A first-person horror investigation in a rain-soaked house, service yard and woodland, with physical interactions, puzzles and the Surveyor.

**Current prerelease: 0.5.3 On Record · runtime 9de26ec.**

## Development snapshot

The source tip now includes the first human-feedback cellar repair: wall-side workbench, actor-sized pursuit routes, mounted relay plates and restrained replaceable enemy cues. West/east exported pursuit and death/retry checks pass. Full-route verification is running; the downloadable prerelease above remains 0.5.3 until a new tested build is published. See OWNER_RECORDING_CUES.md for optional owner recording slots.

## Download and play

1. [Download the Windows ZIP](https://github.com/SneakiiCROWN/UNLISTED/releases/download/unlisted-v0.5.3-on-record-public-test-20261020/UNLISTED-Windows-On-Record-Test.zip).
2. Right-click it, choose **Extract All**, then open the extracted folder.
3. Double-click **UNLISTED.exe** and keep its supporting files together.

No coding tools are needed. GitHub’s **Code → Download ZIP** contains source, not the playable program.

## What is in this version?

The optional SOURCE / RETURN investigation now earns a different final decision. A disputed 1998 close-out, original recording and physically rereadable paper copy connect Eli's investigation to Simon's missing-person record. The existing ACCOUNTED FOR ending remains; the new ON RECORD outcome keeps the case open. Eli's own attendance answer is still recoverable.

The impossible lounge, save/retry recovery, first-person hands/work torch, rain, forest and property routes remain. Completed saves remember the achieved ending; legacy completed saves retain the original one. The title-screen watcher no longer intrudes on either ending, and final choices clear the footer at all three tested resolutions.

## Checked, and still unfinished

The final Windows candidate passes 83 story/layout/save checks and 32 physical comparison/receipt/staging checks. The new ending is exercised through a continuous native route with real movement, interaction, Surveyor contact, death/retry, escape, paper reading and completed-save menus. See VERIFIED_CHECKPOINT.json for exact results and provenance. The original ending also completed a full native route on the preceding narrative runtime, before the paper interaction and final text-clearance adjustment. Both outcomes are rechecked in the final UI/save tests.

A room test in that earlier candidate crashed in NVIDIA's nvoglv64.dll (0xc0000005) while GPU tests had overlapped. Failed evidence remains preserved locally. The final room checks run sequentially; successful reruns do not establish the root cause or guarantee crash-free behaviour on every driver.

Human playtesting, subjective art approval and audio listening remain pending. Two character-art candidates were rejected after actual scene review; the Surveyor model is unchanged and still needs substantial work. Temporary vocals remain replaceable. Broader story pacing and the complete-game goal remain unfinished. This is an incremental alpha with two outcomes, not a promised hour-long finished game.

## Updating without losing progress

Extract each Windows version into a new folder and keep the old folder for rollback. Keep your existing settings and save folders; do not reset or delete app data to update.

Existing normal saves remain in `%APPDATA%/UNLISTED`. The development namespace is separate. Back up saves before experimenting; this release does not reset them. The active development checkout is separate from this publication snapshot.

## What is next?

Continue with genuine Surveyor character-art refinement, narrative pacing and selective environmental horror. Temporary vocals remain replaceable. Existing exterior, rain, first-person work and old checkpoints remain preserved.

## Requirements and credits

64-bit Windows with a Vulkan-capable graphics driver for Godot Forward+. No editor or source build is needed. Game-incorporated font and sound licences permit the playable package, but restrict standalone asset redistribution. See THIRD_PARTY.md and ThirdPartyNotices. The public source repository deliberately omits all asset media; the complete working project and history remain preserved locally.

Original project material is source-available with the permissions in LICENSE.txt; public availability is not a blanket open-source or asset-reuse licence. Third-party licence rights remain intact.

## Found a bug?

[Open an issue](https://github.com/SneakiiCROWN/UNLISTED/issues) with the release version, Windows version, graphics hardware, steps to reproduce and what happened. Share screenshots or a short recording if useful; leave personal saves, account details and private logs out of public reports.
