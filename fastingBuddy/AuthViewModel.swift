import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var storedAccessToken: String = ""
    @Published private(set) var storedRefreshToken: String = ""

    private let accessTokenKey = "supabaseAccessToken"
    private let refreshTokenKey = "supabaseRefreshToken"

    private let service = SupabaseAuthService()

    init() {
        storedAccessToken = UserDefaults.standard.string(forKey: accessTokenKey) ?? ""
        storedRefreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) ?? ""
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
            UserDefaults.standard.set(session.accessToken, forKey: accessTokenKey)
            UserDefaults.standard.set(session.refreshToken, forKey: refreshTokenKey)
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
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isAuthenticated = false
        email = ""
        password = ""
    }
}
