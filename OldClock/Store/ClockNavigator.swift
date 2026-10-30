import SwiftUI

/// Tab, Edit mode and the modal screens of the Clock app.
final class ClockNavigator: ObservableObject {
    /// The modal sheets that slide up from the bottom (iOS 6).
    enum Modal: Identifiable, Equatable {
        case citySearch
        case alarmEditor(ClockAlarm?)
        case timerSound

        var id: String {
            switch self {
            case .citySearch: return "city"
            case .alarmEditor(let alarm): return "alarm-\(alarm?.id.uuidString ?? "new")"
            case .timerSound: return "timer-sound"
            }
        }
    }

    private static let tabKey = "OldClock.Tab"

    @Published private(set) var tab: ClockTab
    @Published var editingWorldClock = false
    @Published var editingAlarms = false
    @Published var modal: Modal?

    init() {
        // iOS 6 reopened the Clock app on the last tab.
        tab = ClockTab(rawValue: UserDefaults.standard.integer(forKey: Self.tabKey)) ?? .worldClock
    }

    func select(_ newTab: ClockTab) {
        guard newTab != tab else { return }
        OldClockHaptics.tap()
        editingWorldClock = false
        editingAlarms = false
        tab = newTab
        UserDefaults.standard.set(newTab.rawValue, forKey: Self.tabKey)
    }

    func present(_ modal: Modal) {
        withAnimation(.easeOut(duration: 0.35)) {
            self.modal = modal
        }
    }

    func dismissModal() {
        oldOSHideKeyboard()
        withAnimation(.easeIn(duration: 0.3)) {
            modal = nil
        }
    }
}
