# UNLISTED asset provenance

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
