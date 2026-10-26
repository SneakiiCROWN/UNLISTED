# Reusable visual inventory

Exact local project: `C:\Users\Snkii\Documents\UNLISTED\Game`.
Raw library: `C:\Users\Snkii\Documents\UNLISTED\Assets`.
Machine-readable private index:
`../Checkpoints/20261026_full_forensic_audit/GraphicsBaseline01/visual_asset_inventory.json`
and `.csv`: 275 imported runtime resources with full paths, SHA-256, native asset
statistics, resource dependencies, direct literal references and nearby retained
licence/provenance pointers. Raw-library index covers all 635 files, including
39 ZIP contents/CRC reviews in the forensic evidence. No media copied publicly.

| Existing source | Reuse | Licence evidence / constraint |
| --- | --- | --- |
| `assets/exterior/` | ambientCG Ground067/Concrete019/Bricks097 maps; woodland, roots, stumps and vegetation | `ambientCG_CC0.txt`, `Quaternius_CC0.txt`, `provenance.json`; specific selected derivatives have recorded hashes |
| `assets/exterior/arrival/` | Existing parked arrival car | `GGBotNet_CC0.txt`, `provenance.json`; retain earlier car and continuity |
| `assets/production_20261025/` | Current detailed sedan, FM radio, duct tape, wrench | `provenance.json`; radio creator CC0, props bundled CC0, Bricchi car commercial permission with attribution. Car is **not** blanket CC0 |
| `assets/interiors/home/` | Existing fitted bed, cabinet, desk and room furniture | Kenney CC0 via retained parent notice; derivative hashes in home provenance |
| `assets/interiors/last_call/` | Familiar service/equipment objects | Kenney CC0 and exact provenance; no arbitrary new machinery |
| `assets/architecture/`, `assets/furniture/`, `assets/machinery/` | Current door/room/equipment meshes; retain texture scale | Consult `THIRD_PARTY.md` and source provenance; no new raw redistribution approval inferred |
| `assets/original/` | Active Surveyor and established silhouettes | Existing notices/provenance; rejected studies remain separate and inactive |
| `assets/audio/foley/`, `assets/audio/sound_touch/` | Existing rain/room/physical sound context for visual studies | WASD, Sonniss and individual provenance; licensed raw recordings stay private |
| `assets/fonts/`, `assets/ui/input/` | Sharp readable documents/UI independent of retro world image | Font notices/OFL and Kenney CC0; preserve accessibility |

Runtime shaders already cover property-ground blending/wetness, night sky,
rain streaks, woodland, bark/leaves, cellar concrete, aged paint, timber,
curtains, mirror silvering, ink and film. See exact `shaders/*.gdshader` paths.
Do not add a second terrain plate or reflection camera to reproduce an existing
effect. `inspection_glass` is the authored mirror feed, not general window glass.

Raw archives not selected into the current game remain candidates, not approved
art or redistribution grants. Screenshot/reference images of other games are
reference material only. New use requires reviewing the actual retained licence.
The index deliberately labels licence pointers as review aids, not clearance.

Regenerate into a **new** folder using `tools/build_visual_inventory.py OUTPUT`.
The tool reads existing forensic asset/archive results, verifies all 36 original
baseline dimensions and hashes them; it does not import, extract, change saves,
modify media or approve rights. Preserve previous index versions.
