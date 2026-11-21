import SwiftUI

/// Picks the subject and day for a new note, then opens the lesson screen, which holds the text, photos and scans.
struct NewNoteSheet: View {
    @Bindable var viewModel: NotesViewModel
    let onContinue: (LessonRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isOther = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Առարկա") {
                    if !viewModel.timetableSubjects.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.timetableSubjects, id: \.self) { subject in
                                    subjectChip(subject)
                                }
                                Button("Այլ") { isOther = true; viewModel.draftSubject = "" }
                                    .buttonStyle(.bordered).buttonBorderShape(.capsule)
                                    .tint(isOther ? .accentColor : .secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .scrollIndicators(.hidden)
                    }
                    if isOther || viewModel.timetableSubjects.isEmpty {
                        TextField("Առարկայի անունը", text: $viewModel.draftSubject)
                    }
                }
                Section {
                    DatePicker("Օր", selection: $viewModel.draftDay, displayedComponents: .date)
                }
            }
            .navigationTitle("Նոր գրառում")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Չեղարկել") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Շարունակել") {
                        if let route = viewModel.draftRoute { onContinue(route) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.draftRoute == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func subjectChip(_ subject: String) -> some View {
        let isOn = !isOther && viewModel.draftSubject == subject
        let style = SubjectStyle(subject: subject)
        return Button {
            isOther = false
            viewModel.draftSubject = subject
        } label: {
            Label(subject, systemImage: style.symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .foregroundStyle(isOn ? .white : style.color)
                .background(isOn ? AnyShapeStyle(style.color.gradient) : AnyShapeStyle(style.color.opacity(0.15)), in: .capsule)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
