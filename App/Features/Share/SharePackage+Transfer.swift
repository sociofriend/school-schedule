/// Lets `ShareLink` send a SharePackage as a `.dasacucak` file, or as text where files are not taken.
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    /// `.dasacucak` file; declared in Info.plist (exported type + document type).
    static let dasacucakShare = UTType(exportedAs: "am.dasacucak.share", conformingTo: .json)
}

extension SharePackage: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .dasacucakShare) { try $0.encoded() } importing: { try SharePackage.decode($0) }
            .suggestedFileName("Դասացուցակ")
        // Apps that cannot take the file (e.g. Notes) get readable text.
        ProxyRepresentation(exporting: \.readableText)
    }
}

extension SharePackage: Identifiable {
    var id: Self { self }
}
