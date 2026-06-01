import SwiftUI

struct RecorderButton: View {
    var isRecording: Bool
    var level: Double
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? .red.opacity(0.16) : .teal.opacity(0.16))
                    .frame(width: 148 + level * 34, height: 148 + level * 34)
                    .animation(.easeOut(duration: 0.18), value: level)

                Circle()
                    .fill(isRecording ? .red : .teal)
                    .frame(width: 116, height: 116)
                    .shadow(color: (isRecording ? Color.red : Color.teal).opacity(0.35), radius: 18, x: 0, y: 10)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}

#Preview {
    RecorderButton(isRecording: true, level: 0.6) {}
        .padding()
}
