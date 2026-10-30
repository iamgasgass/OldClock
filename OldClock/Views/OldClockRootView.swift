import SwiftUI

/// The iOS 6 Clock app: navigation bar, the four tabs (World Clock, Alarm,
/// Stopwatch, Timer) above the black tab bar, the modal screens sliding up,
/// and the alarm / timer alert. Bars extend behind the status bar / Dynamic
/// Island and the home indicator, exactly like OldSafari. The skin follows
/// Settings › OldClock › Aspect UI (Sistema / Chiaro / Scuro).
struct OldClockRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var navigator = ClockNavigator()
    @StateObject private var safeArea = OldOSSafeArea()
    @ObservedObject private var ringer = ClockRinger.shared
    @ObservedObject private var worldClocks = WorldClockStore.shared
    @ObservedObject private var alarms = AlarmStore.shared

    var body: some View {
        GeometryReader { geometry in
            let topInset = max(geometry.safeAreaInsets.top, safeArea.insets.top)
            let bottomInset = max(geometry.safeAreaInsets.bottom, safeArea.insets.bottom)

            ZStack {
                theme.listBackground

                VStack(spacing: 0) {
                    navigationBar(topInset: topInset)
                        .zIndex(2)

                    ZStack {
                        screen(bottomInset: bottomInset)
                            .id(navigator.tab)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .zIndex(1)

                    ClockTabBar(bottomInset: bottomInset)
                        .zIndex(2)
                }

                if let modal = navigator.modal {
                    modalScreen(modal, topInset: topInset, bottomInset: bottomInset)
                        .id(modal.id)
                        .transition(.move(edge: .bottom))
                        .zIndex(10)
                }

                if let ring = ringer.ring {
                    ClockAlertView(
                        ring: ring,
                        onSnooze: { ringer.snooze() },
                        onOK: { ringer.dismiss() }
                    )
                    .id(ring.id)
                    .transition(.opacity)
                    .zIndex(30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear { safeArea.refresh() }
        }
        .ignoresSafeArea()
        .environment(\.oldClockTheme, theme)
        .environmentObject(navigator)
        .animation(.easeInOut(duration: 0.2), value: ringer.ring)
        .onAppear {
            ClockSettings.shared.apply()
            AlarmStore.shared.refreshExpired()
            updateStatusBar()
        }
        .onChange(of: colorScheme) { _ in updateStatusBar() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            AlarmStore.shared.refreshExpired()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            AlarmStore.shared.rescheduleAll()
        }
    }

    private var theme: OldClockTheme {
        OldClockTheme.theme(isDark: colorScheme == .dark)
    }

    private func updateStatusBar() {
        ClockStatusBar.shared.update(lightChrome: colorScheme != .dark)
    }

    // MARK: Navigation bar

    @ViewBuilder
    private func navigationBar(topInset: CGFloat) -> some View {
        switch navigator.tab {
        case .worldClock:
            editableBar(topInset: topInset, title: "World Clock", editing: $navigator.editingWorldClock, canEdit: !worldClocks.cities.isEmpty) {
                navigator.present(.citySearch)
            }
        case .alarm:
            editableBar(topInset: topInset, title: "Alarm", editing: $navigator.editingAlarms, canEdit: !alarms.alarms.isEmpty) {
                navigator.present(.alarmEditor(nil))
            }
        case .stopwatch, .timer:
            ClockTitleBar(topInset: topInset) {
                EmptyView()
            } center: {
                ClockBarTitle(title: navigator.tab.title)
            } trailing: {
                EmptyView()
            }
        }
    }

    /// "Edit" / "Done" on the left, "+" on the right.
    private func editableBar(topInset: CGFloat, title: String, editing: Binding<Bool>, canEdit: Bool, add: @escaping () -> Void) -> some View {
        ClockTitleBar(topInset: topInset) {
            if editing.wrappedValue {
                OldOSRectangleButton(title: "Done", type: theme.primaryButton) {
                    withAnimation(.easeInOut(duration: 0.2)) { editing.wrappedValue = false }
                }
                .padding(.leading, 5)
            } else {
                OldOSRectangleButton(title: "Edit", type: theme.neutralButton) {
                    withAnimation(.easeInOut(duration: 0.2)) { editing.wrappedValue = true }
                }
                .padding(.leading, 5)
                .opacity(canEdit ? 1 : 0.5)
                .disabled(!canEdit)
            }
        } center: {
            ClockBarTitle(title: title)
        } trailing: {
            OldOSRectangleButton(title: "", image: "BarPlus", type: theme.neutralButton) {
                add()
            }
            .padding(.trailing, 5)
        }
    }

    // MARK: Screens

    @ViewBuilder
    private func screen(bottomInset: CGFloat) -> some View {
        switch navigator.tab {
        case .worldClock: WorldClockView()
        case .alarm: AlarmListView()
        case .stopwatch: StopwatchView()
        case .timer: TimerView(bottomInset: bottomInset)
        }
    }

    @ViewBuilder
    private func modalScreen(_ modal: ClockNavigator.Modal, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        switch modal {
        case .citySearch:
            CitySearchView(topInset: topInset, bottomInset: bottomInset)
        case .alarmEditor(let alarm):
            AlarmEditorView(original: alarm, topInset: topInset, bottomInset: bottomInset)
        case .timerSound:
            TimerSoundView(topInset: topInset, bottomInset: bottomInset)
        }
    }
}
