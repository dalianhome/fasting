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
    @Published private(set) var userEmail: String?
    @Published private(set) var storedAccessToken: String = ""
    @Published private(set) var storedRefreshToken: String = ""

    private let accessTokenKey = "supabaseAccessToken"
    private let refreshTokenKey = "supabaseRefreshToken"
    private let userEmailKey = "supabaseUserEmail"

    private let service = SupabaseAuthService()

    init() {
        storedAccessToken = UserDefaults.standard.string(forKey: accessTokenKey) ?? ""
        storedRefreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
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
            userEmail = session.user.email ?? email
            UserDefaults.standard.set(session.accessToken, forKey: accessTokenKey)
            UserDefaults.standard.set(session.refreshToken, forKey: refreshTokenKey)
            if let emailToStore = userEmail {
                UserDefaults.standard.set(emailToStore, forKey: userEmailKey)
            }
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
        userEmail = nil
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        isAuthenticated = false
        email = ""
        password = ""
    }
}
