import SwiftUI

struct ChromeBar: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                Image(systemName: "chevron.left")
            }
            .disabled(true)

            Button(action: {}) {
                Image(systemName: "chevron.right")
            }
            .disabled(true)

            TextField("Enter URL", text: $appState.urlText)
                .textFieldStyle(.roundedBorder)
                .disabled(appState.apiKey == nil)
                .onSubmit {
                    appState.submitURL()
                }

            Button(action: { appState.submitURL() }) {
                Image(systemName: "arrow.right")
            }
            .disabled(appState.apiKey == nil || appState.isLoading)
        }
        .padding(8)
    }
}
