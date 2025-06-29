
import XCTest
@testable import LLMTextTranslator

class ClipboardManagerTests: XCTestCase {

    var clipboardManager: ClipboardManager!

    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager()
    }

    override func tearDown() {
        clipboardManager = nil
        super.tearDown()
    }

    func testWriteToClipboard() {
        let testText = "Hello, World!"
        clipboardManager.writeToClipboard(text: testText)
        XCTAssertEqual(clipboardManager.readFromClipboard(), testText, "The text read from the clipboard should match the text that was written.")
    }

    func testReadFromClipboard() {
        let testText = "Test reading from clipboard."
        clipboardManager.writeToClipboard(text: testText)
        let readText = clipboardManager.readFromClipboard()
        XCTAssertEqual(readText, testText, "Should be able to read the text that was written to the clipboard.")
    }

    func testClearClipboard() {
        clipboardManager.writeToClipboard(text: "Some text")
        clipboardManager.clearClipboard()
        XCTAssertNil(clipboardManager.readFromClipboard(), "The clipboard should be empty after clearing.")
    }

    func testHasText() {
        clipboardManager.clearClipboard()
        XCTAssertFalse(clipboardManager.hasText(), "Clipboard should not have text after clearing.")
        
        clipboardManager.writeToClipboard(text: "Some text")
        XCTAssertTrue(clipboardManager.hasText(), "Clipboard should have text after writing to it.")
        
        clipboardManager.writeToClipboard(text: "  ")
        XCTAssertFalse(clipboardManager.hasText(), "Clipboard should not have text if it only contains whitespace.")
    }

    func testGetClipboardTextLength() {
        let testText = "12345"
        clipboardManager.writeToClipboard(text: testText)
        XCTAssertEqual(clipboardManager.getClipboardTextLength(), testText.count, "The length of the clipboard text should be correct.")
        
        clipboardManager.clearClipboard()
        XCTAssertEqual(clipboardManager.getClipboardTextLength(), 0, "The length of the clipboard text should be 0 when empty.")
    }

    func testAddToHistory() {
        clipboardManager.clearHistory()
        clipboardManager.addToHistory(text: "first item")
        XCTAssertEqual(clipboardManager.getHistory(), ["first item"])
        
        clipboardManager.addToHistory(text: "second item")
        XCTAssertEqual(clipboardManager.getHistory(), ["second item", "first item"])
    }

    func testHistoryLimit() {
        clipboardManager.clearHistory()
        for i in 1...15 {
            clipboardManager.addToHistory(text: "item \(i)")
        }
        XCTAssertEqual(clipboardManager.getHistory().count, 10, "History should be trimmed to the max count.")
        XCTAssertEqual(clipboardManager.getHistory().first, "item 15")
        XCTAssertEqual(clipboardManager.getHistory().last, "item 6")
    }

    func testClearHistory() {
        clipboardManager.addToHistory(text: "some history")
        clipboardManager.clearHistory()
        XCTAssertTrue(clipboardManager.getHistory().isEmpty, "History should be empty after clearing.")
    }
}
