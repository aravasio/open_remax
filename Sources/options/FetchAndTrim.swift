#if os(macOS)
import SwiftSoup
import Foundation
import Cocoa

// Function to fetch HTML content from a given URL and trim it to the <body> part
func fetchAndTrimHTML(url: String) {
    do {
        guard let url = URL(string: url) else {
            print("Error: Invalid URL")
            return
        }
        
        let htmlString = try String(contentsOf: url)
        let doc: Document = try SwiftSoup.parse(htmlString)
        let body: Element? = try doc.body()
        guard let bodyHTML = try body?.html() else {
            print("Error: Body not found")
            return
        }
        
        // Copy the trimmed HTML content to the pasteboard (clipboard) on macOS
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(bodyHTML, forType: .string)
        print("Trimmed HTML content copied to clipboard.")
    } catch {
        print("Error: \(error)")
    }
}
#endif
