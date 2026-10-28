# UNLISTED — The House Remembers / 28 October continuation

**PRIVATE QA — STABILITY NOT CLEARED.** Version remains v0.10.9-dev; public release and prior House Answers delivery are preserved. Gameplay source: fadfe75; QA initialization/fixture source: 694f600; final runtime including room-transform cover correction: dbaaa02. Recovery before edits: recovery/pre-house-remembers-20261028 -> 8c32536.

## Implemented in the ordinary game

1. **The curtains belong to the player too.** A small physical pull on the clear left side of the lounge window opens/closes the existing cloth with keyboard or controller interaction. A short eased movement respects pause and reduced motion. Manual choice is saved immediately; loading during movement restores its intended completed state. Legacy automatic closure still restores. The existing unseen closure cannot waste itself on already closed curtains, and once the player reopens the spent anomaly it does not silently close again. No new mandatory puzzle, journal or objective.
2. **Window perception matches the scene.** Existing transparent-glass metadata now distinguishes vision from the physical barrier. Only explicitly marked transparent panes are skipped by Surveyor player-visibility rays; opaque walls, frames and doors remain occluders. The actual UV-deformed curtain triangles block vision, including pleats and the real centre gap. Hearing, collision, navigation, solid attack rays and pursuit state rules retain their existing systems. This is not automatic invisibility or a switch that cancels a chase.
3. **The restored room answers movement.** After the impossible room has genuinely been witnessed and revisited, the established optional ceiling event can answer actual walking with up to four delayed contacts above the room. Standing still does not start a canned walking sequence; stopping can leave one already scheduled step, then silence. The sequence expires, yields to an encounter or departure, freezes on pause and is consumed safely on save/load without replay. It adds no actor or claim about identity and does not extend the game with chores.
4. **Connected physical/presentation repair.** Sewn tabs bridge the old gap from curtain cloth to its real pole and follow the same shader displacement. The pull was moved away from the reading-lamp silhouette after native inspection. The short prompt and optional 'Curtains rustle.' caption describe the actual action and existing positional cloth sound. The pull adds no floor obstacle and is disabled when the copied bedroom owns the room. All graphics profiles retain their rendering systems.

## Actual Windows verification

| Exported native scope | Checks | Seconds |
|---|---:|---:|
| features1080 | 29 | 17.84 |
| features1440 | 29 | 16.94 |
| features3440 | 29 | 17.94 |
| threat | 58 | 114.94 |
| impossible | 52 | 68.67 |
| ambient | 48 | 26.41 |
| endings | 70 | 62.74 |
| lifecycle3440 | 2 | 12.80 |
| prebuilt_features1080 | 31 | 17.84 |
| prebuilt_features1440 | 31 | 16.94 |
| prebuilt_features3440 | 31 | 17.92 |
| dread | 28 | 22.91 |
| prebuilt_impossible | 52 | 68.61 |
| prebuilt_endings | 70 | 62.99 |
| prebuilt_lifecycle3440 | 2 | 12.80 |
| prebuilt_idle | 2 | 332.81 |

The feature fixtures use actual isolated engine interaction and movement input, physics, synthetic controller Start/B/X, legacy/manual saves and actual window rays. 1080p uses Balanced, 1440p Original and 3440x1440 Enhanced. Candidate06 checks the production gameplay change; Candidate09 retains that same gameplay and adds only optional QA initialization/diagnostics and the maintained aftermath fixture. Candidate10 changes only the old quiet-reservation fixture. Candidate11 corrects only the automatic window-click caption to match the actual tab-top curtain hardware; timed/route checks are retained rather than repeated for wording. Candidate12 corrects curtain sight to use the physically transformed room coordinates, adds positive/no-ghost-cover native checks at all three resolutions and repeats the affected impossible-room suite. Physical controller hardware is not tested. The prebuilt cases separately check that entry/context change rather than repeating the unaffected full investigation. These placed-state fixtures and direct optional-event requests are not a fresh investigation, a human first playthrough or proof of fear/comprehension. Native screenshots and sampled motion/audio are retained. Existing threat coverage checks perception, movement, pursuit, hiding, story mode, attack, death and retry. Impossible-room and ambient suites cover the changed surrounding systems. Both departures resume the preserved naturally earned Phase5 evidence checkpoint; this is segmented continuation, not a new uninterrupted full route. Unchanged radio/UV/lightbox/weight paths retain the previous baseline rather than being repeatedly re-run.

## Crash investigation — unresolved

The no-recorder hypothesis produced a **fresh failure**: the 330-second legacy-viewport menu observation emitted the same missing-particle error without installing an AudioEffectRecord. Its engine-error result is preserved and is not counted as passing merely because its menu assertions passed. This warning therefore does not require that QA recorder in this observed condition. The ordinary owner crash remains a separate unresolved failure.

The next bounded hypothesis concerns moving a live rendered game into the QA viewport. An opt-in alternative QA scene constructs the unchanged game directly inside its final sized private viewport/world. It avoids the live viewport handoff; normal New Game, main.tscn selection and ordinary world construction remain unchanged. Export templates refused a direct command-line scene override in Candidate08; that startup failure is preserved. Candidate09 instead reuses the existing deferred-diagnostic pattern behind an explicit QA-only flag, before world construction. Same-binary legacy/prebuilt observations, new polling-time error records and prebuilt input/save/room/ending checks are preserved. Clean prebuilt observations are not proof of an engine fix, an established cause, or ordinary foreground-owner stability. The same Candidate10 binary also passed a 30-second legacy-handoff control. That prevents attributing the intermittent warning solely to handoff. The 330-second prebuilt observation and relevant prebuilt recovery checks were clean; neither ordinary freeze-and-close reproduction nor a permanent engine fix was established. The new diagnostic entry remains explicit QA-only.

Twelve ultrawide ending/title/porch recovery cycles again trace GPU emitters, CPU mist and heightfield resources. Stable scene handles do not certify renderer-internal ownership. A review of the [Godot 4.7-family storage lookup](https://github.com/godotengine/godot/blob/4.7-stable/servers/rendering/renderer_rd/storage_rd/particles_storage.cpp) confirms that the named motion-vector-offset getter first looks up a particle owner and rejects a missing owner. This narrows what that warning means; it does not identify the offending RID or establish a matching fix in our exact 4.7.2 binary. The earlier owner null-execution dump, Vulkan read fault and guarded missing-particle log remain separate unresolved evidence. No engine, OS, driver, registry or BIOS changes were made.

## Surveyor art: bounded attempt rejected

Reviewed the previous native close-up, silhouette and preserved Blender construction. An editable new weatherhood removes the cap/peak/high collar, frames the existing aged face, adds weighted continuous hood/rolled edges and anatomy-local cloth folds. It retains 65 bones and exported existing animation clips. Static front/side/rear/face renders still show an ordinary hooded person, smooth coat, crude cuffs/boots and insufficient facial character. **FAILED STATIC ART GATE.** It was not inserted into the game and no native art integration/animation approval is claimed. A hood does not solve the deeper anatomical, garment-retopology, seam/UV and surface-detail deficiencies. The bounded study is preserved privately; no further small costume variations were attempted. Original active Surveyor and previous rejected studies remain intact.

## Failure evidence and corrections

- Candidate01: new tab-loop numeric inference caused a script parse failure. Fixed with an explicit float; retained exact-child script-abort evidence is not an owner crash.
- Candidate02: the TV table blocked the test's chosen line across the lounge; the fixture was moved to the real clear aisle. Its open-window check exposed the existing opaque sight treatment of physical glass.
- Candidate03: exact-name glass identification missed Godot's suffixed duplicate name; the first walking fixture also aimed only the camera rather than using the movement driver's body heading. Retained failed results are not counted as passes.
- Candidate04: the additional QA diagnostic needed an explicit Dictionary type. Candidate05 then demonstrated the exact ClosedWindowGlass2 obstruction. Candidate06 uses the existing transparent_glass metadata and the actual movement helper; relevant checks pass.

Candidate09's old aftermath fixture initially tried to replay during a saved quiet interval (25 passed / 2 failed). Candidate10 first proves that quiet blocks premature replay, then resets quiet only for each independent recovery/interruption fixture. No gameplay reservation was weakened. Its failed report remains preserved.

Original evidence directories and exports remain unchanged. No historical failures are erased. Artwork remains unapproved; subjective sound quality, artistic quality, human understanding/fear and 30–60 minute first-play duration remain unverified. Existing menus, arrival, canon, saves and both ending meanings are retained.

## Owner instructions and recovery

Extract the entire new private ZIP into a fresh folder and run UNLISTED.exe. Normal launch retains the original enemy and your existing settings/save compatibility. The new pull is beside the lounge window; interact to draw/open the curtains. Accessibility captions and reduced motion retain their settings. There is no new compulsory task and no request for owner testing before work can continue.

Open EVIDENCE.html for native state comparisons, the sampled Windows gameplay recording, failure logs and clearly labelled Blender static review. Current before/after curtain frames show actual interaction states, not a deterministic cross-build weather comparison. The preceding House Answers native captures and failed window-sight observations remain the cross-build baseline. DELIVERY.json records exact private/public commits, tag, executable/ZIP hashes, independently extracted checks and complete private source/history backup. Complete source includes the editable previous character files and new failed hood study; raw asset inbox and earlier builds remain separately preserved. No public release.
