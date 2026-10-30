import SwiftUI

/// iOS 6 Stopwatch: the big "00:00.0" on the silver display, Start / Stop
/// (green / red) and Reset / Lap, and the lap list.
struct StopwatchView: View {
    @Environment(\.oldClockTheme) private var theme
    @ObservedObject private var model = StopwatchModel.shared

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !model.isRunning)) { context in
                ClockDisplayPanel {
                    Text(ClockFormat.stopwatch(model.elapsed(at: context.date)))
                        .font(OldOSFont.bold(64))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            HStack(spacing: 10) {
                if model.isRunning {
                    ClockBigButton(title: "Stop", style: .red) { model.stop() }
                    ClockBigButton(title: "Lap", style: .silver) { model.lap() }
                } else {
                    ClockBigButton(title: "Start", style: .green) { model.start() }
                    ClockBigButton(title: "Reset", style: .silver, enabled: model.hasTime) { model.reset() }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(ClockGroupedBackground())
            .overlay(Rectangle().fill(Color.black.opacity(0.3)).frame(height: 1), alignment: .bottom)

            lapList
        }
    }

    private var lapList: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10.0, paused: !model.isRunning)) { context in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if model.isRunning || !model.laps.isEmpty {
                        // The lap running now, then the recorded laps (newest first).
                        if model.isRunning || model.hasTime {
                            lapRow(number: model.laps.count + 1, time: model.currentLap(at: context.date))
                        }
                        ForEach(Array(model.laps.enumerated()).reversed(), id: \.offset) { index, lap in
                            lapRow(number: index + 1, time: lap)
                        }
                    }
                }
            }
            .background(theme.listBackground)
        }
    }

    private func lapRow(number: Int, time: TimeInterval) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lap \(number)")
                    .font(OldOSFont.bold(17))
                    .foregroundColor(theme.listRowText)
                Spacer()
                Text(ClockFormat.stopwatch(time))
                    .font(OldOSFont.regular(17))
                    .monospacedDigit()
                    .foregroundColor(theme.listRowText)
            }
            .padding(.horizontal, 14)
            .frame(height: 43)
            Rectangle().fill(theme.listSeparator).frame(height: 1)
        }
    }
}

/// The silver LCD-like panel of the stopwatch and of the running timer.
struct ClockDisplayPanel<Content: View>: View {
    @Environment(\.oldClockTheme) private var theme
    var height: CGFloat = 110
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(oldOS: theme.isDark
                ? [OldOSStop(.oldOS(70, 70, 74), 0), OldOSStop(.oldOS(40, 40, 44), 1)]
                : [OldOSStop(.oldOS(252, 252, 252), 0), OldOSStop(.oldOS(228, 230, 234), 0.55), OldOSStop(.oldOS(204, 208, 214), 1)])
            content()
                .foregroundColor(theme.isDark ? .white : .black)
                .shadow(color: theme.isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.9), radius: 0, x: 0, y: theme.isDark ? -1 : 1)
                .padding(.horizontal, 12)
        }
        .frame(height: height)
        .overlay(Rectangle().fill(Color.white.opacity(theme.isDark ? 0.12 : 0.9)).frame(height: 1), alignment: .top)
        .overlay(Rectangle().fill(Color.black.opacity(0.35)).frame(height: 1), alignment: .bottom)
    }
}
