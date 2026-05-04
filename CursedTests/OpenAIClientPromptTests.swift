import XCTest
@testable import Cursed

final class OpenAIClientPromptTests: XCTestCase {

    // MARK: - Simplify prompt

    func testSimplifyPromptContainsHTML() {
        let html = "<html><body><h1>Hello</h1></body></html>"
        let prompt = OpenAIClient.buildSimplifyPrompt(html: html)

        XCTAssertTrue(prompt.contains("```\n\(html)\n```"),
                       "Simplify prompt should embed the HTML inside fenced code blocks")
    }

    func testSimplifyPromptContainsInstruction() {
        let prompt = OpenAIClient.buildSimplifyPrompt(html: "<p>test</p>")

        XCTAssertTrue(prompt.contains("Write simplified HTML"),
                       "Simplify prompt should include the simplification instruction")
        XCTAssertTrue(prompt.contains("without elements unrelated to rendering"),
                       "Simplify prompt should mention stripping non-visual elements")
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
