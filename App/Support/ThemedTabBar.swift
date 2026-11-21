import SwiftUI

/// The app's main tabs.
enum AppTab: Hashable, CaseIterable {
    case today, calendar, tasks, notes, settings

    var title: String {
        switch self {
        case .today: "Այսօր"
        case .calendar: "Օրացույց"
        case .tasks: "Անելիքներ"
        case .notes: "Գրառումներ"
        case .settings: "Կարգավորումներ"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max"
        case .calendar: "calendar"
        case .tasks: "checklist"
        case .notes: "note.text"
        case .settings: "gearshape"
        }
    }
}

/// Bottom tab bar whose icons play the theme's selection animation; system tab items can't animate.
struct ThemedTabBar: View {
    @Binding var selection: AppTab
    var badges: [AppTab: Int] = [:]
    @State private var taps: [AppTab: Int] = [:]
    @Namespace private var highlight
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                button(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func button(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        let count = taps[tab, default: 0]
        return Button {
            taps[tab, default: 0] += 1
            withAnimation(theme.motion.spring) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .symbolVariant(isSelected ? .fill : .none)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 26)
                    .themedDoneEffect(value: count)
                    .themedPop(trigger: count)
                    .overlay(alignment: .topTrailing) { badge(badges[tab] ?? 0) }
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? theme.accent : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background {
                if isSelected {
                    Capsule()
                        .fill(theme.accent.opacity(0.14))
                        .padding(.horizontal, 4)
                        .matchedGeometryEffect(id: "selected", in: highlight)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private func badge(_ count: Int) -> some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .frame(minWidth: 17, minHeight: 17)
                .background(Color.red, in: .capsule)
                .offset(x: 12, y: -6)
        }
    }
}
