import Foundation
import Combine

/// The iOS 6 stopwatch: Start / Stop, Lap / Reset, with the lap list.
/// It keeps running while the app is closed (the start time is saved).
final class StopwatchModel: ObservableObject {
    static let shared = StopwatchModel()

    private struct Saved: Codable {
        var startDate: Date?
        var accumulated: TimeInterval
        var laps: [TimeInterval]
    }

    private static let key = "OldClock.Stopwatch"

    /// Set while running.
    @Published private(set) var startDate: Date?
    /// Time banked by previous runs.
    @Published private(set) var accumulated: TimeInterval = 0
    /// Lap durations, first lap first.
    @Published private(set) var laps: [TimeInterval] = []

    var isRunning: Bool { startDate != nil }
    var hasTime: Bool { isRunning || accumulated > 0 }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            startDate = saved.startDate
            accumulated = saved.accumulated
            laps = saved.laps
        }
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        accumulated + (startDate.map { date.timeIntervalSince($0) } ?? 0)
    }

    /// The lap being timed now.
    func currentLap(at date: Date = Date()) -> TimeInterval {
        elapsed(at: date) - laps.reduce(0, +)
    }

    func start() {
        guard !isRunning else { return }
        startDate = Date()
        persist()
    }

    func stop() {
        guard let start = startDate else { return }
        accumulated += Date().timeIntervalSince(start)
        startDate = nil
        persist()
    }

    func lap() {
        guard isRunning else { return }
        laps.append(currentLap())
        persist()
    }

    func reset() {
        guard !isRunning else { return }
        accumulated = 0
        laps = []
        persist()
    }

    private func persist() {
        let saved = Saved(startDate: startDate, accumulated: accumulated, laps: laps)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
