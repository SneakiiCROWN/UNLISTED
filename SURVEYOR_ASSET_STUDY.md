# Surveyor Reborn: asset-first rigged study / 28 October 2026

**PRIVATE STUDY. NOT PROMOTED. ART STANDARD NOT MET.**

The working gameplay model remains `surveyor_presence.glb`, hash
`1bbfb311d83db53cf433948af5345f893f9160e1eb3c4d6c6782151f286f2bd6`.
The new model requires an isolated QA mode **and** `--surveyor-assets`.
Ordinary New Game, saves and all authored encounters retain the working model.
No public playable release is made. Original owner-menu and intermittent
null-particle stability faults remain unresolved; these checks do not clear them.

## What was built

Inspected the actual four supplied archives plus UAL1, their readmes/licences,
glTF data, material dependencies, armatures and animation lists. Original archive
SHA-256 values and preservation checks are in the private recovery folder.

The base, both animation libraries and fantasy clothing Standard packs declare
CC0. Their Godot/glTF exports were used instead of FBX unit conversions. The
clothing readme explicitly warns against retaining the unseen full body.
Only the anatomical head/neck and eyes/brows are retained beneath the clothing.

The isolated candidate uses actual authored torso, sleeves, trousers, boots and
hood meshes. Fantasy buckles/shoulder accessories were removed, body remnants
were cut away, and source crease textures were recoloured and bounded to 1024px.
The selected GLB is about 11.5 MB; the first 83.6 MB export was not retained as
the selected runtime asset. The construction and rigged Blender files are packed
privately; no failed MakeHuman coat extraction or nearest-surface weight transfer
was reused.

The 65-bone active rig and existing locomotion/contact clips are preserved.
Clothing shares the bone names but has a different rest basis: each vertex is
corrected through its weighted source-rest/target-rest matrices, preserving the
garment's authored weights. It is not blindly parented onto a supposedly
identical skeleton. A UAL2 `Idle_No_Loop` response is rest-relative retargeted to
`Asset_HeadResponse` for preview. It is **not** repeatedly played as a gameplay
idle; that unmotivated gesture would make the actor worse. Chase speed, attack
timing, collision, perception, navigation and save schema are unchanged.

Two short cloth cues were selected from the existing Sonniss GDC2026 InMotionAudio
Foley T-Shirt collection. The supplied licence allows game synchronisation and
modification, retains copyright, and prohibits standalone resale and AI training.
The excerpts are ordinary audio edits, not generated voices or training data.
The private candidate plays them quietly at its actual torso when changing
between selected poses, with a four-second cooldown and seven-metre limit.
Existing surface footsteps, room audio routing and replaceable vocals remain.
Subjective listening/character sound approval is pending.

## MPFB compatibility

The supplied MPFB 2.0.18 manifest requires Blender 4.2 or later and declares
GPL-3.0-or-later for the add-on. Installed Blender is **5.2.2 LTS**.
Legacy-style module registration failed because this release expects an extension
package. The first extension attempt also lacked its preference entry. The
correct temporary local-extension registration with preferences enabled succeeds,
then unregisters. No owner preferences were saved or global add-on installed.
The failure logs and successful receipt are preserved. This certifies registration
only, not every MPFB authoring function or the licence of every third-party
MakeHuman clothing download. MPFB is not a dependency of this candidate.

## Actual visual assessment

Reviewed neutral front, side, rear and facial renders, followed by actual Windows
player-eye hall, close-up, silhouette, both sides of the lounge glass, walking,
running, pursuit and capture images. The first assembly had a sharp facial seam
and retained fantasy fittings. The second exposed a hood/head intersection and
an incorrect diagnostic arm pose. These failed construction states are retained.

The selected construction fixes those specific defects and provides a genuinely
skinned in-game study. **It is not a convincing final Surveyor.** The youthful
hero face, plain white eyes, short tunic closure, sleeve proportions and boot
styling still read too much like the fantasy kit. The silhouette is insufficiently
distinctive. Do not describe it as professional finished horror art, or promote
it on the strength of mechanical passes. The remaining blocker is bespoke face
and service-workwear art, not another AI-controller rewrite. These Standard
archives contain no ready-made late-1990s service-worker outfit. Further work
needs deliberate garment/face authoring or a more suitable licensed source,
rather than more colours and pieces on this same tunic.

## Native Windows checks

All checks use isolated saves/input, the actual exported renderer, real collision,
working animations and game audio. They are not a human playtest.

- Baseline 1080p comparison: **11 passed, 0 failed**.
- Candidate 1080p art/movement fixture: **14 passed, 4 failed**. The fixture left
  the threat disabled after the art section, so its pursuit/death/retry assertions
  failed. Preserve the full failed report. Only its labelled art/window/movement
  excerpt is used for that visual evidence; it is not a passing encounter run.
- Corrected candidate live 1080p: **16 passed, 0 failed**. Actual perception,
  pursuit, warned contact, camera separation, capture pause, death and retry.
- Candidate 1440p and 3440x1440 art/window fixtures: **12 passed, 0 failed each**.
- Candidate existing threat regression: **58 passed, 0 failed**. Includes skeleton
  animation, occluded perception, hearing/search, hiding, sprint escape, actual
  unlocked door, physical cellar ramp, collision, death/retry and story survival.

Accepted runs log no runtime errors/warnings and preserve the owner's save and
settings hashes. Ordinary fallback geometry is byte-identical to the recovery
checkpoint. No fresh full investigation or ending route was rerun: neither
progression nor those triggers changed. No hardware-controller certification,
human fear/art approval, or long-session stability claim is made.

Evidence uses placed comparison cameras and clearly labelled locomotion fixtures;
the live contact segment uses real AI. Recordings sample approximately six images
per second with real wall-clock durations. A 30fps video encode repeats frames;
it does not manufacture native 30fps gameplay evidence.

## Recovery and next step

Root: `../Checkpoints/20261028_surveyor_assets/`. Original resources, failed studies,
compatibility logs, construction files, native evidence and previous builds remain.
`recovery/pre-surveyor-assets-20261028` preserves the complete pre-change source.
Current work is on `production/surveyor-asset-study`. Exact checkpoint hashes,
private ZIPs and extracted-executable verification are in `DELIVERY.json` once
sealed. Safe source only is pushed to the existing repository; licensed binaries,
audio, Blender projects and archives remain private.

Do not run another series of decorative variants on this unsuccessful tunic.
Retain the proven garment-binding pipeline and current gameplay fallback while
developing a more suitable, authored character design. Owner visual approval is
required before any gameplay replacement.
