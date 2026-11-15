import SwiftUI

struct TasksView: View {
    @Bindable var viewModel: TasksViewModel
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groups) { group in
                    Section(group.title) {
                        ForEach(group.tasks) { task in
                            TaskRow(title: task.title, subject: task.subject, isDone: task.isDone,
                                    dueText: viewModel.dueText(for: task)) { viewModel.toggle(task) }
                                .swipeActions { Button("Ջնջել", role: .destructive) { viewModel.delete(task) } }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.groups.isEmpty {
                    ContentUnavailableView("Ամեն ինչ արված է", systemImage: "checkmark.seal",
                                           description: Text("Նոր անելիք ավելացրու + կոճակով։"))
                }
            }
            .animation(.default, value: viewModel.remainingCount)
            .navigationTitle("Անելիքներ")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Toggle(isOn: $viewModel.showsCompleted) { Label("Կատարվածները", systemImage: "eye") }
                        .toggleStyle(.button)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Ավելացնել", systemImage: "plus") {
                        viewModel.prepareDraft()
                        isAdding = true
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.remainingCount > 0 {
                    Text("Մնացել է՝ \(viewModel.remainingCount)")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.regularMaterial, in: .capsule)
                        .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $isAdding) { AddTaskSheet(viewModel: viewModel) }
        }
    }
}

private struct AddTaskSheet: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ինչ անել", text: $viewModel.draftTitle).focused($focused)
                Picker("Առարկա", selection: $viewModel.draftSubject) {
                    Text("Առանց առարկայի").tag("")
                    ForEach(viewModel.subjects, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: viewModel.draftSubject) { viewModel.subjectChanged() }
                DatePicker("Ժամկետ", selection: $viewModel.draftDue, displayedComponents: .date)
            }
            .navigationTitle("Նոր անելիք")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Չեղարկել") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Պահել") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                    .disabled(viewModel.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
