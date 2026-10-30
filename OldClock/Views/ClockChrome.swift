import SwiftUI

// The iOS 6 chrome of the Clock app, built from the OldOS pieces:
// navigation bar (`generic_title_bar`, `double_text_title_bar`,
// `generic_title_bar_cancel_save`), bar buttons (`tool_bar_rectangle_button`)
// and the black tab bar (`TabButton_Phone`, the iOS 6 tab button of OldOS).

// MARK: - Navigation bar

/// The blue (or graphite) bar, extended behind the status bar / Dynamic
/// Island with one gradient, exactly like the OldSafari chrome.
struct ClockTitleBar<Leading: View, Center: View, Trailing: View>: View {
    @Environment(\.oldClockTheme) private var theme
    let topInset: CGFloat
    var height: CGFloat = 60
    var topText: String? = nil
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var center: () -> Center
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)

            ZStack {
                if let topText {
                    // `double_text_title_bar`: prompt line above the title.
                    VStack(spacing: 0) {
                        Text(topText)
                            .font(OldOSFont.regular(14))
                            .foregroundColor(theme.isDark ? theme.pageTitle : .oldOS(47, 62, 88))
                            .shadow(color: theme.isDark ? Color.black.opacity(0.65) : Color.white.opacity(0.65), radius: 0, x: 0, y: theme.isDark ? -2.0 / 3.0 : 2.0 / 3.0)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                        Spacer()
                    }
                }

                VStack(spacing: 0) {
                    if topText != nil { Spacer().frame(height: height - 60) }
                    ZStack {
                        HStack {
                            Spacer()
                            center()
                            Spacer()
                        }
                        HStack {
                            leading()
                            Spacer()
                            trailing()
                        }
                    }
                    .frame(height: 60)
                }
            }
            .frame(height: height)
        }
        .background(
            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)
                Color.clear
                    .frame(height: height)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)
            }
            .background(LinearGradient(oldOS: theme.barGradient))
        )
        .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
    }
}

/// The embossed white 22pt title.
struct ClockBarTitle: View {
    @Environment(\.oldClockTheme) private var theme
    let title: String
    var forward = true

    var body: some View {
        Text(title)
            .font(OldOSFont.bold(22))
            .foregroundColor(theme.titleBarTitle)
            .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: 190)
            .id(title)
            .transition(
                AnyTransition.asymmetric(
                    insertion: .move(edge: forward ? .trailing : .leading),
                    removal: .move(edge: forward ? .leading : .trailing)
                ).combined(with: .opacity)
            )
    }
}

/// The pointed back button (`Button_wp5` artwork with the title on top).
struct ClockBackButton: View {
    @Environment(\.oldClockTheme) private var theme
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            OldClockHaptics.tap()
            action()
        } label: {
            ZStack {
                Image("NavBack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200 * 84 / 162 * (33 / 34.33783783783784), height: 33)
                    .saturation(theme.barButtonSaturation)
                    .brightness(theme.barButtonBrightness)
                Text(title)
                    .font(OldOSFont.bold(13))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: 90)
                    .padding(.leading, 5)
                    .offset(x: 1, y: -1.1)
            }
        }
        .buttonStyle(.plain)
        .padding(.leading, 5.5)
        .offset(y: -0.5)
    }
}

// MARK: - Bar buttons

/// OldOS `tool_bar_rectangle_button` (text or image content).
struct OldOSRectangleButton: View {
    @Environment(\.oldClockTheme) private var theme
    let title: String
    var image: String? = nil
    var type: OldOSButtonType = .gray
    var heightModifier: CGFloat = 0
    var action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Group {
                if let image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13)
                        .padding([.leading, .trailing], 11)
                } else {
                    Text(title)
                        .font(OldOSFont.bold(13.25))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                        .lineLimit(1)
                        .fixedSize()
                        .padding([.leading, .trailing], 11)
                }
            }
            .frame(height: 32 + heightModifier)
            .oldOSInnerShadowBackground(
                RoundedRectangle(cornerRadius: 5.5),
                oldOSButtonGradient(type),
                radius: 0.8,
                offset: CGPoint(x: 0, y: 0.6),
                intensity: 0.7
            )
            .shadow(color: Color.white.opacity(theme.isDark ? 0.12 : 0.28), radius: 0, x: 0, y: 0.8)
        }
        .buttonStyle(.plain)
        .frame(height: 32 + heightModifier)
    }
}

// MARK: - Tab bar

/// The 57pt black glass tab bar (World Clock, Alarm, Stopwatch, Timer),
/// extended down to the bottom of the screen on devices with a home indicator.
struct ClockTabBar: View {
    @EnvironmentObject private var navigator: ClockNavigator
    let bottomInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(ClockTab.allCases) { tab in
                        ClockTabButton(
                            tab: tab,
                            selected: navigator.tab == tab,
                            width: geometry.size.width / CGFloat(ClockTab.allCases.count)
                        ) {
                            navigator.select(tab)
                        }
                        if tab != ClockTab.allCases.last {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(height: 55)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 57)

            Color.clear.frame(height: bottomInset)
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(oldOS: OldClockBlackChrome.barGradient).frame(height: 57)
                OldClockBlackChrome.bottomFill
            }
        )
    }
}

/// OldOS `TabButton_Phone`, with the Clock glyphs.
struct ClockTabButton: View {
    let tab: ClockTab
    let selected: Bool
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: max(width - 5, 0), height: 51)
                        .blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            glyph(width: 30.5, height: 30.5)
                                .overlay(LinearGradient(oldOS: [.oldOS(205, 233, 249), .oldOS(75, 220, 251)]))
                                .mask(glyph(width: 30.5, height: 30.5))
                                .offset(y: -0.5)

                            glyph(width: 30, height: 30)
                                .overlay(
                                    LinearGradient(oldOS: [
                                        OldOSStop(.oldOS(197, 210, 229), 0),
                                        OldOSStop(.oldOS(99, 162, 216), 0.47),
                                        OldOSStop(.oldOS(0, 145, 230), 0.49),
                                        OldOSStop(.oldOS(21, 197, 252), 1)
                                    ])
                                    .rotationEffect(.degrees(-15))
                                    .frame(width: 40, height: 30)
                                    .brightness(0.095)
                                )
                                .mask(glyph(width: 30, height: 30))
                                .shadow(color: Color.black.opacity(0.6), radius: 2.5, x: 0, y: 2.5)
                        }
                        Text(tab.title)
                            .font(OldOSFont.bold(11))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                } else {
                    VStack(spacing: 2) {
                        glyph(width: 30, height: 30)
                            .overlay(LinearGradient(oldOS: [.oldOS(157, 157, 157), .oldOS(89, 89, 89)]))
                            .mask(glyph(width: 30, height: 30))
                            .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        Text(tab.title)
                            .font(OldOSFont.bold(11))
                            .foregroundColor(.oldOS(168, 168, 168))
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: width, height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func glyph(width: CGFloat, height: CGFloat) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
    }
}
