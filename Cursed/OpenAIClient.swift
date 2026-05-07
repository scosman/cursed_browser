import Foundation

enum OpenAIClient {

    // MARK: - Prompt Builders (testable)

    static func buildSimplifyPrompt(html: String, url: String) -> String {
        """
        Write simplified HTML that a vision model will read and draw as an image. Your job is to produce HTML the renderer can use to draw what a real browser user would see at this URL — not a literal rendering of the input bytes.

        Goal: render like a real browser would. When that conflicts with rendering the HTML as-is, choose "like a real browser".

        Three cases — pick whichever fits the input:

        1. Complete, working page. Stay true to it; let the original page drive layout, structure, and design. Keep `<img>` tags with src, alt, and any size/class hints — the renderer draws images well from filename, dimensions, and alt text, so do NOT drop image-heavy sections or replace them with placeholders. Keep meaningful structure (header, nav, main, sidebars, footer). Strip only what doesn't render: scripts, tracking pixels, hidden meta, raw style/data blobs.

        2. JavaScript-rendered page (SPA shell, empty root div, "Loading...", no real content in the body). Predict the post-hydration state and write HTML for THAT, not the pre-JS shell. Use any signal available — title, meta/og tags, JSON embedded in `<script>` tags, link hrefs, the URL itself — and produce simplified HTML as if you'd captured the page after it finished loading.

        3. Bot-blocked, captcha, "Access denied", "unusual traffic", or any anti-bot interstitial. Ignore the block. Use the URL — domain, path, query parameters — to guess what the user was trying to see, and render a plausible version of that. A Reddit thread URL → a plausible Reddit thread page. A Google search URL with `q=cats` → a plausible search results page. Lean creative; a real-ish page beats a "blocked" screen. Don't mention the block.

        A VLM-based browser is unstoppable — it can guess. Be confident and creative when needed.

        Output only the simplified HTML. No commentary, no code fences.

        URL: \(url)

        ```
        \(html)
        ```
        """
    }

    static func buildRenderPrompt(html: String) -> String {
        """
        Render this HTML to PNG. Don't render it using an HTML renderer — read it and draw me an image of what it would render as. No SVGs, no code. Just read and draw. Render the page in 3:2 aspect ratio as if in a browser of 1000px width; this may result in the page being truncated (some content under the fold), that's okay and expected; don't attempt to render whole page to the bottom unless the page is short.

        ```
        \(html)
        ```
        """
    }

    // MARK: - Code Fence Stripping

    static func stripCodeFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Match ```html or ```<anything> at the start
        if result.hasPrefix("```") {
            // Remove opening fence line
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            } else {
                // Single-line fenced block (degenerate case)
                result.removeFirst(3)
            }

            // Remove closing fence
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }

            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return result
    }

    // MARK: - API Calls

    static func simplifyHTML(_ html: String, url: String, apiKey: String) async throws -> String {
        let prompt = buildSimplifyPrompt(html: html, url: url)

        let requestBody = ChatRequest(
            model: "gpt-5.4-mini",
            messages: [ChatMessage(role: "user", content: prompt)]
        )

        let data = try await post(
            path: "/v1/chat/completions",
            body: requestBody,
            apiKey: apiKey
        )

        let response: ChatResponse
        do {
            response = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw CursedError.openAI(message: "Failed to parse simplify response")
        }

        guard let content = response.choices.first?.message.content else {
            throw CursedError.openAI(message: "No content in simplify response")
        }

        return stripCodeFences(content)
    }

    static func renderImage(html: String, apiKey: String) async throws -> Data {
        let prompt = buildRenderPrompt(html: html)

        let requestBody = ImageRequest(
            model: "gpt-image-2",
            prompt: prompt,
            size: "1536x1024"
        )

        let data = try await post(
            path: "/v1/images/generations",
            body: requestBody,
            apiKey: apiKey
        )

        let response: ImageResponse
        do {
            response = try JSONDecoder().decode(ImageResponse.self, from: data)
        } catch {
            throw CursedError.openAI(message: "Failed to parse image response")
        }

        guard let b64String = response.data.first?.b64_json else {
            throw CursedError.openAI(message: "No image data in response")
        }

        guard let pngData = Data(base64Encoded: b64String) else {
            throw CursedError.openAI(message: "Invalid base64 image data")
        }

        return pngData
    }

    // MARK: - HTTP Helper

    private static func post<T: Encodable>(
        path: String,
        body: T,
        apiKey: String
    ) async throws -> Data {
        guard let url = URL(string: "https://api.openai.com\(path)") else {
            throw CursedError.openAI(message: "Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 240
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CursedError.openAI(message: "Network error: \(error.localizedDescription)")
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            // Try to extract error message from OpenAI response
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw CursedError.openAI(message: errorResponse.error.message)
            }
            throw CursedError.openAI(message: "HTTP \(httpResponse.statusCode)")
        }

        return data
    }

    // MARK: - Codable Types

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
    }

    private struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    struct ChatResponse: Decodable {
        let choices: [ChatChoice]
    }

    struct ChatChoice: Decodable {
        let message: ChatResponseMessage
    }

    struct ChatResponseMessage: Decodable {
        let content: String?
    }

    private struct ImageRequest: Encodable {
        let model: String
        let prompt: String
        let size: String
    }

    struct ImageResponse: Decodable {
        let data: [ImageData]
    }

    struct ImageData: Decodable {
        let b64_json: String?
    }

    private struct OpenAIErrorResponse: Decodable {
        let error: OpenAIErrorDetail
    }

    private struct OpenAIErrorDetail: Decodable {
        let message: String
    }
}
