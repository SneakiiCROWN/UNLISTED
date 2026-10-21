# Field Return / native acceptance

The full input-driven Windows routes in Investigation_07 each passed 142 checks. Both start at New Game, solve the original route, meet the live Surveyor, die/retry, escape, carry a physical tool tin down the ramp, recover the original report, earn the optional comparison, choose an ending, save/reload the signed departure, pause/resume, leave through the gate and restore the completed ending.

The final delivery is Investigation_08. The only ordinary-game code difference from the continuous-route build is the register explanatory label: contained lines and wording that distinguishes legacy immediate completion from the new playable departure. Final focused checks passed:

| Evidence | Result | Build |
|---|---:|---|
| Physical investigation, true crouch, cover, save/departure, new register at all three resolutions | 48 / 0 | 08 |
| Props, support/collision, throwing, memory, saves and old schema | 33 / 0 | 08 |
| Legacy eligibility, both endings, completed saves, encoding and three-resolution layout | 84 / 0 | 08 |
| Recount pause/save/skip at 2560x1440 | 20 / 0 | 08 |
| Recount pause/save/skip at 3440x1440 | 20 / 0 | 08 |
| Impossible-room visibility, occupancy, restoration and three-resolution views | 43 / 0 | 07 |
| Live threat, hiding, story mode, collision, recovery and animation | 54 / 0 | 07 |

Screenshots were visually inspected. The original report is readable in a scrollable record, the physical cover fits its holder, and the final register text stays inside the screen. The cover fixture checks actual blocked eye/torso rays, not a cosmetic hiding flag. The heavy-object route uses input and swept rigid-body carrying. Separate labelled placements establish that a person depresses the release, leaving it closes the drawer and a mug is too light.

Live player settings and checkpoint hashes were unchanged across each acceptance batch. Native recordings retain original wall-clock timing and game-bus sound. Captured signal is not a subjective audio review or a performance benchmark.

Earlier attempts remain preserved in Investigation_01 through _07. In particular, _05 reached the correct ending but failed an incorrect test that expected walking beyond the ending boundary; _07's only systems failure was the obsolete assumption that exactly two carryable objects exist. The final support test checks real nearby geometry for every carryable instead. A screenshot review also caught the long register line; the final build corrects it and tests horizontal bounds. These earlier failures are not silently counted as passing.

Human retesting, horror effectiveness and artistic approval remain pending. The Surveyor model, broader map audit, richer sound variety and long-form progression remain unfinished. Existing resource-cleanup warnings and the earlier NVIDIA driver issue are not claimed resolved.
