# Interior / glazing continuation — 21 October 2026

This is working development AFTER the sealed public 0.5.5 Last Departure delivery.
Do not replace that ZIP, tag, complete-source archive or evidence directory.

## Implemented

- The records office uses two fitted Kenney CC0 desk meshes, retaining the original
  footprints and .8 m worktop height. Existing worn wood/steel replace the source's
  bright colours. Drawer construction gives the stations a believable purpose.
- The wall record's type fits its actual paper; corner pins attach it physically.
  Archive CRT text fits the screen, with restrained phosphor and physical controls.
- An open archive box holds files on the actual cabinet top. A continuous lead joins
  the working stations; the existing recorder now has a visible tape path.
- The utility mattress has a raised metal cot frame and a shaped, draped canvas
  cover. The fuse, stock bench and circulation remain in their original positions.
- The existing rain recording has two real 3D sources at the actual kitchen/lounge
  glazing. The room-wide filtered bed is quieter, leaving positional detail near
  the windows; the stronger outdoor rain and cellar shelter levels are retained.
- Player-height review found a rain streak INSIDE the room near the window. GPU
  heightfield collision alone missed some drops. The streak shader now also clips
  fragments within the existing house, porch, annex and shed shells. Actual views
  show the indoor streak removed while rain remains beyond the glass. These bounds
  must follow any future change to the building footprints.

## Evidence and verification

Current export: ../Builds/UNLISTED_InteriorLife_04/UNLISTED.exe.
Its targeted interior route passes 28 checks using normal movement and interaction
from a labelled powered fixture: hall recording, transport playback, archive/key,
door return, utility fuse, lounge circulation, window approach and save/load.
Screenshots and a six-second game-bus recording are in QA/interiors.

Before the final cosmetic cloth/rain rendering changes, InteriorLife_02 also passed
the impossible-room regression (44) and systems/physical interaction (33). Those
results are not mislabelled as tests of a newer binary. Final exterior/recount
receipts are kept alongside the current preview. The first fixture omitted the
hall recording and failed to reopen the deliberately slammed office door; its
failed evidence remains in InteriorLife_01. Normal gameplay was not changed to
make those mistaken fixture assumptions pass.

No complete fresh route or new public release is claimed for this continuation.
The published Last Departure binary separately has both full ending routes verified.
Human playtesting, subjective listening and final art approval remain pending.
The cot/recording hardware still use simple original construction; broader interior
art needs further selective work. The lounge/impossible furnishings and kitchen
layout are deliberately preserved. No rejected Surveyor study is promoted.

## Provenance

Selected desk and open-box meshes come from the user's existing Kenney Furniture
Kit 2.0 archive. Its included License.txt explicitly grants CC0. Originals remain
untouched. Selected files, licence and archive hash are under assets/interiors.
Existing Dusk wood/steel, original paper/canvas and licensed rain remain in use.
The public source omits all media, including these selected models. The complete
licensed project and original asset library remain local.

Surveyor anatomy/workwear source review stays separate in
../Assets/Intake_20261021_MakeHuman/Surveyor_Licensed_Source_Review.blend.
It is source preparation, not a fitted/rigged enemy or approved character candidate.
The ordinary Quit cleanup warning and earlier NVIDIA issue remain documented in
LAST_DEPARTURE_PUBLICATION.md; neither is claimed fixed by this art/audio work.
