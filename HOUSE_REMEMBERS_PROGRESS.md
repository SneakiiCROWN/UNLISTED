# The House That Remembers / UNTESTED source pass

24 October 2026. Continues complete private 839ea42 / public 5213742, including the untested property overhaul. Verified private Windows source remains 6295892; published Windows release remains v0.10.0. Owner excluded Godot launches/imports, gameplay suites, captures, Windows exports, human playtesting and releases. None were performed. Static source and GLB geometry inspection are not engine verification.

## Implemented house art

- Lounge sofa: the approved source couch is long on Z (.907 x .850 x 1.600 m bounds), while the old fitting stretched its short X axis to 2.6 m. Refit only its visible mesh to .95 x .95 x 2.6 m and orient the low front towards the TV. The original wrapper and exact collider remain; old visual meshes are hidden, not deleted. A plain worn throw samples actual corrected sofa triangles and drapes over one arm. No new floor furniture or collision.
- Lounge: a small approved book stack sits on the imported shelf's measured board, clear of the bottles; existing TV and reading lamp gain physical leads/socket fittings. A closed unmarked envelope rests beside, not over, the newspaper. The reading-lamp geometry/light now belong to LoungeContents, so they leave with the lounge during the copied-bedroom transformation. Light position, energy and radius remain unchanged.
- Office: recorder desk blotter, a supported pencil tray in the clear left/front corner, archive folder and cabinet shoes, a restrained task-light hood/hinge and a restraint on the existing wall-mounted microphone lead. The existing UV work mat, lamp foot, transport controls, receipt and historical reel tray remain clear in source. No new instructions, labels or documents.
- Recorder: a small physical meter/needle sits between the existing reels, with scale ticks, case fasteners and tape guides meeting the existing tape path. It is static in ordinary play and is not falsely presented as an audio-responsive meter. A separate inactive study owns the proposed animation.
- Utility/Spare Place: cot webbing/feet, stand-offs filling the measured mirror-to-wall gap and backing beneath the existing tool rail. Existing cot cover, card, birthday evidence, mirror camera/frustum/layers, observation conditions and saves are retained. New glass material preserves the old horizontal reflection flip with only a narrow silvered-edge wear treatment; the central feed is not distorted or blurred by a new post-process.
- Cellar/underfloor: original concrete walls receive restrained damp/mineral variation with existing licensed maps. Added header mount plates, generator vibration pads bridging the existing 10 mm plinth gap, overhead cable hangers, pipe suspensions meeting the actual crawl roof, conduit spacers and rail-end fixings. Improved the existing overhead clip's contact span. No geometry/nav/puzzle collider or rack movement changes; no floor debris placed in escape paths.
- Copied bedroom: wallpaper repair has the same print shifted in register; a small sewn rug repair follows the actual rug surface; the known 10 mm bedside-lamp gap receives a base pad and a connected lead/socket. Details are children of RememberedBedroom and follow existing visibility/save transitions. No invented photograph, date, name or childhood revelation.

Static hardware is material-batched using MultiMesh; fitted cloth is one small mesh. No extra shadow-casting lights, global exposure changes, enemy logic, player/controller/torch code, new save schema or mandatory gates. Existing shadows remain; the throw can receive/cast ordinary shadows. Hardware placement metadata is retained for later inspection.

## Environmental horror / isolated inactive study

recorder_memory_study.tscn / recorder_memory_study.gd: an 11-second authored mechanical return. After a quiet hold, three restrained clicks accompany the meter; the reels creep backwards briefly and settle. Uses the original latch recording, not dialogue or final creature vocals. Tiny reel creep is omitted with reduced motion. Start is opt-in, development/title-only; cleanup restores touched angles and stops sounds, including cancellation when leaving the title. No ordinary world/F1 registration, case flags or hint text. enable_preview defaults false. These guards/timing/cleanup are source implementations, NOT tested results.

Proposed future case staging: after the player has fully heard the historical reel and the mechanism has stopped, in a quiet interval with no pursuit/recount/departure/other authored sequence. A late return of the recognisable mechanical rhythm, not a claim that relay isolation cuts power to the entire house. Persistence and eligibility must be integrated with existing event systems only after verification. The wallpaper mismatch is a passive art detail, not a new scripted scare or quest.

## Asset reuse and limits

No purchases, downloads or new raw media. Reuses approved Daniel Jurys CC0 couch, existing Kenney/home books and mirror, Dusk wood/steel/wallpaper, ambientCG Concrete019 colour/roughness, original canvas/paper/latch and existing room assets. Original new code supplies hardware, cloth fit, concrete variation and glass edge wear. Raw licensed media remains private; original art/rigs and rejected Surveyor studies remain preserved. The Surveyor model and AI are unchanged.

Source review caught the sofa's real source axis, shelf depth, a potential tray/lamp overlap (tray moved to the recorder desk), unsupported hypothetical cable clips (not added), headboard height being unsuitable for mattress trim (rug used instead), and the crawl-roof/ceiling contact heights. Final placement and appearance still require player-eye review.

## Deferred verification / do not claim complete

1. First clean Godot import/compile of accumulated property AND house scripts/shaders/scenes. Keep failures separately; preserve Integration_05.
2. Native player-eye comparisons: sofa orientation/proportions/throw contact, shelf book support, lamp ownership through both room states, desk/table/UV/receipt/reel access, meter visibility at interaction distance. 1080p, 1440p and 3440x1440.
3. Mirror image orientation/colour/edge treatment, cot contradiction, observation eligibility and save/reload. Confirm central occupant silhouette remains readable, not obscured by wear. Current shader replacement has NOT been rendered.
4. Cellar concrete visibility/tiling/damp balance, generator pads and brackets, underfloor clearance and rack travel; actual movement, pursuit/hiding, carrying and both ending paths when testing resumes. Source collider preservation is not gameplay proof.
5. Remembered-bedroom transition, drawer/evidence, rug/lamps and material seam from real eye height, including legacy saves. No new room ownership leaks.
6. Isolated recorder-study timing, cue audibility, motion reduction, repeat/skip/removal/title-exit cleanup and exact save/settings integrity. Do not enable ordinary encounters before eligibility, captions, event interruption and persistence are verified.
7. Draw cost/shadows and shader performance; no performance, fear, artistic or subjective listening approval claimed. Wider furnishing, lighting composition and substantial middle-act production remain unfinished.
