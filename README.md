# Voice Coach

Voice Coach is a native SwiftUI iPhone app for practicing technical interviews, research talks, startup pitches, leadership conversations, and social speaking.

The MVP runs locally on the phone:

- Records audio with `AVFoundation`
- Transcribes with Apple's `Speech` framework
- Scores pace, filler words, pauses, vocal consistency, clarity, confidence, executive presence, and storytelling
- Saves session history on device
- Shows score trends and filler-word trends over time

## Model Direction

The current app uses a deterministic local analyzer so the core product is fast, private, and easy to run.

For a stronger AI layer, the best iOS-first choices are:

1. Apple Foundation Models for iOS 26+ devices with Apple Intelligence enabled. This avoids bundling a multi-GB model and is the cleanest on-device path for native Swift apps.
2. Gemma through Google AI Edge / LiteRT once the iOS runtime and exact Gemma 4 variant are stable on your target phone.
3. A cloud fallback for long-form transcript review if you later want higher-quality coaching and do not require fully offline mode.

The app is intentionally structured so the analyzer can be replaced or augmented by an on-device LLM provider later.

## Open

Open `VoiceCoach.xcodeproj` in Xcode, select an iPhone simulator or device, and run the `VoiceCoach` target.

Speech recognition works best on a real iPhone because simulator microphone and speech behavior can be inconsistent.
