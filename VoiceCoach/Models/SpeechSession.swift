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
        audioFileName: nil
    )
}
