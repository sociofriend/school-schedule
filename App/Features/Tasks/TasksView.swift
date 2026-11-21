import SwiftUI

struct TasksView: View {
    @Bindable var viewModel: TasksViewModel
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            ProgressRing(progress: viewModel.progress, lineWidth: 8, tint: .yellow)
                            Text("⭐️").font(.title2)
                        }
                        .frame(width: 60, height: 60)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Այս շաբաթ՝ \(viewModel.starsThisWeek) աստղ").font(.headline)
                            if viewModel.streak > 0 {
                                Text("🔥 \(viewModel.streak) օր անընդմեջ").font(.subheadline.weight(.semibold)).foregroundStyle(.orange)
                            }
                            Text(viewModel.cheer).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
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
                    ContentUnavailableView {
                        Label("Ամեն ինչ արված է 🏆", systemImage: "party.popper.fill")
                    } description: {
                        Text("Նոր անելիք ավելացրու + կոճակով։")
                    }
                    .padding(.top, 120)
                }
            }
            .animation(.spring, value: viewModel.remainingCount)
            .overlay { ConfettiView(trigger: viewModel.celebrations).ignoresSafeArea() }
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
                    Text("Մնացել է՝ \(viewModel.remainingCount) 💪")
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

/// New homework form, shared by Tasks and Today.
struct AddTaskSheet: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ինչ անել", text: $viewModel.draftTitle, axis: .vertical).focused($focused)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(TasksViewModel.quickTitles, id: \.self) { title in
                                Button(title) { viewModel.draftTitle = title }
                                    .buttonStyle(.bordered).buttonBorderShape(.capsule)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
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
