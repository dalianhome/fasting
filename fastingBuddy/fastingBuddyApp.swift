import SwiftUI

@main
struct FastingBuddyApp: App {
    @StateObject private var store = FastingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
