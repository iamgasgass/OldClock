import Foundation

// MARK: - Tabs

/// The four tabs of the iOS 6 Clock app, in iOS 6 order.
enum ClockTab: Int, CaseIterable, Identifiable {
    case worldClock
    case alarm
    case stopwatch
    case timer

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .worldClock: return "World Clock"
        case .alarm: return "Alarm"
        case .stopwatch: return "Stopwatch"
        case .timer: return "Timer"
        }
    }

    var iconName: String {
        switch self {
        case .worldClock: return "TabWorldClock"
        case .alarm: return "TabAlarm"
        case .stopwatch: return "TabStopwatch"
        case .timer: return "TabTimer"
        }
    }
}

// MARK: - World Clock

/// A city of the World Clock list ("Cupertino", "U.S.A.", America/Los_Angeles).
struct WorldCity: Codable, Hashable, Identifiable {
    let name: String
    let country: String
    let timeZoneID: String

    var id: String { "\(name)|\(country)|\(timeZoneID)" }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }

    /// "Cupertino, U.S.A." as in the iOS 6 city search list.
    var displayName: String {
        country.isEmpty ? name : "\(name), \(country)"
    }

    static let cupertino = WorldCity(name: "Cupertino", country: "U.S.A.", timeZoneID: "America/Los_Angeles")

    private enum CodingKeys: String, CodingKey {
        case name = "n"
        case country = "c"
        case timeZoneID = "z"
    }
}

// MARK: - Sounds

/// An alarm / timer sound. iOS 6 offered the ringtones, a song from the
/// library ("Pick a song"), "None" (alarm) and "Stop Playing" (timer).
struct ClockSound: Codable, Hashable, Identifiable {
    enum Kind: String, Codable {
        case tone
        case song
        case none
        case stopPlaying
    }

    var kind: Kind
    /// Tone name ("Marimba") or the song title.
    var name: String
    /// `MPMediaItem.persistentID` of a picked song.
    var songID: UInt64?

    var id: String { "\(kind.rawValue)|\(name)|\(songID ?? 0)" }

    static func tone(_ name: String) -> ClockSound {
        ClockSound(kind: .tone, name: name, songID: nil)
    }

    static let marimba = ClockSound.tone("Marimba")
    static let none = ClockSound(kind: .none, name: "None", songID: nil)
    static let stopPlaying = ClockSound(kind: .stopPlaying, name: "Stop Playing", songID: nil)

    /// The iOS 6 ringtones, alphabetical as in Settings › Sounds.
    static let ringtones: [String] = [
        "Alarm", "Ascending", "Bark", "Bell Tower", "Blues", "Boing",
        "Crickets", "Digital", "Doorbell", "Duck", "Harp", "Marimba",
        "Motorcycle", "Old Car Horn", "Old Phone", "Piano Riff", "Pinball",
        "Robot", "Sci-Fi", "Sonar", "Strum", "Timba", "Time Passing",
        "Trill", "Xylophone"
    ]

    /// Bundled file name ("Old Car Horn" → "OldCarHorn.caf").
    static func fileName(for tone: String) -> String {
        tone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") + ".caf"
    }

    /// The bundled file that plays for this sound (a song falls back to
    /// Marimba when the app is not open, as a notification cannot play it).
    var fileName: String? {
        switch kind {
        case .tone: return Self.fileName(for: name)
        case .song: return Self.fileName(for: "Marimba")
        case .none, .stopPlaying: return nil
        }
    }

    var title: String { name }
}

// MARK: - Alarms

/// One alarm of the Alarm tab (iOS 6: time, Repeat, Sound, Snooze, Label,
/// on / off switch).
struct ClockAlarm: Codable, Hashable, Identifiable {
    var id = UUID()
    var hour: Int
    var minute: Int
    /// Calendar weekdays (1 = Sunday … 7 = Saturday).
    var repeatDays: Set<Int> = []
    var sound: ClockSound = .marimba
    var snooze = true
    var label = "Alarm"
    var enabled = true
    /// When a one-time alarm will go off (it switches itself off after).
    var fireDate: Date?

    var isRepeating: Bool { !repeatDays.isEmpty }

    /// The next time this alarm goes off from `date`.
    func nextFire(after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        if repeatDays.isEmpty {
            return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime)
        }
        return repeatDays.compactMap { day -> Date? in
            var c = components
            c.weekday = day
            return calendar.nextDate(after: date, matching: c, matchingPolicy: .nextTime)
        }.min()
    }
}

enum ClockRepeat {
    /// iOS 6 summary of the Repeat row: "Never", "Every day", "Weekdays",
    /// "Weekends", or the short day names ("Mon Wed Fri").
    static func summary(_ days: Set<Int>) -> String {
        if days.isEmpty { return "Never" }
        if days.count == 7 { return "Every day" }
        if days == [2, 3, 4, 5, 6] { return "Weekdays" }
        if days == [1, 7] { return "Weekends" }
        let symbols = shortSymbols
        return orderedDays.filter { days.contains($0) }.map { symbols[$0 - 1] }.joined(separator: " ")
    }

    /// "Every Sunday" … "Every Saturday" (Repeat screen rows).
    static func rowTitle(_ day: Int) -> String {
        "Every \(fullSymbols[day - 1])"
    }

    /// Weekdays in the order of the user's calendar (Sunday first in the U.S.).
    static var orderedDays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    private static let englishFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static var shortSymbols: [String] { englishFormatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] }
    static var fullSymbols: [String] { englishFormatter.weekdaySymbols ?? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] }
}

// MARK: - Formatting

enum ClockFormat {
    /// The device uses the 24-hour clock (Settings › General › Date & Time).
    static var uses24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return !format.contains("a")
    }

    /// "7:05" + "AM" (or "19:05" + nil with the 24-hour clock).
    static func time(hour: Int, minute: Int) -> (String, String?) {
        if uses24Hour {
            return (String(format: "%d:%02d", hour, minute), nil)
        }
        let h = hour % 12 == 0 ? 12 : hour % 12
        return (String(format: "%d:%02d", h, minute), hour < 12 ? "AM" : "PM")
    }

    /// Stopwatch "00:00.0" (minutes:seconds.tenths; hours appear after 60 min).
    static func stopwatch(_ interval: TimeInterval) -> String {
        let tenths = Int((max(interval, 0) * 10).rounded(.down))
        let t = tenths % 10
        let seconds = (tenths / 10) % 60
        let minutes = (tenths / 600) % 60
        let hours = tenths / 36000
        if hours > 0 {
            return String(format: "%d:%02d:%02d.%d", hours, minutes, seconds, t)
        }
        return String(format: "%02d:%02d.%d", minutes, seconds, t)
    }

    /// Timer countdown "00:59:58".
    static func countdown(_ interval: TimeInterval) -> String {
        let total = Int(max(interval, 0).rounded(.up))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }
}
