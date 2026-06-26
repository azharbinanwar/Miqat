import SwiftUI

struct PulsingDot: View {
    var color: Color = .green
    var size: CGFloat = 10

    @State private var ripple = false

    var body: some View {
        ZStack {
            // Ripple ring 1
            Circle()
                .stroke(color.opacity(ripple ? 0 : 0.6), lineWidth: 2)
                .frame(width: size * (ripple ? 3.5 : 1), height: size * (ripple ? 3.5 : 1))
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: ripple)

            // Ripple ring 2 (delayed)
            Circle()
                .stroke(color.opacity(ripple ? 0 : 0.3), lineWidth: 1.5)
                .frame(width: size * (ripple ? 2.5 : 1), height: size * (ripple ? 2.5 : 1))
                .animation(.easeOut(duration: 1.4).delay(0.4).repeatForever(autoreverses: false), value: ripple)

            // Solid center dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .frame(width: size * 4, height: size * 4)
        .onAppear { ripple = true }
    }
}
