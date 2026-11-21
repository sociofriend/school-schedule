import SwiftUI

struct RootView: View {
    let environment: AppEnvironment
    @State private var today: TodayViewModel
    @State private var calendar: CalendarViewModel
    @State private var tasks: TasksViewModel
    @State private var notes: NotesViewModel
    @State private var settings: SettingsViewModel
    @State private var profile: ProfileViewModel
    @State private var inbox: ShareInboxViewModel
    @State private var tab: AppTab = .today
    @Environment(\.scenePhase) private var scenePhase

    init(environment: AppEnvironment) {
        self.environment = environment
        let store = environment.store
        _today = State(initialValue: TodayViewModel(store: store, backpack: BackpackViewModel()))
        _calendar = State(initialValue: CalendarViewModel(store: store))
        _tasks = State(initialValue: TasksViewModel(store: store))
        _notes = State(initialValue: NotesViewModel(store: store))
        _profile = State(initialValue: ProfileViewModel())
        _inbox = State(initialValue: ShareInboxViewModel(store: store))
        _settings = State(initialValue: SettingsViewModel(store: store, notifications: environment.notifications))
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayView(viewModel: today, tasks: tasks, profile: profile, store: environment.store)
                .tag(AppTab.today)
                .toolbar(.hidden, for: .tabBar)
            CalendarScreen(viewModel: calendar, store: environment.store)
                .tag(AppTab.calendar)
                .toolbar(.hidden, for: .tabBar)
            TasksView(viewModel: tasks, sender: profile.name)
                .tag(AppTab.tasks)
                .toolbar(.hidden, for: .tabBar)
            NotesView(viewModel: notes, store: environment.store)
                .tag(AppTab.notes)
                .toolbar(.hidden, for: .tabBar)
            SettingsView(viewModel: settings, profile: profile, store: environment.store)
                .tag(AppTab.settings)
                .toolbar(.hidden, for: .tabBar)
        }
        // Own tab bar (system tabs hidden above) so the icons can play the theme's selection animation.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ThemedTabBar(selection: $tab, badges: [.tasks: tasks.dueSoonCount])
        }
        .themed(profile.isComplete ? profile.theme : nil, appearance: profile.appearance)
        .fullScreenCover(isPresented: .constant(!profile.isComplete)) { OnboardingView(profile: profile) }
        // A share opened before onboarding waits until the profile is done.
        .sheet(item: Binding(get: { profile.isComplete ? inbox.package : nil }, set: { if $0 == nil { inbox.decline() } })) {
            ShareInboxView(viewModel: inbox, package: $0)
        }
        .alert("Չհաջողվեց բացել ֆայլը", isPresented: $inbox.failed) {
            Button("Լավ", role: .cancel) {}
        } message: {
            Text("Գուցե այն ստեղծվել է հավելվածի ավելի նոր տարբերակով։")
        }
        .onOpenURL { inbox.open($0) }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            today.reload()
            environment.notifications.rescheduleInBackground()
        }
    }
}
