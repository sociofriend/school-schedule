import SwiftUI

/// Picks a lesson's subject: the grade's official list (searchable), the kid's own subjects, or any typed name.
struct SubjectPickerView: View {
    let grade: Int?
    let curriculum: [String]
    let own: [String]
    let onPick: (String) -> Void

    @State private var query = ""
    @State private var custom = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Այլ առարկա / Ձեռքով մուտքագրել", text: $custom)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .onSubmit {
                                if custom.trimmingCharacters(in: .whitespaces).isEmpty {
                                    UIApplication.dismissKeyboard()
                                } else {
                                    pick(custom)
                                }
                            }
                        if !custom.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Ավելացնել") { pick(custom) }.fontWeight(.semibold)
                        }
                    }
                    if !query.isEmpty, !(curriculum + own).contains(where: { $0.caseInsensitiveCompare(query) == .orderedSame }) {
                        Button("Ավելացնել «\(query)»", systemImage: "plus") { pick(query) }
                    }
                    Button("Ազատ ժամ", systemImage: "moon.zzz") { pick("") }
                } footer: {
                    Text("Դպրոցական բաղադրիչ, խմբակ կամ անհատական դաս՝ գրիր անունը։")
                }

                subjects(TimetableEditorViewModel.filter(own, by: query), title: "Իմ առարկաները")
                subjects(TimetableEditorViewModel.filter(curriculum, by: query),
                         title: grade.map(ArmenianCurriculum.gradeName) ?? "Բոլոր առարկաները",
                         hint: grade == nil ? "Նշիր դասարանդ պրոֆիլում, և այստեղ կմնան միայն քո դասարանի առարկաները։" : nil)
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Որոնել առարկա")
            .navigationTitle("Առարկա")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissable()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Չեղարկել") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func subjects(_ list: [String], title: String, hint: String? = nil) -> some View {
        if !list.isEmpty {
            Section {
                ForEach(list, id: \.self) { subject in
                    Button { pick(subject) } label: {
                        HStack(spacing: 12) {
                            SubjectIcon(subject: subject, size: 30)
                            Text(subject).foregroundStyle(.primary)
                        }
                    }
                }
            } header: {
                Text(title)
            } footer: {
                if let hint { Text(hint) }
            }
        }
    }

    private func pick(_ subject: String) {
        onPick(subject)
        dismiss()
    }
}
