import SwiftUI

struct ContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        TabView {
            DashboardView(store: store)
                .tabItem {
                    Label("Today", systemImage: "gauge.with.dots.needle.67percent")
                }

            RecorderView(store: store)
                .tabItem {
                    Label("Record", systemImage: "mic.circle.fill")
                }

            SessionsView(store: store)
                .tabItem {
                    Label("Sessions", systemImage: "waveform.path.ecg")
                }

            ProgressScreen(store: store)
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
        }
        .tint(.teal)
    }
}

#Preview {
    ContentView(store: .preview)
}
