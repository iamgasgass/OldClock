import SwiftUI

/// The iOS 6 World Clock face: white with black numerals and hands by day,
/// black with white numerals and hands by night, the thin red second hand
/// with its red cap, in a bevelled metal rim.
struct AnalogClockFace: View {
    let date: Date
    let timeZone: TimeZone
    var size: CGFloat = 72

    private var components: (hour: Int, minute: Int, second: Double) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let seconds = Double(c.second ?? 0) + Double(c.nanosecond ?? 0) / 1_000_000_000
        return (c.hour ?? 0, c.minute ?? 0, seconds)
    }

    /// iOS 6 switched to the black face between 6 PM and 6 AM.
    static func isNight(hour: Int) -> Bool {
        hour < 6 || hour >= 18
    }

    var body: some View {
        let time = components
        let night = Self.isNight(hour: time.hour)
        let face = night ? Color.oldOS(22, 22, 24) : Color.white
        let ink = night ? Color.white : Color.black

        ZStack {
            // Rim.
            Circle()
                .fill(LinearGradient(oldOS: night
                    ? [.oldOS(120, 120, 124), .oldOS(30, 30, 32)]
                    : [.oldOS(250, 250, 250), .oldOS(150, 150, 154)]))
            Circle()
                .fill(face)
                .padding(size * 0.035)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(night ? 0.8 : 0.35), lineWidth: 0.8)
                        .padding(size * 0.035)
                )
                .overlay(
                    // Soft inner shadow under the rim.
                    Circle()
                        .stroke(LinearGradient(oldOS: [Color.black.opacity(0.35), Color.clear]), lineWidth: size * 0.05)
                        .blur(radius: size * 0.02)
                        .padding(size * 0.05)
                        .clipShape(Circle().inset(by: size * 0.035))
                )

            // Numerals 1–12.
            ForEach(1...12, id: \.self) { n in
                let angle = Double(n) * .pi / 6
                Text("\(n)")
                    .font(OldOSFont.regular(size * 0.155))
                    .foregroundColor(ink)
                    .position(
                        x: size / 2 + CGFloat(sin(angle)) * size * 0.355,
                        y: size / 2 - CGFloat(cos(angle)) * size * 0.355
                    )
            }

            // Hour and minute hands.
            hand(angle: (Double(time.hour % 12) + Double(time.minute) / 60) * 30, length: 0.25, width: 0.055, color: ink)
            hand(angle: (Double(time.minute) + time.second / 60) * 6, length: 0.37, width: 0.04, color: ink)

            // Second hand (red, with the counterweight tail).
            Capsule()
                .fill(Color.oldOS(220, 20, 20))
                .frame(width: max(size * 0.012, 0.8), height: size * 0.52)
                .offset(y: -size * 0.13)
                .rotationEffect(.degrees(floor(time.second) * 6))
            Circle()
                .fill(Color.oldOS(220, 20, 20))
                .frame(width: size * 0.07, height: size * 0.07)
            Circle()
                .fill(Color.oldOS(120, 0, 0))
                .frame(width: size * 0.02, height: size * 0.02)

            // Glass reflection.
            Circle()
                .fill(LinearGradient(oldOS: [Color.white.opacity(night ? 0.12 : 0.35), Color.white.opacity(0)]))
                .frame(width: size * 0.8, height: size * 0.45)
                .offset(y: -size * 0.2)
                .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.5), radius: 1.5, x: 0, y: 1.5)
    }

    private func hand(angle: Double, length: CGFloat, width: CGFloat, color: Color) -> some View {
        HandShape()
            .fill(color)
            .frame(width: size * width, height: size * (length + 0.06))
            .offset(y: -size * (length - 0.06) / 2)
            .rotationEffect(.degrees(angle))
    }
}

/// A tapered hand, wide at the centre, pointed at the tip.
private struct HandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.width))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - rect.width), control: CGPoint(x: rect.midX, y: rect.maxY + rect.width * 0.4))
        path.closeSubpath()
        return path
    }
}
