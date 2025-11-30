import Foundation

struct CompletedFast: Identifiable, Codable {
    let id: UUID
    let planName: String
    let startDate: Date
    let endDate: Date
    var durationHours: Double
    var isSuccessful: Bool

    init(id: UUID = UUID(), planName: String, startDate: Date, endDate: Date, durationHours: Double, isSuccessful: Bool) {
        self.id = id
        self.planName = planName
        self.startDate = startDate
        self.endDate = endDate
        self.durationHours = durationHours
        self.isSuccessful = isSuccessful
    }
}
