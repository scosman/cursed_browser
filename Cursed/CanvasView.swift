import SwiftUI

struct CanvasView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if appState.apiKey == nil {
                WelcomeView(appState: appState)
            } else if appState.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let image = appState.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .aspectRatio(3.0 / 2.0, contentMode: .fit)
    }
}
