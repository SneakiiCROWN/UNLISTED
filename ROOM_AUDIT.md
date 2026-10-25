# Director pass / connected room ledger

Evidence scope is explicit. Player-height fixtures are visual inspections, not complete movement proof. All old builds and rejected evidence remain.

| Cluster | Observed defect / action | Verification and remaining work |
|---|---|---|
| Kitchen | Calendar/clock overlapped the window. Cabinets/fridge left a service gap behind the counters; pot stood above its visible stove surface. Vase buried in counter. | Director_05 actual 1080p aisle and close views reviewed. Calendar/clock on solid wall, rear units fitted to wall, stove against side wall. Vase supported. Pot collider height measured from imported triangles: pot bottom .86010 m vs mesh .86062 m. Counter cup/three tins settle within 2 mm of actual surface. No new doorway/navigation change. Sink lowered to a shallow unit; its existing low-detail model remains an art limitation. This is a repair, not finished kitchen art. |
| Kitchen / physical puzzle | Fixed counter cup and tins were noninteractive. Release counted bodies merely hovering above it. | Shared system now has nine loose bodies. Tool tin, pot, three cans and mixed mugs/can work. One mug fails. A shelf above the plate fails. Stacking transmits mass once per supported body; save/load and actual carrying to the drawer pass in Director_05 (34/0 overall). Guaranteed tool tin/fitting remain. Wider combinations/player experimentation still need human review. |
| Utility / Spare Place | Old 0.55 m aisle trapped the player; false-card wording could imply a true 1999 return. Reflection selected the shelf. | Preserved prior cot move/31 native tests, updated card text explicitly rejects the chronology. Correct reflective face and raw feed inspected in SparePlace_10. Reflection's silhouette and missing full-body reflection need art review; not promoted as finished. New encounter regression running in Director_06. |
| Lounge / office | A/B receipt called tonight's event 1998. Paper described the live doorway step as part of a recording. | Central narrative and physical receipt corrected together. Existing 07 player-height views reviewed: room layouts left intact. Full support/doorway/corner audit is pending, including upper shelf objects; no blanket claim that these rooms are finished. |
| Bedroom memory | Simon's last page and Eli's interpretation needed a clearer distinction between the copied room and his real home. | Page rewritten centrally; retained physical furniture/drawer/rubbing and closed-room change conditions. Existing working geometry preserved. Full current-case route regression pending. |
| Cellar / underfloor | Mechanical release lacked actual supported-mass behaviour; clutter/support and tall actor need continued review. | Support graph repaired, ordinary carrying route to original passes. Existing cellar view reviewed. Full native investigation, rack, pursuit, cover and clearance regressions running. No new rooms constructed. |
| Hall / porch / endings | Choices implied closing the missing-person case, although the actual interaction closes Eli's service call. | Register, journal and both outcomes now distinguish the call-out from Simon remaining missing. Legacy paths preserved. Native layout/earned-route review pending. Stronger cinematic staging remains undone. |
| Exterior / shed / gate | Existing rain, forest and route preserved. | No new external art or weather change this batch. Full porch/window/rear/gate/woodland multi-angle audit, lightning and contextual sound pass remain. |

## Next connected repairs

Finish native evidence review, then continue room clusters and rare/legacy text inventory. Audit Surveyor visibility/spatial entry and retirement before changing encounter logic. The new weighted ambient director, lightning/window scenes, art-compatible character pipeline, broader portable objects and cinematic finale are NOT implemented by this batch. Keep these distinct from the repaired support puzzle and existing authored beats. No new runtime added just to increase content count.

Final native 08 confirms the vase and all three cans have separate rendered bounds and correct support. Its 36 targeted checks pass. Director_06 full route, cover/rack, both endings and impossible room pass; Director_08 bedroom/updated text and three-resolution fixtures also pass. These functional results do not replace the unfinished deeper multi-angle room/art audit.


## Second connected audit / current candidate

Lounge: measured shelf top is 1.85 m. Bottles now contact it. The four old lower books had no shelf at all and were removed. Existing real movement through the door, chair and front circulation passes. Other lounge corners and the full property remain pending.

Utility: mirror lowered/aligned to the cot and checked from the clear aisle. Returned blanket has head/shoulder/torso/knee contour; real card is excluded from the covered return. Height marks moved clear. Actual exported screenshot reviewed. Missing player-body reflection remains a limitation.

Porch/gate: new-case arrival outside existing saved gate. One knock/ajar/open sequence tested through real movement, input, collision, pause and save/load; ordinary and legacy doors retained. No exterior art overhaul this continuation.


## 24 October / source-only room finish, NOT visually accepted

Source groups 0e658f1 / d8fe284 / 76ccf3d continue 19dc757. Kitchen sink source was a complete cabinet/tap compressed to 14 cm: full proportions restored while the prior base collision is retained. Recorder/reel/radio supports, lounge shelf packers, utility hooks, cellar housings/header/flanges and shed service wiring are implemented. Added two curated carryables on existing supports. Exterior downpipes now connect to roof gutters and outlets. No new route blockers, terrain changes or light-energy retuning. Review all of these in-engine when testing resumes; source coordinates are not player-eye visual evidence. See DEVELOPMENT_PAUSED_TESTS.md for the accumulated checks.


## 24 October / counter and work-surface continuation â€” UNTESTED

Counter backsplash uses the existing Dusk cracked tiles around, not across, the real front window (opening x=-5.59..-4.01, y=1..2.4). Office bookends rest on existing .675/1.225 m boards. Counter vase converted to a shared carryable; work mug and small parts tin added to clear portions of existing utility/shed benches. No new floor obstacles or route collision. Coordinates/materials reviewed in source, not player-eye acceptance. See the newest DEVELOPMENT_PAUSED_TESTS.md section for required visual/physics checks.


## 24 October / accumulated working-room verification

Native Integration_04/05 reviewed the accumulated room pass. Repaired the reparented lounge-shelf reference (which interrupted later finish functions) and measured/fixed 11 mm plant-pot penetration into the kitchen worktop. The stable proxy now rests within 0.6 mm. Complete sink, tile/window junctions, worktop props, hall microphone/cable, cot/frame, cellar practical housings/common header, shed conduit/service box and downpipe/rain were inspected at player height. Kitchen/recorder received three-resolution captures. No global controller, enemy navigation, gate, room layout or story gate was changed. Recorder presentation now reuses the physical historical-reel design; controls/audio remain intact. Alpha art and broader furnishing remain unfinished; screenshots are evidence, not owner approval. See PLAYABILITY_CANDIDATE_VERIFICATION.md.


## 24 October / property overhaul - UNTESTED source

Connected arrival/lane/gate, west approach, foundations, woodland pockets, shed work area/drainage and service-cut finish are implemented in property_finish.gd and the existing ground shader. Terrain heights/triangles, original woodland RNG/colliders, door/grille collision, AI and save schema are preserved in source. Corner trim follows measured .18 m walls; shed flashing follows the existing 6.5 m repair roof rather than the inner ceiling. Source review only; no engine/import, screenshots or gameplay. An inactive footprint study is not registered for ordinary play. See PROPERTY_OVERHAUL_PROGRESS.md for changed regions and deferred checks.


## 24 October / house interior pass - UNTESTED

Lounge/office, utility, cellar/underfloor and copied-bedroom source changes are detailed in HOUSE_REMEMBERS_PROGRESS.md. Corrected the approved couch's long-axis fitting while retaining its original collider; cloth/support queries use actual mesh triangles. Reading lamp follows LoungeContents during transformation. Mirror feed geometry/eligibility retained with unrendered edge-wear material. No engine/gameplay/visual acceptance. Existing property pass remains untested too; do not confuse either with verified 6295892.


## 25 October / Property Continuation
Actual player-eye comparison found shed lining covering exterior faces. Corrected inward direction relative to shed centre; collision/foundation/doors retained. Native1080/1440/3440 property views reviewed with damp timber/ground, sheltered vegetation and softened near-lens rain. Fresh case412/0 supplies actual traversal, carrying, exit physics, hiding and both departures. Not a claim all rooms or character art are finished. Scope: PROPERTY_CONTINUATION_VERIFICATION.md.
