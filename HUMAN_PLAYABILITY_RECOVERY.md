# Human playability / active 0.10.1-dev continuation

Base preserved: v0.10.0 The Last Call; private 84aa3ae, recovery/before-human-playability-84aa3ae. Public playable release is still v0.10.0. No release/tag is overwritten.

## Completed and tested

B toggles crouch during gameplay, backs out of menus, and does not open Pause/the title. Start opens Pause, including from inspections, and resumes Pause. Releases return to the action that received the press, even across screen changes. LB remains a compatible held-crouch alias; hints advertise B. New Game clears an old crouch latch. Keyboard crouch and movement speeds are unchanged.

Charge check (keyboard B / D-pad Up) shows a small meter for 3.5 seconds, then fades. Low charge shows it briefly. Accessibility has a saved always-visible option, off by default. The existing charge, UV, spare inventory, cap exchange and backup semantics are unchanged.

Targeted wording: jammed service gate/latch, Inspect reflection, UV attachment, upstairs recorder, speaker link, printed slip and clearance copy. Mirror reaction respects observation settings. This is NOT a complete dialogue/rare-string audit.

Native Windows build: Builds/UNLISTED_HumanPolish_02/UNLISTED.exe. Focused human fixture 23/0; existing field/controller/battery/contact fixture 38/0; controller plan fixture 8/0. Actual B/Start/journal/inspection/settings transitions, low-ceiling/standing recovery, New Game reset, battery UI and saved preference pass. Screenshots at 1080p, 1440p and 3440x1440. Owner checkpoint/settings hashes unchanged. Human artistic/controller-hardware approval remains pending. No full-route repeat was needed for this checkpoint; sprint speed/endurance was unchanged.

## Identified objects / remaining work

The shed loose object is props.spare: approved pipe_valve.glb, displayed as an iron fitting, 0.26 x 0.22 x 0.26 m, 1.1 kg. It is separate from the essential UV inspection attachment. The existing physics impact can already knock the service-exit latch loose. No arbitrary attachment/fetch gate was invented.

The torch still uses four small 18 mm diameter x 52 mm cylinders in a 2x2 pack. Actual service GLB rear-bore mesh bounds are about 58 x 58 x 112 mm; body bounds about 58 x 58 x 173 mm. These are mesh bounds, NOT a proven internal usable volume. Inspect actual inner clearance before deciding D-cell count and fitting a convincing carrier; preserve inventory semantics and excellent cap/hand animation.

Not implemented yet: hold/toggle sprint preference, stamina with natural recovery and fading bar, D-cell art, complete human-language/rare-condition review, broader physical-clutter and furniture audit. No keyboard/pad rebinding editor currently exists. Car arrival cinematic remains explicitly later, after high-priority repairs.

## Exact next start

Preserve this checkpoint/backup first. Continue natural writing and control consistency, then implement hold/toggle sprint and balanced stamina as one tested slice. Retest actual Surveyor escapes, crouch/cover, pause, retry and save handling if movement changes. Do not insert rejected Surveyor art or promise a complete 30-60 minute game. Use existing isolated native QA; the owner can keep using the PC. Publish no rushed Windows prerelease.
