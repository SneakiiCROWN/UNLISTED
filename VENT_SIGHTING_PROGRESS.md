# First service-crawl Surveyor sighting / 24 October 2026

Implemented on the preserved complete local Surveyor Reborn checkpoint. Ordinary gameplay still uses the original surveyor_presence.glb; no rejected art is promoted. Public v0.10.0 and previous private builds remain preserved.

## Player-visible change

The first south-to-north service crawl can reveal the existing working Surveyor through a fitted inspection grille. A joined, raised foundation recess exposes the actual stairwell rather than an empty shell. The actor physically walks from the lower landing, up the real ramp, through the utility portal and around the existing room corner. Footsteps come from the shared distance-driven positional sound system. There is no forced view, new dialogue, explanatory popup, clone or separate enemy controller.

New cases opt into one sighting. Legacy saves without the event key do not. A blocked route, closed utility portal or competing encounter delays eligibility; passing the window without a safe opportunity spends it. Camera turning cannot permit visible spawning: geometry visibility is checked independently of the camera frustum. Retirement requires continuous solid occlusion from the current and predicted camera and possible crawl-exit viewpoints. No timer alone removes the body.

Stopping, reversing and continuing forward leave the actor walking its route. Pause stops it. Mid-crossing saves preserve its physical position, yaw, animation phase and destination. Deliberately leaving cover and catching up transfers that same body to the existing warning/AI, without a position reset. Story mode keeps the non-attacking staged walk instead. Staged movement retains the normal capsule, gravity, doors, corner recovery and locomotion matching. If obstruction prevents a safe crossing, no visible teleport is allowed.

## Actual Windows verification and scope

All runs use isolated player data and off-screen native Windows rendering with real movement input, actual collision and wall-clock image/audio capture. Owner save/settings hashes remained unchanged for every run. These are seeded focused fixtures, not a fresh full investigation or human playtest.

- VentSighting_01: normal 10/0, reverse 8/0, forward 8/0, pause/save 11/0, legacy 6/0, pending encounter 6/0, closed portal 6/0. Low opening passed mechanics but gave an insufficient upper-body glimpse; retained as an inferior visual iteration.
- VentSighting_02: normal 10/0 and existing active encounter 4/0. Initial follow fixture failed 1 assertion because it stopped 4.23 m from the actor, outside the 2.4 m handoff distance. Failure evidence remains separate; it was not a demonstrated product teleport.
- VentSighting_03: corrected actual follow 9/0, ultrawide 10/0, save 11/0. No positional discontinuity at handoff.
- VentSighting_04: raised inspection recess, actual native screenshots reviewed. Normal 1080p 10/0, reversing 8/0, 3440x1440 10/0 and pause/load 11/0. The normal camera visibility sample increases from 4 samples to 30; this measures that fixture, not human fear or guaranteed attention. Native-time normal and reversal videos preserve the real captured frames/audio.
- VentSighting_05: final story-mode guard, same geometry. Story-mode close following and safe retirement 11/0; normal-mode physical follow/warning 9/0, largest sampled movement step 0.0186 m. Clean import/export and clean QA Quit callbacks. Independent extracted-package check is recorded in the private delivery receipt.

The original active model is unchanged. Unrelated previously passing ending, puzzle and character-art suites were not rerun. No public playable release is made. Human fright, discoverability, sound balance and aesthetic approval remain pending. Dynamic physical obstruction can leave a visible actor waiting in an animated idle until safe cover is available; arbitrary malicious prop barricades have not been exhaustively tested. No finite test matrix proves every possible camera/input combination.

## Art recovery remains unresolved

Reviewed the actual licensed garment thumbnails and retained Blender/source files. Available MakeHuman clothing includes ordinary shirts/trousers, padded casual jacket, formal suits and a blue bib overall with short sleeves; the selected worksuit is not a ready-made inspection coat. The prior extracted coat has unresolved binding/export defects. No new coat extraction, nearest-surface weight transfer or decorative revision of that rejected geometry was attempted.

No convincing new static character has been produced in this milestone. A professional static garment fit and silhouette on one anatomical base is still needed before rigging. Do not present source availability, licence validity or working animation as artistic approval. Existing Blender projects, source archives and failed studies remain private and untouched. The licensed garment inventory contact sheet is retained privately with this session's recovery evidence.
