import XCTest
@testable import Cursed

enum TestEnv {
    static func openAIKey(filePath: String = #filePath) -> String? {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !key.trimmingCharacters(in: .whitespaces).isEmpty {
            return key.trimmingCharacters(in: .whitespaces)
        }

        var dir = URL(fileURLWithPath: filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let envURL = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envURL, encoding: .utf8),
               let key = parseDotEnv(contents, name: "OPENAI_API_KEY"),
               !key.isEmpty {
                return key
            }
            let parent = dir.deletingLastPathComponent()
            if parent == dir { break }
            dir = parent
        }
        return nil
    }

    private static func parseDotEnv(_ contents: String, name: String) -> String? {
        for rawLine in contents.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            guard key == name else { continue }
            var value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            if value.count >= 2,
               (value.hasPrefix("\"") && value.hasSuffix("\""))
                || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            return value
        }
        return nil
    }
}

final class OpenAIIntegrationTests: XCTestCase {

    private var apiKey: String!

    override func setUpWithError() throws {
        guard let key = TestEnv.openAIKey() else {
            throw XCTSkip("OPENAI_API_KEY not set in env or repo .env; skipping live API tests.")
        }
        apiKey = key
    }

    func testSimplifyHTMLReturnsNonEmpty() async throws {
        let html = """
        <html><body>
          <h1>Hello world</h1>
          <p>A small paragraph.</p>
          <script>alert('x')</script>
        </body></html>
        """
        let result = try await OpenAIClient.simplifyHTML(html, apiKey: apiKey)
        XCTAssertFalse(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       "Simplified HTML should be non-empty")
    }

    func testRenderImageReturnsPNGBytes() async throws {
        let html = "<html><body><h1>Hi</h1></body></html>"
        let data = try await OpenAIClient.renderImage(html: html, apiKey: apiKey)
        XCTAssertGreaterThan(data.count, 1024, "Expected real image bytes")
        let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        XCTAssertEqual(Array(data.prefix(8)), pngMagic, "Expected PNG magic header")
    }

    func testFullRenderPipeline() async throws {
        let pipeline = RenderPipeline()
        let image = try await pipeline.load(url: "example.com", apiKey: apiKey)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }
}
