import PhotosUI
import SwiftUI
import VisionKit

/// Capture → OCR → review flow for the timetable.
struct ScanTimetableView: View {
    let store: DataStore
    @State private var viewModel = ScanViewModel()
    @State private var isCameraPresented = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showsManualEditor = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Սկանավորել")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Փակել") { dismiss() } }
                }
                .navigationDestination(isPresented: $showsManualEditor) {
                    TimetableEditorView(store: store) { dismiss() }.armenianBackButton()
                }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            DocumentScannerView { images in Task { await viewModel.process(images) } }
                .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { await viewModel.processPhotoData([data]) }
                pickerItem = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            sourcePicker
        case .processing:
            ProgressView("Ճանաչում եմ…").frame(maxHeight: .infinity)
        case .review:
            if let result = viewModel.result {
                TimetableEditorView(store: store, scanned: result) { dismiss() }
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Չհաջողվեց", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                if !viewModel.recognizedText.isEmpty {
                    DisclosureGroup("Ինչ կարդացի նկարից") {
                        ScrollView {
                            Text(viewModel.recognizedText)
                                .font(.caption.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                Button("Կրկին փորձել") { viewModel.reset() }.buttonStyle(.borderedProminent)
                Button("Լրացնել ձեռքով") { showsManualEditor = true }
            }
        }
    }

    private var sourcePicker: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.viewfinder").font(.system(size: 64)).foregroundStyle(.tint)
            Text("Լուսանկարիր դասացուցակը կամ ընտրիր էլ. օրագրի screenshot-ը, որտեղ երևում են օրերն ու ժամերը։")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if VNDocumentCameraViewController.isSupported {
                Button("Լուսանկարել", systemImage: "camera") { isCameraPresented = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Ընտրել screenshot / նկար", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
            Button("Լրացնել ձեռքով") { showsManualEditor = true }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}
