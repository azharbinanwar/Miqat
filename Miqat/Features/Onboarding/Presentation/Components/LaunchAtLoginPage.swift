import SwiftUI

struct LaunchAtLoginPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingIcon(systemName: vm.loginItemRequested ? "checkmark.circle.fill" : "power")
                .padding(.top, 52)

            Text("Start with macOS")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text("Miqat stays in your menu bar, always ready with your next prayer time.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 48)

            VStack(alignment: .leading, spacing: 14) {
                OnboardingBullet(icon: "menubar.rectangle", text: "Menu bar always shows next prayer")
                OnboardingBullet(icon: "macwindow",         text: "Floating panel on your desktop")
                OnboardingBullet(icon: "bell.fill",         text: "Notifications fire at prayer time")
            }
            .padding(.top, 32)
            .padding(.horizontal, 52)

            if vm.loginItemRequested {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Launch at login enabled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 28)
            } else if vm.loginItemNeedsApproval {
                VStack(spacing: 10) {
                    Text("Enable in System Settings → General → Login Items")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
                        )
                    } label: {
                        Text("Open System Settings →")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)
            }
        }
    }
}
