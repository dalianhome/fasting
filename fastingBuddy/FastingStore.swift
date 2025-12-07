import Foundation
import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case neon
    case midnight
    case sunrise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neon: return "Neon Nights"
        case .midnight: return "Midnight Focus"
        case .sunrise: return "Sunrise Glow"
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var cardGradient: LinearGradient {
        LinearGradient(
            colors: cardColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var accentGlow: LinearGradient {
        LinearGradient(
            colors: glowColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: accentColors),
            center: .center
        )
    }

    var highlightAccent: Color {
        switch self {
        case .neon:
            return Color(red: 0.98, green: 0.52, blue: 0.14)
        case .midnight:
            return Color(red: 0.2, green: 0.78, blue: 0.89)
        case .sunrise:
            return Color(red: 1.0, green: 0.7, blue: 0.4)
        }
    }

    var actionTint: Color {
        switch self {
        case .neon:
            return Color(red: 0.87, green: 0.41, blue: 0.95)
        case .midnight:
            return Color(red: 0.26, green: 0.63, blue: 0.98)
        case .sunrise:
            return Color(red: 1.0, green: 0.56, blue: 0.58)
        }
    }

    var surface: Color { Color.white.opacity(0.06) }
    var surfaceStroke: Color { Color.white.opacity(0.12) }

    private var backgroundColors: [Color] {
        switch self {
        case .neon:
            return [
                Color(red: 0.04, green: 0.06, blue: 0.12),
                Color(red: 0.11, green: 0.09, blue: 0.25),
                Color(red: 0.18, green: 0.12, blue: 0.34)
            ]
        case .midnight:
            return [
                Color(red: 0.03, green: 0.05, blue: 0.11),
                Color(red: 0.08, green: 0.1, blue: 0.19),
                Color(red: 0.15, green: 0.17, blue: 0.28)
            ]
        case .sunrise:
            return [
                Color(red: 0.13, green: 0.06, blue: 0.16),
                Color(red: 0.25, green: 0.1, blue: 0.22),
                Color(red: 0.34, green: 0.15, blue: 0.27)
            ]
        }
    }

    private var cardColors: [Color] {
        switch self {
        case .neon:
            return [
                Color(red: 0.38, green: 0.17, blue: 0.66),
                Color(red: 0.16, green: 0.72, blue: 0.86)
            ]
        case .midnight:
            return [
                Color(red: 0.16, green: 0.29, blue: 0.52),
                Color(red: 0.1, green: 0.2, blue: 0.34)
            ]
        case .sunrise:
            return [
                Color(red: 0.93, green: 0.45, blue: 0.52),
                Color(red: 0.99, green: 0.69, blue: 0.51)
            ]
        }
    }

    private var glowColors: [Color] {
        switch self {
        case .neon:
            return [
                Color(red: 0.6, green: 0.84, blue: 1.0).opacity(0.7),
                Color(red: 0.93, green: 0.52, blue: 0.98).opacity(0.65)
            ]
        case .midnight:
            return [
                Color(red: 0.46, green: 0.78, blue: 0.97).opacity(0.7),
                Color(red: 0.37, green: 0.53, blue: 1.0).opacity(0.6)
            ]
        case .sunrise:
            return [
                Color(red: 1.0, green: 0.76, blue: 0.62).opacity(0.7),
                Color(red: 0.98, green: 0.52, blue: 0.7).opacity(0.65)
            ]
        }
    }

    private var accentColors: [Color] {
        switch self {
        case .neon:
            return [
                Color(red: 0.37, green: 0.93, blue: 1.0),
                Color(red: 0.99, green: 0.52, blue: 0.11)
            ]
        case .midnight:
            return [
                Color(red: 0.46, green: 0.78, blue: 0.97),
                Color(red: 0.32, green: 0.88, blue: 0.76)
            ]
        case .sunrise:
            return [
                Color(red: 1.0, green: 0.63, blue: 0.76),
                Color(red: 1.0, green: 0.83, blue: 0.59)
            ]
        }
    }
}

struct WeeklyStats {
    let windowLabel: String
    let totalFasts: Int
    let successfulFasts: Int
    let successRate: Double
    let averageDurationHours: Double
    let longestFastHours: Double
}

struct WindowSuggestion {
    let startMinutes: Int
    let endMinutes: Int
    let sampleSize: Int
}

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
    @Published var theme: AppTheme = .neon

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
        var theme: AppTheme?
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

    func stopFast(at completionDate: Date = Date()) {
        guard isFasting, let plan = selectedPlan, let start = fastStartDate else { return }
        let end = completionDate
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

    func completeFastIfNeeded(asOf date: Date = Date()) {
        guard isFasting, let end = fastEndDate else { return }
        if date >= end {
            stopFast(at: end)
        }
    }

    func remainingTime(asOf date: Date = Date()) -> TimeInterval {
        guard isFasting, let end = fastEndDate else { return 0 }
        return max(end.timeIntervalSince(date), 0)
    }

    func fastProgress(asOf date: Date = Date()) -> Double {
        guard isFasting, let start = fastStartDate, let plan = selectedPlan else { return 0 }
        let elapsed = date.timeIntervalSince(start)
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
            theme = decoded.theme ?? .neon
            completeFastIfNeeded(asOf: Date())
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
            dailyReminderEnabled: dailyReminderEnabled,
            theme: theme
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

    func currentStreakMilestones() -> (achieved: Int?, next: Int?) {
        let thresholds = [3, 7, 14, 30]
        let streak = currentStreak()

        let achieved = thresholds.last(where: { streak >= $0 })
        let next = thresholds.first(where: { streak < $0 })

        return (achieved, next)
    }

    func weeklyStats(endingAt date: Date = Date()) -> WeeklyStats {
        let calendar = Calendar.current
        guard let startOfWindow = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: date)) else {
            return WeeklyStats(windowLabel: "Last 7 days", totalFasts: 0, successfulFasts: 0, successRate: 0, averageDurationHours: 0, longestFastHours: 0)
        }

        let windowHistory = history.filter { $0.endDate >= startOfWindow && $0.endDate <= date }

        guard !windowHistory.isEmpty else {
            return WeeklyStats(windowLabel: "Last 7 days", totalFasts: 0, successfulFasts: 0, successRate: 0, averageDurationHours: 0, longestFastHours: 0)
        }

        let successful = windowHistory.filter { $0.isSuccessful }
        let durations = windowHistory.map { $0.durationHours }
        let averageDuration = durations.reduce(0, +) / Double(windowHistory.count)
        let longest = durations.max() ?? 0
        let rate = Double(successful.count) / Double(windowHistory.count)

        return WeeklyStats(
            windowLabel: "Last 7 days",
            totalFasts: windowHistory.count,
            successfulFasts: successful.count,
            successRate: rate,
            averageDurationHours: averageDuration,
            longestFastHours: longest
        )
    }

    func preferredWindow(limit: Int = 14) -> WindowSuggestion? {
        let successful = history.filter { $0.isSuccessful }
        guard !successful.isEmpty else { return nil }

        let recent = Array(successful.prefix(limit))
        let starts = recent.map { $0.startDate }
        let ends = recent.map { $0.endDate }

        guard let averageStart = averageTimeMinutes(for: starts), let averageEnd = averageTimeMinutes(for: ends) else {
            return nil
        }

        return WindowSuggestion(startMinutes: averageStart, endMinutes: averageEnd, sampleSize: recent.count)
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

    private func averageTimeMinutes(for dates: [Date]) -> Int? {
        guard !dates.isEmpty else { return nil }
        let calendar = Calendar.current
        let minutes = dates.compactMap { date -> Int? in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            guard let hour = components.hour, let minute = components.minute else { return nil }
            return hour * 60 + minute
        }
        guard !minutes.isEmpty else { return nil }
        let total = minutes.reduce(0, +)
        return Int(round(Double(total) / Double(minutes.count)))
    }

    func deleteFasts(withIDs ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let originalCount = history.count
        let idSet = Set(ids)
        history.removeAll { idSet.contains($0.id) }
        guard history.count != originalCount else { return }
        saveToDefaults()
    }

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
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
