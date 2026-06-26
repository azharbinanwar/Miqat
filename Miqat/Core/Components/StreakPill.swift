import SwiftUI

struct StreakPill: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppColor.softAmber)
            Text("\(days)d")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(7)
        .background(.white.opacity(0.12), in: Capsule())
    }
}
