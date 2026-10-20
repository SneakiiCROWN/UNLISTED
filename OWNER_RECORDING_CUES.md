# Replaceable Surveyor recording cues

Temporary sounds remain in use. The game now has separate recording slots and
prevents repeated pursuit transitions from stacking the same inhalation. Ordinary
voice cues have a 12-second minimum gap; attack inhalations have a 4-second gap.
Attack animation/warning time remains 1.1 seconds, even when a repeated vocal is
suppressed. One accepted vocal replaces the previous one rather than layering it.

Record dry mono WAV masters at 48 kHz / 24 bit. Keep peaks below clipping and leave
a second of room tone on either side. Keep the original takes outside exported
assets. Audition/mix first, then convert selected takes to OGG without silence padding.
Copy only approved game-ready clips to Game/assets/audio/owner/ using these names:

| File | Cue | Direction / useful length |
|---|---|---|
| surveyor_warning.ogg | First physical presence | A restrained inhale through the nose; almost involuntary. 1–2 s. |
| surveyor_pursuit.ogg | Pursuit begins, only after a quiet interval | Controlled effort, not a repeated roar. 1–2 s. |
| surveyor_attack.ogg | The existing warned grab | A short sharp intake, no speech. Under 0.8 s. |
| capture_contact.ogg | Close inspection, one second into capture | Cloth/close breath; leave the first transient soft. About 1 s. |
| capture_register.ogg | Late capture, around 2.7 seconds | Optional barely intelligible whisper or breath ending. Under 0.9 s. |

Capture timings do not stretch to fit recordings. Avoid recognisable Simon dialogue
until story context and casting are agreed; the Surveyor is not confirmed to be
Eli's father. No owner recordings are required for play. Missing clips use the
preserved temporary sounds. No microphone or live audio capture runs in the game.
Human sound approval remains pending; signal loudness alone is not a mix review.
