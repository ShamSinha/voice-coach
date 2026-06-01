import SwiftUI

struct SessionsView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "waveform.path.ecg",
                        description: Text("Recorded sessions appear here with transcripts, scores, and coaching notes.")
                    )
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRow(session: session)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sessions")
        }
    }

    private func delete(at offsets: IndexSet) {
        let sessionsToDelete = offsets.map { store.sessions[$0] }
        sessionsToDelete.forEach(store.delete)
    }
}

private struct SessionRow: View {
    var session: SpeechSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.16))
                Text("\(session.metrics.overallScore)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(scoreColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Label(session.focus.rawValue, systemImage: session.focus.symbolName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(session.date.sessionLabel) | \(session.duration.compactDuration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var scoreColor: Color {
        switch session.metrics.overallScore {
        case 80...:
            return .teal
        case 65..<80:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SessionsView(store: .preview)
}
