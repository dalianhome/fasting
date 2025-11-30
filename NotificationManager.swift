import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if !granted {
                print("Notification permission not granted")
            }
        }
    }

    func scheduleStartNotification(planName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Fasting started"
        content.body = "Your fasting window has begun. Stay hydrated! (\(planName))"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fasting_start", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleCompletionNotification(planName: String, endDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Fasting complete!"
        content.body = "You\'ve reached your fasting goal for the plan \(planName)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(endDate.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: "fasting_complete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to start fasting"
        content.body = "Set your fasting window to stay on track with your goals."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "fasting_daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fasting_start", "fasting_complete"])
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fasting_daily_reminder"])
    }
}
