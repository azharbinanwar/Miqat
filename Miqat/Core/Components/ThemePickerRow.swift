import SwiftUI

struct ThemePickerRow: View {
    @Binding var selection: AppTheme
    let accentColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 14))
                .foregroundStyle(AppColor.accentGold)
                .frame(width: 28, height: 28)
                .background(AppColor.accentGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text("Theme").font(.system(size: 13, weight: .medium))
                Text("App colour scheme").font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeCard(theme)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        let selected = selection == theme
        return Button { selection = theme } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cardBackground(theme))
                        .frame(width: 64, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selected ? accentColor : Color.secondary.opacity(0.2),
                                        lineWidth: selected ? 2 : 1)
                        )
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(sidebarColor(theme))
                            .frame(width: 16, height: 28)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(contentColor(theme))
                            .frame(width: 32, height: 28)
                    }
                }
                Text(theme.rawValue.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selected ? accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func cardBackground(_ theme: AppTheme) -> AnyShapeStyle {
        switch theme {
        case .dark:   return AnyShapeStyle(Color.black)
        case .light:  return AnyShapeStyle(Color.white)
        case .system: return AnyShapeStyle(LinearGradient(
            stops: [.init(color: .black, location: 0.499), .init(color: .white, location: 0.501)],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private func sidebarColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .dark:   return .white.opacity(0.15)
        case .light:  return .black.opacity(0.08)
        case .system: return .gray.opacity(0.4)
        }
    }

    private func contentColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .dark:   return .white.opacity(0.07)
        case .light:  return .black.opacity(0.04)
        case .system: return .gray.opacity(0.2)
        }
    }
}
