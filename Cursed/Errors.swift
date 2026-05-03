import Foundation

enum CursedError: LocalizedError, Equatable {
    case invalidURL
    case network(underlying: String)
    case httpStatus(Int)
    case openAI(message: String)
    case badImageData
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Enter a valid address like google.com or https://example.com."
        case .network(let underlying):
            return "Network error: \(underlying)"
        case .httpStatus(let code):
            return "The server returned an error (HTTP \(code))."
        case .openAI(let message):
            return "OpenAI API error: \(message)"
        case .badImageData:
            return "The rendered image data could not be decoded."
        case .unknown(let message):
            return "Something went wrong: \(message)"
        }
    }
}
