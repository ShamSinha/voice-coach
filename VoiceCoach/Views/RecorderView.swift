import SwiftUI

struct RecorderView: View {
    @ObservedObject var store: SessionStore
    @StateObject private var recorder = RecordingManager()
    @State private var selectedFocus: PracticeFocus = .technicalInterview
    @State private var savedSession: SpeechSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    focusPicker

                    VStack(spacing: 16) {
                        RecorderButton(
                            isRecording: recorder.isRecording,
                            level: recorder.audioLevel
                        ) {
                            toggleRecording()
                        }

                        Text(recorder.isRecording ? recorder.elapsedTime.compactDuration : "0:00")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(recorder.isRecording ? .red : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)

                    transcriptPanel

                    if let errorMessage = recorder.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .coachCard()
                    }

                    if let savedSession {
                        savedSessionCard(savedSession)
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Record")
        }
    }

    private var focusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session Focus")
                .font(.headline)

            Picker("Session Focus", selection: $selectedFocus) {
                ForEach(PracticeFocus.allCases) { focus in
                    Label(focus.rawValue, systemImage: focus.symbolName)
                        .tag(focus)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .coachCard()
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Transcript", systemImage: "quote.bubble")
                    .font(.headline)

                Spacer()

                if recorder.isRecording {
                    Text("Live")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.12), in: Capsule())
                }
            }

            Text(recorder.transcript.isEmpty ? "..." : recorder.transcript)
                .font(.body)
                .foregroundStyle(recorder.transcript.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .coachCard()
    }

    private func savedSessionCard(_ session: SpeechSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ScoreRing(score: session.metrics.overallScore, size: 72, lineWidth: 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Saved")
                        .font(.headline)
                    Text(session.date.sessionLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ForEach(session.recommendations, id: \.self) { recommendation in
                RecommendationRow(text: recommendation)
            }
        }
        .coachCard()
    }

    private func toggleRecording() {
        if recorder.isRecording {
            if let session = recorder.stopRecording(focus: selectedFocus) {
                store.add(session)
                savedSession = session
            }
        } else {
            savedSession = nil
            Task {
                await recorder.startRecording()
            }
        }
    }
}

#Preview {
    RecorderView(store: .preview)
}
