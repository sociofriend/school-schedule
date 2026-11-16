import CoreGraphics
import CoreImage
import SwiftyTesseract
import UIKit

protocol TextRecognizing: Sendable {
    func recognizeText(in image: CGImage) async throws -> [RecognizedText]
}

/// On-device OCR with Tesseract and the Armenian model (`Resources/tessdata/hye.traineddata`).
/// Apple Vision does not support Armenian script, so it is not used for timetables.
/// Returns words: a text line can span several table columns, so the parser groups words into cells itself.
struct TesseractTextRecognizer: TextRecognizing {
    var language = "hye"

    func recognizeText(in image: CGImage) async throws -> [RecognizedText] {
        let language = language
        return try await Task.detached(priority: .userInitiated) {
            let prepared = OCRPreprocessor.prepare(image)
            let tesseract = Tesseract(language: .custom(language), dataSource: Bundle.main, engineMode: .lstmOnly)
            let (_, lines) = try tesseract.recognizedBlocks(from: UIImage(cgImage: prepared), for: .word).get()
            let width = CGFloat(prepared.width), height = CGFloat(prepared.height)
            return lines.compactMap { line in
                let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                let rect = line.boundingBox.cgRect // top-left origin, pixels
                // Normalise to Vision-style coordinates (bottom-left origin, 0...1) used by the parser.
                return RecognizedText(text: text, box: CGRect(x: rect.minX / width, y: 1 - rect.maxY / height,
                                                              width: rect.width / width, height: rect.height / height))
            }
        }.value
    }
}

/// Tesseract reads dark text on a light background best: grayscale, invert dark-mode screenshots,
/// and upscale small images.
enum OCRPreprocessor {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func prepare(_ image: CGImage) -> CGImage {
        var output = CIImage(cgImage: image)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0, kCIInputContrastKey: 1.1])
        if averageLuminance(of: output) < 0.5 {
            output = output.applyingFilter("CIColorInvert")
        }
        if image.width < 2000 {
            output = output.applyingFilter("CILanczosScaleTransform", parameters: [kCIInputScaleKey: 2.0, kCIInputAspectRatioKey: 1.0])
        }
        return context.createCGImage(output, from: output.extent.integral) ?? image
    }

    private static func averageLuminance(of image: CIImage) -> CGFloat {
        let average = image.applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: CIVector(cgRect: image.extent)])
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(average, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: nil)
        return CGFloat(pixel[0]) / 255
    }
}
