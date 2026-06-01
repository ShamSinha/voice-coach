import Combine
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class OnDeviceCoach: ObservableObject {
    @Published private(set) var isAnalyzing = false
    @Published private(set) var statusMessage = "On-device AI coach ready when available."

    func enhance(_ session: SpeechSession) async -> SpeechSession {
        guard !session.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "AI coach skipped because the transcript is empty."
            return session
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let coaching = try await FoundationModelSpeechCoach().analyze(session: session)
                statusMessage = "On-device AI coach applied."
                return session.applyingAI(coaching)
            } catch {
                statusMessage = "AI coach unavailable: \(error.localizedDescription)"
                return session
            }
        } else {
            statusMessage = "AI coach requires iOS 26 or newer."
            return session
        }
        #else
        statusMessage = "Build with an SDK that includes FoundationModels to enable the AI coach."
        return session
        #endif
    }
}

private enum OnDeviceCoachError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "Foundation Models is unavailable: \(reason)"
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct FoundationSpeechCoachingOutput {
    let confidence: Int
    let clarity: Int
    let fillerWords: Int
    let executivePresence: Int
    let storytelling: Int
    let persuasion: Int
    let summary: String
    let recommendations: [String]

    func result(source: String) -> AICoachingResult {
        AICoachingResult(
            confidence: confidence.clampedScore,
            clarity: clarity.clampedScore,
            fillerWords: max(0, fillerWords),
            executivePresence: executivePresence.clampedScore,
            storytelling: storytelling.clampedScore,
            persuasion: persuasion.clampedScore,
            summary: summary,
            recommendations: Array(recommendations.prefix(5)),
            source: source
        )
    }
}

@available(iOS 26.0, *)
private struct FoundationModelSpeechCoach {
    func analyze(session: SpeechSession) async throws -> AICoachingResult {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw OnDeviceCoachError.unavailable(String(describing: model.availability))
        }

        let languageSession = LanguageModelSession(
            model: model,
            instructions: """
            You are a private, on-device speech coach. Score only from the transcript and metrics supplied by the app. Be direct, specific, and practical. Prefer short recommendations that the speaker can apply in the next practice session.
            """
        )

        let response = try await languageSession.respond(
            to: prompt(for: session),
            generating: FoundationSpeechCoachingOutput.self
        )
        return response.content.result(source: "Apple Foundation Models")
    }

    private func prompt(for session: SpeechSession) -> String {
        """
        Analyze this speech practice session for clarity, confidence, executive presence, storytelling, and persuasion.

        Focus:
        \(session.focus.rawValue)

        Transcript:
        \(session.transcript)

        Local speech metrics:
        - Duration: \(session.duration.compactDuration)
        - Speaking rate: \(session.metrics.wordsPerMinute.wholeNumber) words per minute
        - Filler words: \(session.metrics.fillerWordCount)
        - Average pause: \(session.metrics.averagePause.oneDecimal) seconds
        - Longest pause: \(session.metrics.longestPause.oneDecimal) seconds
        - Volume consistency: \(session.metrics.volumeConsistency.wholeNumber) out of 100
        - Energy variation: \(session.metrics.energyVariation.oneDecimal)
        \(acousticPromptLines(for: session.acousticMetrics))

        Return 0-100 integer scores. Recommendations should be concrete, not generic.
        """
    }

    private func acousticPromptLines(for metrics: AcousticMetrics?) -> String {
        guard let metrics else {
            return "- Acoustic metrics: unavailable"
        }

        return """
        - Mean pitch F0: \(metrics.meanPitchHz?.wholeNumber ?? "unavailable") Hz
        - Pitch range: \(metrics.pitchRangeHz?.wholeNumber ?? "unavailable") Hz
        - Jitter: \(metrics.jitterPercent?.oneDecimal ?? "unavailable") percent
        - Shimmer: \(metrics.shimmerPercent?.oneDecimal ?? "unavailable") percent
        - Silence duration: \(metrics.silenceDuration.oneDecimal) seconds
        - Silence ratio: \((metrics.silenceRatio * 100).oneDecimal) percent
        - Mean energy: \(metrics.meanEnergy.oneDecimal)
        """
    }
}
#endif

private extension Int {
    var clampedScore: Int {
        min(100, max(0, self))
    }
}
