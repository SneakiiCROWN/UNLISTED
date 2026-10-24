# UNLISTED asset provenance

Missing Minute: bedSingle, cabinetBedDrawer, bookcaseClosedDoors, books,
lampRoundTable and radio reuse the existing Kenney Furniture Kit 2.0 archive,
CC0 (assets/interiors/Kenney_CC0.txt). Private provenance records hashes in
assets/interiors/missing_minute_provenance.json. The single carryable tin is a
scene-selection derivative of the approved licensed Dusk tins model; geometry
and textures stay private. No new third-party downloads or AI-generated media.

Working interior continuation (after public 0.5.5): selected desk and open archive
box from Kenney Furniture Kit 2.0, supplied archive kenney_furniture-kit.zip.
Included License.txt explicitly declares CC0; retained in assets/interiors/Kenney_CC0.txt
with SHA-256 provenance.json. Source colours are replaced by existing worn materials.
These are not retroactively added to the sealed Last Departure executable.

Verified 19 October 2026. Original archives remain untouched in ../Assets and Downloads.

- Architecture: Elegant Crow, Retro Modular House Pack. Models CC0, textures AmbientCG and additional Pexels images as declared by creator. https://elegantcrow.itch.io/retro-modular-house-pack . Converted selected FBX files with Blender, attached supplied atlas. https://creativecommons.org/publicdomain/zero/1.0/ ; https://www.pexels.com/license/ . Use integrated game only; do not resell source images as an asset pack.
- Furniture: Daniel Jurys, PSX Derelict Furniture Standard, CC0. https://daniel-jurys.itch.io/psx-derelict-furniture . Selected supplied GLBs; positioned and scaled.
- Machinery: chilly_durango, 3D Retro Plumbing, Wiring & Machinery, CC0. https://chilly-durango.itch.io/3d-retro-plumbing-wiring . Converted supplied blend models to GLB; external images relinked.
- Concrete: Poly Haven, Dirty Concrete, diffuse from the supplied dirty_concrete_4k.blend.zip. CC0, https://polyhaven.com/license . Applied to basement walls.
- Ambience: CAPTNPHANTOM, PSX Ambient Pack, supplied custom licence in assets/audio/ambient_license.txt. Hollow.wav integrated in game. Commercial and personal game use permitted. Original full-length music stays in ignored conversion sources; the modified game loop is versioned for recovery. Pack redistribution prohibited.
- Additional geometry, story, effects and procedural sound recordings: created for UNLISTED in this workspace.
- Kitchen furnishings and surface textures: GameDev Deck, Dusk House PSX Kitchen free, supplied CC0 LICENSE.txt in assets/dusk/. Extracted from the existing Downloads archive and converted FBX to GLB with external images relinked. No purchase or additional download.
- Godot Engine: MIT licence, https://godotengine.org/license/ .

No reference screenshots are used as textures. No paid assets or software purchased.

- Metadata font: Analog Mono Plus v1.1 by Andrew Gleeson, extracted from the existing licensed user asset archive. Incorporated game use permitted by the supplied licence, included at assets/fonts/LICENSE.txt and with this build. Do not redistribute the loose font as a font pack.
- Interface body/title: Segoe UI and Bahnschrift via Godot SystemFont on Windows. Font files are not copied or redistributed.
- The Unrecorded (Surveyor replacement): original Blender mesh authored for UNLISTED; coat texture derived from the existing CC0 Daniel Jurys furniture texture. Source tools/Unrecorded.blend. Old Surveyor source remains preserved.

- v0.3 active Surveyor: original articulated Blender geometry and original generated work-canvas texture. The old mattress-derived v0.2 character is preserved as a historical asset. Animation authored in Godot AnimationPlayer; no external animation library.
- v0.3 paper/door surfaces, cartridge fuse, supply/isolation panels, exterior frames and cosmetic flashlight hand: original procedural textures/geometry authored for UNLISTED. Existing licensed architecture, furniture and audio remain in use.

- v0.4 Surveyor: Quaternius Universal Base Characters Standard male humanoid and selected Universal Animation Library Standard in-place animations, supplied CC0 1.0 licences verified in local archives. Original adapted workwear, hood, service patch and textures for UNLISTED. Rest-relative retargeting retains target limb proportions. Universal Animation Library 2 audited but no clips shipped. https://quaternius.com/ ; https://creativecommons.org/publicdomain/zero/1.0/ . Source tools/Surveyor_v04.blend and tools/build_skeletal_surveyor.py; licence assets/original/QUATERNIUS_CC0.txt. Prior character versions are historical and preserved.

- v0.4 recorded wood/stone walking and impacts: WASD Sound, 2026, selected from the already downloaded WASD Footstep SFX Free Bundle v3 archive. Supplied royalty-free licence permits commercial game use and project modifications, prohibits standalone sound redistribution and model training. Twelve clips converted to mono 22050 Hz PCM, trimmed and level matched for this game. Licence assets/audio/foley/WASD_License.pdf and .txt included. These are game-incorporated recordings, not a standalone sound library. Source archive is preserved untouched outside the project; no download or purchase. Door movement now uses quiet recorded timber contact instead of the old buzzing tone; dedicated hinge recordings are still a polish item.

- v0.5 active Surveyor: continued CC0 Quaternius humanoid and UAL retargets with original skinned service coat, gloves, relaxed hand posing and less reflective eyes. Source tools/Surveyor_v05.blend (packed textures) and build_surveyor_v05.py. Prior v0.4 character and sources remain preserved.
- v0.5 plaster accent: Dimitrios Savva / Poly Haven, Peeling Painted Wall, CC0, https://polyhaven.com/a/peeling_painted_wall . Diffuse selected from the existing peeling_painted_wall_4k.blend.zip, resized to 512 pixels and desaturated. No new downloads. Room dressing reuses the existing licensed Dusk and furniture materials; transport, paper receipt, property ledgers and survey are original code geometry.

- Continued Surveyor: same CC0 Quaternius worker rig and UAL clips, original adapted folded hood, knee-length inspection coat, relaxed brow, matte/desaturated skin and existing work-canvas weave. Active source tools/Surveyor_Continuation.blend and refine_surveyor_continuation.py. All earlier models remain preserved. Active diffuse/normal maps are 512 pixels; body cloth uses a supported second UV channel. The inspection/capture uses original Godot camera, skeletal modifier and physical alignment work, without new third-party animation dependencies.
- Surveyor inhale and cloth contact: Epic Stock Media and InMotionAudio, selected from the user's existing Sonniss GDC 2026 bundle under its bundled synchronized-project EULA. Two short recordings only, converted to mono 22050 Hz Vorbis with restrained filtering/fades. Provenance and original hashes: assets/audio/foley/surveyor_provenance.json; exact licence: SONNISS_GDC_License.pdf. Original download collection is untouched and is not included in game/source packages. Recordings are incorporated game assets, not a standalone sound library. No AI training or sound-model use. The final three-click register motif is derived from UNLISTED's existing original latch sound.
# Exterior continuation / 20 October 2026

- Quaternius Ultimate Nature Pack (June 2019), 18 selected meshes from the supplied
  archive. CC0 1.0; exact bundled licence in `assets/exterior/Quaternius_CC0.txt`.
  Normalised uniformly, materials adapted, instanced for the Briar Lane woodland.
- ambientCG Ground067, WoodSiding006, Bricks097 and Concrete019, supplied 1K JPG maps.
  CC0 1.0, verified against the [official licence](https://docs.ambientcg.com/license/).
  Original JPGs retained; runtime imports limited to 512 pixels with mipmaps and VRAM
  compression. See `assets/exterior/provenance.json` for source/output hashes.
- No complete downloaded library, unrelated reference artwork, raw commercial sound
  collection or unverified Industrial/PSX Graveyard demo asset was added to the game.


- Weather: Jake Fielding, Interior Wind Rain and Storms, constant window rain from the existing Sonniss GDC bundle. Adapted to a short seamless in-game loop with filtered sheltered playback. Source hash/recipe at assets/audio/foley/weather_provenance.json; existing SONNISS_GDC_License.pdf applies. No loose-library redistribution; no new Surveyor vocal recordings.

# First-person / Surveyor presence continuation

- First-person work torch, hands and sleeves: original project geometry and materials; reproducible source tools/build_first_person.py and FirstPerson_WorkTorch.blend. No new external art dependencies.
- Surveyor presence: existing CC0 Quaternius worker topology/rig and seven retargeted UAL clips, with original fitted thick hood, damp hair, facial sculpt and coat-fold changes. Active source tools/Surveyor_Presence.blend and refine_surveyor_presence.py. Earlier sources/models remain preserved. Provenance assets/original/surveyor_presence_provenance.json. Existing Sonniss temporary vocal/cloth cues remain unchanged and replaceable.

- Isolated Erasure character study (not the default Surveyor): existing CC0 Quaternius base/UAL clips plus Hair_Long from Universal Base Characters Standard, licence reread from the preserved archive. Original continuous weighted coat, facial sculpt, vertex wear and fitting. Existing skin/work-canvas textures retained. Packed editable study: tools/Surveyor_ErasureStudy.blend. No rejected Hollow/Return design was promoted.


## Recovered home / underfloor work

Kalam Regular by Indian Type Foundry (2014), unmodified SIL OFL 1.1. Source: https://github.com/google/fonts/tree/main/ofl/kalam ; licence assets/fonts/Kalam_OFL.txt. Kenney CC0 furniture derivatives add UVs and fitted bedding; provenance in assets/interiors/home/provenance.json, originals and Blender sources preserved locally. Quiet paper handling derives from the already licensed SONNISS GDC 2026 antique-book recording; provenance in assets/audio/foley/paper_provenance.json. Original Eli sketch and cloth shader are authored game material. Raw media is not included in public source.

The underfloor rack movement cue derives from 344 Audio / Extreme Winds Vol. 1, Large Metal Box Drag (SONNISS GDC 2026). Paper and rack edits select active sections, apply fades and peak matching; original bank files remain unchanged. See the local provenance JSON files. Both remain covered by the bundled SONNISS licence.

The experimental utility inspection glass uses Kenney Furniture Kit's bathroomMirror.glb (CC0), from the user's preserved archive. Licence: assets/interiors/Kenney_CC0.txt; source entry/hash: assets/interiors/spare_mirror_provenance.json. Its render texture, off-axis camera and contradictory cloth layer are original code. Raw GLB remains in the complete private source, not the public code checkout.

The Inspection milestone's walk-in office cupboard derives from Kenney Furniture Kit 2.0 bookcaseClosedDoors (CC0). Internal shelves/base are removed and the existing hinged doors extended; frame, back, top and handles are retained. The original approved model, Blender derivative and SHA-256 provenance stay in the complete local project. The inspection case reuses the approved Kenney cardboardBoxOpen. The small fluorescent sleeve seal is an original SVG; battery sleeves/cells and inspection-head fitting are original game geometry. No new third-party media download or Surveyor artwork is introduced in this milestone.

## Arrival station wagon

GGBotNet, PSX Style Cars, Car 01 / grey texture, CC0 as posted by the author at https://opengameart.org/content/psx-style-cars . Exact download/page and original files preserved locally. Converted to glTF at 4.45 m length with wet material response. Provenance and licence in assets/exterior/arrival/. Raw media remains excluded from public source.

### Last Call monitor
`assets/interiors/last_call/speakerSmall.glb` is from the existing Kenney Furniture Kit (CC0). Its included licence and local provenance accompany the runtime asset. No restricted raw library files are published with the source.


24 October development (untested): psx_prop_single_bottle.glb selects Bottle_0 under the unchanged parent of the existing approved Dusk psx_prop_bottles_01.glb. Original geometry/materials/embedded image retained. Local source/output hashes and selection provenance are in assets/dusk/psx_prop_single_bottle.provenance.json; tools/select_scene_component.py records the non-destructive scene selection. Derivative raw media remains private under the original asset licence. No new third-party download. The full existing Dusk sink unit is now used at its proper counter proportions; no new sink artwork.


24 October isolated arrival study (untested): Car_Engine_Turning_Off.ogg and Car_Door_Close.ogg are unmodified selections from the same already-approved GGBotNet PSX Style Cars CC0 source pack used for Eli's parked car. Local output filenames and exact original hashes are recorded in assets/audio/arrival/provenance.json; the original intake archive is preserved. No new download, generated voice or final mixing approval. Audio media stays private with the complete source.


### Property overhaul / UNTESTED source, 24 October

No new asset intake, downloads or purchases. Reuses the already integrated Quaternius CC0 nature meshes/prototypes, ambientCG CC0 Ground067/Concrete019/WoodSiding006 textures, licensed existing Dusk steel and original work canvas. Hardware and the inactive bootprint shader are original native code/geometry. Existing licences and provenance above apply; raw media remains private.


### House interior pass / UNTESTED source, 24 October

No new raw asset intake. Reuses the existing approved Daniel Jurys CC0 couch, Kenney/home book and mirror assets, licensed Dusk materials, ambientCG Concrete019, and original canvas/paper/latch. Original code supplies static hardware, fitted throw, concrete/glass shaders and an inactive recorder-memory study. Existing licences/provenance apply. No new dialogue, creature recording or external character artwork.

### Isolated Surveyor Reborn construction study / 24 October

Development-only, not a replacement approved for ordinary gameplay. Uses the preserved MakeHuman CC0 system male_generic proxy, low-poly eyes/brown eye texture, male_worksuit01 and onlytheghosts old Eurasian male skin from the existing CC0 intake. The supplied system mhclo/proxy headers identify the CC0 dedication and Data Collection AB / Joel Palmius / Jonas Hauquier; complete intake licences remain in Assets/Intake_20261021_MakeHuman. Existing Quaternius CC0 65-bone rig, seven UAL retargets and native finger/foot topology are retained. Original inspection-coat/cap construction and rest-pose fitting are in tools/build_surveyor_reborn.py and the private packed tools/Surveyor_Reborn.blend. Exact source hashes and construction limits are in assets/original/surveyor_reborn_provenance.json. Raw media, editable licensed source and failure captures remain private. No new downloads, purchases, character voice or public playable release.

### Integrated arrival / 25 October 2026

The New Game arrival also selects Car_Door_Open.ogg and Car_Engine_Loop.ogg, unmodified from the same preserved GGBotNet PSX Style Cars CC0 archive. Hashes and original filenames are in assets/audio/arrival/provenance.json. Engine-off and door-close selections are reused. No new download, voice or paid asset. Raw media remains private; notices accompany the private Windows package.

### Selected production integration / 25 October 2026

Retro Car With Interior by Bricchi Games, https://bricchi-games.itch.io/retro-car-with-interior . Creator explicitly permits commercial use with attribution and describes CC 4.0 in the author comments. Credit retained in game and accompanying notice. Supplied white/emission textures relinked; grounded origin, simplified glass and glTF derivative. Original station wagon and all originals remain preserved privately. No implication of a more specific licence variant.

Wrench and DuctTape from the user's retro_props.zip: included retro_props_lists.txt dedicates the pack to CC0. Only these two optional portable workshop objects are selected. FM Radio by Animimo Studios, https://animimostudios.itch.io/psx-electronics-asset-pack-free : creator page declares CC0. This replaces the existing functional receiver's visual only; original dial and puzzle remain.

Input Prompts 1.5A by Kenney, CC0, https://kenney.nl/assets/input-prompts . Seven supplied keyboard/Xbox glyphs selected from the existing archive. No new download. Full local archive hashes and selection records remain private. The complete source and Windows notices retain attribution; raw media is excluded from public code snapshots.

### Sound, Touch and Tension / 25 October 2026

Selected existing Sonniss GameAudio GDC2026 recordings: Sonic Bat Vintage Radio power button 003 and mode select wheel 006; 344 Audio Antique Small Metals opening an antique blowtorch lid; Epic Stock Media HD Lock and Mechanism counting-machine container interaction; InMotionAudio Foley T-Shirt cloth movement24. These are short mono game-incorporated derivatives under the supplied Sonniss EULA, preserved at assets/audio/sound_touch/Sonniss_GDC2026_License.pdf. Exact original/output SHA-256, source paths and processing are in assets/audio/sound_touch/provenance.json. Attribution is not required by that EULA; originals and editable sources remain private. They are not relicensed CC0 or published as a sound library. No voice generation or AI training.

Kenney impact sounds: impactMetal_light_000/001 and impactSoft_medium_000, CC0 from the already downloaded archive. Included notice assets/audio/sound_touch/Kenney_CC0.txt. New fixed hand poses are original derivatives of the game's existing original work-hand construction helpers; no external hand/model source. Source and packed editable Blender files preserved privately; original support hand and all old audio remain intact.
