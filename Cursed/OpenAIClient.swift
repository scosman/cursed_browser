import Foundation

enum OpenAIClient {

    // MARK: - Prompt Builders (testable)

    static func buildSimplifyPrompt(html: String) -> String {
        """
        Write simplified HTML for this page. One that renders the same, without elements unrelated to rendering: javascript, etc. Simplify to get it down to a reasonable facsimile, but short and sweet.

        ```
        \(html)
        ```
        """
    }

    static func buildRenderPrompt(html: String) -> String {
        """
        Render this HTML to PNG. Don't render it using an HTML renderer — read it and draw me an image of what it would render as. No SVGs, no code. Just read and draw.

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

    static func simplifyHTML(_ html: String, apiKey: String) async throws -> String {
        let prompt = buildSimplifyPrompt(html: html)

        let requestBody = ChatRequest(
            model: "gpt-5.5",
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
