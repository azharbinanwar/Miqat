import SwiftUI

struct NotificationsPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingIcon(systemName: vm.notifRequested ? "bell.badge.fill" : "bell.fill")
                .padding(.top, 52)

            Text("Stay on Time")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text("Get reminded before each prayer so you never miss one.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 48)

            VStack(alignment: .leading, spacing: 14) {
                OnboardingBullet(icon: "clock.badge",      text: "15 minutes before each prayer")
                OnboardingBullet(icon: "bell.fill",        text: "Alert at prayer time")
                OnboardingBullet(icon: "checkmark.circle", text: "Mark as prayed from the notification")
            }
            .padding(.top, 32)
            .padding(.horizontal, 52)

            if vm.notifRequested {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Notifications enabled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 28)
            }
        }
    }
}
