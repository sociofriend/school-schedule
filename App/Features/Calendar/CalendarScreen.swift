import SwiftUI

struct CalendarScreen: View {
    @Bindable var viewModel: CalendarViewModel
    let store: DataStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthCalendarView(selection: $viewModel.selectedDate, markedDays: viewModel.markedDays)
                }
                Section(viewModel.selectedDate.armenianLongDay) {
                    if viewModel.snapshot.lessons.isEmpty {
                        Text("Դասեր չկան").foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.snapshot.lessons) { lesson in
                        NavigationLink(value: LessonRoute(day: viewModel.snapshot.date, subject: lesson.subject)) {
                            LessonRow(lesson: lesson, hasNote: viewModel.subjectsWithNotes.contains(lesson.subject))
                        }
                    }
                }
                if !viewModel.snapshot.tasks.isEmpty {
                    Section("Անելիքներ") {
                        ForEach(viewModel.snapshot.tasks) { task in
                            TaskRow(title: task.title, subject: task.subject, isDone: task.isDone) { viewModel.toggle(task) }
                        }
                    }
                }
            }
            .navigationTitle("Օրացույց")
            .navigationDestination(for: LessonRoute.self) { LessonDetailView(store: store, route: $0) }
            .toolbar {
                Button("Այսօր") { viewModel.selectedDate = .now }
            }
        }
    }
}
