import Foundation
import Combine

/// The alarms of the Alarm tab, sorted by time like iOS 6, saved, and
/// mirrored into local notifications.
final class AlarmStore: ObservableObject {
    static let shared = AlarmStore()

    private static let key = "OldClock.Alarms"

    @Published private(set) var alarms: [ClockAlarm] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([ClockAlarm].self, from: data) {
            alarms = saved.sorted(by: Self.order)
        }
    }

    private static func order(_ a: ClockAlarm, _ b: ClockAlarm) -> Bool {
        (a.hour, a.minute) < (b.hour, b.minute)
    }

    func alarm(_ id: UUID) -> ClockAlarm? {
        alarms.first { $0.id == id }
    }

    /// Save (add or edit). A saved alarm is switched on, as on iOS 6.
    func save(_ alarm: ClockAlarm) {
        var alarm = alarm
        alarm.enabled = true
        alarm.fireDate = alarm.isRepeating ? nil : alarm.nextFire()
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        alarms.sort(by: Self.order)
        persist()
        ClockNotifications.requestAuthorization()
        ClockNotifications.schedule(alarm)
    }

    func delete(_ id: UUID) {
        alarms.removeAll { $0.id == id }
        persist()
        ClockNotifications.cancel(id)
    }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == id }), alarms[index].enabled != enabled else { return }
        alarms[index].enabled = enabled
        alarms[index].fireDate = enabled && !alarms[index].isRepeating ? alarms[index].nextFire() : nil
        persist()
        if enabled { ClockNotifications.requestAuthorization() }
        ClockNotifications.schedule(alarms[index])
    }

    /// A one-time alarm switches itself off once it has gone off (iOS 6).
    func refreshExpired(now: Date = Date()) {
        var changed = false
        for index in alarms.indices {
            let alarm = alarms[index]
            if alarm.enabled, !alarm.isRepeating, let fire = alarm.fireDate, fire <= now {
                alarms[index].enabled = false
                alarms[index].fireDate = nil
                changed = true
            }
        }
        if changed { persist() }
    }

    /// The alarm went off while OldClock was open.
    func didFire(_ id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }), !alarms[index].isRepeating else { return }
        alarms[index].enabled = false
        alarms[index].fireDate = nil
        persist()
    }

    /// Re-creates every notification (after a launch or a time zone change).
    func rescheduleAll() {
        for alarm in alarms {
            ClockNotifications.schedule(alarm)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
