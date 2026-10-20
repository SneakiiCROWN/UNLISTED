# Source and build boundary

UNLISTED 0.5.4 Cellar Repair responds to the first human playtest.
Final runtime checkpoint: 421b70c67a8758c9ee0182236f79480ff4d2cb58.
Complete licensed local source checkpoint: 8e15337d5e7d624d4a81ccf58b936eaa950a34ae.
Both full normal-input routes, west/east pursuit, room recovery, hiding/story mode,
resolution views and saved outcomes are recorded in VERIFIED_CHECKPOINT.json.
The old failing table geometry and intermediate failures remain preserved locally.

Public source excludes all assets/ media, private logs, personal saves, credentials
and private Git history. Model and sound references are intentionally unresolved in
this snapshot. Use the Windows prerelease to play; a complete licensed development
checkout is required to rebuild with tools/build_local_release.py. The builder uses
isolated staging and QA paths, preserving the active checkout and ordinary saves.

The character study was not accepted; the active Surveyor model is unchanged.
OWNER_RECORDING_CUES.md documents optional replacement cues without shipping owner
recordings. Third-party rights and the source-available project licence are unchanged.
Godot is MIT licensed. Do not extract/repackage game-only media as standalone assets.

Current development code follows private checkpoint 033c467345a3457f4ba4b2dca4db770ead486dc5. This is newer than the verified v0.5.4 binary. DEVELOPMENT_CHECKPOINT.json describes its narrower verification scope. Character geometry, editable blends, textures, captures and complete licensed source remain local.
