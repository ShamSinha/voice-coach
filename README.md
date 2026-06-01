# Voice Coach

Voice Coach is a native SwiftUI iPhone app for practicing technical interviews, research talks, startup pitches, leadership conversations, and social speaking.

The MVP runs locally on the phone:

- Records audio with `AVFoundation`
- Transcribes with Apple's `Speech` framework
- Extracts acoustic features: pitch/F0, pitch range, jitter, shimmer, speaking rate, silence duration, and energy
- Scores pace, filler words, pauses, vocal consistency, clarity, confidence, executive presence, storytelling, and persuasion
- Enhances coaching with Apple Foundation Models when building/running on iOS 26+ with Apple Intelligence available
- Saves session history on device
- Shows score trends and filler-word trends over time

## Model Direction

The app uses a deterministic local analyzer first so the core product is fast, private, and easy to run. It also includes an optional Apple Foundation Models layer behind `#if canImport(FoundationModels)`.

Current behavior:

1. Every recording gets local transcript and acoustic analysis.
2. If Foundation Models is available, the transcript plus local metrics are sent to Apple's on-device model through `LanguageModelSession`.
3. The model returns structured scores and recommendations through guided generation.
4. If Foundation Models is unavailable, the app keeps the local scores and shows an availability message.

Gemma through Google AI Edge / LiteRT is still a good future option once the iOS runtime and exact Gemma 4 variant are stable on your target phone.

## Open

Open `VoiceCoach.xcodeproj` in Xcode, select an iPhone simulator or device, and run the `VoiceCoach` target.

Speech recognition works best on a real iPhone because simulator microphone and speech behavior can be inconsistent.
