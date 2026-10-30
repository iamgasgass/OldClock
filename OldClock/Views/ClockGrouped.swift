import SwiftUI

// The grouped tables of the alarm editor and the timer (OldOS
// `settings_main_list`, `list_section`), themed for Light and Dark.

/// OldOS `vertical_bar_background`: blue-grey pinstripes behind grouped tables.
struct ClockGroupedBackground: View {
    @Environment(\.oldClockTheme) private var theme

    var body: some View {
        ZStack {
            theme.groupedBackground
            OldOSPinstripeBackground(line: theme.groupedPinstripe)
                .clipped()
        }
    }
}

/// The white rounded card with the grey outline.
struct ClockCard<Content: View>: View {
    @Environment(\.oldClockTheme) private var theme
    var cornerRadius: CGFloat = 10
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.cardStroke, lineWidth: 1.25)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: Color.white.opacity(theme.isDark ? 0.06 : 0.6), radius: 0, x: 0, y: 1)
    }
}

struct ClockCardSeparator: View {
    @Environment(\.oldClockTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.cardStroke)
            .frame(height: 1.25)
    }
}

/// "Repeat            Never  >": title, blue value, disclosure arrow.
struct ClockCardRow<Accessory: View>: View {
    @Environment(\.oldClockTheme) private var theme
    let title: String
    var value: String? = nil
    var showsSeparator = true
    var checked = false
    var disclosure = true
    var action: (() -> Void)? = nil
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(spacing: 0) {
            if let action {
                Button(action: action) {
                    row
                }
                .buttonStyle(ClockCardButtonStyle())
            } else {
                // Rows with a control (Snooze) are not buttons, so the
                // switch gets its own taps and drags.
                row
            }
            if showsSeparator { ClockCardSeparator() }
        }
    }

    private var row: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(OldOSFont.bold(17))
                .foregroundColor(checked ? theme.checkmark : theme.listRowText)
                .lineLimit(1)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(OldOSFont.regular(17))
                    .foregroundColor(theme.cardFieldText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            accessory()
            if checked {
                Image("BlueCheck")
            } else if disclosure && action != nil {
                Image("TableNext")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 44 - (showsSeparator ? 1.25 : 0))
        .contentShape(Rectangle())
    }
}

extension ClockCardRow where Accessory == EmptyView {
    init(title: String, value: String? = nil, showsSeparator: Bool = true, checked: Bool = false, disclosure: Bool = true, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.showsSeparator = showsSeparator
        self.checked = checked
        self.disclosure = disclosure
        self.action = action
        self.accessory = { EmptyView() }
    }
}

/// iOS 6 blue cell selection inside a card.
struct ClockCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(oldOS: [
                    OldOSStop(.oldOS(5, 140, 245), 0),
                    OldOSStop(.oldOS(1, 93, 230), 1)
                ])
                .opacity(configuration.isPressed ? 1 : 0)
            )
    }
}

/// The section title above a card ("Ringtones").
struct ClockSectionTitle: View {
    @Environment(\.oldClockTheme) private var theme
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(OldOSFont.bold(17))
                .foregroundColor(theme.sectionHeader)
                .shadow(color: theme.isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.9), radius: 0, x: 0, y: 1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}

/// The big iOS 6 glossy buttons (Stopwatch Start / Stop / Lap / Reset,
/// Timer Start / Cancel, Delete Alarm).
struct ClockBigButton: View {
    enum Style {
        case green, red, silver
    }

    let title: String
    let style: Style
    var enabled = true
    var height: CGFloat = 50
    let action: () -> Void

    private var gradient: LinearGradient {
        switch style {
        case .green:
            return LinearGradient(oldOS: [
                OldOSStop(.oldOS(140, 214, 124), 0),
                OldOSStop(.oldOS(76, 178, 58), 0.5),
                OldOSStop(.oldOS(50, 158, 34), 0.5),
                OldOSStop(.oldOS(58, 170, 40), 1)
            ])
        case .red:
            return LinearGradient(oldOS: [
                OldOSStop(.oldOS(239, 135, 142), 0),
                OldOSStop(.oldOS(199, 52, 63), 0.48),
                OldOSStop(.oldOS(189, 20, 33), 0.49),
                OldOSStop(.oldOS(189, 20, 33), 1)
            ])
        case .silver:
            return LinearGradient(oldOS: [
                OldOSStop(.oldOS(252, 252, 252), 0),
                OldOSStop(.oldOS(226, 228, 232), 0.5),
                OldOSStop(.oldOS(208, 211, 217), 0.5),
                OldOSStop(.oldOS(222, 225, 230), 1)
            ])
        }
    }

    var body: some View {
        Button {
            guard enabled else { return }
            OldClockHaptics.tap()
            action()
        } label: {
            Text(title)
                .font(OldOSFont.bold(20))
                .foregroundColor(style == .silver ? (enabled ? .oldOS(60, 64, 72) : .oldOS(160, 164, 172)) : .white)
                .shadow(color: style == .silver ? Color.white.opacity(0.9) : Color.black.opacity(0.5), radius: 0, x: 0, y: style == .silver ? 1 : -1)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(RoundedRectangle(cornerRadius: 10).fill(gradient))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.45), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white.opacity(style == .silver ? 0.9 : 0.35), lineWidth: 1)
                        .padding(1)
                )
                .shadow(color: Color.white.opacity(0.35), radius: 0, x: 0, y: 1)
                .opacity(enabled || style == .silver ? 1 : 0.6)
                .contentShape(Rectangle())
        }
        .buttonStyle(ClockBigButtonPress())
    }
}

private struct ClockBigButtonPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.12 : 0)
    }
}
