import Foundation

enum PageFetcher {
    static func fetch(_ url: URL) async throws -> String {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
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
