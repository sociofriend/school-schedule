import SwiftUI

struct NotesView: View {
    @Bindable var viewModel: NotesViewModel
    let store: DataStore
    @State private var path: [LessonRoute] = []
    @State private var isAdding = false
    @State private var pendingRoute: LessonRoute?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !viewModel.subjects.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            chip("Բոլորը", isOn: viewModel.subjectFilter == nil) { viewModel.subjectFilter = nil }
                            ForEach(viewModel.subjects, id: \.self) { subject in
                                chip(subject, isOn: viewModel.subjectFilter == subject) { viewModel.subjectFilter = subject }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                ForEach(viewModel.groups) { group in
                    Section(group.day.armenianLongDay) {
                        ForEach(group.notes) { note in
                            NavigationLink(value: LessonRoute(day: note.day, subject: note.subject)) {
                                NoteRow(note: note)
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.groups.isEmpty {
                    if viewModel.searchText.isEmpty {
                        ContentUnavailableView {
                            Label {
                                Text("Գրառումներ չկան")
                            } icon: {
                                Image(systemName: "note.text").themedFloat()
                            }
                        } description: {
                            Text("Գրիր, լուսանկարիր գրատախտակը կամ սկանավորիր տետրը։")
                        } actions: {
                            Button("Նոր գրառում", systemImage: "plus", action: startAdding)
                                .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                        }
                    } else {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Որոնել գրառումներում")
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Գրառումներ")
            .navigationDestination(for: LessonRoute.self) { LessonDetailView(store: store, route: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Նոր գրառում", systemImage: "plus", action: startAdding)
                }
            }
            // Push after the sheet is gone, so the two transitions don't collide.
            .sheet(isPresented: $isAdding, onDismiss: {
                if let route = pendingRoute { path.append(route) }
                pendingRoute = nil
            }) {
                NewNoteSheet(viewModel: viewModel) { pendingRoute = $0 }
            }
        }
    }

    private func startAdding() {
        viewModel.prepareDraft()
        isAdding = true
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .tint(isOn ? nil : Color.secondary)
            .buttonBorderShape(.capsule)
    }
}

private struct NoteRow: View {
    let note: LessonNote

    var body: some View {
        HStack(spacing: 12) {
            if let photo = note.photos.first {
                PhotoThumbnail(data: photo.imageData, maxPixelSize: 160)
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                SubjectIcon(subject: note.subject, size: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(note.subject).font(.headline)
                if !note.text.isEmpty {
                    Text(note.text).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            if note.photos.count > 0 {
                Label("\(note.photos.count)", systemImage: "photo").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
