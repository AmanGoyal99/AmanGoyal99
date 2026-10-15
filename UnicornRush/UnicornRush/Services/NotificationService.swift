import Foundation
import UserNotifications

/// Local "come back" nudges. Permission is only requested after the player closes
/// their first round, when they're already invested — much higher opt-in rate than
/// asking on first launch.
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.setBadgeCount(0) { _ in }
    }

    func scheduleComebacks(offlinePerSecond: Double, streak: Int, company: String) {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let name = company.isEmpty ? "Your startup" : company
            if offlinePerSecond > 0 {
                let earned = offlinePerSecond * 3 * 3_600
                self.schedule(id: "team-earned",
                              title: "\(name) made \(Format.money(earned)) 💸",
                              body: "Your team kept shipping while you were gone. Investors are calling.",
                              after: 3 * 3_600)
            }
            if streak > 0 {
                self.schedule(id: "streak",
                              title: "Your \(streak)-day streak is on the line 🔥",
                              body: "Check in to keep it alive and grab today's bonus.",
                              after: 22 * 3_600)
            }
        }
    }

    private func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
