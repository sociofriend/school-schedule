import PhotosUI
import SwiftUI
import VisionKit

struct LessonDetailView: View {
    @State private var viewModel: LessonDetailViewModel
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var selectedPhoto: NotePhoto?
    @FocusState private var isTaskFieldFocused: Bool

    init(store: DataStore, route: LessonRoute) {
        _viewModel = State(initialValue: LessonDetailViewModel(store: store, route: route))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            Section("✏️ Գրառում") {
                TextField("Ինչ անցանք, կարևոր նշումներ…", text: $viewModel.noteText, axis: .vertical)
                    .lineLimit(4...)
            }

            Section("📷 Լուսանկարներ") {
                if !viewModel.photos.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(viewModel.photos) { photo in
                                Button { selectedPhoto = photo } label: {
                                    PhotoThumbnail(data: photo.imageData)
                                        .frame(width: 96, height: 96)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .contextMenu {
                                    Button("Ջնջել", systemImage: "trash", role: .destructive) { viewModel.delete(photo) }
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                if VNDocumentCameraViewController.isSupported {
                    Button("Լուսանկարել գրատախտակը", systemImage: "camera") { isCameraPresented = true }
                }
                PhotosPicker(selection: $pickerItems, matching: .images) {
                    Label("Ընտրել պատկերասրահից", systemImage: "photo.on.rectangle")
                }
            }

            Section("📚 Տնային") {
                ForEach(viewModel.tasks) { task in
                    TaskRow(title: task.title, subject: "", isDone: task.isDone,
                            dueText: task.dueDate.formatted(.dateTime.weekday().day().month())) { viewModel.toggle(task) }
                        .swipeActions { Button("Ջնջել", role: .destructive) { viewModel.delete(task) } }
                }
                TextField("Նոր տնային", text: $viewModel.newTaskTitle)
                    .focused($isTaskFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(viewModel.addTask)
                DatePicker("Հանձնել", selection: $viewModel.newTaskDue, displayedComponents: .date)
                Button("Ավելացնել", systemImage: "plus", action: viewModel.addTask)
                    .disabled(viewModel.newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(SubjectStyle(subject: viewModel.title).color)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    SubjectIcon(subject: viewModel.title, size: 30)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.title).font(.headline)
                        Text(viewModel.dateText).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            DocumentScannerView { viewModel.addPhotos($0) }.ignoresSafeArea()
        }
        .sheet(item: $selectedPhoto) { PhotoViewer(data: $0.imageData) }
        .onChange(of: pickerItems) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) { viewModel.addPhotoData(data) }
                }
                pickerItems = []
            }
        }
        .onDisappear(perform: viewModel.finish)
    }
}

/// Full-screen zoomable photo.
struct PhotoViewer: View {
    let data: Data
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1

    var body: some View {
        NavigationStack {
            PhotoThumbnail(data: data, maxPixelSize: 2048, contentMode: .fit)
                .scaleEffect(scale)
                .gesture(MagnifyGesture().onChanged { scale = max(1, $0.magnification) }.onEnded { _ in
                    withAnimation(.spring) { scale = 1 }
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .toolbar { Button("Փակել") { dismiss() } }
        }
    }
}
