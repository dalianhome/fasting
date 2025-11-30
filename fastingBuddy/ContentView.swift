import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "timer")
                }

            PlansView()
                .tabItem {
                    Label("Plans", systemImage: "target")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingStore())
}
