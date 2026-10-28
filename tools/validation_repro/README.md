# Validation03 minimal release reproduction

This independent project uses the same installed Godot4.7.2 release template. It reads no UNLISTED saves or licensed media. Export Windows Desktop and run the executable with --headless -- followed by one mode:

- correct: proper Node3D parent, valid constructors and cleanup; expected exit0. This is the default.
- guarded: invalid parent returns null, validity check refuses further use; expected exit12.
- original: intentionally reproduces the old unsafe fixture, including queue_free on the null result; expected native access violation0xC0000005.

Only original intentionally crashes. Raw release runs, hashes and matching native dumps are privately preserved in Checkpoints/20261029_next_nightmare. The matching engine fault is RVA0x16594e4, read0x198 with RCX=0. This does not establish a cause for the historical menu or renderer failures. No engine/driver/system modification is required.
