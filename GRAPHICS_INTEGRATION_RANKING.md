# Provisional integration order - graphics phases 1 to 4

Nothing below authorizes a production merge. Owner artistic review, relevant story
state/encounter checks and stability validation are still required. Original PSX
must remain available. Rankings concern value and dependencies, not approval.

| Rank | Treatment | Recommendation and remaining gate |
|---|---|---|
| 1 | Phase3 ground, foundations and protected-route layout | Retain as the environment base for review; native traversal/checkpoint proof is separate from the fixed cameras. Check legacy positions and arrival/departure shots during integration. |
| 1 | Phase1/2 practical falloff, roof-masked lit rain and sheltered wetness | Reuse the current systems. No added lights or particles are needed; verify wetness through normal weather/story states. |
| 1 | Phase4 softer puddle highlights and timber readability | Leading Balanced material candidate; compare matched moving footage before approval. Keep default parameters at original values for rollback/Original. |
| 1 | Aged glass with clear fallback | Retain real outside visibility. Dynamic actor clips supplement static controls. Keep precomputed room return off; a believable window is preferable to false scene information. |
| 2 | Phase4 connected woodland silhouettes and textured stone | Review composition versus preserved Phase3 at all sizes. Stable batch IDs fix incomplete application. Consider measured draws/primitives and fine-branch aliasing; do not accept cost solely because more detail exists. |
| 3 | Enhanced SSAO | Optional only if owner review finds useful contact depth over Balanced. Retain current bounded settings; no radius/quality escalation. |
| 3 | Enhanced SSR | Optional visual effect. Screen-space information is incomplete; never use a reflection as a mandatory clue or reliable actor mirror. Compare cost/benefit in PERFORMANCE.json. |
| 3 | Enhanced low exterior fog | Optional. Keep volume outside house/porch and verify openings/sightlines. Short tests do not establish sustained performance or fairness in every encounter. |
| Hold | Static lounge cubemap | Accurate only for its baked empty powered room. Disabled in Phase3/4. Needs state gating and a suitable use case before reconsideration. |
| Excluded | Live ReflectionProbes | Prior minimal native controls reproduced seven texture-RID shutdown warnings. No engine patch or harmlessness claim. |
| Deferred | SSIL, SDFGI, hardware ray tracing | No demonstrated need in the selected candidate. Do not stack features to increase a checklist. |

The native median/p95 table and retained slow/spike samples are in
GRAPHICS_PHASE4_RESULTS.md/PERFORMANCE.json. There are no GPU timestamps or
minimum-spec/sustained-FPS claims. Human visual judgement remains pending.
The owner main-menu idle crash remains unresolved, independently of these ranks.

Current ultrawide five-second tradeoff: porch-outward Balanced median/p95
1.65/2.08 ms versus Enhanced 2.15/2.79 ms. Lane Balanced 9.75/12.23 ms
included two >33.3 ms intervals; Phase3 baseline 9.95/11.30 ms had none in its
sample. These do not establish a sustained performance win. The extra Enhanced
cost and inconsistent tails support keeping it optional, with artistic benefit
still requiring owner judgement.
