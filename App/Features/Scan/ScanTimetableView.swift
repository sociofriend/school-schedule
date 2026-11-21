import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

/// Capture (camera, photo/screenshot, or PDF) → OCR → compare/review flow for the timetable.
struct ScanTimetableView: View {
    let store: DataStore
    @State private var viewModel = ScanViewModel()
    @State private var isCameraPresented = false
    @State private var isPDFPickerPresented = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showsManualEditor = false
    @State private var scannedToEdit: ParsedTimetable?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    private var existingEntries: [TimetableEntry] { store.timetable().entries }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Դասացուցակի ներմուծում")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Փակել") { dismiss() } }
                }
                .navigationDestination(isPresented: $showsManualEditor) {
                    TimetableEditorView(store: store) { dismiss() }.armenianBackButton()
                }
                .navigationDestination(item: $scannedToEdit) { scanned in
                    TimetableEditorView(store: store, scanned: scanned) { dismiss() }.armenianBackButton()
                }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            DocumentScannerView { images in Task { await viewModel.process(images) } }
                .ignoresSafeArea()
        }
        .fileImporter(isPresented: $isPDFPickerPresented, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                Task { await viewModel.processPDF(url: url) }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { await viewModel.processPhotoData([data]) }
                pickerItem = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            sourcePicker
        case .processing:
            ProgressView("Ճանաչում եմ…").frame(maxHeight: .infinity)
        case .review:
            if let result = viewModel.result {
                if existingEntries.isEmpty {
                    TimetableEditorView(store: store, scanned: result) { dismiss() }
                } else {
                    TimetableCompareView(
                        current: existingEntries,
                        incoming: result.entries,
                        onEditAndApply: { scannedToEdit = result },
                        onKeepCurrent: { dismiss() },
                        onPickAnother: { viewModel.reset() }
                    )
                }
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Չհաջողվեց", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                if !viewModel.recognizedText.isEmpty {
                    DisclosureGroup("Ինչ կարդացի նկարից") {
                        ScrollView {
                            Text(viewModel.recognizedText)
                                .font(.caption.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                Button("Կրկին փորձել") { viewModel.reset() }.buttonStyle(.borderedProminent).foregroundStyle(theme.onAccent)
                Button("Լրացնել ձեռքով") { showsManualEditor = true }
            }
        }
    }

    private var sourcePicker: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.viewfinder").font(.system(size: 60)).foregroundStyle(.tint)
            Text(existingEntries.isEmpty
                 ? "Լուսանկարիր դասացուցակը կամ ընտրիր screenshot / PDF ֆայլ, որտեղ երևում են օրերն ու ժամերը։"
                 : "Ընտրիր նկար, screenshot կամ PDF՝ ներկայիս դասացուցակի հետ համեմատելու և թարմացնելու համար։")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                if VNDocumentCameraViewController.isSupported {
                    Button {
                        isCameraPresented = true
                    } label: {
                        Label("Լուսանկարել տեսախցիկով", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(theme.onAccent)
                    .controlSize(.large)
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Ընտրել նկար / screenshot", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    isPDFPickerPresented = true
                } label: {
                    Label("Ընտրել PDF ֆայլ", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 4)

            Button("Լրացնել ձեռքով") { showsManualEditor = true }
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxHeight: .infinity)
    }
}

extension ParsedTimetable: Hashable {
    static func == (lhs: ParsedTimetable, rhs: ParsedTimetable) -> Bool {
        lhs.entries == rhs.entries && lhs.periods == rhs.periods
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(entries.count)
        for entry in entries {
            hasher.combine(entry.weekday)
            hasher.combine(entry.period)
            hasher.combine(entry.subject)
            hasher.combine(entry.room)
        }
    }
}

/// Side-by-side diff of the current timetable vs a scanned image/PDF timetable before applying changes.
private struct TimetableCompareView: View {
    let current: [TimetableEntry]
    let incoming: [TimetableEntry]
    let onEditAndApply: () -> Void
    let onKeepCurrent: () -> Void
    let onPickAnother: () -> Void

    @State private var onlyChanges = true
    @Environment(\.theme) private var theme

    private enum SlotDiff: Equatable {
        case same(String)
        case added(String)
        case removed(String)
        case changed(old: String, new: String)

        var isChange: Bool {
            if case .same = self { return false }
            return true
        }
    }

    private struct DayDiff: Identifiable {
        let weekday: Int
        let slots: [(period: Int, diff: SlotDiff)]
        var id: Int { weekday }
    }

    private var allDays: [DayDiff] {
        let currentByDay = Dictionary(grouping: current, by: \.weekday)
        let incomingByDay = Dictionary(grouping: incoming, by: \.weekday)
        return Weekday.schoolWeek.compactMap { weekday in
            let oldByPeriod = Dictionary((currentByDay[weekday] ?? []).map { ($0.period, $0.subject) }, uniquingKeysWith: { a, _ in a })
            let newByPeriod = Dictionary((incomingByDay[weekday] ?? []).map { ($0.period, $0.subject) }, uniquingKeysWith: { a, _ in a })
            let maxPeriod = max(oldByPeriod.keys.max() ?? 0, newByPeriod.keys.max() ?? 0)
            guard maxPeriod > 0 else { return nil }
            let slots: [(Int, SlotDiff)] = (1...maxPeriod).compactMap { period in
                let old = oldByPeriod[period]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let new = newByPeriod[period]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                switch (old.isEmpty, new.isEmpty) {
                case (true, true): return nil
                case (true, false): return (period, .added(new))
                case (false, true): return (period, .removed(old))
                case (false, false):
                    if old.caseInsensitiveCompare(new) == .orderedSame {
                        return (period, .same(new))
                    }
                    return (period, .changed(old: old, new: new))
                }
            }
            return slots.isEmpty ? nil : DayDiff(weekday: weekday, slots: slots)
        }
    }

    private var totalChanges: Int {
        allDays.reduce(0) { $0 + $1.slots.filter(\.diff.isChange).count }
    }

    private var visibleDays: [DayDiff] {
        guard onlyChanges else { return allDays }
        return allDays.compactMap { day in
            let changed = day.slots.filter(\.diff.isChange)
            return changed.isEmpty ? nil : DayDiff(weekday: day.weekday, slots: changed)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if totalChanges == 0 {
                        Label("Տարբերություններ չկան", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("Ներկայիս դասացուցակը համընկնում է նկարի/PDF-ի հետ։")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Գտնվել է \(totalChanges) փոփոխություն", systemImage: "arrow.left.arrow.right.circle.fill")
                            .font(.headline)
                            .foregroundStyle(theme.accent)
                        HStack(spacing: 12) {
                            legendChip("+", title: "Ավելացված", color: .green)
                            legendChip("−", title: "Հեռացված", color: .red)
                            legendChip("↻", title: "Փոխված", color: .orange)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)

                if totalChanges > 0 {
                    Picker("Ցուցադրում", selection: $onlyChanges) {
                        Text("Միայն փոփոխությունները").tag(true)
                        Text("Բոլոր դասերը").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }

            ForEach(visibleDays) { day in
                Section(Weekday.name(day.weekday)) {
                    ForEach(day.slots, id: \.period) { slot in
                        slotRow(period: slot.period, diff: slot.diff)
                    }
                }
            }

            Section {
                Button {
                    onEditAndApply()
                } label: {
                    Label("Խմբագրել և կիրառել նորը", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(theme.onAccent)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                Button("Ընտրել այլ նկար կամ PDF", action: onPickAnother)
                Button("Թողնել ներկայիսը", role: .cancel, action: onKeepCurrent)
            }
        }
        .navigationTitle("Համեմատություն")
    }

    private func legendChip(_ badge: String, title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(badge)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(title).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func slotRow(period: Int, diff: SlotDiff) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(period).")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .trailing)

            switch diff {
            case .same(let subject):
                Text(subject).foregroundStyle(.secondary)
            case .added(let subject):
                Text("+").fontWeight(.bold).foregroundStyle(.green)
                Text(subject).fontWeight(.semibold).foregroundStyle(.green)
            case .removed(let subject):
                Text("−").fontWeight(.bold).foregroundStyle(.red)
                Text(subject).strikethrough().foregroundStyle(.red)
            case .changed(let old, let new):
                Text("↻").fontWeight(.bold).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(old).strikethrough().font(.subheadline).foregroundStyle(.red)
                    Text(new).fontWeight(.semibold).foregroundStyle(.green)
                }
            }
        }
    }
}
