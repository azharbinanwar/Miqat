import SwiftUI

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            OnboardingIcon(assetName: "MiqatLogo")
                .padding(.top, 52)

            Text("Miqat")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text("Never miss a prayer.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 14) {
                OnboardingBullet(icon: "menubar.rectangle",      text: "Always-visible menu bar countdown")
                OnboardingBullet(icon: "rectangle.inset.filled", text: "Beautiful floating desktop widget")
                OnboardingBullet(icon: "bell.badge.fill",        text: "Smart reminders before each prayer")
            }
            .padding(.top, 34)
            .padding(.horizontal, 52)
        }
    }
}
