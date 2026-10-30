import SwiftUI

/// iOS 6 Timer: the hours / mins wheel, "When Timer Ends" and the big green
/// Start; while counting, the remaining time and the red Cancel.
struct TimerView: View {
    @Environment(\.oldClockTheme) private var theme
    @EnvironmentObject private var navigator: ClockNavigator
    @ObservedObject private var model = TimerModel.shared
    let bottomInset: CGFloat

    @State private var wheel: [Int] = [0, 15]

    var body: some View {
        VStack(spacing: 0) {
            if model.isRunning {
                TimelineView(.periodic(from: Date(), by: 0.25)) { context in
                    ClockDisplayPanel(height: ClockWheelPicker.height) {
                        Text(ClockFormat.countdown(model.remaining(at: context.date)))
                            .font(OldOSFont.bold(60))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .transition(.opacity)
            } else {
                ClockWheelPicker(columns: Self.columns, selection: $wheel, onChange: applyWheel)
                    .background(Color.black)
                    .transition(.opacity)
            }

            VStack(spacing: 20) {
                ClockCard {
                    ClockCardRow(title: "When Timer Ends", value: model.sound.title, showsSeparator: false, action: {
                        navigator.present(.timerSound)
                    })
                }

                if model.isRunning {
                    ClockBigButton(title: "Cancel", style: .red) {
                        withAnimation(.easeInOut(duration: 0.25)) { model.cancel() }
                    }
                } else {
                    ClockBigButton(title: "Start", style: .green, enabled: model.duration >= 60) {
                        withAnimation(.easeInOut(duration: 0.25)) { model.start() }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ClockGroupedBackground())
        }
        .onAppear {
            let minutes = Int(model.duration / 60)
            wheel = [minutes / 60, minutes % 60]
        }
    }

    static let columns: [ClockWheelColumn] = [
        ClockWheelColumn(rows: (0..<24).map { "\($0)" }, width: 140, alignment: .right, unit: "hours"),
        ClockWheelColumn(rows: (0..<60).map { "\($0)" }, width: 140, alignment: .right, unit: "mins")
    ]

    private func applyWheel() {
        let hours = wheel.first ?? 0
        let minutes = wheel.count > 1 ? wheel[1] : 0
        var total = hours * 60 + minutes
        if total == 0 {
            // iOS 6: the wheel will not stop on 0 h 0 min.
            total = 1
            wheel = [0, 1]
        }
        model.duration = TimeInterval(total * 60)
    }
}

/// "When Timer Ends" (modal, Cancel / Set).
struct TimerSoundView: View {
    @Environment(\.oldClockTheme) private var theme
    @EnvironmentObject private var navigator: ClockNavigator
    let topInset: CGFloat
    let bottomInset: CGFloat

    @State private var sound = TimerModel.shared.sound

    var body: some View {
        VStack(spacing: 0) {
            ClockTitleBar(topInset: topInset) {
                OldOSRectangleButton(title: "Cancel", type: theme.neutralButton) {
                    navigator.dismissModal()
                }
                .padding(.leading, 5)
            } center: {
                ClockBarTitle(title: "When Timer Ends")
            } trailing: {
                OldOSRectangleButton(title: "Set", type: theme.primaryButton) {
                    TimerModel.shared.sound = sound
                    navigator.dismissModal()
                }
                .padding(.trailing, 5)
            }
            SoundListView(selection: $sound, allowsSong: false, allowsNone: false, allowsStopPlaying: true, bottomInset: bottomInset)
        }
        .background(ClockGroupedBackground())
    }
}
