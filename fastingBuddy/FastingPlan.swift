import Foundation

struct FastingPlan: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let fastingHours: Int
    let eatingHours: Int
    let isCustom: Bool

    init(id: UUID = UUID(), name: String, fastingHours: Int, eatingHours: Int, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.fastingHours = fastingHours
        self.eatingHours = eatingHours
        self.isCustom = isCustom
    }
}
