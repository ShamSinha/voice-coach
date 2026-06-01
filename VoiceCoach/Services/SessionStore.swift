import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [SpeechSession] = []

    private let fileName = "voice-coach-sessions.json"

    init(loadFromDisk: Bool = true) {
        if loadFromDisk {
            load()
        }
    }

    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.metrics.overallScore }
        return total / sessions.count
    }

    var totalPracticeTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var fillerWordsPerMinute: Double {
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        guard totalDuration > 0 else { return 0 }
        let fillerCount = sessions.reduce(0) { $0 + $1.metrics.fillerWordCount }
        return Double(fillerCount) / (totalDuration / 60)
    }

    func add(_ session: SpeechSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(_ session: SpeechSession) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([SpeechSession].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            sessions = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save sessions: \(error.localizedDescription)")
        }
    }

    private var storeURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
}

extension SessionStore {
    static var preview: SessionStore {
        let store = SessionStore(loadFromDisk: false)
        store.sessions = [
            .sample,
            SpeechSession(
                title: "Startup Pitch",
                focus: .startupPitch,
                date: .now.addingTimeInterval(-86400),
                duration: 121,
                transcript: "Our product helps technical founders practice high stakes communication before interviews, investor calls, and research presentations.",
                segments: [],
                metrics: SessionMetrics(
                    overallScore: 70,
                    confidenceScore: 68,
                    clarityScore: 74,
                    executivePresenceScore: 71,
                    storytellingScore: 65,
                    wordsPerMinute: 168,
                    fillerWordCount: 9,
                    fillerWordsPerMinute: 4.5,
                    averagePause: 0.5,
                    longestPause: 2.8,
                    volumeConsistency: 75,
                    energyVariation: 0.28,
                    wordCount: 28,
                    uniqueWordRatio: 0.86
                ),
                recommendations: [
                    "Slow the pace by about 10 percent.",
                    "Use a concrete customer example after the problem statement."
                ],
                audioFileName: nil
            )
        ]
        return store
    }
}
