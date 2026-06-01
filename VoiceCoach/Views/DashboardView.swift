import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: SessionStore

    private var latest: SpeechSession? {
        store.sessions.first
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    LazyVGrid(columns: columns, spacing: 12) {
                        MetricTile(
                            title: "Practice",
                            value: store.totalPracticeTime.shortPracticeTime,
                            subtitle: "\(store.sessions.count) recorded sessions",
                            systemImage: "timer",
                            tint: .orange
                        )

                        MetricTile(
                            title: "Filler Rate",
                            value: "\(store.fillerWordsPerMinute.oneDecimal)/min",
                            subtitle: "Lower is cleaner",
                            systemImage: "text.bubble",
                            tint: .indigo
                        )

                        MetricTile(
                            title: "Average",
                            value: store.sessions.isEmpty ? "-" : "\(store.averageScore)",
                            subtitle: "Composite score",
                            systemImage: "chart.line.uptrend.xyaxis",
                            tint: .teal
                        )
                    }

                    if let latest {
                        latestSession(latest)
                    } else {
                        emptyState
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Voice Coach")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            ScoreRing(score: latest?.metrics.overallScore ?? store.averageScore, size: 116)

            VStack(alignment: .leading, spacing: 8) {
                Text(latest == nil ? "Ready for a session" : "Latest readout")
                    .font(.title2.bold())

                Text(latest?.focus.rawValue ?? "Record, transcribe, and review your speaking metrics.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .coachCard()
    }

    private func latestSession(_ session: SpeechSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(session.focus.rawValue, systemImage: session.focus.symbolName)
                    .font(.headline)

                Spacer()

                if session.isAIEnhanced {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.teal)
                        .accessibilityLabel("AI enhanced")
                }

                Text(session.duration.compactDuration)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                compactScore(title: "Confidence", score: session.metrics.confidenceScore, color: .teal)
                compactScore(title: "Clarity", score: session.metrics.clarityScore, color: .orange)
                compactScore(title: "Presence", score: session.metrics.executivePresenceScore, color: .indigo)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(session.recommendations, id: \.self) { recommendation in
                    RecommendationRow(text: recommendation)
                }
            }
        }
        .coachCard()
    }

    private func compactScore(title: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(score)")
                .font(.title3.bold())
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("No sessions yet", systemImage: "mic.badge.plus")
                .font(.headline)

            Text("Your first recording will create scores for pace, filler words, vocal consistency, clarity, and executive presence.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .coachCard()
    }
}

#Preview {
    DashboardView(store: .preview)
}
