import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String? = nil
    @Published var urlText: String = ""
    @Published var isLoading: Bool = false
    @Published var currentImage: NSImage? = nil
    @Published var currentError: CursedError? = nil

    var currentTask: Task<Void, Never>?

    func submitURL() {
        let raw = urlText
        guard let key = apiKey, !key.isEmpty else { return }

        currentTask?.cancel()

        currentTask = Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let url = try URLNormalizer.normalize(raw)
                let html = try await PageFetcher.fetch(url)

                guard !Task.isCancelled else { return }

                // Placeholder: log HTML length until the render pipeline exists
                print("[Cursed] Fetched \(url.absoluteString): \(html.count) characters")
            } catch let error as CursedError {
                guard !Task.isCancelled else { return }
                currentError = error
            } catch {
                guard !Task.isCancelled else { return }
                currentError = .unknown(error.localizedDescription)
            }
        }
    }
}
