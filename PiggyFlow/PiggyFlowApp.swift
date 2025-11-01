import SwiftUI
import SwiftData

@main
struct PiggyFlowApp: App {
    @StateObject private var appleSignInManager = AppleSignInManager()
    @AppStorage("username") private var userName: String = ""
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appleSignInManager)
                .environmentObject(DataManager.shared)
                .modelContainer(DataManager.shared.localContainer)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @AppStorage("username") private var userName: String = ""
    
    var body: some View {
        Group {
            if !userName.isEmpty || appleSignInManager.isAuthenticated {
                MainTabView()
            } else {
                OnBoardingScreen()
            }
        }
    }
}
