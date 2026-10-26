# Reflection warning investigation — 27 October 2026

The seven leaked Texture RIDs are reproducible without UNLISTED assets, world,
audio, UI, custom shaders or private input viewport. The private minimal project
has a camera, box, point light and optional default UPDATE_ONCE ReflectionProbe.
After two seconds the probe is queued for deletion, eight frames elapse, then
the app quits. Exact source/logs: sibling
`../20261027_graphics_phase2/ProbeRepro/` and `release_*.log`.

| Native case / Godot4.7.2 Forward+ Vulkan | Exit | Warning |
| --- | ---: | --- |
| Editor runtime, no probe | 0 | None |
| Editor runtime, one probe | 0 | Seven Texture RIDs |
| Windows release export, no probe | 0 | None |
| Windows release export, one probe | 0 | Seven Texture RIDs |

This isolates the warning beyond our game-specific shutdown ordering. UPDATE_ONCE
and explicit deletion do not avoid it. It is not evidence that the leak is safe,
that every probe configuration behaves identically or that the driver is ruled
out. No driver, engine version, renderer, registry or system setting was changed.

[Godot issue122498](https://github.com/godotengine/godot/issues/122498) describes
the same warning and missing reflection-atlas cleanup. The exact
[4.7.2 source](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/storage_rd/light_storage.cpp#L1558)
allocates six colour views and their colour buffer but `_reflection_atlas_clear`
does not explicitly free them. The downloaded versioned file and local control
results strongly support this upstream explanation. We did not patch/rebuild
Godot, attach symbols to prove every leaked object, or claim a runtime leak rate.

**Decision:** keep live ReflectionProbes excluded. Do not suppress the warnings
or label them harmless. This finding does not explain the owner's ordinary
idle-menu crash, whose normal startup uses no study probes.

## Selected alternative

An actual six-face128px lounge capture is baked once into a private Cubemap.
The glass samples it directly in a box-projected material; showcase playback
adds no reflection cameras or reflection atlas. A weak static room return is
used only from the lounge's interior viewpoints. Outside viewers retain actual
interior visibility and normal sky/material response. Moving actors are never
claimed to be present in the baked return. Changing furniture, power or copied
rooms require gating/rebaking before production integration.

The first bake incorrectly placed ResourceSaver inside an assertion, which is
stripped in release. The missing file was detected before use. Bake02 moves the
save outside the assertion and independently verifies the525,726-byte resource.
Initial no-bake visual captures remain in Build01, not final reflection proof.

Build03's actor-control fixture also exposed an untyped-variable parse error.
Its log/result are preserved; only its owned failed process was stopped. Typed
booleans and a targeted parser check repaired the fixture. It is not a new
native GPU crash or a successful gameplay run. Final results are in Build05.

No original crash dump, rejected visual candidate or Phase1 artifact was removed.
