# Owner main-menu crash / 26 October 2026

This is a real ordinary-launch failure of the named v0.10.9 private candidate,
reported by the owner while doing nothing on the title screen. Prior automated
gameplay passes did not establish idle-menu stability. The candidate is not
cleared for a reliable owner playthrough.

## Preserved observation

- Windows Application Error1000 at17:44:48+10 and WER1001 at17:44:51+10,
  report a79a54c3-4093-4670-a8b1-5f969f415a8e; PID5300 /0x14B4.
- Matching Local CrashDumps file:61,408,933bytes; SHA256
  39716b04da312c53b12f769af0641f4778ffb683942e4d7cc0dad51e52ebcbb8.
- Debugger reports process uptime1minute50seconds at dump time. Exception
  context is an execution access violation with RIP0 on the main thread. The
  initial unwind has invalid-looking return addresses and lacks private engine
  symbols. It does not identify the responsible function or module. Large
  offsets from NvOptimusEnablement/NoHotPatch exports are not actual call names.
- Ordinary engine log has only the Vulkan/Forward+ startup header; no script
  error or automated-input marker. This differs from the earlier NVIDIA invalid
  read and the separate fixture null-read. A common root cause is unproved.
- Screenshot and Windows path show Explorer launched inside the ZIP, creating
  a temporary executable. That launch detail is not a demonstrated cause. The
  temporary image was no longer available for independent hashing. The retained
  extracted candidate still matches its sealed executable hash.

Raw dump, full debugger output, original logs and Windows events remain PRIVATE:
Checkpoints/20261026_owner_menu_idle_5300. No raw dump or owner settings belong
in the public repository.

## Focused reproduction

One bounded six-minute diagnostic was added to the existing stability helper:
normal root Window/title, copied owner preferences (fullscreen2560x1440, motion
and flicker reduction off), uncapped normal Engine.max_fps0, no New Game, no
SubViewport, no resize loop. Physical input is blocked and writes are private.
The non-activating mouse-through window avoids collecting desktop input. Each
15-second heartbeat is durable. These differences mean it is not an identical
uninstrumented owner launch. This option is diagnostics, not a gameplay fix.

The bounded run completed360.47seconds, exit0, no logged errors. Native end
screenshot confirms the title remained active; no case began. Node count stayed
4893, object count10554-10555. Owner saves/settings remained unchanged. Runtime
fingerprints match the delivered06 production source/resources; the additional
QA observer changes the executable and is not an identical ordinary launch.
Exact executable hashes, raw reports and screenshots are in the private case.
Passing one repeat cannot clear an intermittent failure.
Node/object counts can reveal growth but do not prove absence of memory
corruption. Release static-memory counters returning0 are unavailable evidence.

No engine, renderer, audio-loop, asset or game-scene change is justified by the
current exception alone. No Windows, driver, registry, BIOS or overlay settings
were changed. No new playable ZIP or public release is asserted as a repair.

Root cause and fix remain unresolved. A useful next diagnostic needs a meaningful
symbolized native call site or reproducible failure boundary; blindly replacing
working scenes, audio or gameplay would not be an evidence-based repair.

For launch-path clarity, the existing independently extracted executable is in
Checkpoints/20261026_player_experience_candidate/IndependentExtract/UNLISTED.exe.
Use an extracted folder rather than Explorer's compressed-folder launch in future,
but do not treat that as a proven crash remedy.
