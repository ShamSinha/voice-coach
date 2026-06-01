import SwiftUI

struct SessionsView: View {
    @ObservedObject var store: SessionStore
    @State private var selectedFocus: PracticeFocus?

    private var filteredSessions: [SpeechSession] {
        guard let selectedFocus else { return store.sessions }
        return store.sessions.filter { $0.focus == selectedFocus }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                focusFilter

                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        selectedFocus == nil ? "No Sessions" : "No \(selectedFocus?.rawValue ?? "Focus") Sessions",
                        systemImage: selectedFocus?.symbolName ?? "waveform.path.ecg",
                        description: Text(emptyDescription)
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
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

    private var emptyDescription: String {
        if let selectedFocus {
            return "Record a \(selectedFocus.rawValue.lowercased()) session from the Record tab and it will appear here."
        }
        return "Recorded sessions appear here with transcripts, scores, and coaching notes."
    }

    private var focusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                focusButton(title: "All", systemImage: "square.grid.2x2", focus: nil)

                ForEach(PracticeFocus.allCases) { focus in
                    focusButton(title: focus.rawValue, systemImage: focus.symbolName, focus: focus)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func focusButton(title: String, systemImage: String, focus: PracticeFocus?) -> some View {
        let isSelected = selectedFocus == focus
        let count = focus.map { selected in
            store.sessions.filter { $0.focus == selected }.count
        } ?? store.sessions.count

        return Button {
            selectedFocus = focus
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                Text("\(count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.22) : Color.secondary.opacity(0.14), in: Capsule())
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.teal : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func delete(at offsets: IndexSet) {
        let sessionsToDelete = offsets.map { filteredSessions[$0] }
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
