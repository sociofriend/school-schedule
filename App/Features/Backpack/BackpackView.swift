import SwiftUI

/// Today card: backpack progress, opens the packing checklist.
struct BackpackCard: View {
    let viewModel: BackpackViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    ProgressRing(progress: viewModel.progress, lineWidth: 6, tint: .orange)
                    Text(viewModel.isComplete ? "✅" : "🎒").font(.title2)
                        .ambient(viewModel.isComplete ? .pulse : .sway)
                        .themedPop(trigger: viewModel.isComplete)
                }
                .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Պայուսակ").font(.headline)
                    EmojiText(viewModel.isComplete ? "Պատրաստ է, ոչինչ չես մոռացել 👏"
                         : "Հավաքված է՝ \(viewModel.packedCount)/\(viewModel.items.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.headline).foregroundStyle(.tertiary)
            }
            .card(tint: .orange)
            .contentShape(.rect)
        }
        .buttonStyle(BouncyButtonStyle())
        .foregroundStyle(.primary)
        .accessibilityHint("Բացել պայուսակի ցուցակը")
    }
}

/// Packing checklist: big rows, subject icons, the kid's own items and quick suggestions.
struct BackpackSheet: View {
    @Bindable var viewModel: BackpackViewModel
    @Environment(\.dismiss) private var dismiss

    private static let suggestions = ["Օրագիր", "Գրիչ և մատիտ", "Ջրի շիշ", "Մարզահագուստ", "Նախաճաշ", "Բանալի"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.items) { item in
                        Button { withAnimation(.spring) { viewModel.toggle(item) } } label: {
                            HStack(spacing: 14) {
                                if let subject = item.subject {
                                    SubjectIcon(subject: subject, size: 40)
                                } else {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.orange.gradient, in: .rect(cornerRadius: 12, style: .continuous))
                                }
                                Text(item.subject.map { "\($0)՝ գիրք և տետր" } ?? item.title)
                                    .font(.body.weight(.medium))
                                    .strikethrough(item.isPacked, color: .secondary)
                                    .foregroundStyle(item.isPacked ? .secondary : .primary)
                                Spacer(minLength: 0)
                                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(item.isPacked ? Color.green : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                                    .themedDoneEffect(value: item.isPacked)
                            }
                            .frame(minHeight: 48)
                            .contentShape(.rect)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .sensoryFeedback(.selection, trigger: item.isPacked)
                        .accessibilityValue(item.isPacked ? "Դրված է" : "Դեռ չէ")
                        .swipeActions {
                            if item.subject == nil {
                                Button("Ջնջել", role: .destructive) { viewModel.removeExtra(item) }
                            }
                        }
                    }
                } header: {
                    Text(viewModel.day.armenianLongDay)
                }

                Section("Իմ իրերը") {
                    HStack {
                        TextField("Էլ ինչ վերցնել…", text: $viewModel.newExtra)
                            .submitLabel(.done)
                            .onSubmit(viewModel.addExtra)
                        Button("Ավելացնել", systemImage: "plus.circle.fill", action: viewModel.addExtra)
                            .labelStyle(.iconOnly).font(.title2)
                            .disabled(viewModel.newExtra.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    let titles = Set(viewModel.items.map(\.title))
                    let left = Self.suggestions.filter { !titles.contains($0) }
                    if !left.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(left, id: \.self) { title in
                                    Button("+ \(title)") {
                                        viewModel.newExtra = title
                                        viewModel.addExtra()
                                    }
                                    .buttonStyle(.bordered).buttonBorderShape(.capsule).tint(.orange)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .overlay { ConfettiView(trigger: viewModel.celebrations).ignoresSafeArea() }
            .navigationTitle("🎒 Պայուսակ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Պատրաստ է") { dismiss() }.fontWeight(.semibold) }
        }
        .presentationDetents([.medium, .large])
    }
}
