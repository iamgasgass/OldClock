import SwiftUI
import UIKit

// OldOS drawing helpers needed by the Clock screens that OldSafari never used.
// `OldOSKit.swift` is shared verbatim with OldSafari; additions live here.

// MARK: - Borders

extension View {
    func oldOSBorder(width: CGFloat = 1, edges: [Edge], gradient: LinearGradient) -> some View {
        overlay(OldOSEdgeBorder(width: width, edges: edges).fill(gradient))
    }

    /// OldOS `animationsDisabled()`: the keypad keys light up instantly.
    func oldOSAnimationsDisabled() -> some View {
        transaction { $0.animation = nil }
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

// MARK: - Shapes

/// OldOS `RoundedCorners`: a rectangle with an independent radius per corner
/// (used by the two halves of the iOS 6 segmented control).
struct OldOSRoundedCorners: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height
        let tr = min(min(self.tr, h / 2), w / 2)
        let tl = min(min(self.tl, h / 2), w / 2)
        let bl = min(min(self.bl, h / 2), w / 2)
        let br = min(min(self.br, h / 2), w / 2)

        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

// MARK: - Misc

extension Color {
    /// PureSwiftUI `cgLightGray` (white 0.667), used for the footers.
    static let oldOSLightGray = Color(white: 0.667)
}

extension Collection {
    subscript(optional index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

enum OldClockHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func press() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

extension OldOSScreen {
    static var keyWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }

    /// The topmost presented controller, used to show system sheets / alerts.
    static var topController: UIViewController? {
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
