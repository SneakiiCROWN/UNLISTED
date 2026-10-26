# Priority zero / active crash investigation / 26 October2026

Recovered clean f9e6082. Original owner dump5300, older driver failure, separate
fixture failure and all old candidates are preserved. No new content or version.

Confirmed private paths: complete world/subsystems build before menu; always-on
Presentation audio9s/90s loops and27s creak; always-on MenuStage mist, lighting,
tree/camera motion and47s silhouette cycle. No source evidence yet identifies
an invalid callback or freed receiver; these are hypotheses, not crash causes.

First ordinary extracted0.10.9:625.28seconds, observed main-menu Quit, exit0.
Ordinary0.10.6:715.31seconds, observed main-menu Quit, exit0. No QA or renderer
arguments in either; owner saves/settings unchanged. CUA captures inspect actual
foreground menus. These successful comparisons do not clear intermittence.

The owner dump has RIP0 on main thread and no trustworthy native caller. Nearest
exports are not a diagnosis. PE and official-release metadata are being recorded
privately; no matching published Windows symbols found in that release's assets.

First debugger observation01 stopped early after265seconds: its initial commands
were not armed, so it is NOT a successful first-chance capture. Corrected02 uses
an initial command file and its sx table explicitly verifies AV break/not-handled
with first/second-chance callbacks. Full dumps stay private. The quoted command
parser strips backslashes from02 dump names; if a dump occurs, also inspect its
private extracted working directory. Future helper uses forward slashes. Do not
discard failed setup logs or pretend a handled first-chance event is a crash.

Explicit diagnostic switches now isolate menu sound, mist, silhouette, animation
and a2D-only view of the fully built world. A separate nondefault diagnostic entry
defers the entire original world until New Game, then loads the original arrival
and private save/recovery flow. Neither is promoted as a production fix. Ordinary
launch defaults retain the existing game and title. Native comparison results
remain pending; inspect component_results.json and deferred_report.json.

Owner confirmed PC free for foreground tests. Another3D application was observed
open, left untouched. Current read-only aggregate GPU context was2.76GiB/16.38GiB;
this does not establish pressure at the owner's failure. WHEA query found no
matching events; that does not rule out a system issue. No Windows, driver,
BIOS, registry or system-wide overlay modifications.

Evidence root: Builds/UNLISTED_Priority_Zero_Evidence. Raw dumps, owner snapshots
and full debugger/module logs remain private. Safe source only goes to GitHub.
Do not claim root cause, fix, three repaired-build passes or stable release yet.
