import SwiftUI

@main
struct VoiceCoachApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: sessionStore)
        }
    }
}
