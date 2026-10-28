# UNLISTED — Nightmare Stability, 28 October 2026

**PRIVATE QA — STABILITY NOT CLEARED. No native crash repair is claimed.**

Entry private source 0b297c4; safe public source 4085586. Recovery tag recovery/pre-nightmare-stability-20261028 protects entry. The preceding Operation Stability delivery and all owner saves/settings remain preserved.

## New evidence

OrdinaryCapture01 reached the real particle-owner rejection at 203.241375 engine seconds (poll first observed at 203.629794 wall seconds). It used the ordinary main scene and root Window, cloned owner settings/save, no QA viewport, no recorder, no startup debugger and no rendering override. Its explicit diagnostic Logger held this caller for fifteen seconds only AFTER the real error. CDB attached afterwards, saved all native thread stacks and a private minidump, then detached successfully. The captured thread is the main thread. This is the first exercised real-error late-attach path.

The stack returns from the error logger into the particle motion-vector getter at native RVA 0x2832a5c; the caller resumes at 0x27667f3. Disassembly immediately preceding that caller loads the geometry base and calls the already-identified getter. The pinned Forward+ source does this for a geometry instance with INSTANCE_DATA_FLAG_PARTICLES. This identifies the actual rendering operation; it does NOT yet identify the rejected RID, its lifetime, an offending scene object, or a common cause with either native access violation. NoHotPatch and NvOptimusEnablement labels in the stripped binary are nearest exported data symbols, not names of these functions.

The small dump does not retain all required heap data. A follow-up matched capture requests full PRIVATE process memory after the same real error. These dumps must never be included in public source or public releases. No production executable or installed engine was patched. The contemplated native trap was not implemented because late attachment succeeded.

OrdinaryCapture01 subsequently reached its 300-second watchdog and was deliberately terminated by its launcher. Exit 1 is a FORCED DIAGNOSTIC DEADLINE, not a spontaneous game crash or a clean startup/shutdown pass. The late-attach break/hold is also an injected diagnostic intervention, not the owner's freeze. Both owner file hashes remained identical.

## Changes

- Explicit --native-error-capture=<absolute directory> reuses the ordinary root/render path while redirecting settings and checkpoints to supplied copies; startup refuses missing isolated settings.
- The existing error Logger and resource observer can run in this opt-in mode. Ordinary play without the flag retains previous behaviour.
- tools/capture_ordinary_particle.py owns one child, refuses test overlap, records owner hashes, observes real errors, verifies the signalled PID before attaching, and labels forced deadlines. Optional --full-dump retains private resource memory.

No gameplay, character, graphics, shader, audio mix, hardware, driver or Windows setting was changed. The impossible-room simulated-time correction remains intact. Prior native 1080p/1440p/ultrawide, physical capture/retry and segmented earned-ending results remain the regression baseline, not newly repeated successes.

## Still unresolved

The original menu null-execution crash, particle ownership failure and impossible-room Vulkan-path access violation are not proved to share a cause. A clean observation cannot clear any intermittent fault. Separate Python native failures without UNLISTED remain competing evidence, not a diagnosis of hardware or software outside the game. No rejected artwork is promoted and no public release is authorised.

Evidence: Checkpoints/20261028_nightmare_stability beside the existing project. Full process-memory dumps stay private; representative screenshots and sanitised run results may accompany a private QA package.

## Follow-up observations and current session

OrdinaryCapture02 observed 420.424 seconds without the rejected owner or a spontaneous native crash. It then reached its explicitly forced watchdog deadline (exit1). It is NOT a clean Quit pass, stability clearance or proof the error is fixed. The full-memory attachment was not triggered. Original failed evidence is preserved separately; there is no repeated-run-until-pass replacement.

After the owner resumed MW4, no further foreground actions were taken. Capture helpers now accept --mute to change only isolated/copied QA preferences. Owner settings, other applications and system volume are untouched. MutedRoom03 uses the actual Candidate01 Windows export, preconstructed private viewport and Original1080p:52 checks, zero failures/errors/warnings,74.843928 seconds, exit0 and owner hashes unchanged. It covers physical transformation, input-driven traversal, room save/load, Surveyor contact, death/retry and restoration. It is a MUTED background regression with another game running, not audio listening or performance acceptance. The existing simulated-time contact allowance remains unchanged.

A hidden/muted title capture requests PRIVATE full memory only after the real particle error, preserving the root foreground/QA-viewport distinction. Audio mute and MW4 concurrency are explicit test conditions. No public release, character change or speculative workaround is introduced.
