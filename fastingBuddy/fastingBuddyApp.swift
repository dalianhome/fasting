import SwiftUI

@main
struct CyberismFastingApp: App {
    @StateObject private var store = FastingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
