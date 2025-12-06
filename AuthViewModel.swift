import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("supabaseAccessToken") private var storedAccessToken: String = ""
    @AppStorage("supabaseRefreshToken") private var storedRefreshToken: String = ""

    private let service = SupabaseAuthService()

    init() {
        isAuthenticated = !storedAccessToken.isEmpty
    }

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let session = try await service.login(email: email, password: password)
            storedAccessToken = session.accessToken
            storedRefreshToken = session.refreshToken
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        storedAccessToken = ""
        storedRefreshToken = ""
        isAuthenticated = false
        email = ""
        password = ""
    }
}
