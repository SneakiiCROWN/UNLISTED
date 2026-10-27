# Rejected renderer error - Phase4

Evidence: Checkpoints/20261027_graphics_phase4/Evidence03/final_balanced2560.
The native export exited 0 but logged `Parameter "particles" is null` from
`particles_get_instance_buffer_motion_vectors_offsets`. The wrapper correctly
rejected it. No warning was hidden, no native crash occurred, and owner save/
settings hashes remained unchanged. The specific camera frame is not established.

The same-named upstream method looks up particle ownership and guards against a
missing resource. That identifies the type of missing resource, not its cause:
https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/servers/rendering/renderer_rd/storage_rd/particles_storage.cpp
Source line numbers do not match the binary log, so no exact-build attribution
or upstream issue/fix is asserted. A broad search did not establish an exact
matching issue. No engine, driver or OS modifications were made.

Application change: for explicit Phase4 Balanced/Enhanced only, set the existing
Phase2 rain material before adding the emitter to the scene. The profile detects
that material and avoids a redundant live draw-mesh replacement. This removes
avoidable churn; causation is a hypothesis, not demonstrated fact. Earlier
phase defaults and ordinary gameplay stay unchanged.

Acceptance is bounded: one 1080p selected run plus three independent 1440p
rechecks, then the selected comparison/performance/motion matrix. Every result
is retained. If an error recurs the driver stops rather than accepting a warning.
The owner intermittent main-menu crash remains unresolved; a relationship is not established.
