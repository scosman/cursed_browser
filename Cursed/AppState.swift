import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String? = nil
    @Published var urlText: String = ""
    @Published var isLoading: Bool = false
    @Published var currentImage: NSImage? = nil
}
