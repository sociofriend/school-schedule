import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    let store: DataStore
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.hasTimetable {
                    ContentUnavailableView {
                        Label("Դասացուցակ չկա", systemImage: "camera.viewfinder")
                    } description: {
                        Text("Լուսանկարիր դասացուցակը, և այն ավտոմատ կլրացվի։")
                    } actions: {
                        Button("Սկանավորել") { isScanning = true }.buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section("Դասեր") {
                        if viewModel.snapshot.lessons.isEmpty {
                            Text("Դասեր չկան").foregroundStyle(.secondary)
                        }
                        ForEach(viewModel.snapshot.lessons) { lesson in
                            NavigationLink(value: LessonRoute(day: viewModel.snapshot.date, subject: lesson.subject)) {
                                LessonRow(lesson: lesson,
                                          isCurrent: lesson.period == viewModel.currentPeriod,
                                          hasNote: viewModel.subjectsWithNotes.contains(lesson.subject))
                            }
                        }
                    }
                    Section {
                        if viewModel.snapshot.tasks.isEmpty {
                            Text("Անելիքներ չկան 🎉").foregroundStyle(.secondary)
                        }
                        ForEach(viewModel.snapshot.tasks) { task in
                            TaskRow(title: task.title, subject: task.subject, isDone: task.isDone) { viewModel.toggle(task) }
                        }
                    } header: {
                        Text("Անելիքներ")
                    } footer: {
                        let remaining = viewModel.snapshot.remainingTasks.count
                        if remaining > 0 { Text("Մնացել է՝ \(remaining)") }
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .navigationDestination(for: LessonRoute.self) { LessonDetailView(store: store, route: $0) }
            .refreshable { viewModel.reload() }
            .sheet(isPresented: $isScanning) { ScanTimetableView(store: store) }
        }
    }
}
