# Phase 4 - Balanced Atmosphere (isolated)

Based on Phase3 dd6c678; production remains 9e09084. All prior archives, saves,
settings, forensic evidence and graphics tags remain preserved. No merge or public
Windows release. Owner intermittent menu crash remains unresolved.

Three selected corrections, based on native Phase1/2/3 images and recording frames:
1. Solid tiered conifer crowns and pale palette rocks. The same 60 existing conifer
   placements now use already present connected branch/leaf prototypes. Existing
   near-tree collision policy is retained; no tree locations are scattered or
   routes moved. Stone batches reuse the licensed grain texture at world scale,
   retaining the actual rock meshes and all collisions.
2. Dark exterior timber. Balanced/Enhanced lift existing timber diffuse response
   by 1.32, increase existing clouded moon energy from .30 to .34, and lower the
   existing porch practical from 1.05 to .96. No extra lights, ambient emission,
   shadow atlases, renderer changes or global interior-ambient increase.
3. Excessively sharp front puddle highlights. Existing Phase2 ground has a
   default-off surface_restraint parameter; Phase4 Balanced/Enhanced use .32
   shallow-water roughness/.28 specular rather than .20/.38. Puddle shapes,
   sheltered masks, terrain, collision and rain remain established systems.

Implementation:
- exterior_world.gd attaches stable asset identity metadata to its render batches
  and matching colliders. Godot auto-renames duplicate node names; source asset
  identity now selects every intended conifer, bush and stone batch reliably.
  Baseline geometry/layout remain unchanged. Candidate01/02 visual evidence and
  the deliberately stopped incomplete comparison batch remain preserved.
- scripts/graphics_phase4_atmosphere.gd reuses property_finish batching and existing
  tree/stone/material resources. Changes are applied after the existing Phase3
  landscape only with --graphics-phase4. --atmosphere-baseline keeps Phase3.
- shaders/phase2_ground.gdshader and phase2_timber.gdshader add opt-in parameters;
  default values preserve prior profiles. Constant-power bed shaping also uses
  nonnegative inputs explicitly. No competing material/shader framework.
- scripts/graphics_study.gd and tools/run_graphics_study.py expose isolated flags
  and moving-window controls. scripts/graphics_phase4_route.gd adds first knock,
  front entry/exit, ordinary closing and actual wall-cover AI sight checks.
- Original keeps original rendering on revised art. Balanced is provisional first
  review choice. Enhanced retains the existing optional SSAO/SSR/fog study; no new
  SDFGI, probes, ray tracing or heavier shadows are introduced.

Glass retains Phase3's cleaner fallback: static room return disabled. Moving tests
use the actual Surveyor and production locomotion/collision method with a labelled
controlled camera strafe. No story encounter is newly authored or promoted. Bodies
remain in reached positions until QA exit, without a tail-of-clip teleport. These
are stronger than static fixtures but not natural first-playthrough encounter proof.

Production story, puzzles, Surveyor model/AI, hiding, arrival/departure cinematics,
input and saves are untouched. The office has no exterior window at the E04 fixture;
E08 is an obstructed fence control. Captions preserve those coverage limits.
Actual native results, performance, integration ranking and delivery hashes are
recorded separately. Human artistic approval and full integration remain pending.

A selected Candidate03 1440p run logged one renderer null-particle resource error;
it completed but was rejected. Evidence03/final_balanced2560 is preserved. No
crash or owner-file change occurred. The exact root cause is not established.
Phase4 now chooses the same Phase2 rain material before emitters enter the tree,
and the profile avoids a redundant live draw-mesh swap. This removes avoidable
resource churn; it is a hypothesis-driven application change, not a proven engine
fix or a claim about the owner's menu crash. Bounded native rechecks and final
matrix results remain the acceptance gates. No engine/driver change.
