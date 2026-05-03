import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(appState: appState)
            CanvasView(appState: appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
