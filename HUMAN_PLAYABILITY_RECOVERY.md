# UNLISTED human-playability continuation / 0.10.1-dev

Public Windows release remains v0.10.0 The Last Call. Preserve its release, tag, complete source, saves and all older builds. The source below is newer, unreleased work; never replace it with the public release source.

## Secured recovery points

- Initial clean private checkpoint: 84aa3ae; tag recovery/before-human-playability-84aa3ae.
- Controls/meter: private 6a00028, public a14922c; complete private archive in Checkpoints/20261023_human_playability_01.
- Sprint/office language: private 273b65c, public 600bb24; complete private archive in Checkpoints/20261023_human_playability_02.
- Newest cell presentation: this checkpoint; complete private archive and exact commit/hash receipt in Checkpoints/20261023_human_playability_03/RECOVERY.json. No restricted raw media is published.

## Implemented

B toggles crouch in gameplay and backs out in menus; Start pauses/resumes, including from inspections. Button releases return to the action that received the original press. Low ceilings preserve crouch; New Game clears the latch. LB remains a held-crouch compatibility alias. Isolated native input keeps the owner's normal PC input out of QA.

Charge check shows a small bottom-right meter for 3.5 seconds, then fades. Low charge shows it briefly. A saved Accessibility preference allows a permanent meter, off by default.

Saved Hold/Toggle sprint preference, roughly 7.5 seconds of running, a short recovery delay and roughly five seconds of recovery. A small stamina bar fades at full recovery. Pause/crouch cancel toggle sprint. Numeric fatigue survives saves; old saves start full. Existing walking/sprint/crouch speeds remain unchanged. These are initial tuning values, not human-approved balance.

Targeted human-language repairs: service gate/latch, mirror, UV attachment, recorder/speaker link, office power/cable/tap controls and Simon's dependent note/hint, printed clearance evidence. Existing collected Last Call notes refresh known text without awarding evidence. This is not a complete rare-dialogue audit.

One original unbranded D cell replaces the four small cylinders in the service animation and both physical pickups. It has a jacket, bands, insulated positive shoulder and metal contacts. A shallow tray rests on the measured support mesh. Cell envelope about 34.2 x 61 mm; size reference: https://data.energizer.com/pdfs/en95.pdf . Actual service GLB rear-bore mesh bounds are about 58 x 58 x 112 mm; these bounds are not a proof of all internal clearance. Native opened-cap/extraction/seating views were reviewed against the existing bore and supporting fingers. Cap, hand and sleeve AnimationPlayer paths/timing, battery charge/drain, UV, backup and saved spare counts are unchanged. Existing pack identifiers remain internally for save compatibility; no manufacturer artwork is copied.

The shed iron fitting is already a physics weight that can strike the service-exit latch. It is separate from the essential UV attachment; no arbitrary extra fetch gate was added.

## Windows verification / evidence

Latest local executable: Builds/UNLISTED_HumanPolish_07/UNLISTED.exe.

- Final cell build: focused actual ray/controller pickups and saved inventory 5/0; reload/input/pause/movement/reduced-motion/occupied-hand/death/retry 18/0; staged native poses at 1440p and 3440x1440 3/0 each. Check actual report totals if continuing; screenshots in QA/cells, QA/reload, QA/poses1440 and QA/posesuw. Cell build changes are cosmetic and text-only after the earlier integrated movement verification.
- Build 05: stamina/real live cellar pursuit escape/save 23/0; B/Start/meter/low ceiling/New Game 23/0; office labels/documents 7/0 at each of 1080p, 1440p and 3440x1440; naturally earned saved-bay escape and both original endings 48/0.
- Build 02 baseline: original field/controller/battery/contact 38/0; controller-plan 8/0.
- Owner checkpoint/settings hashes unchanged. Final native logs contain no runtime script errors.

Earlier failed evidence stays in place. Build 03's distance fixture started off the curved lane and failed; the corrected fixture follows actual lane/ground coordinates. Its live cellar escape had passed. No terrain was changed to satisfy that fixture. Builds 06 and 07 retain the intermediate/final cell screenshots.

## Honest remaining work / next continuation

Whole-game rare-condition writing, broader physical furniture/prop review and later car-arrival cinematic remain unfinished. Human controller-hardware testing, endurance/balance, subjective art/story comprehension and listening approval remain pending. No claim of 30-60 minutes, a finished Surveyor redesign or a polished complete game is made.

Continue from the newest clean private source and receipt, not an older archive. Preserve rejected Surveyor studies outside ordinary gameplay. Use targeted isolated Windows tests for changed systems; avoid repeating passed full routes unless a relevant gameplay change warrants it. No new public Windows prerelease is made by this checkpoint.
