# Known limitations / 0.5.5

- Alpha game: not a completed hour-long experience. The new recount is intentionally brief.
- Surveyor character art remains below the intended quality. Asset-first Blender construction is underway; no new candidate is approved or active.
- Broader furnishing, object placement, outdoor composition and environmental sound variety need further human-led visual review.
- The mechanical relay drawer uses simple original geometry. It opens after isolation, when pursuit can begin; reading it is optional and can wait until escape.
- Human playtesting of this candidate, artistic sign-off, horror effectiveness and subjective audio-mix approval remain pending. Signal measurements only prove captured audio is non-silent and not clipped.
- Earlier NVIDIA nvoglv64.dll crashes have no confirmed root cause. Final tests run one GPU process at a time; this does not prove the driver issue is resolved.
- Native recordings use timestamped viewport sampling and repeated frames at original wall-clock timing. Capture cadence is not a performance benchmark.
- Public source excludes licensed media. Use the Windows ZIP to play; rebuilding needs the complete licensed local checkout.
- Temporary Surveyor vocals remain replaceable through documented owner recording slots.

Ordinary source-engine Quit and forced headless exits can report pre-existing audio/resource cleanup warnings despite exit code zero. The older 0.5.4 binary reproduces them. Gameplay QA stops audio during teardown, so its clean logs do not prove ordinary shutdown is fixed.
