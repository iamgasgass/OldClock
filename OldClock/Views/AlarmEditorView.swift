import SwiftUI

/// iOS 6 "Add Alarm" / "Edit Alarm": Cancel / Save, the card with Repeat,
/// Sound, Snooze and Label, "Delete Alarm" when editing, and the time wheel
/// at the bottom. Repeat, Sound and Label push their own screens.
struct AlarmEditorView: View {
    @Environment(\.oldClockTheme) private var theme
    @EnvironmentObject private var navigator: ClockNavigator
    @ObservedObject private var keyboard = ClockKeyboard.shared
    let original: ClockAlarm?
    let topInset: CGFloat
    let bottomInset: CGFloat

    private enum Screen {
        case main, repeatDays, sound, label
    }

    @State private var alarm: ClockAlarm
    @State private var screen: Screen = .main
    @State private var forward = true
    @State private var wheel: [Int]
    @FocusState private var labelFocused: Bool

    init(original: ClockAlarm?, topInset: CGFloat, bottomInset: CGFloat) {
        self.original = original
        self.topInset = topInset
        self.bottomInset = bottomInset
        let start: ClockAlarm
        if let original {
            start = original
        } else {
            // iOS 6 proposes the current time.
            let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
            start = ClockAlarm(hour: now.hour ?? 7, minute: now.minute ?? 0)
        }
        _alarm = State(initialValue: start)
        _wheel = State(initialValue: Self.wheelValues(hour: start.hour, minute: start.minute))
    }

    private var title: String {
        switch screen {
        case .main: return original == nil ? "Add Alarm" : "Edit Alarm"
        case .repeatDays: return "Repeat"
        case .sound: return "Sound"
        case .label: return "Label"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ClockTitleBar(topInset: topInset) {
                if screen == .main {
                    OldOSRectangleButton(title: "Cancel", type: theme.neutralButton) {
                        navigator.dismissModal()
                    }
                    .padding(.leading, 5)
                } else {
                    ClockBackButton(title: original == nil ? "Add Alarm" : "Edit Alarm") {
                        go(.main)
                    }
                }
            } center: {
                ClockBarTitle(title: title, forward: forward)
            } trailing: {
                if screen == .main {
                    OldOSRectangleButton(title: "Save", type: theme.primaryButton) {
                        AlarmStore.shared.save(alarm)
                        navigator.dismissModal()
                    }
                    .padding(.trailing, 5)
                }
            }
            .zIndex(2)

            ZStack {
                content
                    .id(screen)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading),
                        removal: .move(edge: forward ? .leading : .trailing)
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(ClockGroupedBackground())
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .main: mainScreen
        case .repeatDays: repeatScreen
        case .sound:
            SoundListView(selection: $alarm.sound, allowsSong: true, allowsNone: true, allowsStopPlaying: false, bottomInset: bottomInset)
        case .label: labelScreen
        }
    }

    private func go(_ target: Screen) {
        oldOSHideKeyboard()
        forward = target != .main
        withAnimation(.linear(duration: 0.28)) {
            screen = target
        }
    }

    // MARK: Main

    private var mainScreen: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ClockCard {
                        ClockCardRow(title: "Repeat", value: ClockRepeat.summary(alarm.repeatDays), action: { go(.repeatDays) })
                        ClockCardRow(title: "Sound", value: alarm.sound.title, action: { go(.sound) })
                        ClockCardRow(title: "Snooze", disclosure: false, accessory: {
                            ClockToggle(isOn: $alarm.snooze)
                        })
                        ClockCardRow(title: "Label", value: alarm.label, showsSeparator: false, action: { go(.label) })
                    }

                    if let original {
                        ClockBigButton(title: "Delete Alarm", style: .red, height: 45) {
                            AlarmStore.shared.delete(original.id)
                            navigator.dismissModal()
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 20)
            }

            ClockWheelPicker(columns: Self.timeColumns, selection: $wheel, onChange: applyWheel)
                .padding(.bottom, bottomInset)
                .background(Color.black)
        }
    }

    // MARK: Repeat

    private var repeatScreen: some View {
        ScrollView(showsIndicators: false) {
            ClockCard {
                let days = ClockRepeat.orderedDays
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    ClockCardRow(
                        title: ClockRepeat.rowTitle(day),
                        showsSeparator: index < days.count - 1,
                        checked: alarm.repeatDays.contains(day),
                        disclosure: false,
                        action: {
                            if alarm.repeatDays.contains(day) {
                                alarm.repeatDays.remove(day)
                            } else {
                                alarm.repeatDays.insert(day)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
            .padding(.bottom, bottomInset)
        }
    }

    // MARK: Label

    private var labelScreen: some View {
        VStack(spacing: 0) {
            ClockCard {
                HStack {
                    TextField("Alarm", text: $alarm.label)
                        .font(OldOSFont.regular(17))
                        .foregroundColor(theme.listRowText)
                        .submitLabel(.done)
                        .focused($labelFocused)
                        .onSubmit {
                            if alarm.label.trimmingCharacters(in: .whitespaces).isEmpty { alarm.label = "Alarm" }
                            go(.main)
                        }
                    if !alarm.label.isEmpty {
                        Button {
                            alarm.label = ""
                        } label: {
                            Image("TextFieldClear")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
            }
            .padding(.horizontal, 10)
            .padding(.top, 20)
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { labelFocused = true }
        }
    }

    // MARK: Time wheel

    /// hour / minute (looping) / AM-PM, or hour / minute in 24-hour time.
    static var timeColumns: [ClockWheelColumn] {
        let minutes = (0..<60).map { String(format: "%02d", $0) }
        if ClockFormat.uses24Hour {
            return [
                ClockWheelColumn(rows: (0..<24).map { String(format: "%02d", $0) }, width: 100, alignment: .right, loops: true),
                ClockWheelColumn(rows: minutes, width: 100, alignment: .left, loops: true)
            ]
        }
        return [
            ClockWheelColumn(rows: (1...12).map { "\($0)" }, width: 96, alignment: .right, loops: true),
            ClockWheelColumn(rows: minutes, width: 96, alignment: .left, loops: true),
            ClockWheelColumn(rows: ["AM", "PM"], width: 84, alignment: .left)
        ]
    }

    static func wheelValues(hour: Int, minute: Int) -> [Int] {
        if ClockFormat.uses24Hour { return [hour, minute] }
        return [(hour % 12 == 0 ? 12 : hour % 12) - 1, minute, hour < 12 ? 0 : 1]
    }

    private func applyWheel() {
        if ClockFormat.uses24Hour {
            alarm.hour = wheel[0]
            alarm.minute = wheel[1]
        } else {
            let h12 = wheel[0] + 1
            let pm = wheel.count > 2 && wheel[2] == 1
            alarm.hour = (h12 % 12) + (pm ? 12 : 0)
            alarm.minute = wheel[1]
        }
    }
}
