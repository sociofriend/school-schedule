import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    let store: DataStore
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if viewModel.hasTimetable {
                        lessonsSection
                        tasksSection
                    } else {
                        emptyTimetable
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .overlay { ConfettiView(trigger: viewModel.celebrations).ignoresSafeArea() }
            .navigationTitle(viewModel.title)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LessonRoute.self) { LessonDetailView(store: store, route: $0) }
            .refreshable { viewModel.reload() }
            .sheet(isPresented: $isScanning) { ScanTimetableView(store: store) }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(viewModel.greeting.title) \(viewModel.greeting.emoji)")
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

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Դասեր", symbol: "backpack.fill", tint: .blue)
            if viewModel.snapshot.lessons.isEmpty {
                Text("Դասեր չկան, ազատ օր է 🎉").foregroundStyle(.secondary).card(tint: .blue)
            }
            ForEach(viewModel.snapshot.lessons) { lesson in
                let isCurrent = lesson.period == viewModel.currentPeriod
                NavigationLink(value: LessonRoute(day: viewModel.snapshot.date, subject: lesson.subject)) {
                    LessonRow(lesson: lesson, isCurrent: isCurrent,
                              hasNote: viewModel.subjectsWithNotes.contains(lesson.subject))
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20, style: .continuous))
                        .overlay {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(SubjectStyle(subject: lesson.subject).color, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Անելիքներ", symbol: "checklist", tint: .green)
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
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20, style: .continuous))
        }
    }

    private var emptyTimetable: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 110, height: 110)
                .background(Color.accentColor.gradient, in: .circle)
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
        }
        .frame(maxWidth: .infinity)
        .card()
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
