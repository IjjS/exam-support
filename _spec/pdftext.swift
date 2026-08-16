// Extract the text layer from a PDF using macOS PDFKit. No installation required.
//   swift _spec/pdftext.swift <file.pdf>              全ページ
//   swift _spec/pdftext.swift <file.pdf> 14 20        pages 14-20 (1-indexed, inclusive)
// Prints "===== p.N =====" before each page. Empty output means there is no text
// layer (a scanned PDF) — fall back to page rendering for just the pages needed.
import Foundation
import PDFKit

let a = CommandLine.arguments
guard a.count > 1, let doc = PDFDocument(url: URL(fileURLWithPath: a[1])) else {
    FileHandle.standardError.write("cannot open PDF\n".data(using: .utf8)!)
    exit(1)
}
let from = a.count > 2 ? max(1, Int(a[2]) ?? 1) - 1 : 0
let to   = a.count > 3 ? min(Int(a[3]) ?? doc.pageCount, doc.pageCount) : doc.pageCount
guard from < to else { exit(1) }
for i in from..<to {
    if let p = doc.page(at: i) {
        print("\n===== p.\(i + 1) =====\n" + (p.string ?? ""))
    }
}
