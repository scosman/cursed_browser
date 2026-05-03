import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(appState: appState)
            CanvasView(appState: appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { appState.currentError != nil },
                set: { if !$0 { appState.currentError = nil } }
            ),
            presenting: appState.currentError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "An unknown error occurred.")
        }
    }
}
