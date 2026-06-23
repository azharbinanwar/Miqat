import SwiftUI

struct OnboardingView: View {
    @State private var vm = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            vm.pageGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.55), value: vm.page)

            VStack(spacing: 0) {
                pageContent
                    .id(vm.page)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                Spacer(minLength: 0)
                bottomBar
            }
        }
        .frame(width: 480, height: 580)
        .sheet(isPresented: $vm.showSearch) {
            CitySearchDialog { result in
                vm.locationVM.addFromSearch(result)
                vm.showSearch = false
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch vm.page {
        case 0: WelcomePage()
        case 1: MadhabPage(vm: vm)
        case 2: NotificationsPage(vm: vm)
        case 3: LocationPage(vm: vm)
        case 4: LaunchAtLoginPage(vm: vm)
        default: EmptyView()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 7) {
                ForEach(0..<5) { i in
                    Capsule()
                        .fill(.white.opacity(i == vm.page ? 1 : 0.3))
                        .frame(width: i == vm.page ? 22 : 7, height: 7)
                        .animation(.spring(duration: 0.35), value: vm.page)
                }
            }

            if vm.isNotifPage {
                Button {
                    Task { await vm.skipNotifications() }
                } label: {
                    Text("Not Now")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            if vm.isLoginPage {
                Button { onComplete() } label: {
                    Text("Not Now")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            Button {
                Task {
                    if vm.isLoginPage {
                        await vm.requestLoginItem()
                        onComplete()
                    } else {
                        await vm.advance()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isBlocked {
                        ProgressView().controlSize(.small).tint(vm.ctaTextColor)
                        Text("Detecting location…").font(.system(size: 15, weight: .bold))
                    } else {
                        Text(vm.ctaLabel).font(.system(size: 15, weight: .bold))
                        Image(systemName: vm.ctaIcon).font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(vm.ctaTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white.opacity(vm.isBlocked ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(vm.isBlocked)
            .padding(.horizontal, 36)
        }
        .padding(.bottom, 36)
    }
}
