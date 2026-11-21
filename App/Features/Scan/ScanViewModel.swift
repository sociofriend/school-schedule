import Foundation
import Observation
import PDFKit
import UIKit

@MainActor
@Observable
final class ScanViewModel {
    enum Phase: Equatable {
        case idle, processing, review, failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var result: ParsedTimetable?
    /// Raw OCR lines, shown when parsing fails so the user sees what was read.
    private(set) var recognizedText = ""

    private let recognizer: TextRecognizing
    private let parser = TimetableParser()

    init(recognizer: TextRecognizing = TesseractTextRecognizer()) {
        self.recognizer = recognizer
    }

    func process(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        phase = .processing
        do {
            var merged = ParsedTimetable()
            recognizedText = ""
            for image in images {
                guard let cgImage = ImageTools.resized(image, maxDimension: 3000).cgImage else { continue }
                let texts = try await recognizer.recognizeText(in: cgImage)
                recognizedText += TextLayout.cells(from: texts).map(\.text).joined(separator: "\n")
                merged.merge(try parser.parse(texts))
            }
            guard !merged.entries.isEmpty else { throw TimetableParser.ParseError.noWeekdaysFound }
            result = merged
            phase = .review
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func processPhotoData(_ data: [Data]) async {
        await process(data.compactMap(UIImage.init(data:)))
    }

    /// Renders each page of a picked PDF into a high-resolution image and runs the same OCR pipeline.
    func processPDF(url: URL) async {
        phase = .processing
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            phase = .failed("Չհաջողվեց բացել PDF ֆայլը։")
            return
        }

        let images = (0..<document.pageCount).compactMap { index -> UIImage? in
            guard let page = document.page(at: index) else { return nil }
            let bounds = page.bounds(for: .mediaBox)
            let maxDim = max(bounds.width, bounds.height)
            guard maxDim > 0 else { return nil }
            let scale = min(2.5, 2400 / maxDim)
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
        }

        guard !images.isEmpty else {
            phase = .failed("PDF ֆայլում էջեր չգտնվեցին։")
            return
        }
        await process(images)
    }

    func reset() {
        phase = .idle
        result = nil
        recognizedText = ""
    }
}
