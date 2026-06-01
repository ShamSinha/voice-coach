import Foundation

enum PracticeFocus: String, CaseIterable, Codable, Identifiable {
    case technicalInterview = "Technical Interview"
    case researchPresentation = "Research Presentation"
    case startupPitch = "Startup Pitch"
    case leadershipDiscussion = "Leadership Discussion"
    case socialConversation = "Social Conversation"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .technicalInterview:
            return "terminal"
        case .researchPresentation:
            return "chart.bar.doc.horizontal"
        case .startupPitch:
            return "sparkles"
        case .leadershipDiscussion:
            return "person.3.sequence"
        case .socialConversation:
            return "bubble.left.and.bubble.right"
        }
    }
}

struct TranscriptSegment: Codable, Equatable, Identifiable {
    var id = UUID()
    var text: String
    var timestamp: TimeInterval
    var duration: TimeInterval
}

struct SessionMetrics: Codable, Equatable {
    var overallScore: Int
    var confidenceScore: Int
    var clarityScore: Int
    var executivePresenceScore: Int
    var storytellingScore: Int
    var persuasionScore: Int? = nil
    var wordsPerMinute: Double
    var fillerWordCount: Int
    var fillerWordsPerMinute: Double
    var averagePause: Double
    var longestPause: Double
    var volumeConsistency: Double
    var energyVariation: Double
    var wordCount: Int
    var uniqueWordRatio: Double
}

struct AcousticMetrics: Codable, Equatable {
    var meanPitchHz: Double?
    var minPitchHz: Double?
    var maxPitchHz: Double?
    var jitterPercent: Double?
    var shimmerPercent: Double?
    var silenceDuration: TimeInterval
    var silenceRatio: Double
    var meanEnergy: Double
    var energyVariation: Double
    var voicedFrameCount: Int
    var totalFrameCount: Int

    var pitchRangeHz: Double? {
        guard let minPitchHz, let maxPitchHz else { return nil }
        return maxPitchHz - minPitchHz
    }
}

struct AICoachingResult: Codable, Equatable {
    var confidence: Int
    var clarity: Int
    var fillerWords: Int
    var executivePresence: Int
    var storytelling: Int
    var persuasion: Int
    var summary: String
    var recommendations: [String]
    var source: String
}

struct SpeechSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var focus: PracticeFocus
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var segments: [TranscriptSegment]
    var metrics: SessionMetrics
    var recommendations: [String]
    var audioFileName: String?
    var acousticMetrics: AcousticMetrics? = nil
    var aiCoaching: AICoachingResult? = nil

    var isAIEnhanced: Bool {
        aiCoaching != nil
    }

    func applyingAI(_ coaching: AICoachingResult) -> SpeechSession {
        var copy = self
        copy.aiCoaching = coaching
        copy.metrics.confidenceScore = coaching.confidence
        copy.metrics.clarityScore = coaching.clarity
        copy.metrics.executivePresenceScore = coaching.executivePresence
        copy.metrics.storytellingScore = coaching.storytelling
        copy.metrics.persuasionScore = coaching.persuasion
        copy.metrics.overallScore = Self.weightedScore([
            (coaching.confidence, 0.22),
            (coaching.clarity, 0.24),
            (coaching.executivePresence, 0.22),
            (coaching.storytelling, 0.16),
            (coaching.persuasion, 0.16)
        ])
        copy.recommendations = Array((coaching.recommendations + recommendations).uniqued().prefix(5))
        return copy
    }

    private static func weightedScore(_ parts: [(Int, Double)]) -> Int {
        let totalWeight = parts.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return 0 }
        let score = parts.reduce(0) { $0 + Double($1.0) * $1.1 } / totalWeight
        return min(100, max(0, Int(score.rounded())))
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension SpeechSession {
    static let sample = SpeechSession(
        title: "Technical Interview",
        focus: .technicalInterview,
        date: .now.addingTimeInterval(-3600),
        duration: 156,
        transcript: "Transformers outperform previous sequence models mainly because self-attention lets each token compare itself with every other token. There are three important reasons: parallel training, long-range context, and flexible representation learning.",
        segments: [
            TranscriptSegment(text: "Transformers", timestamp: 0.2, duration: 0.4),
            TranscriptSegment(text: "outperform", timestamp: 0.7, duration: 0.4),
            TranscriptSegment(text: "previous", timestamp: 1.2, duration: 0.3)
        ],
        metrics: SessionMetrics(
            overallScore: 78,
            confidenceScore: 76,
            clarityScore: 84,
            executivePresenceScore: 72,
            storytellingScore: 69,
            wordsPerMinute: 142,
            fillerWordCount: 5,
            fillerWordsPerMinute: 1.9,
            averagePause: 0.8,
            longestPause: 2.1,
            volumeConsistency: 82,
            energyVariation: 0.34,
            wordCount: 46,
            uniqueWordRatio: 0.78
        ),
        recommendations: [
            "Open with the conclusion in the first sentence.",
            "Keep pauses under two seconds when moving between points.",
            "Replace filler words with a brief silent pause."
        ],
        audioFileName: nil,
        acousticMetrics: AcousticMetrics(
            meanPitchHz: 126,
            minPitchHz: 94,
            maxPitchHz: 182,
            jitterPercent: 1.2,
            shimmerPercent: 4.8,
            silenceDuration: 18,
            silenceRatio: 0.12,
            meanEnergy: 0.18,
            energyVariation: 0.34,
            voicedFrameCount: 96,
            totalFrameCount: 123
        ),
        aiCoaching: AICoachingResult(
            confidence: 80,
            clarity: 86,
            fillerWords: 5,
            executivePresence: 76,
            storytelling: 72,
            persuasion: 74,
            summary: "Clear technical answer with a strong structure and room for a sharper story.",
            recommendations: [
                "State the final answer before explaining the mechanism.",
                "Use one concrete example to make the explanation more memorable."
            ],
            source: "Preview"
        )
    )
}
