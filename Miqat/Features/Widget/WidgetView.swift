import SwiftUI

struct WidgetView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.57, green: 0.25, blue: 0.05),
                                 Color(red: 0.85, green: 0.47, blue: 0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)

            VStack(spacing: 16) {
                Text("🕌 Miqat")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("42:18")
                    .font(.system(size: 56, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)

                Text("until Asr")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: 380, height: 580)
    }
}
