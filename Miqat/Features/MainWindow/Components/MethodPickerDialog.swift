import SwiftUI

struct MethodPickerDialog: View {
    @Binding var selection: CalculationMethod
    var onSelect: (CalculationMethod) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var searchQuery: String = ""

    private var filteredMethods: [CalculationMethod] {
        if searchQuery.isEmpty { return CalculationMethod.allCases }
        let q = searchQuery.lowercased()
        return CalculationMethod.allCases.filter { m in
            m.displayName.lowercased().contains(q) ||
            m.region.lowercased().contains(q) ||
            m.angleDescription.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
            methodList
        }
        .frame(width: 420, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { focused = true }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Calculation Method")
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
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search method, region or angle…", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($focused)
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
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
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - List

    private var methodList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if filteredMethods.isEmpty {
                    Spacer(minLength: 40)
                    Text(searchQuery.isEmpty ? "" : "No methods found")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ForEach(Array(filteredMethods.enumerated()), id: \.element.id) { index, method in
                        methodRow(method)
                        if index < filteredMethods.count - 1 {
                            Divider().padding(.leading, 66).opacity(0.3)
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Row

    private func methodRow(_ method: CalculationMethod) -> some View {
        let isSelected = selection.id == method.id

        return Button {
            selection = method
            onSelect(method)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(method.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(method.region)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AccentColor.current)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
