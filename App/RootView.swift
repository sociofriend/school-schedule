import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    @State private var today: TodayViewModel
    @State private var calendar: CalendarViewModel
    @State private var tasks: TasksViewModel
    @State private var notes: NotesViewModel
    @State private var settings: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(environment: AppEnvironment) {
        self.environment = environment
        let store = environment.store
        _today = State(initialValue: TodayViewModel(store: store))
        _calendar = State(initialValue: CalendarViewModel(store: store))
        _tasks = State(initialValue: TasksViewModel(store: store))
        _notes = State(initialValue: NotesViewModel(store: store))
        _settings = State(initialValue: SettingsViewModel(store: store, notifications: environment.notifications))
    }

    var body: some View {
        TabView {
            TodayView(viewModel: today, store: environment.store)
                .tabItem { Label("Այսօր", systemImage: "sun.max") }
            CalendarScreen(viewModel: calendar, store: environment.store)
                .tabItem { Label("Օրացույց", systemImage: "calendar") }
            TasksView(viewModel: tasks)
                .tabItem { Label("Անելիքներ", systemImage: "checklist") }
            NotesView(viewModel: notes, store: environment.store)
                .tabItem { Label("Գրառումներ", systemImage: "note.text") }
            SettingsView(viewModel: settings, store: environment.store)
                .tabItem { Label("Կարգավորումներ", systemImage: "gearshape") }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            today.reload()
            environment.notifications.rescheduleInBackground()
        }
    }
}
