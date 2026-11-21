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
                        ProfileEditView(profile: profile)
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(photo: profile.photo, name: profile.name, size: 52)
                            Text(profile.name.isEmpty ? "Իմ պրոֆիլը" : profile.name).font(.title3.bold())
                        }
                    }
                }

                Section("Ոճ") {
                    ThemePicker(selection: $profile.theme)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .onChange(of: profile.theme) { profile.applyIcon() }
                }

                Section {
                    Toggle("Երեկոյան հիշեցում", isOn: $viewModel.reminderEnabled)
                    if viewModel.reminderEnabled {
                        DatePicker("Ժամը", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if viewModel.notificationsDenied {
                        Button("Միացնել ծանուցումները Կարգավորումներում") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                    }
                } footer: {
                    Text("Ամեն երեկո կստանաս հաջորդ օրվա դասացուցակը և տնայինները։")
                }

                Section("Դասացուցակ") {
                    Button("Սկանավորել նորից", systemImage: "camera.viewfinder") { isScanning = true }
                    NavigationLink {
                        TimetableEditorView(store: store)
                    } label: {
                        Label("Խմբագրել ձեռքով", systemImage: "square.and.pencil")
                    }
                }

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
                } header: {
                    Text("Դասաժամեր")
                } footer: {
                    Text("Widget-ը դասերի ընթացքում ցույց է տալիս այսօրվա, իսկ դրանցից հետո՝ վաղվա դասացուցակը։")
                }
                .onChange(of: viewModel.periods.map { [$0.start, $0.end] }) { viewModel.savePeriods() }
            }
            .navigationTitle("Կարգավորումներ")
            .task { await viewModel.onAppear() }
            .onAppear(perform: viewModel.loadPeriods)
            .sheet(isPresented: $isScanning) { ScanTimetableView(store: store) }
        }
    }
}
