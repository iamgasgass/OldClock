import SwiftUI

/// iOS 6 World Clock: one black glass row per city with the analog face,
/// the city name and "Today" / "Yesterday" / "Tomorrow". Edit shows the red
/// minus and the reorder grabbers.
struct WorldClockView: View {
    @EnvironmentObject private var navigator: ClockNavigator
    @ObservedObject private var store = WorldClockStore.shared
    @State private var toDelete: String?
    @State private var draggingID: String?
    @State private var dragStartIndex = 0
    @State private var dragOffset: CGFloat = 0

    static let rowHeight: CGFloat = 90

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(store.cities) { city in
                        row(city, now: context.date)
                            .offset(y: draggingID == city.id ? dragOffset : 0)
                            .zIndex(draggingID == city.id ? 1 : 0)
                    }
                }
            }
            .scrollDisabled(draggingID != nil)
        }
        .background(
            LinearGradient(oldOS: [.oldOS(24, 24, 26), .oldOS(6, 6, 7)])
        )
        .onChange(of: navigator.editingWorldClock) { editing in
            if !editing { toDelete = nil }
        }
    }

    // MARK: Row

    private func row(_ city: WorldCity, now: Date) -> some View {
        let editing = navigator.editingWorldClock
        let deleting = editing && toDelete == city.id
        return ZStack {
            // Black glass row with the top highlight and the dark divider.
            LinearGradient(oldOS: [
                OldOSStop(.oldOS(66, 66, 70), 0),
                OldOSStop(.oldOS(40, 40, 43), 0.5),
                OldOSStop(.oldOS(28, 28, 30), 0.5),
                OldOSStop(.oldOS(20, 20, 22), 1)
            ])
            VStack(spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.black).frame(height: 1)
            }

            HStack(spacing: 0) {
                if editing {
                    Button {
                        withAnimation(.linear(duration: 0.15)) {
                            toDelete = toDelete == city.id ? nil : city.id
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

                AnalogClockFace(date: now, timeZone: city.timeZone, size: 72)
                    .padding(.leading, editing ? 0 : 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(OldOSFont.bold(22))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(Self.dayText(for: city, now: now))
                        .font(OldOSFont.regular(16))
                        .foregroundColor(.oldOS(160, 160, 166))
                        .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                        .lineLimit(1)
                }
                .padding(.leading, 14)

                Spacer(minLength: 6)

                if deleting {
                    OldOSRectangleButton(title: "Delete", type: .red) {
                        withAnimation {
                            toDelete = nil
                            store.remove(city)
                        }
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if editing {
                    Image("ReorderGrabber")
                        .padding(.horizontal, 14)
                        .frame(height: Self.rowHeight)
                        .contentShape(Rectangle())
                        .gesture(reorderGesture(city))
                        .transition(.opacity)
                }
            }
        }
        .frame(height: Self.rowHeight)
        .shadow(color: Color.black.opacity(draggingID == city.id ? 0.6 : 0), radius: 6, x: 0, y: 3)
    }

    /// "Today", "Yesterday" or "Tomorrow" in that city, compared with here.
    static func dayText(for city: WorldCity, now: Date) -> String {
        var there = Calendar(identifier: .gregorian)
        there.timeZone = city.timeZone
        let a = there.dateComponents([.year, .month, .day], from: now)
        let b = Calendar.current.dateComponents([.year, .month, .day], from: now)
        guard let dayThere = Calendar(identifier: .gregorian).date(from: a),
              let dayHere = Calendar(identifier: .gregorian).date(from: b) else { return "Today" }
        switch dayThere.compare(dayHere) {
        case .orderedAscending: return "Yesterday"
        case .orderedDescending: return "Tomorrow"
        case .orderedSame: return "Today"
        }
    }

    private func reorderGesture(_ city: WorldCity) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if draggingID != city.id {
                    draggingID = city.id
                    toDelete = nil
                    dragStartIndex = store.cities.firstIndex(of: city) ?? 0
                }
                let raw = Int((value.translation.height / Self.rowHeight).rounded())
                let target = min(max(dragStartIndex + raw, 0), store.cities.count - 1)
                if let current = store.cities.firstIndex(of: city), current != target {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        store.move(from: current, to: target)
                    }
                }
                dragOffset = value.translation.height - CGFloat(target - dragStartIndex) * Self.rowHeight
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    dragOffset = 0
                    draggingID = nil
                }
            }
    }
}
