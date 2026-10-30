import SwiftUI

/// OldOS `toggle` (Common.swift): the iOS 6 ON / OFF switch, 104 × 30, with
/// the blue ON track, the grey OFF track and the white knob you can drag
/// or tap. The original kept its own state; this one drives a binding.
struct ClockToggle: View {
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)? = nil

    private static let travel: CGFloat = 53.6666666667

    @State private var offset: CGFloat = 0
    @State private var showOverlay = false
    @State private var dragStart: CGFloat?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(52, 123, 245), 0.0),
                    OldOSStop(.oldOS(53, 126, 247), 0.50),
                    OldOSStop(.oldOS(91, 154, 247), 0.47),
                    OldOSStop(.oldOS(101, 161, 249), 1.0)
                ]))
                .modifier(ToggleInnerShadow(color: Color.oldOS(1, 19, 50).opacity(0.32), radius: 0.3, side: .leading))
                .overlay(
                    LinearGradient(oldOS: [
                        OldOSStop(.oldOS(232, 232, 232), 0.0),
                        OldOSStop(.oldOS(235, 235, 235), 0.50),
                        OldOSStop(.oldOS(247, 247, 247), 0.50),
                        OldOSStop(.oldOS(251, 251, 251), 1.0)
                    ])
                    .modifier(ToggleInnerShadow(color: Color.black.opacity(0.43), radius: 0.3, side: .trailing))
                    .offset(x: 100 + offset)
                )
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray, lineWidth: 0.25)
                )

            HStack {
                Spacer()
                Text("OFF")
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.oldOS(125, 125, 125))
                    .padding(.trailing, 12)
                    .shadow(color: Color.white.opacity(0.84), radius: 2, x: 0, y: 2)
                    .offset(x: Self.travel + offset)
            }
            .clipped()

            HStack {
                Text("ON")
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.white)
                    .padding(.leading, 14)
                    .shadow(color: Color.black.opacity(0.45), radius: 0.34, x: 0, y: -1.25)
                ZStack {
                    Rectangle()
                        .fill(Color.oldOS(101, 41, 1).opacity(0.6))
                        .cornerRadius(4.25)
                        .padding(.leading, 4)
                        .offset(x: -1)
                        .frame(maxHeight: 30)
                        .clipped()
                        .blur(radius: 0.5)
                        .opacity(offset > -52 ? 0.95 : 0)
                    Rectangle()
                        .fill(Color.oldOS(101, 41, 1).opacity(0.6))
                        .cornerRadius(4.25)
                        .padding(.leading, 4)
                        .offset(x: 1)
                        .frame(maxHeight: 30)
                        .clipped()
                        .blur(radius: 0.5)
                        .opacity(offset < -1 ? 0.95 : 0)
                    Rectangle()
                        .fill(LinearGradient(oldOS: [.oldOS(208, 208, 208), .oldOS(254, 254, 254)]))
                        .modifier(ToggleTopHighlight(color: .white, radius: 0.15))
                        .cornerRadius(4)
                        .overlay(Color.gray.opacity(showOverlay ? 0.3 : 0))
                        .oldOSAddBorder(LinearGradient(oldOS: [.oldOS(136, 135, 135), .oldOS(183, 182, 182)]), width: 0.5, cornerRadius: 4)
                        .padding(.leading, 4)
                }
            }
            .offset(x: offset)
            .clipped()
        }
        .frame(width: 104, height: 30)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStart == nil { dragStart = offset }
                    showOverlay = true
                    offset = min(max((dragStart ?? 0) + value.translation.width, -Self.travel), 0)
                }
                .onEnded { value in
                    showOverlay = false
                    let moved = abs(value.translation.width) > 3
                    dragStart = nil
                    // A tap flips the switch; a drag settles on the nearer side.
                    let newValue = moved ? offset > -Self.travel / 2 : !isOn
                    set(newValue)
                }
        )
        .onAppear {
            offset = isOn ? 0 : -Self.travel
        }
        .onChange(of: isOn) { value in
            guard dragStart == nil else { return }
            withAnimation(.linear(duration: 0.1)) {
                offset = value ? 0 : -Self.travel
            }
        }
    }

    private func set(_ value: Bool) {
        OldClockHaptics.tap()
        withAnimation(.linear(duration: 0.1)) {
            offset = value ? 0 : -Self.travel
        }
        if value != isOn {
            isOn = value
            onChange?(value)
        }
    }
}

/// OldOS `InnerShadow_Toggle` / `InnerShadow_Toggle_Secondary`.
private struct ToggleInnerShadow: ViewModifier {
    var color: Color
    var radius: CGFloat
    var side: HorizontalEdge

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
                        .frame(height: radius * minSide(geo)),
                    alignment: .top
                )
                .overlay(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: side == .leading ? .leading : .trailing, endPoint: side == .leading ? .trailing : .leading)
                        .frame(width: 20 * radius, height: minSide(geo))
                        .opacity(0.3),
                    alignment: side == .leading ? .leading : .trailing
                )
                .overlay(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .bottom, endPoint: .top)
                        .frame(height: radius * minSide(geo) * 0.3)
                        .opacity(0.25),
                    alignment: .bottom
                )
        }
    }

    private func minSide(_ geo: GeometryProxy) -> CGFloat {
        3 * min(geo.size.width, geo.size.height) / 2
    }
}

/// OldOS `InnerShadow_Toggle_Top`.
private struct ToggleTopHighlight: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [color, color.opacity(0), .clear]), startPoint: .top, endPoint: .bottom)
                        .frame(height: radius * 3 * min(geo.size.width, geo.size.height) / 2),
                    alignment: .top
                )
        }
    }
}
