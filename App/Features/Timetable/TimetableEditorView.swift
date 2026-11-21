import SwiftUI

struct TimetableEditorView: View {
    @State private var viewModel: TimetableEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    var onSave: () -> Void = {}

    init(store: DataStore, scanned: ParsedTimetable? = nil, grade: Int? = ProfileStore().grade, onSave: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: TimetableEditorViewModel(store: store, scanned: scanned, grade: grade))
        self.onSave = onSave
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            Section {
                Picker("Օր", selection: $viewModel.weekday) {
                    ForEach(Weekday.schoolWeek, id: \.self) { Text(Weekday.shortName($0)).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                if viewModel.isReviewingScan {
                    Text("Ստուգիր ճանաչված դասերը և ուղղիր անհրաժեշտության դեպքում։")
                }
            }

            Section(Weekday.name(viewModel.weekday)) {
                ForEach($viewModel.rows) { $row in
                    HStack {
                        Text("\((viewModel.rows.firstIndex(of: row) ?? 0) + 1).")
                            .monospacedDigit().foregroundStyle(.secondary)
                        TextField("Առարկա (դատարկ՝ ազատ ժամ)", text: $row.subject)
                            .textInputAutocapitalization(.sentences)
                        Button("Ընտրել ցանկից", systemImage: "list.bullet") { viewModel.pickerTarget = .row(row.id) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                        TextField("Սենյակ", text: $row.room)
                            .frame(maxWidth: 80)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button("Ջնջել", role: .destructive) {
                            if let index = viewModel.rows.firstIndex(of: row) { viewModel.delete(at: IndexSet(integer: index)) }
                        }
                    }
                }
                .onMove(perform: viewModel.move)
                Button("Ավելացնել դաս", systemImage: "plus", action: viewModel.addRow)
            }
        }
        .navigationTitle(viewModel.isReviewingScan ? "Ստուգում" : "Դասացուցակ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Պահել") {
                    viewModel.save()
                    onSave()
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) { ArmenianEditButton(editMode: $editMode) }
        }
        .environment(\.editMode, $editMode)
        .sheet(item: $viewModel.pickerTarget) { _ in
            SubjectPickerView(grade: viewModel.grade, curriculum: viewModel.curriculumSubjects,
                              own: viewModel.ownSubjects, onPick: viewModel.choose)
        }
    }
}
