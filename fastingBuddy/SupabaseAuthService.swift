import Foundation

struct SupabaseSession: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: SupabaseUser

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct SupabaseUser: Decodable {
    let id: String
    let email: String?
}

struct SupabaseErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
    }
}

enum SupabaseAuthError: LocalizedError {
    case invalidURL
    case requestFailed(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to build Supabase authentication endpoint."
        case .requestFailed(let message):
            return message
        case .decodingFailed:
            return "Unexpected response from Supabase."
        }
    }
}

final class SupabaseAuthService {
    func login(email: String, password: String) async throws -> SupabaseSession {
        guard let url = URL(string: "\(SupabaseConfig.url)/auth/v1/token?grant_type=password") else {
            throw SupabaseAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.requestFailed("No response from Supabase.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if let supabaseError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                let message = supabaseError.errorDescription ?? supabaseError.message ?? supabaseError.error ?? "Login failed."
                throw SupabaseAuthError.requestFailed(message)
            }
            throw SupabaseAuthError.requestFailed("Login failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(SupabaseSession.self, from: data)
        } catch {
            throw SupabaseAuthError.decodingFailed
        }
    }
}
