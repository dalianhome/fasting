import SwiftUI

@main
struct FastingBuddyApp: App {
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
