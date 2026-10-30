import SwiftUI

/// The iOS 6 `UIAlertView`: the dark blue glass box with the white rim,
/// the bold title, the message and the glossy buttons ("Snooze" / "OK").
struct ClockAlertView: View {
    let ring: ClockRinger.Ring
    let onSnooze: () -> Void
    let onOK: () -> Void

    @State private var scale: CGFloat = 1.1
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // iOS 6 dimmed the screen with a radial shadow.
            RadialGradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.65)], center: .center, startRadius: 40, endRadius: 500)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(ring.title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -1)
                    .padding(.top, 16)
                Text(ring.message)
                    .font(OldOSFont.regular(16))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                HStack(spacing: 10) {
                    if ring.canSnooze {
                        alertButton("Snooze", emphasised: false, action: onSnooze)
                    }
                    alertButton("OK", emphasised: ring.canSnooze, action: onOK)
                }
                .padding(.horizontal, 12)
                .padding(.top, 18)
                .padding(.bottom, 14)
            }
            .frame(width: 284)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(oldOS: [
                            OldOSStop(Color.oldOS(36, 54, 108).opacity(0.94), 0),
                            OldOSStop(Color.oldOS(10, 26, 72).opacity(0.94), 1)
                        ]))
                    // The glossy arc of the iOS 6 alert.
                    Ellipse()
                        .fill(LinearGradient(oldOS: [Color.white.opacity(0.32), Color.white.opacity(0.06)]))
                        .frame(width: 520, height: 120)
                        .offset(y: -70)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }
        }
    }

    private func alertButton(_ title: String, emphasised: Bool, action: @escaping () -> Void) -> some View {
        Button {
            OldClockHaptics.tap()
            action()
        } label: {
            Text(title)
                .font(OldOSFont.bold(18))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -1)
                .frame(maxWidth: .infinity)
                .frame(height: 43)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(oldOS: emphasised
                            ? [OldOSStop(Color.white.opacity(0.42), 0), OldOSStop(Color.white.opacity(0.22), 0.5), OldOSStop(Color.white.opacity(0.12), 0.5), OldOSStop(Color.white.opacity(0.2), 1)]
                            : [OldOSStop(Color.white.opacity(0.3), 0), OldOSStop(Color.white.opacity(0.12), 0.5), OldOSStop(Color.white.opacity(0.04), 0.5), OldOSStop(Color.white.opacity(0.1), 1)]))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.55), lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(ClockBigButtonPressPublic())
    }
}

struct ClockBigButtonPressPublic: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.15 : 0)
    }
}
