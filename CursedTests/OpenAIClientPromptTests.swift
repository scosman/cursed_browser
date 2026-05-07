import XCTest
@testable import Cursed

final class OpenAIClientPromptTests: XCTestCase {

    // MARK: - Simplify prompt

    func testSimplifyPromptContainsHTML() {
        let html = "<html><body><h1>Hello</h1></body></html>"
        let prompt = OpenAIClient.buildSimplifyPrompt(html: html, url: "https://example.com/")

        XCTAssertTrue(prompt.contains("```\n\(html)\n```"),
                       "Simplify prompt should embed the HTML inside fenced code blocks")
    }

    func testSimplifyPromptContainsURL() {
        let url = "https://reddit.com/r/cats/comments/abc"
        let prompt = OpenAIClient.buildSimplifyPrompt(html: "<p>test</p>", url: url)

        XCTAssertTrue(prompt.contains(url),
                       "Simplify prompt should embed the URL so the model can use it as signal")
    }

    func testSimplifyPromptContainsInstruction() {
        let prompt = OpenAIClient.buildSimplifyPrompt(html: "<p>test</p>", url: "https://example.com/")

        XCTAssertTrue(prompt.contains("Write simplified HTML"),
                       "Simplify prompt should include the simplification instruction")
        XCTAssertTrue(prompt.contains("render like a real browser would"),
                       "Simplify prompt should state the real-browser rendering goal")
        XCTAssertTrue(prompt.contains("JavaScript-rendered"),
                       "Simplify prompt should cover the JS-rendered case")
        XCTAssertTrue(prompt.contains("Bot-blocked"),
                       "Simplify prompt should cover the bot-blocked case")
        XCTAssertTrue(prompt.contains("`<img>`"),
                       "Simplify prompt should instruct keeping <img> tags rather than dropping image-heavy sections")
    }

    // MARK: - Render prompt

    func testRenderPromptContainsHTML() {
        let html = "<div>Simplified content</div>"
        let prompt = OpenAIClient.buildRenderPrompt(html: html)

        XCTAssertTrue(prompt.contains("```\n\(html)\n```"),
                       "Render prompt should embed the HTML inside fenced code blocks")
    }

    func testRenderPromptContainsInstruction() {
        let prompt = OpenAIClient.buildRenderPrompt(html: "<p>test</p>")

        XCTAssertTrue(prompt.contains("Render this HTML to PNG"),
                       "Render prompt should include the render instruction")
        XCTAssertTrue(prompt.contains("read it and draw me an image"),
                       "Render prompt should instruct the model to draw, not render")
    }

    // MARK: - Code fence stripping

    func testStripCodeFencesWithHTMLTag() {
        let input = """
        ```html
        <html><body>Hello</body></html>
        ```
        """
        let result = OpenAIClient.stripCodeFences(input)
        XCTAssertEqual(result, "<html><body>Hello</body></html>")
    }

    func testStripCodeFencesWithBareFence() {
        let input = """
        ```
        <html><body>Hello</body></html>
        ```
        """
        let result = OpenAIClient.stripCodeFences(input)
        XCTAssertEqual(result, "<html><body>Hello</body></html>")
    }

    func testStripCodeFencesNoFences() {
        let input = "<html><body>Hello</body></html>"
        let result = OpenAIClient.stripCodeFences(input)
        XCTAssertEqual(result, "<html><body>Hello</body></html>")
    }
}
