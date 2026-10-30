import SwiftUI
import UIKit

/// One wheel of the picker.
struct ClockWheelColumn {
    var rows: [String]
    var width: CGFloat
    /// Text alignment inside the wheel.
    var alignment: NSTextAlignment = .right
    /// Rows repeat endlessly (hours / minutes of the iOS 6 time picker).
    var loops = false
    /// The fixed unit drawn on the selection bar ("hours", "mins").
    var unit: String? = nil
}

/// The iOS 6 `UIDatePicker` / `UIPickerView`: white cylinders in the dark
/// metal frame, shaded top and bottom, with the glass selection bar. The
/// wheels are a real `UIPickerView` (iOS physics), the iOS 6 artwork is
/// drawn around them.
struct ClockWheelPicker: View {
    let columns: [ClockWheelColumn]
    @Binding var selection: [Int]
    var onChange: (() -> Void)? = nil

    static let height: CGFloat = 216

    var body: some View {
        GeometryReader { geometry in
            let total = columns.reduce(0) { $0 + $1.width } + CGFloat(max(columns.count - 1, 0)) * 4
            let scale = min(1, (geometry.size.width - 24) / max(total, 1))
            let widths = columns.map { $0.width * scale }
            let wheelsWidth = widths.reduce(0, +) + CGFloat(max(columns.count - 1, 0)) * 4
            ZStack {
                // Dark metal frame (UIPickerView background).
                LinearGradient(oldOS: [
                    OldOSStop(.oldOS(54, 56, 66), 0),
                    OldOSStop(.oldOS(33, 35, 44), 0.5),
                    OldOSStop(.oldOS(21, 22, 28), 0.5),
                    OldOSStop(.oldOS(38, 40, 48), 1)
                ])

                // The white cylinders, separated by the dark gaps.
                HStack(spacing: 4) {
                    ForEach(Array(widths.enumerated()), id: \.offset) { _, width in
                        LinearGradient(oldOS: [
                            OldOSStop(.oldOS(150, 150, 154), 0),
                            OldOSStop(.oldOS(236, 236, 238), 0.16),
                            OldOSStop(.white, 0.5),
                            OldOSStop(.oldOS(236, 236, 238), 0.84),
                            OldOSStop(.oldOS(150, 150, 154), 1)
                        ])
                        .frame(width: width)
                        .overlay(
                            HStack {
                                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 1)
                                Spacer()
                                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 1)
                            }
                        )
                    }
                }
                .frame(width: wheelsWidth)
                .padding(.vertical, 10)

                ClockPickerRepresentable(columns: columns, widths: widths, selection: $selection, onChange: onChange)
                    .frame(width: wheelsWidth)
                    .padding(.vertical, 10)

                // Cylinder shading over the rows.
                VStack(spacing: 0) {
                    LinearGradient(oldOS: [Color.black.opacity(0.55), Color.black.opacity(0)])
                        .frame(height: 70)
                    Spacer()
                    LinearGradient(oldOS: [Color.black.opacity(0), Color.black.opacity(0.55)])
                        .frame(height: 70)
                }
                .frame(width: wheelsWidth)
                .padding(.vertical, 10)
                .allowsHitTesting(false)

                // The glass selection bar, with the units.
                ZStack {
                    LinearGradient(oldOS: [
                        OldOSStop(Color.oldOS(220, 226, 240).opacity(0.55), 0),
                        OldOSStop(Color.oldOS(160, 172, 200).opacity(0.45), 0.5),
                        OldOSStop(Color.oldOS(120, 134, 170).opacity(0.40), 0.5),
                        OldOSStop(Color.oldOS(140, 154, 190).opacity(0.45), 1)
                    ])
                    .overlay(
                        VStack {
                            Rectangle().fill(Color.oldOS(90, 100, 130).opacity(0.9)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color.oldOS(70, 78, 104).opacity(0.9)).frame(height: 1)
                        }
                    )
                    HStack(spacing: 4) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                            HStack {
                                Spacer()
                                if let unit = column.unit {
                                    Text(unit)
                                        .font(OldOSFont.bold(17))
                                        .foregroundColor(.black)
                                        .shadow(color: Color.white.opacity(0.7), radius: 0, x: 0, y: 1)
                                        .padding(.trailing, 10)
                                }
                            }
                            .frame(width: widths[index])
                        }
                    }
                }
                .frame(width: wheelsWidth + 10, height: 46)
                .shadow(color: Color.black.opacity(0.35), radius: 1.5, x: 0, y: 1.5)
                .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: Self.height)
    }
}

/// The real wheels (`UIPickerView`) with iOS 6 rows and no modern
/// selection highlight.
struct ClockPickerRepresentable: UIViewRepresentable {
    let columns: [ClockWheelColumn]
    let widths: [CGFloat]
    @Binding var selection: [Int]
    var onChange: (() -> Void)?

    /// Rows of a looping wheel are repeated this many times.
    static let loopCycles = 200

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ClassicPickerView {
        let picker = ClassicPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear
        DispatchQueue.main.async {
            context.coordinator.select(selection, in: picker, animated: false)
        }
        return picker
    }

    func updateUIView(_ picker: ClassicPickerView, context: Context) {
        let coordinator = context.coordinator
        let needsReload = coordinator.parent.widths != widths || coordinator.parent.columns.map(\.rows) != columns.map(\.rows)
        coordinator.parent = self
        if needsReload { picker.reloadAllComponents() }
        coordinator.select(selection, in: picker, animated: true)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: ClockPickerRepresentable

        init(_ parent: ClockPickerRepresentable) {
            self.parent = parent
        }

        private func count(_ component: Int) -> Int {
            let column = parent.columns[component]
            return column.loops ? column.rows.count * ClockPickerRepresentable.loopCycles : column.rows.count
        }

        /// Selects the values without fighting a wheel that is moving.
        func select(_ values: [Int], in picker: UIPickerView, animated: Bool) {
            for (component, value) in values.enumerated() where component < parent.columns.count {
                let column = parent.columns[component]
                guard !column.rows.isEmpty else { continue }
                let current = picker.selectedRow(inComponent: component)
                let currentValue = column.loops ? current % column.rows.count : current
                if currentValue == value, current >= 0 { continue }
                var row = value
                if column.loops {
                    let middle = (ClockPickerRepresentable.loopCycles / 2) * column.rows.count
                    row = middle + value
                }
                picker.selectRow(row, inComponent: component, animated: animated)
            }
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            parent.columns.count
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            count(component)
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            parent.widths[component]
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            44
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let column = parent.columns[component]
            let label = (view as? UILabel) ?? UILabel()
            label.text = column.rows[row % column.rows.count]
            label.font = OldOSFont.uiBold(24)
            label.textColor = .black
            label.textAlignment = column.alignment
            label.backgroundColor = .clear
            // Room for the fixed unit on the right of the number.
            let trailing: CGFloat = column.unit == nil ? 18 : 64
            let leading: CGFloat = column.alignment == .left ? 18 : 0
            let container = UIView(frame: CGRect(x: 0, y: 0, width: parent.widths[component], height: 44))
            label.frame = container.bounds.inset(by: UIEdgeInsets(top: 0, left: leading, bottom: 0, right: trailing))
            container.addSubview(label)
            return container
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let column = parent.columns[component]
            let value = column.loops ? row % column.rows.count : row
            var values = parent.selection
            while values.count < parent.columns.count { values.append(0) }
            values[component] = value
            if column.loops {
                // Re-centre a looping wheel so it never runs out of rows.
                let middle = (ClockPickerRepresentable.loopCycles / 2) * column.rows.count + value
                if abs(row - middle) > column.rows.count * 20 {
                    pickerView.selectRow(middle, inComponent: component, animated: false)
                }
            }
            parent.selection = values
            parent.onChange?()
        }
    }
}

/// `UIPickerView` without the iOS 14+ rounded grey selection highlight.
final class ClassicPickerView: UIPickerView {
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews where subview.bounds.height < 60 && !(subview is UITableView) {
            subview.backgroundColor = .clear
        }
    }
}
