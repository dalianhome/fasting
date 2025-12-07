import Foundation

enum FastingSyncError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to build Supabase sync endpoint."
        case .requestFailed(let status):
            return "Sync failed with status code \(status)."
        case .decodingFailed:
            return "Unexpected response from Supabase."
        }
    }
}

struct SupabaseFastRecord: Codable {
    let id: UUID
    let userId: String
    let planName: String
    let startDate: Date
    let endDate: Date
    let durationHours: Double
    let isSuccessful: Bool

    init(from fast: CompletedFast, userId: String) {
        self.id = fast.id
        self.userId = userId
        self.planName = fast.planName
        self.startDate = fast.startDate
        self.endDate = fast.endDate
        self.durationHours = fast.durationHours
        self.isSuccessful = fast.isSuccessful
    }

    func asCompletedFast() -> CompletedFast {
        CompletedFast(
            id: id,
            planName: planName,
            startDate: startDate,
            endDate: endDate,
            durationHours: durationHours,
            isSuccessful: isSuccessful
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planName = "plan_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case durationHours = "duration_hours"
        case isSuccessful = "is_successful"
    }
}

final class FastingSyncService {
    func fetchHistory(accessToken: String, userId: String) async throws -> [CompletedFast] {
        guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/fasts?user_id=eq.\(userId)&order=end_date.desc") else {
            throw FastingSyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FastingSyncError.decodingFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw FastingSyncError.requestFailed(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([SupabaseFastRecord].self, from: data)
            return records.map { $0.asCompletedFast() }
        } catch {
            throw FastingSyncError.decodingFailed
        }
    }

    func upsertHistory(accessToken: String, userId: String, fasts: [CompletedFast]) async throws {
        guard !fasts.isEmpty else { return }
        guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/fasts") else {
            throw FastingSyncError.invalidURL
        }

        let payload = fasts.map { SupabaseFastRecord(from: $0, userId: userId) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FastingSyncError.decodingFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw FastingSyncError.requestFailed(httpResponse.statusCode)
        }
    }
}
