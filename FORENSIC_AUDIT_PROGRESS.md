# Full forensic audit / active recovery / 26 October 2026

Production and graphics work remain gated by the unresolved owner idle crash.
Pre-audit recovery: `recovery/pre-full-forensic-20261026` / complete private
`0d15f78`; previous diagnostic delivery and full source remain sealed. Never
reset to the old public release. No assets, saves, releases or dumps deleted.

Private evidence: `Checkpoints/20261026_full_forensic_audit`.

Completed mechanical coverage: 125 existing GDScript files, 16 shaders, 8 scenes,
108 Python tools; 178-commit chronological file map; 532 literal resource edges.
The initial scan preceded the new audit tools. Corrected Godot parser pass loaded
150 script/scene/theme/shader resources without errors. It excluded its own live
runner; the failed forced-reload setup is retained separately, not a project bug.
275 imported assets loaded, 104 GLB containers/hierarchies/bones/animation targets
structurally checked. No stale source MD5, absent import outputs or structural
asset faults found. All 785 entries in diagnostic05's embedded PCK passed MD5
and bounds checks; exact literal production resource paths have export remaps.
Asset library: 635 files / 9,731,315,066 bytes indexed, not all artistically or
individually licence-approved. Counts are mechanical coverage, not a claim that
every line has completed manual semantic review. Remaining review is active.

## Confirmed findings and narrow repairs

- Crash B: preserved v0.10.9 baseline fixture reproduces the same native null
  read at executable RVA0x24662f5. Windows unwind bounds locate the function;
  its own embedded strings identify `servers/audio/effects/audio_effect_record.cpp`
  and `set_recording_active`. RCX is null, RDX false. This identifies the missed
  recorder initialization/finalization path, not a nearest-export guess. Ordinary
  owner menu uses no QA recorder, so this does not diagnose Crash C.
- Two preserved-fixture reproductions captured matching first-chance context.
  First full dump failed on unreadable pages (error299); no fake dump claim.
  `/mA` captured the second 2,375,408,662-byte dump; inaccessible pages may be
  omitted. Only this bounded known failure was repeated for the dump correction.
- Shared QA finalization now rejects a missing recorder with explicit failure
  status/exit92 before the native call. Negative native test confirmed controlled
  rejection, no access violation, no script error, owner data unchanged. Correctly
  initialized recorder/old baseline scenario completed normally in export02.
- Malformed checkpoint `{"schema":1,"pos":7}` reproduced a title-menu script
  error. Central core-format validation now protects menu availability and loading
  before live state changes. Optional legacy fields remain optional. This does
  not claim complete validation of every nested future story field.
- Presentation and always-processing inherited weather were making unchanged
  volume writes every frame. Exact-value guards retain actual fades and sound,
  reducing unnecessary native bus-data replacements. This is scoped resource
  churn reduction, not a demonstrated cause/fix of the main-thread RIP0 crash.
  Native 3D audio continues its own spatial updates; no upstream race is claimed
  eliminated. No weather, menu animation or audio feature was removed.

Export01 focused test retained one fixture error: it checked a 7.875-second title
fade after two seconds. Corrected timing in export02 passed; no production fade
duration was changed. Current targeted native results are in export02/QA/forensic.
Both initialized capture and deliberate missing-recorder rejection are recorded
separately. Old results have not been overwritten or counted as fresh passes.

## Still required

See `FORENSIC_AUDIT_REPORT.md` for the completed targeted lifecycle/history
interpretation, seven-executable identity matrix, raw-library integrity scope,
first 16m40s ordinary idle and extracted save/ending/pursuit/recorder checks.
The five graphics-production documents and private 36-image native baseline
are prepared; no experimental effects were promoted. Second ordinary idle is
in progress. Complete manual semantic coverage of dormant conditional paths
and an actual reproducible owner failure boundary remain open. Crash A
(driver invalid read) and Crash C (owner
main-thread execution at0) remain unresolved. No valid bisect good/bad boundary
has been established; the v0.10.6 success is not immunity.

The latest graphics directive is accepted as a separate zero-cost programme.
Reuse this inventory for visual assets/rendering configuration; prepare baseline
and isolated studies after this audit checkpoint. Do not merge experimental
SSAO/SSR/fog/material changes into normal gameplay while stability remains open.

No Windows, BIOS, driver, registry, overlay or unrelated-application change.
No public playable release. Safe source only goes to the existing repository;
raw dumps, owner snapshots, licensed media and complete archives remain private.
