import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ScanViewModel {
    enum Phase: Equatable {
        case idle, processing, review, failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var result: ParsedTimetable?

    private let recognizer: TextRecognizing
    private let parser = TimetableParser()

    init(recognizer: TextRecognizing = VisionTextRecognizer()) {
        self.recognizer = recognizer
    }

    func process(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        phase = .processing
        do {
            var merged = ParsedTimetable()
            for image in images {
                guard let cgImage = ImageTools.resized(image, maxDimension: 3000).cgImage else { continue }
                let texts = try await recognizer.recognizeText(in: cgImage)
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

    func reset() {
        phase = .idle
        result = nil
    }
}
