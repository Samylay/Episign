import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}
