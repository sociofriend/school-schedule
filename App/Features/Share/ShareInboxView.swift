import SwiftUI

/// Shown when a share arrives: what was received first, then where to put it.
struct ShareInboxView: View {
    @Bindable var viewModel: ShareInboxViewModel
    let package: SharePackage

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text("🎁").font(.system(size: 56))
                        Text(headline).font(.title3.bold()).multilineTextAlignment(.center)
                        if !package.sender.isEmpty {
                            Text("Ուղարկեց՝ \(package.sender)").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                switch package.content {
                case .task(let task): taskSections(task)
                case .timetable(let timetable): timetableSections(timetable)
                }
            }
            .navigationTitle("Ստացված")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Չեմ ուզում", action: viewModel.decline) }
                ToolbarItem(placement: .confirmationAction) { Button("Ավելացնել", action: viewModel.accept) }
            }
        }
        .interactiveDismissDisabled()
    }

    private var headline: String {
        switch package.content {
        case .task: "Քեզ առաջադրանք են ուղարկել"
        case .timetable: "Քեզ դասացուցակ են ուղարկել"
        }
    }

    @ViewBuilder private func taskSections(_ task: SharePackage.Task) -> some View {
        Section("Ինչ է ստացվել") {
            HStack(spacing: 14) {
                SubjectIcon(subject: task.subject, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title).font(.headline)
                    Text([task.subject, task.dueDate.armenianShortDay].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        Section {
            Picker("Առարկա", selection: $viewModel.subject) {
                Text("Առանց առարկայի").tag("")
                ForEach(viewModel.subjects, id: \.self) { Text($0).tag($0) }
            }
            .onChange(of: viewModel.subject) { viewModel.subjectChanged() }
            DatePicker("Ժամկետ", selection: $viewModel.due, displayedComponents: .date)
        } header: {
            Text("Որտե՞ղ դնենք")
        } footer: {
            Text("Առարկան ընտրելիս ժամկետը կդառնա այդ առարկայի հաջորդ դասը։")
        }
    }

    @ViewBuilder private func timetableSections(_ timetable: Timetable) -> some View {
        ForEach(Weekday.schoolWeek.filter { day in timetable.entries.contains { $0.weekday == day } }, id: \.self) { weekday in
            Section(Weekday.name(weekday)) {
                ForEach(timetable.entries.filter { $0.weekday == weekday }.sorted { $0.period < $1.period }, id: \.self) { entry in
                    HStack(spacing: 12) {
                        Text("\(entry.period).").monospacedDigit().foregroundStyle(.secondary)
                        SubjectIcon(subject: entry.subject, size: 28)
                        Text(entry.subject)
                        Spacer()
                        if let range = timetable.periods[entry.period] {
                            Text(PeriodRange.format(range.start)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        Section {
            if viewModel.hasOwnTimetable {
                Picker("Ինչ անենք", selection: $viewModel.mode) {
                    Text("Փոխարինել իմը").tag(ShareInboxViewModel.TimetableMode.replace)
                    Text("Լրացնել դատարկ ժամերը").tag(ShareInboxViewModel.TimetableMode.merge)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            if viewModel.mode == .replace, !timetable.periods.isEmpty {
                Toggle("Վերցնել դասաժամերն էլ", isOn: $viewModel.takesBellTimes)
            }
        } header: {
            Text("Որտե՞ղ դնենք")
        } footer: {
            if viewModel.hasOwnTimetable {
                Text(viewModel.mode == .replace
                     ? "Քո դասացուցակը կփոխարինվի ստացվածով։"
                     : "Քո դասերը կմնան, ստացվածից կավելանան միայն ազատ ժամերի դասերը։")
            } else {
                Text("Սա կդառնա քո դասացուցակը։ Հետո կարող ես խմբագրել Կարգավորումներում։")
            }
        }
    }
}
