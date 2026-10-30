import Foundation
import Combine

/// The iOS 6 timer: hours / minutes on the wheel, "When Timer Ends" sound,
/// Start / Cancel. It keeps counting while the app is closed and rings
/// through a notification.
final class TimerModel: ObservableObject {
    static let shared = TimerModel()

    private struct Saved: Codable {
        var duration: TimeInterval
        var endDate: Date?
        var sound: ClockSound
    }

    private static let key = "OldClock.Timer"

    /// Chosen on the wheel (iOS 6 default: 15 minutes).
    @Published var duration: TimeInterval = 15 * 60 {
        didSet { persist() }
    }
    @Published var sound: ClockSound = .marimba {
        didSet {
            persist()
            if let endDate { ClockNotifications.scheduleTimer(at: endDate, sound: sound) }
        }
    }
    @Published private(set) var endDate: Date?

    private var ticker: AnyCancellable?

    var isRunning: Bool { endDate != nil }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            duration = saved.duration
            sound = saved.sound
            endDate = saved.endDate
        }
        // Ended while the app was closed: the notification already rang.
        if let endDate, endDate <= Date() {
            self.endDate = nil
            persist()
        }
        startTicker()
    }

    func remaining(at date: Date = Date()) -> TimeInterval {
        guard let endDate else { return duration }
        return max(endDate.timeIntervalSince(date), 0)
    }

    func start() {
        guard !isRunning, duration >= 60 else { return }
        let end = Date().addingTimeInterval(duration)
        endDate = end
        persist()
        ClockNotifications.requestAuthorization()
        ClockNotifications.scheduleTimer(at: end, sound: sound)
        startTicker()
    }

    func cancel() {
        endDate = nil
        persist()
        ClockNotifications.cancelTimer()
        ticker = nil
    }

    /// Time is up (from the ticker, or the notification while the app is open).
    func finish() {
        guard isRunning else { return }
        endDate = nil
        persist()
        ticker = nil
        ClockNotifications.cancelTimer()
        ClockRinger.shared.ringTimer(sound: sound)
    }

    private func startTicker() {
        guard endDate != nil else { return }
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self, let end = self.endDate else { return }
                guard now >= end else { return }
                if now.timeIntervalSince(end) > 2 {
                    // Ended while the app was in the background: the
                    // notification has already rung.
                    self.endDate = nil
                    self.persist()
                    self.ticker = nil
                } else {
                    self.finish()
                }
            }
    }

    private func persist() {
        let saved = Saved(duration: duration, endDate: endDate, sound: sound)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
