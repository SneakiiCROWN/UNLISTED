# Property overhaul / UNTESTED development source

24 October 2026. Continues complete private 6295892 / public c818219. Existing public v0.10.0 and the private Integration_05 Windows candidate remain unchanged. Owner explicitly excluded Godot launches/imports, automated gameplay suites, captures, Windows exports, human playtesting and releases. None were performed for this pass. Source review is not compilation or visual acceptance.

## Implemented

- Ground shader: feathered, irregular wear joins the curved lane, gate, front path, west-house circuit, shed approach and east service return. Added wheel wear, gate/rear-door compaction and damp foundation edges using the existing soil/concrete maps. Vertex positions and every terrain collider remain unchanged.
- Front/house: gate-post shoes/caps and fence-foot collars; masonry caps on the actual existing foundation courses; two-piece weatherboard corner returns; hangers on the existing roof gutters; framed existing catch pits; supply-entry drip loop into the west wall. No extra gate, porch step or duplicated house gutter.
- Woodland: small authored verge groups frame the approach, west circuit, shed and east return. A few dead-tree silhouettes/logs/stump sit beyond the existing wire perimeter. Near-route stones are mostly buried low relief. Random grass/bush visuals are suppressed only in these pockets, after all existing RNG and tree/rock collision creation; the baseline physical woodland remains intact.
- Shed: flashing fitted to the actual 6.5 m repair roof (top y=3.00), corner/plinth returns, weather hood above the existing door head, west-eave gutter/leader/soakaway, mounted through-wall feed junction connecting to the existing indoor service box. Existing interior service pipe stays separate. No extra door trim, replacement roof or blocked shed threshold.
- Maintenance work: the original movable iron fitting now has a thin bench wipe mat; removed fasteners sit in a supported tray. Added a wall-side restraint rail/hooks below the existing note. The fitting, UV equipment, note, existing parts tin and their original interactions remain in place.
- Yard/exit: flush duct covers and wall-side equipment heels; coping/joints on the original service-cut cheeks and a thin landing-edge frame. The real incline, clear opening, grille sweep, severed contact, latch and all existing collision remain unchanged.
- Static details use region/material/mesh MultiMesh batches. Placement metadata is retained on PropertyFinish and ServiceExitFinish for later coordinate inspection. No new per-frame processing, lights, AI rules, save fields or mandatory puzzle gates.

## Reused assets

No purchases, downloads or new raw asset intake. Existing Quaternius CC0 nature meshes/material prototypes (grass, plants, bushes, stones, dead trees, logs and stump); ambientCG CC0 Ground067, Concrete019 and WoodSiding006 maps; licensed existing Dusk steel and original work canvas. Original new code geometry supplies hardware/flashings. Prior licences/provenance remain authoritative in THIRD_PARTY.md and assets/exterior. No licensed media goes to public GitHub.

## Environmental horror candidate / INACTIVE

scenes/property_memory_study.tscn plus property_memory_study.gd and property_bootprint.gdshader prepare seven alternating muddy work-boot impressions ending at the shed's wall-feed position, without a matching return trail. Original native shader/geometry, no identity claim, document, audio explanation, visitor or quest. A small AnimationPlayer reveal is present. The scene is not loaded by ordinary gameplay or F1; enable_preview defaults false. Its explicit preview is guarded to development/title-only and never writes case data.

Proposed future activation ONLY after visual/runtime approval: once after the shed discovery and relay isolation; reveal while the position is unobserved, outside pursuit, recount, departure, blackout and other authored beats. Use existing event persistence when integrating; it is deliberately NOT wired or saved now. Do not treat a local relay isolator as proof the whole property supply is off. No running-machine contradiction was added on that faulty assumption.

## Source measurements and review

House walls are .18 m deep; the new corner returns overlap the real outside faces, rather than using assumed .28 m walls. The shed already has a 6.5 m cap at y=2.82..3.00; details follow that, not the inner ceiling. Existing shed door head trim reaches y=2.68; the new hood starts above it. Bench top y=.80 supports the tray and millimetre-thin cloth. Landing/coping references use service_exit.exterior_height and the existing cheek tops. Nature source GLB bounds were read offline to establish normalized log/rock dimensions. These are source measurements, not screenshots.

## Deferred verification

1. First Godot import/compile of the new scripts/shaders/scene, with all failures kept separately. Do not overwrite Integration_05.
2. Player-eye comparisons at porch/windows/gate/car/lane, west passage, shed door/perimeter/workbench, rear yard and both ends of the service incline. Check contact, trim intersections, drain destinations, no grass through walls, mud width/colour, wet response and natural blend. Check 1080p, 1440p and 3440x1440.
3. Actual walking in both directions, gate/shed/grille opening and full sweeps, carry/throw/weight of the original fitting/tin, UV and note access. Confirm no ray interception or changed hiding/Surveyor routes. Although colliders are unchanged in source, visuals still require traversal review.
4. MultiMesh bounds/culling, total draw cost and extra ground-shader cost, especially ultrawide. Small details disable added shadow passes; no performance claim without measurement.
5. Inactive footprint study: orientation/opacity, ground contact/z-fighting, rain plausibility, lighting/readability and a quiet unobserved reveal. No promotion until persistence, interruption and authored-event safety are designed and tested.
6. Existing save/retry and both endings remain the baseline; focused integration on changed locations when testing resumes. No fresh playthrough-duration, art, story comprehension, fear or listening claim.

This is an unverified production candidate, not a new Windows release. Wider interior art and audio/horror expansion remain unfinished.
