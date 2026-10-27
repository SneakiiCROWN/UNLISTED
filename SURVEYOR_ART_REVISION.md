# Surveyor Reborn — custom anatomy and field-coat revision / 28 October 2026

**PRIVATE ART REVISION. NOT PROMOTED. FINAL ART STANDARD NOT MET.**

Recovered clean complete source `84606f1`; no newer local work was present.
Pre-change recovery is `recovery/pre-surveyor-art-revision-20261028`.
Work is on `production/surveyor-art-revision`. Neither the active Surveyor nor
the previous rejected fantasy-derived candidate is overwritten. No public release.

## Implemented character work

- Generated a new aged MPFB human with a narrower chin, longer nose, restrained
  cheek/eyelid asymmetry and preserved eyelid, ear, mouth and nose topology.
  The actual full source and target recipe are preserved. This is adapted and
  authored MakeHuman anatomy, not a claim that every vertex was sculpted from
  scratch. No superhero head or fantasy tunic is used on this revision.
- Fitted separate anatomical eyes using MakeHuman's surface-relative proxy
  fitting. They retain grey irises, pupils, sclera and transparent corneal layers.
  Emission is zero. Correct alpha prevents the outer layer becoming an opaque
  black cover. Their brightness in the game comes from actual lighting.
- Retained photographic skin detail from the existing licensed aged-skin source;
  desaturated it moderately, added conservative texture-derived tangent detail
  and roughness, and kept the face readable in the actual retro presentation.
- Constructed new coat topology with **shared torso/armhole/sleeve vertices**,
  curved panel transitions, split lower panels, asymmetric storm collar, offset
  closure and surface-fitted pocket welts. This is not another extracted or
  nearest-weight-transferred MakeHuman coat, nor a set of fantasy clothing parts.
- Constructed new trouser surfaces, tucked cuffs, continuous service boots and a
  scalp-fitted cap/curved weather peak. The working Quaternius anatomical hands
  and original finger weights are retained as close-fitting gloves.
- Assigned explicit anatomical coat/leg weights, with continuous torso and
  shoulder blends. Added a candidate-only upper-back inclination of approximately
  1.4–2.6 degrees. Existing animation rate matching, gaze eligibility and capture
  arm solving remain in charge. No AI speed, capsule, attack, hearing, hiding,
  navigation, checkpoint or save-schema change was made.
- Kept the original seven animation clips on the same 65-bone skeleton. The
  earlier retargeted UAL2 response remains on the previous candidate only; it
  was not forced into this character's idle. Skinned cloth folds are used;
  unstable secondary cloth simulation was not introduced.
- Reused the preceding candidate's short licensed positional cloth cues and
  existing surface footsteps/replaceable vocal slots. No generated or downloaded
  vocal replacement, new story identity or claim about Simon was introduced.

The MPFB add-on remains an isolated local authoring dependency. Original archive,
extension configuration, earlier compatibility failures and successful Blender
5.2.2 registration stay preserved. The basemesh and system-eye files explicitly
declare CC0 in their headers; aged skin intake records identify its CC0 pack.
Add-on GPL licensing is separate from those mesh/texture licences. All raw media,
packed Blender work and audio remain private.

## Art inspection and limits

Reviewed neutral full front/side/rear, bright face/profile and clothing renders
before exporting. Construction01 exposed opaque eye covers, shoulder stretching,
coat/trouser intersections and detached cap fit. Construction02 repaired those
main defects; Construction03 fixed discontinuous torso weighting and added fabric
normal response. The final Construction04 fits the cap foundation to the actual
scalp. All intermediate files/renders/logs remain private, not relabelled passes.

Reviewed actual Windows front, face, side-quarter, rear, hall silhouette, rain,
cellar, both sides of the existing window, walking, running, noise investigation,
pursuit and capture images. The comparison cameras, atmosphere profile and
lighting are shared with the active model and previous rejected candidate.
Neutral inspection includes a clearly labelled fill light. Rain/cellar shots use
the actual environment. No world geometry was altered for a better art screenshot.

**This is a more human anatomical foundation and a different, purpose-built
outfit; it is not a finished frightening antagonist.** The coat remains too
smooth/uniform in several light conditions, footwear needs better last/toe/sole
detail, and the cap/coat silhouette can still read as an ordinary service uniform.
The elongated forehead and pale irises need human artistic assessment. The skin
does not yet have the full localised ageing/variation of a final character.
These are specific remaining art deficiencies, not reasons to rewrite the AI or
count another successful integration as artistic approval. Keep it private.

## Native Windows verification

Selected Windows runtime: `Candidate02/UNLISTED.exe` in the private recovery root.

| Check | Result | Actual scope |
| --- | --- | --- |
| Revised 1080p showcase | 21 passed / 0 failed | Original bones/clips, actual collision-driven walking/running, real source-led investigation, pursuit, warned capture, pause, death and retry |
| Active-model 1080p comparison | 11 / 0 | Same eye-height/render/lighting fixtures, current fallback selected |
| Rejected-candidate 1080p comparison | 12 / 0 | Same fixtures, earlier fantasy study and its UAL2 preview selected |
| Revised 1440p and 3440x1440 | 11 / 0 each | Native art, window, rain and cellar inspection |
| Revised multi-angle capture | 37 / 0 | Three player-facing angles, pause/resume, human arm reach, death/retry, repeat/interrupted capture, reduced-motion and story survival, non-silent game bus |

Accepted runs log no runtime errors/warnings and preserve the owner's save/settings
hashes. Candidate01's earlier 19/0 showcase remains a separate cap revision;
it is not represented as the final binary. The 58/0 navigation/hearing/hiding
baseline from the preceding asset milestone is retained; it was not needlessly
rerun because those gameplay systems did not change. No fresh investigation or
ending route is claimed. Hardware-controller play and human fear/art approval
remain unverified.

Showcase placement and phase transitions are explicit QA fixtures, not new
authored story encounters. Locomotion uses the real production collision method;
the contact segment uses actual perception and AI. Investigation uses a real
positional metal cue and the existing hearing/search code from a labelled placed
starting state. The recorded camera follows the actor for inspection only; no
camera control was removed from ordinary gameplay.

Recordings sample approximately six images per second at actual wall-clock
durations. Their 30fps encoding repeats frames; it is not native 30fps footage or
human playtime. No subjective listening approval is claimed from signal checks.

## Recovery and selection

Private root: `../Checkpoints/20261028_surveyor_revision/`.
Packed editable model: `Construction04/Surveyor_Custom_Fieldcoat.blend`.
Textured rigged GLB: `Construction04/surveyor_revision.glb`.
The blend retains the original animation tracks muted for rest-pose editing;
unmute a single track to inspect it. Full generated MPFB source, recipe and
textures are preserved separately so the head can be revised.

Inside an isolated QA mode, select:

- No character flag: original working Surveyor.
- `--surveyor-assets`: preceding rejected fantasy-derived candidate.
- `--surveyor-revision`: this custom head/field-coat revision.

The revision flag without a recognised QA mode is refused before normal startup.
Ordinary New Game, all saves, the public v0.10.0 game and preserved private
Next Nightmare delivery retain their existing behaviour and character.

Exact private/public recovery hashes, showcase ZIP, complete source/Blender
recovery package, extracted executable check and SHA-256 values are recorded in
`DELIVERY.json` when sealed. Original menu-crash and intermittent renderer faults
remain unresolved; this is **not** a stability clearance or public release.
