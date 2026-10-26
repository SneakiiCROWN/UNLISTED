# Modern PSX production workspace

Status: baseline preparation only; native owner idle crash remains unresolved.
No experimental lighting, reflections, fog or materials promoted to gameplay.
A$0 spent. Engine/template/renderer held at 4.7.2-stable / Forward+ Vulkan.

## Preserve and compare

Runtime baseline: private `4d6e32c`, forensic02 executable SHA-256
`46ef067cb9efe11f311ed68bf6cd8bb3a56b7a9512051bd8f5ff8832e2068571`.
Baseline evidence lives in
`../Checkpoints/20261026_full_forensic_audit/GraphicsBaseline01/`.
`BASELINE_GALLERY.html` links 36 original native images. Exact resource paths,
hashes, dimensions, dependencies and provenance pointers are in JSON/CSV there.

1. Finish the current forensic checkpoint and preserve ordinary idle evidence.
2. Build isolated porch/lounge/cellar studies using the exact baseline camera
   arrays in `scripts/production_views.gd:38`. Do not modify normal startup.
3. Compare one effect at a time: local light/shadow setup; bounded ground wetness;
   static reflection probe; restrained contact occlusion. Keep exposure, retro
   strength, FOV and scene state matched. Record weather phase differences.
4. Measure focused native frame times and workload separately from image readback,
   capped and uncapped, at all three render sizes. Include moving gameplay before
   claiming a performance target. Record GPU identity and focus exclusions.
5. Only combine independently useful effects after visual, gameplay and stability
   review. Preserve the original profile. No new player-facing presets yet.

## Ranked practical work

| Priority | Study | Benefit | Main risk / gate |
| --- | --- | --- | --- |
| 1 | Porch practical-light and contact-shadow balance | Supports believable timber/door contact without globally brightening night | Bias artifacts, washed-out facade; compare unchanged exposure |
| 2 | Ground-only broken wetness and small rain response | Existing material already has roughness/noise/ripples; refine rather than duplicate | Plastic mud, excessive highlight, masks affecting sheltered areas |
| 3 | Lounge dirty glass with bounded UPDATE_ONCE probe | More material presence while retaining sightings outside | Stale capture after room changes, reflection hiding clues |
| 4 | Cellar short-radius occlusion and utility-light falloff | Gives existing beams, pipes and equipment depth | Dark evidence labels, halos, heavy screen-space cost |
| 5 | Selective atmospheric depth | Preserve readable paths and layered forest | Fog washing out composition, extra GPU cost |

Deferred: blanket SSR, global SSIL/SDFGI, live reflection cameras, ray-tracing
plugins and asset replacement. No story, collision, Surveyor art or save changes
are needed for these initial studies.
