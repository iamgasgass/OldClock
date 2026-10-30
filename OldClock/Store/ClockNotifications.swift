import Foundation
import UserNotifications

/// Local notifications for alarms, snoozes and the timer: the way an alarm
/// goes off when OldClock is not on screen (iOS 6 did it from the system).
enum ClockNotifications {
    static let alarmCategory = "OLDCLOCK_ALARM"
    static let alarmNoSnoozeCategory = "OLDCLOCK_ALARM_NOSNOOZE"
    static let timerCategory = "OLDCLOCK_TIMER"
    static let snoozeAction = "OLDCLOCK_SNOOZE"

    /// iOS 6 snooze: 9 minutes.
    static let snoozeInterval: TimeInterval = 9 * 60

    private static var center: UNUserNotificationCenter { .current() }

    static func registerCategories() {
        let snooze = UNNotificationAction(identifier: snoozeAction, title: "Snooze", options: [])
        let alarm = UNNotificationCategory(identifier: alarmCategory, actions: [snooze], intentIdentifiers: [], options: [.customDismissAction])
        let alarmNoSnooze = UNNotificationCategory(identifier: alarmNoSnoozeCategory, actions: [], intentIdentifiers: [], options: [.customDismissAction])
        let timer = UNNotificationCategory(identifier: timerCategory, actions: [], intentIdentifiers: [], options: [])
        center.setNotificationCategories([alarm, alarmNoSnooze, timer])
    }

    static func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Alarms

    private static func prefix(_ id: UUID) -> String { "alarm.\(id.uuidString)." }

    private static func content(title: String, body: String, sound: ClockSound, category: String, userInfo: [String: String]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.userInfo = userInfo
        if let file = sound.fileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(file))
        }
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        return content
    }

    private static func alarmContent(_ alarm: ClockAlarm) -> UNMutableNotificationContent {
        content(
            title: "Alarm",
            body: alarm.label.isEmpty ? "Alarm" : alarm.label,
            sound: alarm.sound,
            category: alarm.snooze ? alarmCategory : alarmNoSnoozeCategory,
            userInfo: ["kind": "alarm", "alarmID": alarm.id.uuidString]
        )
    }

    /// Replaces every pending request of the alarm (one per repeat day, or
    /// one for the next occurrence).
    static func schedule(_ alarm: ClockAlarm) {
        cancel(alarm.id) {
            guard alarm.enabled else { return }
            let content = alarmContent(alarm)
            if alarm.repeatDays.isEmpty {
                var components = DateComponents()
                components.hour = alarm.hour
                components.minute = alarm.minute
                components.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                center.add(UNNotificationRequest(identifier: prefix(alarm.id) + "once", content: content, trigger: trigger))
            } else {
                for day in alarm.repeatDays.sorted() {
                    var components = DateComponents()
                    components.weekday = day
                    components.hour = alarm.hour
                    components.minute = alarm.minute
                    components.second = 0
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    center.add(UNNotificationRequest(identifier: prefix(alarm.id) + "\(day)", content: content, trigger: trigger))
                }
            }
        }
    }

    static func cancel(_ id: UUID, then: (() -> Void)? = nil) {
        let start = prefix(id)
        let snooze = "snooze.\(id.uuidString)"
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(start) || $0 == snooze }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            DispatchQueue.main.async { then?() }
        }
    }

    static func scheduleSnooze(_ alarm: ClockAlarm) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeInterval, repeats: false)
        center.add(UNNotificationRequest(identifier: "snooze.\(alarm.id.uuidString)", content: alarmContent(alarm), trigger: trigger))
    }

    // MARK: Timer

    static let timerID = "timer"

    static func scheduleTimer(at date: Date, sound: ClockSound) {
        cancelTimer()
        let interval = max(date.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let content = content(title: "Clock", body: "Timer Done", sound: sound, category: timerCategory, userInfo: ["kind": "timer"])
        center.add(UNNotificationRequest(identifier: timerID, content: content, trigger: trigger))
    }

    static func cancelTimer() {
        center.removePendingNotificationRequests(withIdentifiers: [timerID])
    }
}
