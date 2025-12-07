import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var store: FastingStore

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
        .onAppear(perform: syncActiveUser)
        .onChange(of: auth.userEmail) { _ in
            syncActiveUser()
        }
        .onChange(of: auth.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                store.setActiveUser(email: nil)
            }
        }
    }

    private func syncActiveUser() {
        store.setActiveUser(email: auth.userEmail)
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingStore())
        .environmentObject(AuthViewModel())
}
