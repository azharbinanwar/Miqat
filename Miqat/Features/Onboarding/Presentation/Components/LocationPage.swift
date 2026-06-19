import SwiftUI

struct LocationPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingIcon(systemName: vm.gpsState == .denied ? "location.slash.fill" : "location.fill")
                .padding(.top, 52)

            Text(vm.gpsState == .denied ? "Location Denied" : "Where are you?")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)

            Text(vm.gpsState == .denied
                 ? "Open System Settings or pick a city below."
                 : "Prayer times are calculated locally — never sent anywhere.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 48)

            VStack(spacing: 10) {
                if vm.gpsState == .denied {
                    openSettingsButton
                } else {
                    gpsCard
                }

                let searchCity     = vm.locationVM.activeLocation
                let searchSelected = searchCity?.icon == "mappin.circle.fill"
                locationCard(
                    icon: "magnifyingglass",
                    label: searchSelected ? (searchCity?.label ?? "Search for a City") : "Search for a City",
                    subtitle: searchSelected ? (searchCity?.city ?? "") : "Tap to search for your city",
                    isSelected: searchSelected
                ) {
                    vm.locationVM.cancelFetch()
                    vm.showSearch = true
                }

                VStack(spacing: 6) {
                    Text("or pick a city")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 8) {
                        ForEach(Location.presets) { preset in
                            let isActive = vm.gpsState != .detecting
                                        && vm.locationVM.activeLocation?.label == preset.label
                            Button {
                                vm.locationVM.cancelFetch()
                                vm.locationVM.addFromSearch(
                                    CityResult(name: preset.label, city: preset.city,
                                               coordinate: preset.coordinate),
                                    label: preset.label
                                )
                            } label: {
                                HStack(spacing: 5) {
                                    if isActive {
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                                    }
                                    Text(preset.label).font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(.white.opacity(isActive ? 1 : 0.85))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white.opacity(isActive ? 0.25 : 0.12), in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(isActive ? 0.5 : 0.2),
                                                          lineWidth: isActive ? 1.5 : 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.top, 24)
            .padding(.horizontal, 36)
        }
        .onAppear {
            if vm.locationVM.fetchState == .idle {
                vm.locationVM.startGPS()
            }
        }
    }

    // MARK: - Private

    private var openSettingsButton: some View {
        Button {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "gear")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open System Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Privacy & Security → Location Services")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var gpsCard: some View {
        let isSelected = vm.gpsState == .done && vm.locationVM.activeLocation?.icon == "location.fill"
        let subtitle: String = {
            if vm.gpsState == .detecting { return "Detecting..." }
            if vm.gpsState == .failed    { return "Could not detect — tap to retry" }
            if isSelected { return vm.locationVM.gpsStatus.isEmpty ? vm.locationVM.activeCityName : vm.locationVM.gpsStatus }
            return "Recommended  ·  requires permission"
        }()
        return locationCard(icon: "location.fill", label: "Use Current Location",
                            subtitle: subtitle, isSelected: isSelected) {
            guard vm.gpsState != .detecting else { return }
            vm.locationVM.retryGPS()
        }
    }

    private func locationCard(icon: String, label: String, subtitle: String,
                               isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? AppColor.teal : .white.opacity(0.75))
                    .frame(width: 38, height: 38)
                    .background(isSelected ? .white : .white.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                if vm.gpsState == .detecting && icon == "location.fill" {
                    ProgressView().controlSize(.small).tint(.white)
                } else if vm.gpsState == .failed && icon == "location.fill" {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(isSelected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(isSelected ? 0.35 : 0.1), lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}
