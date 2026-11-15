import CoreGraphics
import Vision

protocol TextRecognizing: Sendable {
    func recognizeText(in image: CGImage) async throws -> [RecognizedText]
}

/// On-device OCR with Vision.
struct VisionTextRecognizer: TextRecognizing {
    /// Preferred order; only languages Vision supports on this OS are used.
    var preferredLanguages = ["hy-AM", "ru-RU", "en-US"]

    func recognizeText(in image: CGImage) async throws -> [RecognizedText] {
        let languages = preferredLanguages
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            let supported = (try? request.supportedRecognitionLanguages()) ?? []
            let usable = languages.filter(supported.contains)
            if !usable.isEmpty { request.recognitionLanguages = usable }

            try VNImageRequestHandler(cgImage: image).perform([request])
            return (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first.map { RecognizedText(text: $0.string, box: observation.boundingBox) }
            }
        }.value
    }
}
