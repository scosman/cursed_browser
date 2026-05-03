import XCTest
@testable import Cursed

final class URLNormalizerTests: XCTestCase {

    // MARK: - Successful normalization

    func testBareHostGetsPrefixed() throws {
        let url = try URLNormalizer.normalize("google.com")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    func testHostWithPathGetsPrefixed() throws {
        let url = try URLNormalizer.normalize("google.com/search")
        XCTAssertEqual(url.absoluteString, "https://google.com/search")
    }

    func testHostWithPathAndQueryGetsPrefixed() throws {
        let url = try URLNormalizer.normalize("google.com/search?q=test")
        XCTAssertEqual(url.absoluteString, "https://google.com/search?q=test")
    }

    func testHttpsURLUnchanged() throws {
        let url = try URLNormalizer.normalize("https://google.com")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    func testHttpURLUnchanged() throws {
        let url = try URLNormalizer.normalize("http://example.com")
        XCTAssertEqual(url.absoluteString, "http://example.com")
    }

    func testHttpsWithPathUnchanged() throws {
        let url = try URLNormalizer.normalize("https://example.com/page?foo=bar")
        XCTAssertEqual(url.absoluteString, "https://example.com/page?foo=bar")
    }

    // MARK: - Whitespace handling

    func testLeadingWhitespaceIsTrimmed() throws {
        let url = try URLNormalizer.normalize("   google.com")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    func testTrailingWhitespaceIsTrimmed() throws {
        let url = try URLNormalizer.normalize("google.com   ")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    func testSurroundingWhitespaceIsTrimmed() throws {
        let url = try URLNormalizer.normalize("  google.com  ")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    func testNewlinesAreTrimmed() throws {
        let url = try URLNormalizer.normalize("\ngoogle.com\n")
        XCTAssertEqual(url.absoluteString, "https://google.com")
    }

    // MARK: - Error cases

    func testEmptyStringThrows() {
        XCTAssertThrowsError(try URLNormalizer.normalize("")) { error in
            XCTAssertEqual(error as? CursedError, .invalidURL)
        }
    }

    func testWhitespaceOnlyThrows() {
        XCTAssertThrowsError(try URLNormalizer.normalize("   ")) { error in
            XCTAssertEqual(error as? CursedError, .invalidURL)
        }
    }

    func testNewlineOnlyThrows() {
        XCTAssertThrowsError(try URLNormalizer.normalize("\n\n")) { error in
            XCTAssertEqual(error as? CursedError, .invalidURL)
        }
    }

    // MARK: - Host validation

    func testURLWithHostReturnsValidHost() throws {
        let url = try URLNormalizer.normalize("example.com")
        XCTAssertEqual(url.host, "example.com")
    }

    func testHttpsURLPreservesHost() throws {
        let url = try URLNormalizer.normalize("https://www.example.com")
        XCTAssertEqual(url.host, "www.example.com")
    }

    func testURLWithPortWorks() throws {
        let url = try URLNormalizer.normalize("localhost:8080")
        XCTAssertEqual(url.absoluteString, "https://localhost:8080")
        XCTAssertEqual(url.host, "localhost")
    }

    func testSubdomainWorks() throws {
        let url = try URLNormalizer.normalize("docs.google.com/document")
        XCTAssertEqual(url.absoluteString, "https://docs.google.com/document")
        XCTAssertEqual(url.host, "docs.google.com")
    }
}
