# Graphics techniques — source-informed candidates, not measured wins

Current engine: Godot 4.7.2-stable, Forward+. No renderer swap, engine fork,
paid plugin or system change. API defaults/feature behaviour must be checked
against this exact installed engine during each isolated experiment.

| Technique | Initial decision | Limitation / acceptance |
| --- | --- | --- |
| Existing direct lights/shadows | First study | Correct source position, falloff and bias before adding lights; preserve readable labels and dark escape routes |
| Material roughness/normal wetness | First porch study | Current property shader already implements damp paths and rain rings. Avoid uniformly glossy terrain; retain dry shelter |
| ReflectionProbe UPDATE_ONCE | First reflection candidate | Low steady-state cost; capture cost and stale dynamic geometry must be handled. Explicit room-state updates only when necessary |
| SSR | Optional later A/B | Screen-space omissions/off-screen loss; transparent glazing is not a reliable SSR target. Never promise complete mirrors or accurate hidden actors |
| SSAO | Small cellar A/B | Contact depth, but costs GPU time and can produce halos/darken clues. Compare short radius/intensity before global use |
| SSIL | Deferred | Can alter colour/readability and depends on view; measure alone before combining |
| Volumetric fog / FogVolume | Deferred local study | Preserve near paths and rain visibility; assess spatial transitions, cost and banding |
| SDFGI | Defer pending evidence of need | Higher cost, dynamic scene constraints/light leaks; no blanket switch-on |
| LightmapGI | Assess architecture first | Mostly procedural runtime construction and changing rooms complicate authoring/bake continuity; no assumed drop-in win |
| Additional live SubViewport reflections | Avoid initially | Another renderer resource/lifetime path and recurring scene render; existing narrative mirror already has a carefully gated feed |

Official references checked 26 October 2026:

- [Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- [ReflectionProbe](https://docs.godotengine.org/en/stable/classes/class_reflectionprobe.html)
- [GI introduction and tradeoffs](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/introduction_to_global_illumination.html)

These references establish capabilities/tradeoffs, not measured UNLISTED
performance. Current stable documentation may evolve; runtime validation remains
required. No technique in this table has been promoted by this checkpoint.
