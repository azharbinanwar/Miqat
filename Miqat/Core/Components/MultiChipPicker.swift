import SwiftUI

/// Horizontal chip bar where multiple options can be toggled independently.
/// Generic over Int options — use `suffix` for units like "m", "h", etc.
struct MultiChipPicker: View {
    let options: [Int]
    @Binding var selected: [Int]
    let accentColor: Color
    var suffix: String = ""

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isOn = selected.contains(option)
                Button {
                    withAnimation(.spring(duration: 0.15)) {
                        if isOn {
                            selected.removeAll { $0 == option }
                        } else {
                            selected.append(option)
                            selected.sort(by: >)
                        }
                    }
                } label: {
                    Text("\(option)\(suffix)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isOn ? .white : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(
                            isOn ? accentColor : Color(NSColor.controlBackgroundColor),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
