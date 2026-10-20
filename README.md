# UNLISTED

A first-person horror investigation in a rain-soaked house, service yard and woodland, with physical interactions, puzzles and the Surveyor.

**Current prerelease: 0.5.4 Cellar Repair · runtime 421b70c.**

## Download and play

1. [Download the Windows ZIP](https://github.com/SneakiiCROWN/UNLISTED/releases/download/unlisted-v0.5.4-cellar-repair-public-test-20261020/UNLISTED-Windows-Cellar-Repair-Test.zip).
2. Right-click it, choose **Extract All**, then open the extracted folder.
3. Double-click **UNLISTED.exe** and keep its supporting files together.

No coding tools are needed. GitHub’s **Code → Download ZIP** contains source, not the playable program.

## What is in this version?

This update repairs defects reported in the first human playtest. The cellar workbench previously blocked a Surveyor route while an eye-height visibility check incorrectly considered it clear. It now sits along the wall with its props, and cellar navigation checks the actual body clearance. Replanning no longer reverses toward adjacent waypoints.

The service station has mounted hardware, grounded props and worn concrete surfaces. Relay signs meet the wall/backboard, and the overhead strip has physical supports. Repeated pursuit/attack breaths are limited and no longer stack; optional owner recording slots are documented in OWNER_RECORDING_CUES.md.

Both ACCOUNTED FOR and ON RECORD remain, along with the impossible room, Eli/Simon investigation, rain, property and hands. No character candidate was substituted into this release.

## Checked, and still unfinished

The exported repair is checked through both complete normal-input routes, solving the three valves and traversing the previously blocked aisle before actual contact, death/retry, escape and each ending. Separate west/east saved-state scenarios reproduce the obstruction and verify the repair. Resolution views, saved outcomes, hiding/story mode, impossible-room recovery and systems have separate evidence. See VERIFIED_CHECKPOINT.json for final results.

This is the first repair pass after actual human feedback, not a declaration that the game is polished. The Surveyor still needs a convincing character-art redesign. The newer model study was not accepted. Rain visibility, broader furnishing/placement, exterior composition, environmental audio variety and the abrupt post-relay climax remain unfinished. The existing Modern PSX default is configurable, and current player settings remain intact.

Earlier NVIDIA nvoglv64.dll crashes remain unresolved; final GPU checks run serially. The owner has played the preceding release, but this repair candidate still needs human retesting. Subjective audio/art approval remains pending. Temporary creature vocals remain replaceable.

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

## Current development work

The verified download remains **v0.5.4 Cellar Repair**. A later source checkpoint adds clearer roof-aware foreground rain and isolated Surveyor construction studies. The study is **not approved or the default enemy**; face, hair and garment art still need improvement. No new Windows prerelease is claimed. See [current work and limitations](CHARACTER_RAIN_PROGRESS.md).
