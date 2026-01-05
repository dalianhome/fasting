import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isAuthenticated {
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
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingStore())
        .environmentObject(AuthViewModel())
}
