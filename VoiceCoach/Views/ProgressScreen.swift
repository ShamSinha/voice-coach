import Charts
import SwiftUI

struct ProgressScreen: View {
    @ObservedObject var store: SessionStore

    private var chronologicalSessions: [SpeechSession] {
        store.sessions.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if store.sessions.isEmpty {
                        emptyState
                    } else {
                        scoreTrend
                        fillerTrend
                        focusMix
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    private var scoreTrend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Score")
                .font(.headline)

            Chart(chronologicalSessions) { session in
                LineMark(
                    x: .value("Date", session.date),
                    y: .value("Score", session.metrics.overallScore)
                )
                .foregroundStyle(.teal)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", session.date),
                    y: .value("Score", session.metrics.overallScore)
                )
                .foregroundStyle(.orange)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 220)
        }
        .coachCard()
    }

    private var fillerTrend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filler Words")
                .font(.headline)

            Chart(chronologicalSessions) { session in
                BarMark(
                    x: .value("Date", session.date),
                    y: .value("Fillers per minute", session.metrics.fillerWordsPerMinute)
                )
                .foregroundStyle(.indigo.gradient)
            }
            .frame(height: 180)
        }
        .coachCard()
    }

    private var focusMix: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Mix")
                .font(.headline)

            ForEach(PracticeFocus.allCases) { focus in
                let count = store.sessions.filter { $0.focus == focus }.count
                HStack {
                    Label(focus.rawValue, systemImage: focus.symbolName)
                        .font(.subheadline)
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.secondary)
                }
                .opacity(count == 0 ? 0.45 : 1)
            }
        }
        .coachCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("No trend data", systemImage: "chart.xyaxis.line")
                .font(.headline)

            Text("Charts appear after your first saved recording.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .coachCard()
    }
}

#Preview {
    ProgressScreen(store: .preview)
}
