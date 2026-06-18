import SwiftUI

// MARK: - Container

struct OnboardingView: View {
    @State private var page          = 0
    @State private var selectedMadhab: Madhab = .hanafi
    @State private var animating     = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            pageGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.55), value: page)

            VStack(spacing: 0) {
                pageContent
                    .id(page)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer(minLength: 0)
                bottomBar
            }
        }
        .frame(width: 480, height: 580)
    }

    // MARK: Page routing

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: welcomePage
        case 1: locationPage
        case 2: madhabPage
        default: EmptyView()
        }
    }

    // MARK: Page 1 — Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            iconCircle(systemName: "moon.stars.fill")
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
                featureBullet(icon: "menubar.rectangle",      text: "Always-visible menu bar countdown")
                featureBullet(icon: "rectangle.inset.filled", text: "Beautiful floating desktop widget")
                featureBullet(icon: "bell.badge.fill",        text: "Smart reminders before each prayer")
            }
            .padding(.top, 34)
            .padding(.horizontal, 52)
        }
    }

    // MARK: Page 2 — Location

    private var locationPage: some View {
        VStack(spacing: 0) {
            iconCircle(systemName: "location.fill")
                .padding(.top, 52)

            Text("Where are you?")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text("Prayer times are calculated locally.\nYour location is never sent anywhere.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 52)

            VStack(spacing: 10) {
                locationCard(
                    icon: "location.fill",
                    label: "Use Current Location",
                    subtitle: "Recommended  ·  requires permission",
                    primary: true
                )
                locationCard(
                    icon: "magnifyingglass",
                    label: "Search for a City",
                    subtitle: "Enter your city manually",
                    primary: false
                )
            }
            .padding(.top, 28)
            .padding(.horizontal, 36)
        }
    }

    // MARK: Page 3 — Madhab

    private var madhabPage: some View {
        VStack(spacing: 0) {
            iconCircle(systemName: "clock.fill")
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

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 18) {
            HStack(spacing: 7) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(.white.opacity(i == page ? 1 : 0.3))
                        .frame(width: i == page ? 22 : 7, height: 7)
                        .animation(.spring(duration: 0.35), value: page)
                }
            }

            Button {
                withAnimation(.spring(duration: 0.4)) {
                    if page < 2 { page += 1 } else { onComplete() }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(page == 2 ? "Start Praying" : "Continue")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: page == 2 ? "checkmark" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(ctaTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 36)
        }
        .padding(.bottom, 36)
    }

    // MARK: Sub-components

    private func iconCircle(systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 96, height: 96)
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 76, height: 76)
            Image(systemName: systemName)
                .font(.system(size: 38))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private func featureBullet(icon: String, text: String) -> some View {
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

    private func locationCard(icon: String, label: String, subtitle: String, primary: Bool) -> some View {
        Button { advance() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(primary ? Color(hex: "#0D9488") : .white.opacity(0.75))
                    .frame(width: 38, height: 38)
                    .background(primary ? .white : .white.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(primary ? 0.15 : 0.08),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(primary ? 0.25 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func madhabCard(_ madhab: Madhab) -> some View {
        let selected = selectedMadhab == madhab
        return Button { withAnimation(.spring(duration: 0.2)) { selectedMadhab = madhab } } label: {
            VStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .animation(.spring(duration: 0.2), value: selected)

                Text(madhab.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text(madhab == .hanafi
                     ? "Shadow length 2× object"
                     : "Shadow length 1× object")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text("Asr time")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white.opacity(0.1), in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .background(.white.opacity(selected ? 0.2 : 0.08),
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(selected ? 0.55 : 0.12),
                            lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func advance() {
        withAnimation(.spring(duration: 0.4)) { page = min(page + 1, 2) }
    }

    private var pageGradient: LinearGradient {
        switch page {
        case 0:
            return LinearGradient(
                colors: [Color(hex: "#0F172A"), Color(hex: "#1E1B4B"), Color(hex: "#4C1D95")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case 1:
            return LinearGradient(
                colors: [Color(hex: "#0F766E"), Color(hex: "#0284C7")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "#78350F"), Color(hex: "#D97706")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var ctaTextColor: Color {
        switch page {
        case 0: return Color(hex: "#4C1D95")
        case 1: return Color(hex: "#0F766E")
        default: return Color(hex: "#78350F")
        }
    }
}
