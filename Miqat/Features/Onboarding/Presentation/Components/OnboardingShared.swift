import SwiftUI

struct OnboardingIcon: View {
    var systemName: String = ""
    var assetName : String = ""

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.12)).frame(width: 96, height: 96)
            Circle().fill(.white.opacity(0.08)).frame(width: 76, height: 76)
            if !assetName.isEmpty {
                Image(assetName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}

struct OnboardingBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }
}
