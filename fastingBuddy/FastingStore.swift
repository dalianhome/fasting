import Foundation
import Combine

@MainActor
final class FastingStore: ObservableObject {
    @Published var availablePlans: [FastingPlan] = []
    @Published var selectedPlan: FastingPlan?
    @Published var isFasting: Bool = false
    @Published var fastStartDate: Date?
    @Published var fastEndDate: Date?
    @Published var history: [CompletedFast] = []
    @Published var autoStartAfterEating: Bool = false
    @Published var dailyReminderEnabled: Bool = false {
        didSet { handleDailyReminderChange() }
    }

    private let defaultsKey = "FastingStoreData"

    private struct PersistedData: Codable {
        var availablePlans: [FastingPlan]
        var selectedPlan: FastingPlan?
        var isFasting: Bool
        var fastStartDate: Date?
        var fastEndDate: Date?
        var history: [CompletedFast]
        var autoStartAfterEating: Bool
        var dailyReminderEnabled: Bool
    }

    init() {
        loadFromDefaults()
        NotificationManager.shared.requestPermission()
    }

    func startFast() {
        guard let plan = selectedPlan else { return }
        isFasting = true
        fastStartDate = Date()
        fastEndDate = fastStartDate?.addingTimeInterval(TimeInterval(plan.fastingHours) * 3600)
        NotificationManager.shared.cancelNotifications()
        NotificationManager.shared.scheduleStartNotification(planName: plan.name)
        if let endDate = fastEndDate {
            NotificationManager.shared.scheduleCompletionNotification(planName: plan.name, endDate: endDate)
        }
        saveToDefaults()
    }

    func stopFast() {
        guard isFasting, let plan = selectedPlan, let start = fastStartDate else { return }
        let end = Date()
        let duration = end.timeIntervalSince(start) / 3600
        let success = duration >= Double(plan.fastingHours)
        let completed = CompletedFast(planName: plan.name, startDate: start, endDate: end, durationHours: duration, isSuccessful: success)
        history.insert(completed, at: 0)
        isFasting = false
        fastStartDate = nil
        fastEndDate = nil
        NotificationManager.shared.cancelNotifications()
        saveToDefaults()
    }

    func remainingTime() -> TimeInterval {
        guard isFasting, let end = fastEndDate else { return 0 }
        return max(end.timeIntervalSinceNow, 0)
    }

    func fastProgress() -> Double {
        guard isFasting, let start = fastStartDate, let plan = selectedPlan else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        let target = TimeInterval(plan.fastingHours) * 3600
        return min(max(elapsed / target, 0), 1)
    }

    func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            setupDefaultPlans()
            return
        }
        do {
            let decoded = try JSONDecoder().decode(PersistedData.self, from: data)
            availablePlans = decoded.availablePlans
            selectedPlan = decoded.selectedPlan ?? availablePlans.first
            isFasting = decoded.isFasting
            fastStartDate = decoded.fastStartDate
            fastEndDate = decoded.fastEndDate
            history = decoded.history
            autoStartAfterEating = decoded.autoStartAfterEating
            dailyReminderEnabled = decoded.dailyReminderEnabled
        } catch {
            print("Failed to load data: \(error)")
            setupDefaultPlans()
        }
    }

    func saveToDefaults() {
        let data = PersistedData(
            availablePlans: availablePlans,
            selectedPlan: selectedPlan,
            isFasting: isFasting,
            fastStartDate: fastStartDate,
            fastEndDate: fastEndDate,
            history: history,
            autoStartAfterEating: autoStartAfterEating,
            dailyReminderEnabled: dailyReminderEnabled
        )

        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        } catch {
            print("Failed to save data: \(error)")
        }
    }

    func addCustomPlan(fastingHours: Int, eatingHours: Int) {
        let name = "\(fastingHours):\(eatingHours)"
        let plan = FastingPlan(name: name, fastingHours: fastingHours, eatingHours: eatingHours, isCustom: true)
        availablePlans.append(plan)
        selectedPlan = plan
        saveToDefaults()
    }

    func selectPlan(_ plan: FastingPlan) {
        selectedPlan = plan
        saveToDefaults()
    }

    func currentStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        let sorted = history.sorted { $0.endDate > $1.endDate }
        var expectedDate = calendar.startOfDay(for: Date())

        for fast in sorted where fast.isSuccessful {
            let fastDay = calendar.startOfDay(for: fast.endDate)
            if fastDay == expectedDate {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
                expectedDate = previous
            } else if fastDay == calendar.date(byAdding: .day, value: -1, to: expectedDate) {
                streak += 1
                expectedDate = calendar.startOfDay(for: fastDay)
            } else {
                break
            }
        }
        return streak
    }

    func totalSuccessfulFasts() -> Int {
        history.filter { $0.isSuccessful }.count
    }

    func totalFasts() -> Int {
        history.count
    }

    func deleteFast(_ fast: CompletedFast) {
        guard let index = history.firstIndex(where: { $0.id == fast.id }) else { return }
        history.remove(at: index)
        saveToDefaults()
    }

    func deleteFast(id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        history.remove(at: index)
        saveToDefaults()
    }

    func deleteFast(at offsets: IndexSet) {
        let validOffsets = IndexSet(
            offsets.compactMap { offset in
                (offset >= history.startIndex && offset < history.endIndex) ? offset : nil
            }
        )
        guard !validOffsets.isEmpty else { return }
        history.remove(atOffsets: validOffsets)
        saveToDefaults()
    }

    private func setupDefaultPlans() {
        availablePlans = [
            FastingPlan(name: "12:12", fastingHours: 12, eatingHours: 12),
            FastingPlan(name: "14:10", fastingHours: 14, eatingHours: 10),
            FastingPlan(name: "16:8", fastingHours: 16, eatingHours: 8)
        ]
        selectedPlan = availablePlans.first
    }

    private func handleDailyReminderChange() {
        if dailyReminderEnabled {
            NotificationManager.shared.scheduleDailyReminder(hour: 20, minute: 0)
        } else {
            NotificationManager.shared.cancelDailyReminder()
        }
        saveToDefaults()
    }
}
