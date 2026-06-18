import SwiftUI

struct CitySearchDialog: View {
    var onSelect: (CityResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var vm = LocationViewModel.shared
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Text("Search City")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("City name…", text: Bindable(vm).searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($focused)
                if vm.isSearching {
                    ProgressView().controlSize(.small)
                } else if !vm.searchQuery.isEmpty {
                    Button { vm.clearSearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Results
            if vm.searchResults.isEmpty {
                Spacer()
                Text(vm.searchQuery.isEmpty ? "Start typing to search 48,000+ cities" : "No cities found")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(vm.searchResults) { result in
                            Button {
                                onSelect(result)
                                vm.clearSearch()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(hex: "#0D9488"))
                                        .frame(width: 32, height: 32)
                                        .background(Color(hex: "#0D9488").opacity(0.1),
                                                    in: RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text(result.city)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#0D9488").opacity(0.6))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 11)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if result.id != vm.searchResults.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(width: 400, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { focused = true }
        .onDisappear { vm.clearSearch() }
    }
}
