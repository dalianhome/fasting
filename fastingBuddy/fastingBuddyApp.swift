import SwiftUI

@main
struct CyberismFastingApp: App {
    @StateObject private var store = FastingStore()
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
        }
    }
}
