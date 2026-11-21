import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Bindable var profile: ProfileViewModel
    let store: DataStore
    @State private var isScanning = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ProfileEditView(profile: profile).armenianBackButton()
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(profile: profile, size: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name.isEmpty ? "Իմ պրոֆիլը" : profile.name)
                                    .font(.title3.bold())
                                Text(profileSubtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Դասացուցակ") {
                    NavigationLink {
                        SchoolYearsView(store: store).armenianBackButton()
                    } label: {
                        SettingsMenuRow(
                            title: "Ուսումնական տարի",
                            subtitle: "\(store.activeSchoolYear) · Պահել և փոխել տարիները",
                            symbol: "calendar.badge.clock",
                            tint: .indigo
                        )
                    }

                    Button {
                        isScanning = true
                    } label: {
                        SettingsMenuRow(
                            title: "Ներմուծել կամ համեմատել",
                            subtitle: "Լուսանկար, screenshot կամ PDF",
                            symbol: "doc.viewfinder",
                            tint: .blue
                        )
                    }
                    .foregroundStyle(.primary)

                    NavigationLink {
                        TimetableEditorView(store: store, grade: profile.grade).armenianBackButton()
                    } label: {
                        SettingsMenuRow(
                            title: "Խմբագրել ձեռքով",
                            subtitle: "Դասեր, առարկաներ և սենյակներ",
                            symbol: "square.and.pencil",
                            tint: .orange
                        )
                    }

                    NavigationLink {
                        PeriodTimesView(viewModel: viewModel).armenianBackButton()
                    } label: {
                        SettingsMenuRow(
                            title: "Դասաժամեր",
                            subtitle: periodsSubtitle,
                            symbol: "clock.fill",
                            tint: .teal
                        )
                    }

                    if let timetable = viewModel.shareableTimetable {
                        let package = SharePackage(sender: profile.name, content: .timetable(timetable))
                        ShareLink(item: package, message: Text(package.readableText), preview: SharePreview(package.title)) {
                            SettingsMenuRow(
                                title: "Ուղարկել ընկերոջը",
                                subtitle: "Կիսվել դասացուցակով",
                                symbol: "square.and.arrow.up",
                                tint: .green
                            )
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Տեսք և ծանուցումներ") {
                    NavigationLink {
                        AppearanceSettingsView(profile: profile).armenianBackButton()
                    } label: {
                        SettingsMenuRow(
                            title: "Ոճ և թեմա",
                            subtitle: "\(profile.theme.name) · \(profile.appearance.title)",
                            symbol: "paintpalette.fill",
                            tint: .purple
                        )
                    }

                    Toggle(isOn: $viewModel.reminderEnabled) {
                        SettingsMenuRow(
                            title: "Երեկոյան հիշեցում",
                            subtitle: viewModel.reminderEnabled ? "Հաջորդ օրվա դասերն ու տնայինները" : "Անջատված է",
                            symbol: "bell.fill",
                            tint: .pink
                        )
                    }

                    if viewModel.reminderEnabled {
                        DatePicker("Ժամը", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    }

                    if viewModel.notificationsDenied {
                        Button("Միացնել ծանուցումները Կարգավորումներում") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                    }
                }
            }
            .navigationTitle("Կարգավորումներ")
            .task { await viewModel.onAppear() }
            .onAppear(perform: viewModel.loadPeriods)
            .sheet(isPresented: $isScanning) { ScanTimetableView(store: store) }
        }
    }

    private var profileSubtitle: String {
        if let grade = profile.grade {
            return "\(ArmenianCurriculum.gradeName(grade)) · Անուն, նկար, դասարան"
        }
        return "Անուն, նկար, դասարան"
    }

    private var periodsSubtitle: String {
        guard let first = viewModel.periods.first, let last = viewModel.periods.last else {
            return "Դասաժամեր չկան"
        }
        return "\(viewModel.periods.count) դասաժամ · \(first.start.armenianTime())–\(last.end.armenianTime())"
    }
}

/// Consistent icon-badge row used in Settings so every option is scannable at a glance.
private struct SettingsMenuRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint.gradient, in: .rect(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Dedicated sub-screen for theme and light/dark appearance.
private struct AppearanceSettingsView: View {
    @Bindable var profile: ProfileViewModel

    var body: some View {
        Form {
            Section {
                ThemePicker(selection: $profile.theme)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .onChange(of: profile.theme) { profile.applyIcon() }
                AppearancePicker(selection: $profile.appearance)
            } header: {
                Text("Ոճ")
            } footer: {
                Text("Ոճի հետ փոխվում է նաև հավելվածի պատկերակը։")
            }
        }
        .navigationTitle("Ոճ և թեմա")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Dedicated sub-screen for bell schedule / period start and end times.
private struct PeriodTimesView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                ForEach($viewModel.periods) { $period in
                    HStack {
                        Text("\(period.period).").monospacedDigit().foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("Սկիզբ", selection: $period.start, displayedComponents: .hourAndMinute).labelsHidden()
                        Text("–")
                        DatePicker("Ավարտ", selection: $period.end, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                }
                Button("Ավելացնել ժամ", systemImage: "plus", action: viewModel.addPeriod)
                if !viewModel.periods.isEmpty {
                    Button("Հեռացնել վերջինը", systemImage: "minus", role: .destructive, action: viewModel.removeLastPeriod)
                }
            } footer: {
                Text("Widget-ը դասերի ընթացքում ցույց է տալիս այսօրվա, իսկ դրանցից հետո՝ վաղվա դասացուցակը։")
            }
            .onChange(of: viewModel.periods.map { [$0.start, $0.end] }) { viewModel.savePeriods() }
        }
        .navigationTitle("Դասաժամեր")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.loadPeriods)
    }
}

/// Manages timetables across school years so previous years stay archived and browsable.
private struct SchoolYearsView: View {
    let store: DataStore
    @State private var years: [String] = []
    @State private var activeYear: String = SchoolYear.active
    @State private var isAddingYear = false
    @State private var newYearText = ""

    var body: some View {
        Form {
            Section {
                ForEach(years, id: \.self) { year in
                    Button {
                        store.activeSchoolYear = year
                        reload()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(year)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(store.lessonCount(for: year)) դաս")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if year == activeYear {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                                    .font(.title3)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .swipeActions {
                        if years.count > 1 && year != activeYear {
                            Button("Ջնջել", role: .destructive) {
                                store.deleteSchoolYear(year)
                                reload()
                            }
                        }
                    }
                }
            } header: {
                Text("Պահված տարիներ")
            } footer: {
                Text("Նախորդ տարիների դասացուցակները պահվում են. ցանկացած պահի կարող ես անցնել մեկից մյուսը։")
            }

            Section {
                Button("Ավելացնել նոր ուսումնական տարի", systemImage: "plus") {
                    let newest = years.first ?? activeYear
                    newYearText = SchoolYear.next(after: newest)
                    isAddingYear = true
                }
                Button("Վերականգնել 2026-2027 դասացուցակը", systemImage: "arrow.counterclockwise") {
                    store.resetPreset2026_2027()
                    reload()
                }
            }
        }
        .navigationTitle("Ուսումնական տարի")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .alert("Նոր ուսումնական տարի", isPresented: $isAddingYear) {
            TextField("Օր.՝ 2027-2028", text: $newYearText)
            Button("Չեղարկել", role: .cancel) {}
            Button("Ավելացնել") {
                store.addSchoolYear(newYearText)
                reload()
            }
        } message: {
            Text("Կստեղծվի նոր դատարկ դասացուցակ, իսկ նախորդ տարիները կմնան պահված։")
        }
    }

    private func reload() {
        years = store.schoolYears()
        activeYear = store.activeSchoolYear
    }
}
