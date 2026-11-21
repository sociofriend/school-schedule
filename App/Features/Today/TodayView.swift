import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    let tasks: TasksViewModel
    let profile: ProfileViewModel
    let store: DataStore
    @State private var isScanning = false
    @State private var isPacking = false
    @State private var isAddingTask = false
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if viewModel.hasTimetable {
                        // Evenings (showing tomorrow) lead with packing; school hours lead with "now".
                        if !viewModel.isToday { backpackCard }
                        NowCard(phase: viewModel.phase, lessons: viewModel.snapshot.lessons,
                                lessonsDone: viewModel.lessonsDone, isToday: viewModel.isToday)
                        if viewModel.isToday { backpackCard }
                        lessonsSection
                        tasksSection
                    } else {
                        emptyTimetable
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(theme.background)
            .overlay { ConfettiView(trigger: viewModel.celebrations).ignoresSafeArea() }
            .navigationTitle(viewModel.title)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LessonRoute.self) { LessonDetailView(store: store, route: $0) }
            .refreshable { viewModel.reload() }
            .sheet(isPresented: $isScanning) { ScanTimetableView(store: store) }
            .sheet(isPresented: $isPacking) { BackpackSheet(viewModel: viewModel.backpack) }
            .sheet(isPresented: $isAddingTask) { AddTaskSheet(viewModel: tasks) }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarView(profile: profile, size: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(viewModel.dayLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if !viewModel.snapshot.tasks.isEmpty {
                ZStack {
                    ProgressRing(progress: viewModel.progress, lineWidth: 9)
                    Text("\(viewModel.doneCount)/\(viewModel.snapshot.tasks.count)")
                        .font(.headline.monospacedDigit())
                }
                .frame(width: 70, height: 70)
            }
        }
        .padding(.top, 12)
    }

    private var greetingText: String {
        let name = profile.firstName
        return "\(viewModel.greeting.title)\(name.isEmpty ? "" : ", \(name)") \(viewModel.greeting.emoji)"
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Դասեր", symbol: "backpack.fill", tint: .blue)
            ForEach(viewModel.snapshot.lessons) { lesson in
                let isCurrent = lesson.period == viewModel.currentPeriod
                NavigationLink(value: LessonRoute(day: viewModel.snapshot.date, subject: lesson.subject)) {
                    LessonRow(lesson: lesson, isCurrent: isCurrent,
                              hasNote: viewModel.subjectsWithNotes.contains(lesson.subject))
                        .padding(12)
                        .background(theme.surface, in: .rect(cornerRadius: 20, style: .continuous))
                        .overlay {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(SubjectStyle(subject: lesson.subject).color, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(BouncyButtonStyle())
                .contextMenu {
                    Button("Ավելացնել տնային", systemImage: "plus") { addTask(subject: lesson.subject) }
                }
            }
        }
    }

    @ViewBuilder private var backpackCard: some View {
        if !viewModel.backpack.items.isEmpty {
            BackpackCard(viewModel: viewModel.backpack) { isPacking = true }
        }
    }

    private func addTask(subject: String = "") {
        tasks.prepareDraft(subject: subject)
        isAddingTask = true
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "Անելիքներ", symbol: "checklist", tint: .green)
                Spacer()
                Button("Ավելացնել", systemImage: "plus") { addTask() }
                    .labelStyle(.iconOnly)
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
                    .background(Color.green.opacity(0.15), in: .circle)
                    .foregroundStyle(.green)
                    .buttonStyle(BouncyButtonStyle())
            }
            Text(viewModel.cheer).font(.subheadline).foregroundStyle(.secondary)
            VStack(spacing: 4) {
                ForEach(viewModel.snapshot.tasks) { task in
                    TaskRow(title: task.title, subject: task.subject, isDone: task.isDone) {
                        withAnimation(.spring) { viewModel.toggle(task) }
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, viewModel.snapshot.tasks.isEmpty ? 0 : 6)
            .background(theme.surface, in: .rect(cornerRadius: 20, style: .continuous))
        }
    }

    private var emptyTimetable: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(theme.onAccent)
                .frame(width: 110, height: 110)
                .background(theme.accent.gradient, in: .circle)
            Text("Եկ ծանոթանանք դասացուցակիդ հետ").font(.title3.bold()).multilineTextAlignment(.center)
            Text("Լուսանկարիր այն, և ես ամեն ինչ կդասավորեմ 📸")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                isScanning = true
            } label: {
                Label("Սկանավորել", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .foregroundStyle(theme.onAccent)
        }
        .frame(maxWidth: .infinity)
        .card(tint: theme.accent)
    }
}

/// Section heading with a colored symbol.
struct SectionTitle: View {
    let text: String
    let symbol: String
    var tint: Color = .accentColor

    var body: some View {
        Label {
            Text(text).font(.title2.bold())
        } icon: {
            Image(systemName: symbol).foregroundStyle(tint)
        }
        .accessibilityAddTraits(.isHeader)
    }
}
