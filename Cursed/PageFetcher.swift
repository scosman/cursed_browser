import Foundation

enum PageFetcher {
    static func fetch(_ url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CursedError.network(underlying: error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw CursedError.httpStatus(httpResponse.statusCode)
        }

        // Try UTF-8 first, fall back to ISO-Latin-1
        if let body = String(data: data, encoding: .utf8) {
            return body
        }
        if let body = String(data: data, encoding: .isoLatin1) {
            return body
        }
        // Last resort: lossy UTF-8
        return String(decoding: data, as: UTF8.self)
    }
}
