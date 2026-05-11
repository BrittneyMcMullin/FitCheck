import SwiftUI

@main
struct TormentNexusApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                LoginView {
                    appState.isLoggedIn = true
                }
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = NetworkManager.shared.isLoggedIn
    
    init() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("UserDidLogout"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLoggedIn = false
        }
    }
}
