import SwiftUI

struct SessionDetailView: View {
    var session: SpeechSession

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summary

                LazyVGrid(columns: columns, spacing: 12) {
                    MetricTile(
                        title: "Pace",
                        value: "\(session.metrics.wordsPerMinute.wholeNumber) WPM",
                        subtitle: "Target: 125 to 155",
                        systemImage: "speedometer",
                        tint: .teal
                    )

                    MetricTile(
                        title: "Fillers",
                        value: "\(session.metrics.fillerWordCount)",
                        subtitle: "\(session.metrics.fillerWordsPerMinute.oneDecimal) per minute",
                        systemImage: "text.bubble",
                        tint: .indigo
                    )

                    MetricTile(
                        title: "Longest Pause",
                        value: "\(session.metrics.longestPause.oneDecimal)s",
                        subtitle: "Shorter transitions feel cleaner",
                        systemImage: "pause.circle",
                        tint: .orange
                    )

                    MetricTile(
                        title: "Voice",
                        value: "\(session.metrics.volumeConsistency.wholeNumber)",
                        subtitle: "Volume consistency",
                        systemImage: "waveform",
                        tint: .mint
                    )
                }

                scoreBreakdown
                aiCoach
                acousticReadout
                recommendations
                transcript
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 18) {
            ScoreRing(score: session.metrics.overallScore, size: 116)

            VStack(alignment: .leading, spacing: 8) {
                Label(session.focus.rawValue, systemImage: session.focus.symbolName)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(session.date.sessionLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(session.duration.compactDuration) | \(session.metrics.wordCount) words")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .coachCard()
    }

    private var scoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Score Breakdown")
                .font(.headline)

            scoreBar(title: "Confidence", score: session.metrics.confidenceScore, color: .teal)
            scoreBar(title: "Clarity", score: session.metrics.clarityScore, color: .orange)
            scoreBar(title: "Presence", score: session.metrics.executivePresenceScore, color: .indigo)
            scoreBar(title: "Storytelling", score: session.metrics.storytellingScore, color: .mint)
            if let persuasionScore = session.metrics.persuasionScore {
                scoreBar(title: "Persuasion", score: persuasionScore, color: .pink)
            }
        }
        .coachCard()
    }

    private func scoreBar(title: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(score)")
                    .font(.subheadline.monospacedDigit().bold())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)

                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private var aiCoach: some View {
        if let aiCoaching = session.aiCoaching {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("AI Coach", systemImage: "brain.head.profile")
                        .font(.headline)

                    Spacer()

                    Text(aiCoaching.source)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(aiCoaching.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    compactAIStat(title: "Fillers", value: "\(aiCoaching.fillerWords)")
                    compactAIStat(title: "Persuasion", value: "\(aiCoaching.persuasion)")
                }
            }
            .coachCard()
        }
    }

    @ViewBuilder
    private var acousticReadout: some View {
        if let acousticMetrics = session.acousticMetrics {
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio Features")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    acousticTile(
                        title: "Pitch F0",
                        value: acousticMetrics.meanPitchHz.map { "\($0.wholeNumber) Hz" } ?? "-",
                        subtitle: acousticMetrics.pitchRangeHz.map { "Range \($0.wholeNumber) Hz" } ?? "Range unavailable"
                    )

                    acousticTile(
                        title: "Jitter",
                        value: acousticMetrics.jitterPercent.map { "\($0.oneDecimal)%" } ?? "-",
                        subtitle: "Period variation"
                    )

                    acousticTile(
                        title: "Shimmer",
                        value: acousticMetrics.shimmerPercent.map { "\($0.oneDecimal)%" } ?? "-",
                        subtitle: "Amplitude variation"
                    )

                    acousticTile(
                        title: "Silence",
                        value: "\(acousticMetrics.silenceDuration.oneDecimal)s",
                        subtitle: "\((acousticMetrics.silenceRatio * 100).oneDecimal)% of frames"
                    )

                    acousticTile(
                        title: "Energy",
                        value: acousticMetrics.meanEnergy.oneDecimal,
                        subtitle: "Variation \(acousticMetrics.energyVariation.oneDecimal)"
                    )
                }
            }
            .coachCard()
        }
    }

    private func compactAIStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func acousticTile(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coaching Notes")
                .font(.headline)

            ForEach(session.recommendations, id: \.self) { recommendation in
                RecommendationRow(text: recommendation)
            }
        }
        .coachCard()
    }

    private var transcript: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.headline)

            Text(session.transcript.isEmpty ? "No transcript captured." : session.transcript)
                .font(.body)
                .foregroundStyle(session.transcript.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .coachCard()
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: .sample)
    }
}
