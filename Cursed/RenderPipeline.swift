import AppKit

final class RenderPipeline {

    func load(url rawURL: String, apiKey: String) async throws -> NSImage {
        let url = try URLNormalizer.normalize(rawURL)
        let html = try await PageFetcher.fetch(url)
        let simplified = try await OpenAIClient.simplifyHTML(html, url: url.absoluteString, apiKey: apiKey)
        let pngData = try await OpenAIClient.renderImage(html: simplified, apiKey: apiKey)

        guard let image = NSImage(data: pngData) else {
            throw CursedError.badImageData
        }

        return image
    }
}
