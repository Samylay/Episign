import SwiftUI

@main
struct EpisignApp: App {
    @StateObject private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
}
