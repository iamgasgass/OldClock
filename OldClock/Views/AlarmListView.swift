import SwiftUI

/// iOS 6 Alarm tab: the alarms by time ("7:00 AM", "Alarm, Weekdays") with
/// the ON / OFF switch. Edit: red minus, and a tap opens "Edit Alarm".
struct AlarmListView: View {
    @Environment(\.oldClockTheme) private var theme
    @EnvironmentObject private var navigator: ClockNavigator
    @ObservedObject private var store = AlarmStore.shared
    @State private var toDelete: UUID?

    static let rowHeight: CGFloat = 70

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(store.alarms) { alarm in
                    row(alarm)
                }
            }
        }
        .background(theme.listBackground)
        .onChange(of: navigator.editingAlarms) { editing in
            if !editing { toDelete = nil }
        }
    }

    private func row(_ alarm: ClockAlarm) -> some View {
        let editing = navigator.editingAlarms
        let deleting = editing && toDelete == alarm.id
        let time = ClockFormat.time(hour: alarm.hour, minute: alarm.minute)
        let dimmed = !alarm.enabled && !editing
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                if editing {
                    Button {
                        withAnimation(.linear(duration: 0.15)) {
                            toDelete = toDelete == alarm.id ? nil : alarm.id
                        }
                    } label: {
                        ZStack {
                            Image("RemoveMinus")
                            Text("—")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .heavy))
                                .offset(y: deleting ? -0.8 : -2)
                                .rotationEffect(.degrees(deleting ? -90 : 0))
                                .offset(y: deleting ? -0.5 : 0)
                        }
                        .frame(width: 44, height: Self.rowHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Button {
                    guard editing, toDelete == nil else {
                        if toDelete != nil { withAnimation(.linear(duration: 0.15)) { toDelete = nil } }
                        return
                    }
                    navigator.present(.alarmEditor(alarm))
                } label: {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(time.0)
                                    .font(OldOSFont.bold(34))
                                if let suffix = time.1 {
                                    Text(suffix)
                                        .font(OldOSFont.bold(17))
                                }
                            }
                            .foregroundColor(dimmed ? theme.listRowDetail : theme.listRowText)
                            Text(Self.subtitle(alarm))
                                .font(OldOSFont.regular(14))
                                .foregroundColor(theme.listRowDetail)
                                .lineLimit(1)
                        }
                        .padding(.leading, editing ? 0 : 12)
                        Spacer(minLength: 8)
                        if editing && !deleting {
                            Image("TableNext").padding(.trailing, 12)
                        }
                    }
                    .frame(height: Self.rowHeight - 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ClockRowButtonStyle())
                .disabled(!editing)

                if deleting {
                    OldOSRectangleButton(title: "Delete", type: .red) {
                        withAnimation {
                            toDelete = nil
                            store.delete(alarm.id)
                        }
                    }
                    .padding(.trailing, 12)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if !editing {
                    ClockToggle(isOn: Binding(
                        get: { alarm.enabled },
                        set: { store.setEnabled(alarm.id, $0) }
                    ))
                    .padding(.trailing, 12)
                    .transition(.opacity)
                }
            }
            .frame(height: Self.rowHeight - 1)
            Rectangle().fill(theme.listSeparator).frame(height: 1)
        }
        .background(theme.listBackground)
    }

    /// "Alarm" or "Alarm, Weekdays".
    static func subtitle(_ alarm: ClockAlarm) -> String {
        let label = alarm.label.isEmpty ? "Alarm" : alarm.label
        return alarm.isRepeating ? "\(label), \(ClockRepeat.summary(alarm.repeatDays))" : label
    }
}
