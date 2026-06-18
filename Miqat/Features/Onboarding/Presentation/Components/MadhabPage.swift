import SwiftUI

struct MadhabPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingIcon(systemName: "clock.fill")
                .padding(.top, 52)

            Text("Your Madhab")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text("Affects the Asr prayer time calculation.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)

            HStack(spacing: 14) {
                madhabCard(.hanafi)
                madhabCard(.shafi)
            }
            .padding(.top, 28)
            .padding(.horizontal, 36)
        }
    }

    private func madhabCard(_ madhab: Madhab) -> some View {
        let selected = vm.selectedMadhab == madhab
        return Button {
            withAnimation(.spring(duration: 0.2)) { vm.selectedMadhab = madhab }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .animation(.spring(duration: 0.2), value: selected)

                Text(madhab.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text(madhab == .hanafi ? "Shadow length 2× object" : "Shadow length 1× object")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text("Asr time").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white.opacity(0.1), in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .background(.white.opacity(selected ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(selected ? 0.55 : 0.12), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
